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

Email/password account creation and Google/Apple sign-in are implemented for the web and Flutter. The profile is populated from the authenticated Firebase account; passwords are sent directly to Firebase Authentication and are never stored in MILLION. Firebase ID-token custom claims are checked before playback. Configure Firebase before enabling account sign-in:

1. Create a Firebase project, register web/Android/iOS apps, and enable Email/Password, Google, and Apple under Authentication → Sign-in method. Configure each provider's OAuth credentials and authorized domains in Firebase; Apple sign-in on iOS also requires the Apple capability and provider configuration.
2. Copy the Firebase **web app** `apiKey`, `authDomain`, `projectId`, and `appId` into `firebase-config.js`. These are public client settings, not passwords or service-account secrets.
3. For Flutter, provide `MILLION_FIREBASE_API_KEY`, `MILLION_FIREBASE_PROJECT_ID`, and `MILLION_FIREBASE_SENDER_ID`, plus the matching platform app ID. Web additionally needs `MILLION_FIREBASE_AUTH_DOMAIN`; iOS needs `MILLION_IOS_BUNDLE_ID`. Supply them as `--dart-define` values when building/running. `lib/firebase_options.dart` deliberately contains no project credentials.
4. Configure Google OAuth client IDs and Android signing fingerprints, and configure the Apple Service ID / return URL and iOS Sign in with Apple capability as required by Firebase. If native Flutter platform folders have not been generated yet, run `flutter create --platforms android,ios,web .` before configuring the native OAuth callbacks. Use `localhost` or an HTTPS domain authorized in Firebase; direct `file://` opening cannot complete OAuth.

Premium access is **not** granted by signing in, by local storage, or by submitting the existing local subscription request. Playback requires the Firebase ID token to contain the server-issued `premium: true` custom claim. Until a payment provider is integrated and a trusted server assigns/removes this claim, users will not have premium playback. Never set this claim from client code. The authenticated account's name and email come from Firebase; locally added catalogue items, subscription requests, and live links remain device-local.

The current catalogue contains sample metadata and no protected movie library. A browser/app-side entitlement check only hides playback controls; it cannot secure public video URLs. Before publishing paid videos, store them behind private media storage and issue short-lived playback URLs only after the server validates the user's entitlement. Keep payment verification and entitlement changes on a trusted server; never put service-account keys or payment secrets in the app.

## Public website and Google Search

The static web app is prepared for GitHub Pages deployment. Push the project to a GitHub repository on its `main` or `master` branch and enable GitHub Actions for Pages; `.github/workflows/deploy-pages.yml` publishes the site on each push. The workflow URL appears in the repository's Actions run after the first successful deployment.

The site includes basic search and social sharing metadata and permits search crawlers in `robots.txt`. Once the deployed public URL is available, add it to Google Search Console and request indexing. Google decides when and whether to show a site in search; indexing is not immediate or guaranteed. A custom canonical URL and sitemap should only be added after the final public URL is known.
