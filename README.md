# MILLION — Flutter و وێب

بەرنامەیا فلم و دراما ب بادینییا دهۆکێ، ب Flutter هاتییە نڤیسین. فۆنتێ Speda Bold ل `assets/fonts/Speda-Bold.ttf` ـە.

## دەستپێکرن

پێدڤییە Flutter SDK ل سیستەمێ دابمەزرێت. ئەگەر فۆڵدەریێن پلاتفۆرمێ نەبوون، بۆ دروستکرنا Android و iOS و Web:

```sh
flutter create --platforms android,ios,web .
flutter pub get
flutter run
```

بۆ دروستکرنا APK:

```sh
flutter build apk
```

## تایبەتمەندیێن Flutter

- ڕووکاری RTL ب بادینییا دهۆکێ و فۆنتێ Speda
- لاپەرێ سەرەکی ب سلایدەرێ خۆکار هەر دوو چرکە
- بەشێن جودا بۆ فلم، دراما، لایڤ، بژاردە و سیتنگ
- لێگەڕین و فلتەرکرنا ناڤەرۆکێ
- دروستکرنا هەژمار ب ناڤ، ئیمەیڵ و وشەیا نهێنی، یان چوونەژوور ب Google/Gmail یان Apple؛ ناڤ و ئیمەیڵی هەژمار پڕۆفایلێ پڕ دکەن
- دەستگەهشتنا پەخشێ تەنێ ب هەژمارا Firebase و claim ـا `premium: true` یا سێرڤەری ڕێپێدراو دەبیت؛ چوونەژوورێ ب تەنێ بەس نینە
- Admin بەشەکا جودایە: `million` ل گەڕانێ بنڤیسە و ب رمزێ `123` ڤەکە؛ ناڤ و وێنەی فلم و درامایان بگوهۆڕە
- سیتنگ بێ رمز: گۆڕینا ڕەنگا تاریک و ڕوون، Contact Us و Privacy Policy
- پاراستنا ناڤەرۆک، وێنە و بژاردەیان ل ئامێرێ
- هەلبژارتنا وێنە ژ ئامێرێ یان گوهۆڕینا لینکا وێنێ

بەشی لایڤ ئامادەیە، بەڵام بۆ پەخشکرنا کاناڵان لینکێ ڤیدیۆیێ یا مۆڵەتپێدراو پێدڤییە. فلم و ئەڵقەکان داتایێن نموونەیی ن، ژبەر کو لینکێن پەخشێ نەهاتینە دابینکرن.

بۆ بینینا وێبێ، باشترە ل `localhost` یان domain ـەکا HTTPS ڕایبکە؛ چوونەژووریا Firebase ل `file://` کار ناکەت. ل گەڕانێ `million` بنڤیسە، نیشانا Admin دێ ل مێنیویا خوارێ دەرکەڤێت؛ رمز `123` ـە. سیتنگ بێ رمزە. کۆدی Flutter ل `lib/main.dart` ـە. بۆ ڕاکرنا Flutter پێدڤییە SDK هەبیت، پاشی `flutter pub get` و `flutter run` بنڤیسە.




## HD features added

- Search text is larger and higher contrast; artwork loads at higher resolution.
- Settings offers Kurdish, Arabic, and English labels, plus the listed subscription plans.
- Admin (search `million`, then PIN `123`) can add films, dramas, video URLs, and live HLS/MP4 links.
- HLS playback uses hls.js in web browsers that support Media Source Extensions, with native HLS fallback.
- Flutter source includes the same pricing, language selector, local admin media/live forms, and `video_player` playback.

## Production setup still required

No Firebase project, payment provider, or protected media server is connected in this workspace. The sign-in and subscription gate remain fail-closed until the setup below is completed.

## Firebase sign-in and premium access

Google/Apple sign-in and email/password sign-in are implemented for the web and Flutter. Email/password account creation requires a six-digit email verification code. The password and code are submitted over HTTPS to a trusted Firebase callable function; it creates the Auth account only after validating the code, and never stores or logs the password. The profile is populated from the authenticated Firebase account. Firebase ID-token custom claims are checked before playback. Configure Firebase before enabling account sign-in:

