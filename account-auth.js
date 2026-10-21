(() => {
  const status = document.querySelector('#account-status');
  const setupNote = document.querySelector('#account-setup-note');
  const profileDetails = document.querySelector('#account-profile-details');
  const profileName = document.querySelector('#account-profile-name');
  const profileEmail = document.querySelector('#account-profile-email');
  const emailForm = document.querySelector('#account-email-form');
  const nameField = document.querySelector('#account-name-field');
  const nameInput = document.querySelector('#account-name');
  const emailInput = document.querySelector('#account-email');
  const passwordInput = document.querySelector('#account-password');
  const codeField = document.querySelector('#account-code-field');
  const codeInput = document.querySelector('#account-code');
  const submitButton = document.querySelector('#account-email-submit');
  const resendCodeButton = document.querySelector('#account-resend-code');
  const modeToggle = document.querySelector('#account-mode-toggle');
  const googleButton = document.querySelector('#account-google');
  const appleButton = document.querySelector('#account-apple');
  const signOutButton = document.querySelector('#account-signout');
  if (!status || !setupNote || !emailForm || !profileDetails || !googleButton || !appleButton || !signOutButton) return;

  const config = window.MILLION_FIREBASE_CONFIG;
  const configured = config && ['apiKey', 'authDomain', 'projectId', 'appId'].every(key => typeof config[key] === 'string' && config[key].trim());
  let auth = null;
  let user = null;
  let premium = false;
  let creatingAccount = true;
  let codeSent = false;
  let functions = null;

  function stopPlayback() {
    const video = document.querySelector('#video-player');
    if (!video) return;
    video.pause();
    video.removeAttribute('src');
    video.load();
    video.hidden = true;
  }

  function showError(error) {
    console.error('MILLION account error:', error);
    const messages = {
      'auth/unauthorized-domain': 'ئەم domain ـە ل Firebase نەهاتییە مۆڵەتپێدان.',
      'auth/popup-closed-by-user': 'پەنجەرەیا چوونەژوورێ هاتە داخستن.',
      'auth/popup-blocked': 'وێبگەڕ پەنجەرەیا چوونەژوورێ داخست؛ popup ڕێپێبدە.',
      'auth/email-already-in-use': 'ئەڤ ئیمەیڵە پێشتر هەژمارەکا هەیە؛ بچۆ ژوور.',
      'auth/invalid-email': 'فۆرماتا ئیمەیڵێ نەراستە.',
      'auth/weak-password': 'وشەیا نهێنی پێدڤییە لانیکەم ٨ پیت بیت.',
      'auth/invalid-credential': 'ئیمەیڵ یان وشەیا نهێنی نەراستە.',
      'auth/user-disabled': 'ئەڤ هەژمارە ناچالاکە.',
      'auth/too-many-requests': 'هەوڵ زۆر هاتن؛ کەمێک چاوەڕێ بکە و جارەکا دی تاقی بکە.',
      'functions/invalid-argument': 'زانیاری یان کۆد نەراستە، یان کۆد کۆتایی هاتییە.',
      'functions/already-exists': 'ئەڤ ئیمەیڵە پێشتر هەژمارەکا هەیە؛ بچۆ ژوور.',
      'functions/resource-exhausted': 'داواکاری زۆر بوو؛ کەمێک چاوەڕێ بکە و جارەکا دی تاقی بکە.',
      'functions/not-found': 'سێرڤەرێ کۆدێ پشتڕاستکرنێ نەهاتییە چالاککرن.',
      'functions/unavailable': 'پەیوەندییا سێرڤەرێ نەهاتییە؛ دواتر جارەکا دی تاقی بکە.'
    };
    status.textContent = messages[error.code] || `چوونەژوور نەسەرکەفت: ${error.message || 'هەڵەیەکا نەناسراو.'}`;
  }

  function updateMode() {
    codeSent = false;
    codeField.hidden = true;
    resendCodeButton.hidden = true;
    codeInput.required = false;
    codeInput.value = '';
    nameField.hidden = !creatingAccount;
    nameInput.required = creatingAccount;
    nameInput.autocomplete = creatingAccount ? 'name' : 'off';
    passwordInput.autocomplete = creatingAccount ? 'new-password' : 'current-password';
    passwordInput.minLength = creatingAccount ? 8 : 0;
    submitButton.textContent = creatingAccount ? 'کۆدی پشتڕاستکرنێ بنێرە' : 'بچۆ ژوور';
    modeToggle.textContent = creatingAccount ? 'هەژمارا تە هەیە؟ بچۆ ژوور' : 'هەژمارا تە نینە؟ هەژمارا نوی دروست بکە';
    status.textContent = creatingAccount ? 'ناڤ، ئیمەیڵ و وشەیا نهێنی بنڤیسە؛ کۆدی پشتڕاستکرنێ بۆ ئیمەیڵێ تە دێ هێت.' : 'ب ئیمەیڵ و وشەیا نهێنی بچۆ ژوور.';
  }

  function updateProfile(userInfo) {
    const name = userInfo?.displayName?.trim() || userInfo?.email?.split('@')[0] || 'بەکارهێنەرێ MILLION';
    const avatar = document.querySelector('#profile-avatar');
    const preview = document.querySelector('#profile-preview');
    for (const target of [avatar, preview]) {
      target.replaceChildren();
      if (userInfo?.photoURL) {
        const image = document.createElement('img');
        image.src = userInfo.photoURL;
        image.alt = '';
        target.append(image);
      } else {
        const icon = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
        icon.setAttribute('viewBox', '0 0 24 24');
        icon.setAttribute('aria-hidden', 'true');
        icon.innerHTML = '<circle cx="12" cy="8" r="4"></circle><path d="M4 21a8 8 0 0 1 16 0"></path>';
        target.append(icon);
      }
    }
    document.querySelector('#profile-name').textContent = userInfo ? name : 'هەژمار دروست بکە';
    document.querySelector('#profile-open').setAttribute('aria-label', userInfo ? `پڕۆفایلێ ${name}` : 'دروستکرنا هەژمارا MILLION');
    profileName.textContent = name;
    profileEmail.textContent = userInfo?.email || '';
  }

  function requestWatchAccess() {
    if (!user) {
      status.textContent = configured ? 'بۆ سەیرکرنێ هەژمار دروست بکە یان بچۆ ژوور.' : 'بۆ چالاککرنا هەژمارێ، Firebase ڕێک بخە.';
      document.querySelector('#profile-dialog').showModal();
      return;
    }
    if (!premium) toast('ئەڤ هەژمارە اشتراکەکا پارێزراو یا چالاک نینە؛ پارەدان هێشتا نەچالاکە.');
  }

  async function hasPlaybackAccess() {
    if (!auth || !user) {
      stopPlayback();
      requestWatchAccess();
      return false;
    }
    try {
      const token = await user.getIdTokenResult(true);
      premium = token.claims.premium === true;
      if (premium) return true;
      stopPlayback();
      requestWatchAccess();
      return false;
    } catch (error) {
      stopPlayback();
      showError(error);
      return false;
    }
  }

  async function signIn(provider) {
    if (!auth) return;
    googleButton.disabled = true;
    appleButton.disabled = true;
    try {
      await auth.signInWithPopup(provider);
      document.querySelector('#profile-dialog').close();
    } catch (error) {
      showError(error);
    } finally {
      googleButton.disabled = false;
      appleButton.disabled = false;
    }
  }

  modeToggle.addEventListener('click', () => {
    creatingAccount = !creatingAccount;
    updateMode();
  });

  emailInput.addEventListener('input', () => {
    if (!codeSent) return;
    codeSent = false;
    codeField.hidden = true;
    resendCodeButton.hidden = true;
    codeInput.required = false;
    codeInput.value = '';
    submitButton.textContent = 'کۆدێ پشتڕاستکرنێ بنێرە';
    status.textContent = 'ئیمەیڵ گوهۆڕا؛ بۆ ڤی ئیمەیڵی کۆدەکا نوی بخوازە.';
  });

  emailForm.addEventListener('submit', async event => {
    event.preventDefault();
    if (!auth) {
      status.textContent = 'بۆ دروستکرنا هەژمارێ Firebase ڕێک بخە.';
      return;
    }
    const email = emailInput.value.trim();
    const password = passwordInput.value;
    const name = nameInput.value.trim();
    if (!email || (creatingAccount && (!password || !name || (codeSent && !/^\d{6}$/.test(codeInput.value.trim()))))) {
      status.textContent = codeSent ? 'کۆدی ٦ ژمارەیی بنڤیسە.' : 'تکایە هەمی خانە پێدڤییەکان پڕ بکە.';
      return;
    }
    submitButton.disabled = true;
    googleButton.disabled = true;
    appleButton.disabled = true;
    try {
      if (creatingAccount) {
        if (!codeSent) {
          await functions.httpsCallable('requestEmailSignupCode')({ email });
          codeSent = true;
          codeField.hidden = false;
          resendCodeButton.hidden = false;
          codeInput.required = true;
          submitButton.textContent = 'کۆد پشتڕاست بکە و هەژمار دروست بکە';
          status.textContent = 'کۆدی ٦ ژمارەیی بۆ ئیمەیڵێ تە هات. کۆدەکە بنڤیسە.';
          codeInput.focus();
          return;
        }
        await functions.httpsCallable('completeEmailSignup')({
          email,
          code: codeInput.value.trim(),
          name,
          password
        });
        await auth.signInWithEmailAndPassword(email, password);
      } else {
        await auth.signInWithEmailAndPassword(email, password);
      }
      emailForm.reset();
      document.querySelector('#profile-dialog').close();
    } catch (error) {
      showError(error);
    } finally {
      submitButton.disabled = false;
      googleButton.disabled = false;
      appleButton.disabled = false;
    }
  });

  resendCodeButton.addEventListener('click', async () => {
    resendCodeButton.disabled = true;
    try {
      await functions.httpsCallable('requestEmailSignupCode')({ email: emailInput.value.trim() });
      codeInput.value = '';
      status.textContent = 'کۆدەکا نوی بۆ ئیمەیڵێ تە هات؛ پۆستا ژ نوو بپشکنە.';
    } catch (error) {
      showError(error);
    } finally {
      resendCodeButton.disabled = false;
    }
  });

  if (!configured || !window.firebase || !firebase.auth || !firebase.functions) {
    setupNote.textContent = 'بۆ چالاککرنا دروستکرنا هەژمارێ و چوونەژوورێ، Firebase ل firebase-config.js ڕێک بخە.';
    emailForm.querySelectorAll('input,button').forEach(control => { control.disabled = true; });
    googleButton.disabled = true;
    appleButton.disabled = true;
    updateMode();
  } else {
    try {
      if (!firebase.apps.length) firebase.initializeApp(config);
      auth = firebase.auth();
      functions = firebase.app().functions('us-central1');
      setupNote.textContent = 'بۆ هەژمارا ئیمەیڵی، کۆدەکا ٦ ژمارەیی دەنێردرێت؛ backend ـی Firebase و Resend پێدڤییە چالاک بن.';
      googleButton.addEventListener('click', () => signIn(new firebase.auth.GoogleAuthProvider()));
      const apple = new firebase.auth.OAuthProvider('apple.com');
      apple.addScope('email');
      apple.addScope('name');
      appleButton.addEventListener('click', () => signIn(apple));
      signOutButton.addEventListener('click', async () => {
        try {
          await auth.signOut();
        } catch (error) {
          showError(error);
        }
      });
      auth.onAuthStateChanged(async currentUser => {
        user = currentUser;
        premium = false;
        stopPlayback();
        signOutButton.hidden = !currentUser;
        emailForm.hidden = !!currentUser;
        modeToggle.hidden = !!currentUser;
        googleButton.hidden = !!currentUser;
        appleButton.hidden = !!currentUser;
        profileDetails.hidden = !currentUser;
        updateProfile(currentUser);
        if (!currentUser) {
          updateMode();
          return;
        }
        try {
          const token = await currentUser.getIdTokenResult(true);
          premium = token.claims.premium === true;
          document.querySelector('#account-entitlement').textContent = premium ? 'اشتراک چالاکە' : 'اشتراک چالاک نینە';
          status.textContent = 'هەژمار بە سەرکەفتی گرێدرا.';
        } catch (error) {
          user = null;
          updateProfile(null);
          showError(error);
        }
      }, showError);
    } catch (error) {
      showError(error);
    }
  }

  document.addEventListener('click', event => {
    if (user && premium) return;
    const target = event.target instanceof Element ? event.target : null;
    if (!target || !target.closest('#detail-play, .episode-row, #live-page .live-watch, #live-page [data-live-url]')) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    requestWatchAccess();
  }, true);

  window.MillionAuth = { hasPlaybackAccess };
  for (const name of ['playVideo', 'openLiveStream']) {
    const original = window[name];
    if (typeof original !== 'function') continue;
    window[name] = async (...args) => {
      if (!await hasPlaybackAccess()) return;
      return original(...args);
    };
  }

  document.querySelector('#video-player')?.addEventListener('play', event => {
    if (user && premium) return;
    event.target.pause();
    requestWatchAccess();
  }, true);
})();
