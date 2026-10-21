const crypto = require("node:crypto");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { defineSecret, defineString } = require("firebase-functions/params");
const { HttpsError, onCall } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");

initializeApp();
setGlobalOptions({ region: "us-central1", maxInstances: 10 });

const RESEND_API_KEY = defineSecret("RESEND_API_KEY");
const OTP_HASH_SECRET = defineSecret("OTP_HASH_SECRET");
const OTP_FROM = defineString("MILLION_OTP_FROM");
const db = getFirestore();
const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const codeLifetimeMs = 10 * 60 * 1000;
const rateWindowMs = 60 * 60 * 1000;
const sendCooldownMs = 60 * 1000;
const maxCodesPerEmail = 5;
const maxCodesPerIp = 20;
const maxCodeAttempts = 5;

function normalizeEmail(value) {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", "Enter a valid email address.");
  }
  const email = value.trim().toLowerCase();
  if (email.length > 254 || !emailPattern.test(email)) {
    throw new HttpsError("invalid-argument", "Enter a valid email address.");
  }
  return email;
}

function hash(value, secret = "") {
  return secret
    ? crypto.createHmac("sha256", secret).update(value).digest("hex")
    : crypto.createHash("sha256").update(value).digest("hex");
}

function codeHash(email, code) {
  return hash(`${email}:${code}`, OTP_HASH_SECRET.value());
}

function equalHash(left, right) {
  const leftBuffer = Buffer.from(left, "hex");
  const rightBuffer = Buffer.from(right, "hex");
  return leftBuffer.length === rightBuffer.length && crypto.timingSafeEqual(leftBuffer, rightBuffer);
}

function rateState(snapshot, now) {
  const data = snapshot.data();
  const windowStart = data?.windowStart?.toMillis?.() ?? 0;
  const active = now - windowStart < rateWindowMs;
  return {
    count: active ? data.count ?? 0 : 0,
    windowStart: active ? windowStart : now,
    lastSent: data?.lastSent?.toMillis?.() ?? 0,
  };
}

async function sendCode(email, code) {
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${RESEND_API_KEY.value()}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: OTP_FROM.value(),
      to: [email],
      subject: "کۆدی پشتڕاستکرنا MILLION",
      text: `کۆدی پشتڕاستکرنا هەژمارا MILLION یا تە: ${code}. ئەڤ کۆدە پشتی ١٠ خولەکان دکەڤیت. ئەگەر تە نەداوا کرییە، ئەڤ ئیمەیڵە پشتگوڤە بکە.`,
    }),
  });
  if (!response.ok) {
    const responseBody = await response.text();
    console.error("Resend rejected the MILLION verification email:", response.status, responseBody);
    throw new HttpsError("internal", "The verification email could not be sent. Try again later.");
  }
}

exports.requestEmailSignupCode = onCall(
  { secrets: [RESEND_API_KEY, OTP_HASH_SECRET] },
  async (request) => {
    const email = normalizeEmail(request.data?.email);
    try {
      await getAuth().getUserByEmail(email);
      throw new HttpsError("already-exists", "An account already uses this email. Sign in instead.");
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      if (error.code !== "auth/user-not-found") throw error;
    }

    const ip = request.rawRequest.ip || "unknown";
    const emailKey = hash(email, OTP_HASH_SECRET.value());
    const ipKey = hash(ip, OTP_HASH_SECRET.value());
    const challengeRef = db.collection("signupEmailCodes").doc(emailKey);
    const emailRateRef = db.collection("signupEmailCodes").doc(`email-rate-${emailKey}`);
    const ipRateRef = db.collection("signupEmailCodes").doc(`ip-rate-${ipKey}`);
    const now = Date.now();
    const code = crypto.randomInt(0, 1_000_000).toString().padStart(6, "0");

    await db.runTransaction(async (transaction) => {
      const [challenge, emailRate, ipRate] = await Promise.all([
        transaction.get(challengeRef),
        transaction.get(emailRateRef),
        transaction.get(ipRateRef),
      ]);
      const emailState = rateState(emailRate, now);
      const ipState = rateState(ipRate, now);

      if (emailState.lastSent && now - emailState.lastSent < sendCooldownMs) {
        throw new HttpsError("resource-exhausted", "Wait a minute before requesting another code.");
      }
      if (emailState.count >= maxCodesPerEmail || ipState.count >= maxCodesPerIp) {
        throw new HttpsError("resource-exhausted", "Too many code requests. Try again later.");
      }

      transaction.set(challengeRef, {
        codeHash: codeHash(email, code),
        createdAt: Timestamp.fromMillis(now),
        expiresAt: Timestamp.fromMillis(now + codeLifetimeMs),
        attempts: 0,
        used: false,
      });
      transaction.set(emailRateRef, {
        count: emailState.count + 1,
        windowStart: Timestamp.fromMillis(emailState.windowStart),
        lastSent: Timestamp.fromMillis(now),
      });
      transaction.set(ipRateRef, {
        count: ipState.count + 1,
        windowStart: Timestamp.fromMillis(ipState.windowStart),
        lastSent: Timestamp.fromMillis(now),
      });
    });

    try {
      await sendCode(email, code);
    } catch (error) {
      await challengeRef.delete();
      throw error;
    }
    return { sent: true, expiresInSeconds: codeLifetimeMs / 1000 };
  },
);

exports.completeEmailSignup = onCall(
  { secrets: [OTP_HASH_SECRET] },
  async (request) => {
    const email = normalizeEmail(request.data?.email);
    const { code, name, password } = request.data ?? {};
    if (typeof code !== "string" || !/^\d{6}$/.test(code)) {
      throw new HttpsError("invalid-argument", "Enter the 6-digit code from your email.");
    }
    if (typeof name !== "string" || !name.trim() || name.trim().length > 80) {
      throw new HttpsError("invalid-argument", "Enter a valid name.");
    }
    if (typeof password !== "string" || password.length < 8 || password.length > 128) {
      throw new HttpsError("invalid-argument", "The password must be at least 8 characters.");
    }

    const emailKey = hash(email, OTP_HASH_SECRET.value());
    const challengeRef = db.collection("signupEmailCodes").doc(emailKey);
    const expectedHash = codeHash(email, code);
    const valid = await db.runTransaction(async (transaction) => {
      const challenge = await transaction.get(challengeRef);
      const data = challenge.data();
      if (!data || data.used || data.expiresAt.toMillis() <= Date.now()) {
        return false;
      }
      if (data.attempts >= maxCodeAttempts) {
        throw new HttpsError("resource-exhausted", "Too many incorrect codes. Request a new code.");
      }
      if (!equalHash(data.codeHash, expectedHash)) {
        transaction.update(challengeRef, { attempts: data.attempts + 1 });
        return false;
      }
      transaction.update(challengeRef, { used: true });
      return true;
    });

    if (!valid) {
      throw new HttpsError("invalid-argument", "The code is incorrect or expired. Request a new code.");
    }

    try {
      await getAuth().createUser({
        email,
        password,
        displayName: name.trim(),
        emailVerified: true,
      });
      return { created: true };
    } catch (error) {
      if (error.code === "auth/email-already-exists") {
        throw new HttpsError("already-exists", "An account already uses this email. Sign in instead.");
      }
      console.error("MILLION account creation failed:", error.code || error.message);
      throw new HttpsError("internal", "The account could not be created. Request a new code and try again.");
    }
  },
);