1. Create a Firebase project, register web/Android/iOS apps, and enable Email/Password, Google, and Apple under Authentication → Sign-in method. Configure each provider's OAuth credentials and authorized domains in Firebase; Apple sign-in on iOS also requires the Apple capability and provider configuration.
2. Copy the Firebase **web app** `apiKey`, `authDomain`, `projectId`, and `appId` into `firebase-config.js`. These are public client settings, not passwords or service-account secrets.
3. For Flutter, provide `MILLION_FIREBASE_API_KEY`, `MILLION_FIREBASE_PROJECT_ID`, and `MILLION_FIREBASE_SENDER_ID`, plus the matching platform app ID. Web additionally needs `MILLION_FIREBASE_AUTH_DOMAIN`; iOS needs `MILLION_IOS_BUNDLE_ID`. Supply them as `--dart-define` values when building/running. `lib/firebase_options.dart` deliberately contains no project credentials.
4. Configure Google OAuth client IDs and Android signing fingerprints, and configure the Apple Service ID / return URL and iOS Sign in with Apple capability as required by Firebase. If native Flutter platform folders have not been generated yet, run `flutter create --platforms android,ios,web .` before configuring the native OAuth callbacks. Use `localhost` or an HTTPS domain authorized in Firebase; direct `file://` opening cannot complete OAuth.

### Email verification code backend

Email/password sign-up is intentionally unavailable until the trusted code-sending backend is deployed. Numeric codes are generated and verified only in Firebase Cloud Functions; Firestore stores only an HMAC of each code, with a 10-minute expiry, five verification attempts, a one-minute resend cooldown, and per-email/IP hourly limits. Client Firestore access is denied by `firestore.rules`.

1. Enable billing for the Firebase project if the console requires the Blaze plan for Cloud Functions, and create the default Firestore database.
2. Create a Resend account, verify a sending domain, and choose a sender address on that domain. Do not use Resend's test sender for general users.
3. Install the Firebase CLI, sign in, select project `million-675db`, and set the two function secrets without sharing them:

   ```sh
   npm install -g firebase-tools
   firebase login
   firebase use million-675db
   firebase functions:secrets:set RESEND_API_KEY
   firebase functions:secrets:set OTP_HASH_SECRET
   ```

   Use a randomly generated, high-entropy value for `OTP_HASH_SECRET`. Never commit either secret or paste it into chat.
4. Deploy the rules and backend from the project root:

   ```sh
   firebase deploy --only firestore:rules,functions
   ```

   When prompted for `MILLION_OTP_FROM`, enter the verified Resend sender, for example `MILLION <verify@example.com>`.
5. Install Flutter dependencies (`flutter pub get`) before building the native app, so `cloud_functions` is included.

Until this backend and a verified sender domain are configured, email/password sign-up will show an explicit service error. Google and Apple sign-in do not use the email-code flow.

Premium access is **not** granted by signing in, by local storage, or by submitting the existing local subscription request. Playback requires the Firebase ID token to contain the server-issued `premium: true` custom claim. Until a payment provider is integrated and a trusted server assigns/removes this claim, users will not have premium playback. Never set this claim from client code. The authenticated account's name and email come from Firebase; locally added catalogue items, subscription requests, and live links remain device-local.

The current catalogue contains sample metadata and no protected movie library. A browser/app-side entitlement check only hides playback controls; it cannot secure public video URLs. Before publishing paid videos, store them behind private media storage and issue short-lived playback URLs only after the server validates the user's entitlement. Keep payment verification and entitlement changes on a trusted server; never put service-account keys or payment secrets in the app.

## Public website and Google Search

The static web app is prepared for GitHub Pages deployment. Push the project to a GitHub repository on its `main` or `master` branch and enable GitHub Actions for Pages; `.github/workflows/deploy-pages.yml` publishes the site on each push. The workflow URL appears in the repository's Actions run after the first successful deployment.

The site includes basic search and social sharing metadata and permits search crawlers in `robots.txt`. Once the deployed public URL is available, add it to Google Search Console and request indexing. Google decides when and whether to show a site in search; indexing is not immediate or guaranteed. A custom canonical URL and sitemap should only be added after the final public URL is known.
