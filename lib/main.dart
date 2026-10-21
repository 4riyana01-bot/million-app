import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:video_player/video_player.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (DefaultFirebaseOptions.isConfigured) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  runApp(const MillionApp());
}

const ink = Color(0xFF0B1C16);
const panel = Color(0xFF14271F);
const blue = Color(0xFF91B783);
const gold = Color(0xFFC6DDA5);
const muted = Color(0xFFA6B9AA);

class MillionApp extends StatefulWidget {
  const MillionApp({super.key});
  @override
  State<MillionApp> createState() => _MillionAppState();
}

class _MillionAppState extends State<MillionApp> {
  bool _darkMode = true;

  void _setTheme(bool value) => setState(() => _darkMode = value);

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'MILLION',
        debugShowCheckedModeBanner: false,
        themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: ink,
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF10231A), foregroundColor: Colors.white),
          colorScheme: ColorScheme.fromSeed(seedColor: blue, brightness: Brightness.dark),
          fontFamily: 'Speda',
          useMaterial3: true,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF0B1C16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF3D5B45))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF3D5B45))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          ),
        ),
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF3F6FA),
          appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Color(0xFF20382B), elevation: 1),
          colorScheme: ColorScheme.fromSeed(seedColor: blue, brightness: Brightness.light),
          fontFamily: 'Speda',
          useMaterial3: true,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD5E2D1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD5E2D1))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          ),
        ),
        builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
        home: MillionHome(darkMode: _darkMode, onThemeChange: _setTheme),
      );
}

class MediaItem {
  MediaItem({required this.id, required this.title, required this.year, required this.genre, required this.drama, required this.duration, required this.rating, required this.image, required this.description, this.episodes = const [], this.videoUrl = '', this.episodeUrls = const []});
  final int id;
  String title;
  final int year;
  final String genre;
  final bool drama;
  final String duration;
  final String rating;
  String image;
  final String description;
  final List<String> episodes;
  String videoUrl;
  final List<String> episodeUrls;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'year': year, 'genre': genre, 'drama': drama, 'duration': duration, 'rating': rating, 'image': image, 'description': description, 'episodes': episodes, 'videoUrl': videoUrl, 'episodeUrls': episodeUrls};
  factory MediaItem.fromJson(Map<String, dynamic> json) => MediaItem(id: json['id'] as int, title: json['title'] as String, year: json['year'] as int, genre: json['genre'] as String, drama: json['drama'] as bool, duration: json['duration'] as String, rating: json['rating'] as String, image: json['image'] as String, description: json['description'] as String, episodes: (json['episodes'] as List<dynamic>? ?? const []).cast<String>(), videoUrl: json['videoUrl'] as String? ?? '', episodeUrls: (json['episodeUrls'] as List<dynamic>? ?? const []).cast<String>());
}

String photo(String id, [int width = 700]) => 'https://images.unsplash.com/$id?auto=format&fit=crop&w=$width&q=82';

List<MediaItem> seedMedia() => [
      MediaItem(id: 1, title: 'Somewhere in the Quiet', year: 2024, genre: 'دراما', drama: false, duration: '٢ سەعات و ٨ خولەک', rating: '8.7', image: photo('photo-1470252649378-9c29740c9fa8'), description: 'گەشتەکا جوان و هێدی ل نێڤ بیرەوەری و دووری؛ چیرۆکا دوو کەسان کو دەمێ گونجای یەک ددۆزنەوە.'),
      MediaItem(id: 2, title: 'Blue Hour', year: 2023, genre: 'ئەڤین', drama: false, duration: '١ سەعات و ٤٨ خولەک', rating: '8.2', image: photo('photo-1518837695005-2083093ee35b'), description: 'دوو نامۆ ل شەمەندەفەرا دوماهیک یا شەڤێ یەک دبینن و ل شارەکێ پیاسەیەکا درێژ دکەن.'),
      MediaItem(id: 3, title: 'A Quiet Place', year: 2024, genre: 'تریلەر', drama: false, duration: '١ سەعات و ٤١ خولەک', rating: '7.9', image: photo('photo-1511497584788-876760111969'), description: 'ل دارستانێ، کەیسەکا ونبوونێ نهێنییەکا مەترسیدار دەرئێخیت.'),
      MediaItem(id: 4, title: 'Orbiters', year: 2025, genre: 'زانستی', drama: false, duration: '٢ سەعات و ٢ خولەک', rating: '8.4', image: photo('photo-1446776811953-b23d57bd21aa'), description: 'تیمەکا بچووک بۆ دۆزینا ڕاستییەکا نهێنی دچیتە دەرڤەی خۆرێ.'),
      MediaItem(id: 5, title: 'The Art of Looking', year: 2023, genre: 'بەلگەنامەیی', drama: false, duration: '١ سەعات و ٢٦ خولەک', rating: '8.8', image: photo('photo-1513364776144-60967b0f800f'), description: 'چیرۆکا سێ هونەرمەندان و ئەو گۆشەیێن ڤەشارتی یێن جیهان.'),
      MediaItem(id: 6, title: 'Golden Days', year: 2022, genre: 'دراما', drama: false, duration: '١ سەعات و ٥٧ خولەک', rating: '8.1', image: photo('photo-1470770841072-f978cf4d019e'), description: 'برا و خوشکەک بۆ دوماهیک جار دزڤڕنە باخچەیا خێزانێ و نهێنییەکێ ددۆزنەڤە.'),
      MediaItem(id: 7, title: 'Before the Rain', year: 2024, genre: 'ئەڤین', drama: false, duration: '١ سەعات و ٤٦ خولەک', rating: '7.8', image: photo('photo-1500375592092-40eb2168fd21'), description: 'مۆسیقارەک ل دوورگەکێ هاونەوازەکێ چاوەڕێ نەکری ددۆزیتەڤە.'),
      MediaItem(id: 8, title: 'The Deep Archive', year: 2025, genre: 'زانستی', drama: false, duration: '٢ سەعات و ١١ خولەک', rating: '8.5', image: photo('photo-1462331940025-496dfbfc7564'), description: 'ئەرشیڤچییەک پەیامەکێ ژ مانگەدەستکردەکە کەڤن ددۆزیتەڤە.'),
      MediaItem(id: 9, title: 'Small Wonders', year: 2022, genre: 'بەلگەنامەیی', drama: false, duration: '١ سەعات و ١٩ خولەک', rating: '8.3', image: photo('photo-1472396961693-142e6e269027'), description: 'ساڵەک ل باخچەیا گەڕەکەکێ، ژ چاڤێ ئەو کەسان کو دچێنن.'),
      MediaItem(id: 10, title: 'After the Storm', year: 2023, genre: 'تریلەر', drama: false, duration: '١ سەعات و ٥٢ خولەک', rating: '7.7', image: photo('photo-1500530855697-b586d89ba3ee'), description: 'تیمی فریاکەفتنا چیا پشتی تۆفانەکێ ڕێچکەکا نیشانان ددۆزنەڤە.'),
      MediaItem(id: 11, title: 'ڕۆژێن بارانێ', year: 2025, genre: 'دراما یا خێزانی', drama: true, duration: '٢ وەرز · ١٦ ئەڵقە', rating: '9.1', image: photo('photo-1470770841072-f978cf4d019e'), description: 'چیرۆکا خێزانەکێ ل گوندەکێ بچووک؛ ئەڤین و هیڤیێن وان دگەل هەر بارانەکێ دگوهۆڕن.', episodes: ['دەستپێک', 'نامەیا ڤەشارتی', 'بارانا یەکێ', 'ڕێکا مالێ']),
      MediaItem(id: 12, title: 'شار ل دوای نیڤەشەڤێ', year: 2024, genre: 'دراما یا تاوانێ', drama: true, duration: '١ وەرز · ٨ ئەڵقە', rating: '8.8', image: photo('photo-1519608487953-e999c86e7455'), description: 'پۆلیسەکێ نوی ل شارەکەکا مەزن بۆ پەیوەندیێن نێڤبەرا ڕوودانێن نامۆ دگەڕیت.', episodes: ['نیڤەشەڤ', 'شایەتی', 'بۆ نیشانان', 'ڕاستیا ڤەشارتی']),
      MediaItem(id: 13, title: 'مالا کەڤن', year: 2023, genre: 'دراما یا خێزانی', drama: true, duration: '٣ وەرز · ٢٤ ئەڵقە', rating: '8.5', image: photo('photo-1510798831971-661eb04b3739'), description: 'سێ نەوە ژ خێزانەکێ ل مالەکێ کەڤن دژین؛ هەر یەک چیرۆکا خۆ یا هەیە.', episodes: ['مێڤانێ نوی', 'نهێنیا باخچەیێ', 'کلیلێ ژوورا داخستی', 'ڕۆژا زڤڕینێ']),
      MediaItem(id: 14, title: 'ڕێکا دوور', year: 2025, genre: 'دراما یا گەشتێ', drama: true, duration: '١ وەرز · ١٠ ئەڵقە', rating: '8.7', image: photo('photo-1464822759023-fed622ff2c3b'), description: 'دوو هەڤالێن کەڤن پشتی سالانەکا درێژ ب ڕێکەکا درێژ دچن و بیرەوەریێن وان زیندی دبنەڤە.', episodes: ['بریار', 'وێستگەها یەکێ', 'ل سەر ڕێکێ', 'دوماهیک وێستگەه']),
    ];

class MillionHome extends StatefulWidget {
  const MillionHome({super.key, required this.darkMode, required this.onThemeChange});
  final bool darkMode;
  final ValueChanged<bool> onThemeChange;
  @override
  State<MillionHome> createState() => _MillionHomeState();
}

class _MillionHomeState extends State<MillionHome> {
  List<String> get _pages => _language == 'en' ? ['Home', 'Films', 'Drama', 'Live', 'My List', 'Settings'] : _language == 'ar' ? ['الرئيسية', 'أفلام', 'دراما', 'مباشر', 'قائمتي', 'الإعدادات'] : ['سەرەکی', 'فلم', 'دراما', 'لایڤ', 'بژاردە', 'سیتنگ'];
  final _pageController = PageController();
  final _searchController = TextEditingController();
  final _picker = ImagePicker();
  List<MediaItem> _items = seedMedia();
  List<Map<String, dynamic>> _subscriptions = [];
  List<Map<String, String>> _liveChannels = [];
  Set<int> _saved = {};
  int _page = 0, _hero = 0;
  String _query = '', _genre = 'هەمی', _settingsKind = 'هەمی', _settingsQuery = '';
  bool _loading = true, _searchOpen = false, _adminUnlocked = false;
  String _language = 'ku';
  Timer? _heroTimer;
  StreamSubscription<User?>? _authSubscription;
  User? _accountUser;
  bool _premium = false;
  VideoPlayerController? _activeController;

  bool get _dark => widget.darkMode;
  Color get _surface => _dark ? panel : Colors.white;
  Color get _mutedText => _dark ? muted : const Color(0xFF5F735F);
  Color get _primaryText => _dark ? Colors.white : const Color(0xFF253A2C);

  @override
  void initState() {
    super.initState();
    _load();
    _initializeAuth();
    _heroTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || _page != 0 || _items.isEmpty) return;
      _hero = (_hero + 1) % 3;
      _pageController.animateToPage(_hero, duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
    });
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedItems = prefs.getString('million-items');
    if (savedItems != null) {
      try { _items = (jsonDecode(savedItems) as List).map((e) => MediaItem.fromJson(Map<String, dynamic>.from(e))).toList(); } catch (_) {}
    }
    _saved = (prefs.getStringList('million-saved') ?? []).map((value) => int.tryParse(value)).whereType<int>().toSet();
    _language = prefs.getString('million-language') ?? 'ku';
    try { _subscriptions = (jsonDecode(prefs.getString('million-subscriptions') ?? '[]') as List).map((e) => Map<String, dynamic>.from(e)).toList(); } catch (_) {}
    try { _liveChannels = (jsonDecode(prefs.getString('million-live-links') ?? '[]') as List).map((e) => Map<String, String>.from(Map<String, dynamic>.from(e))).toList(); } catch (_) {}
    widget.onThemeChange(prefs.getBool('million-dark-mode') ?? widget.darkMode);
    if (mounted) setState(() => _loading = false);
  }

  void _initializeAuth() {
    if (!DefaultFirebaseOptions.isConfigured) return;
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (user) => _refreshAccount(user),
      onError: (Object error) => _showAccountError(error),
    );
  }

  Future<void> _refreshAccount(User? user) async {
    var premium = false;
    try {
      if (user != null) {
        await user.reload();
        user = FirebaseAuth.instance.currentUser;
        final token = await user?.getIdTokenResult(true);
        premium = token?.claims?['premium'] == true;
      }
      if (!premium) await _activeController?.pause();
      if (mounted) setState(() { _accountUser = user; _premium = premium; });
    } on FirebaseAuthException catch (error) {
      _showAccountError(error);
      if (mounted) setState(() { _accountUser = null; _premium = false; });
    } catch (error) {
      _showAccountError(error);
      if (mounted) setState(() { _accountUser = null; _premium = false; });
    }
  }

  void _showAccountError(Object error) {
    if (!mounted) return;
    final message = error is FirebaseAuthException
        ? 'چوونەژوور نەسەرکەفت: ${error.message ?? error.code}'
        : 'خزمەتا هەژمارێ بەردەست نینە.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signInWithGoogle() async {
    if (!DefaultFirebaseOptions.isConfigured) {
      _showAccountError(StateError('Firebase app configuration is required.'));
      return;
    }
    try {
      if (kIsWeb) {
        final credential = await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
        await _refreshAccount(credential.user);
      } else {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return;
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final result = await FirebaseAuth.instance.signInWithCredential(credential);
        await _refreshAccount(result.user);
      }
    } on FirebaseAuthException catch (error) {
      _showAccountError(error);
    } catch (error) {
      _showAccountError(error);
    }
  }

  Future<void> _signInWithApple() async {
    if (!DefaultFirebaseOptions.isConfigured) {
      _showAccountError(StateError('Firebase app configuration is required.'));
      return;
    }
    try {
      final provider = OAuthProvider('apple.com');
      if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
        await FirebaseAuth.instance.signInWithProvider(provider);
        return;
      }
      const nonceCharacters = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
      final random = Random.secure();
      final rawNonce = List.generate(32, (_) => nonceCharacters[random.nextInt(nonceCharacters.length)]).join();
      final nonce = sha256.convert(utf8.encode(rawNonce)).toString();
      final appleUser = await SignInWithApple.getAppleIDCredential(
        scopes: const [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: nonce,
      );
      final idToken = appleUser.identityToken;
      if (idToken == null) throw StateError('Apple did not return an identity token.');
      final credential = provider.credential(
        idToken: idToken,
        rawNonce: rawNonce,
      );
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      await _refreshAccount(result.user);
    } on FirebaseAuthException catch (error) {
      _showAccountError(error);
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code != AuthorizationErrorCode.canceled) _showAccountError(error);
    } catch (error) {
      _showAccountError(error);
    }
  }

  Future<void> _signOutAccount() async {
    try {
      if (!kIsWeb) await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      await _refreshAccount(null);
    } on FirebaseAuthException catch (error) {
      _showAccountError(error);
    } catch (error) {
      _showAccountError(error);
    }
  }

  Future<bool> _hasWatchAccess() async {
    if (!DefaultFirebaseOptions.isConfigured) {
      _showAccountError(StateError('Firebase app configuration is required.'));
      return false;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) unawaited(_showProfileDialog());
      return false;
    }
    try {
      final token = await user.getIdTokenResult(true);
      final premium = token.claims?['premium'] == true;
      if (!premium) await _activeController?.pause();
      if (mounted) setState(() { _accountUser = user; _premium = premium; });
      if (premium) return true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('هەژمارا تە اشتراکەکا چالاک نینە؛ چوونەژوورێ تەنێ بۆ بینینا ڤیدیۆیان نەبەسە.')),
        );
      }
    } on FirebaseAuthException catch (error) {
      _showAccountError(error);
    } catch (error) {
      _showAccountError(error);
    }
    return false;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('million-items', jsonEncode(_items.map((e) => e.toJson()).toList()));
    await prefs.setStringList('million-saved', _saved.map((e) => e.toString()).toList());
    await prefs.setString('million-live-links', jsonEncode(_liveChannels));
    await prefs.setString('million-subscriptions', jsonEncode(_subscriptions));
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _authSubscription?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _goTo(int index) async {
    if (index == 6 && !_adminUnlocked) {
      final pin = TextEditingController();
      final valid = await showDialog<bool>(context: context, builder: (context) {
        String? error;
        return StatefulBuilder(builder: (context, update) => AlertDialog(
          backgroundColor: const Color(0xFF13271E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFF49674F))),
          title: const Text('رمزێ Admin بنڤیسە', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: pin, autofocus: true, obscureText: true, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'رمز', prefixIcon: Icon(Icons.lock_outline))), if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: const TextStyle(color: Colors.redAccent)))]),
          actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ڤەگەرە')), FilledButton(onPressed: () { if (pin.text == '123') { Navigator.pop(context, true); } else { update(() => error = 'رمز نەراستە. جارەکا دی تاقی بکە.'); } }, child: const Text('چوونە ژوور'))],
        ));
      });
      pin.dispose();
      if (valid != true) return;
      _adminUnlocked = true;
    }
    setState(() { _page = index; _genre = 'هەمی'; });
  }

  List<MediaItem> get _visible {
    Iterable<MediaItem> result = _items;
    if (_page == 1) result = result.where((e) => !e.drama);
    if (_page == 2) result = result.where((e) => e.drama);
    if (_page == 4) result = result.where((e) => _saved.contains(e.id));
    if (_genre != 'هەمی') result = result.where((e) => e.genre == _genre);
    if (_query.isNotEmpty) result = result.where((e) => '${e.title} ${e.genre} ${e.year}'.toLowerCase().contains(_query.toLowerCase()));
    return result.toList();
  }

  Widget _posterImage(String source, {BoxFit fit = BoxFit.cover}) {
    if (source.startsWith('http')) return Image.network(source, fit: fit, errorBuilder: (_, __, ___) => _imageFallback());
    final file = File(source);
    return file.existsSync() ? Image.file(file, fit: fit) : _imageFallback();
  }

  Widget _imageFallback() => Container(color: const Color(0xFF223A2C), child: const Center(child: Icon(Icons.movie_outlined, color: muted, size: 32)));

  Future<void> _showAdminLogin() => _goTo(6);

  Future<void> _setDarkMode(bool value) async {
    widget.onThemeChange(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('million-dark-mode', value);
  }

  String _text(String key) {
    const messages = {
      'ku': {'language': 'زمان / Language', 'subscriptions': 'اشتراکەکان', 'one_month': 'مانگێک', 'six_months': '٦ مانگ', 'one_year': 'ساڵێک', 'name': 'ناڤ', 'email': 'ئیمەیڵ', 'send_request': 'داواکاریی اشتراک بنێرە', 'add_media': 'زیادکرنا فلم / دراما', 'add_live': 'زیادکرنا Live Stream', 'customers': 'داواکاریێن اشتراک', 'pending': 'چاوەڕێی پشتڕاستکرنێ', 'payment_note': 'پارەدان هێشتا gateway نییە؛ ئەڤە داواکارییەکا ناوخۆییە.', 'select_plan': 'پلانی اشتراک هەلبژێرە'},
      'ar': {'language': 'اللغة / Language', 'subscriptions': 'الاشتراكات', 'one_month': 'شهر واحد', 'six_months': '٦ أشهر', 'one_year': 'سنة واحدة', 'name': 'الاسم', 'email': 'البريد الإلكتروني', 'send_request': 'إرسال طلب الاشتراك', 'add_media': 'إضافة فيلم / دراما', 'add_live': 'إضافة بث مباشر', 'customers': 'طلبات الاشتراك', 'pending': 'بانتظار التحقق', 'payment_note': 'الدفع الإلكتروني غير مفعّل بعد؛ هذا الطلب يُحفظ محلياً.', 'select_plan': 'اختر خطة الاشتراك'},
      'en': {'language': 'Language', 'subscriptions': 'Subscriptions', 'one_month': '1 month', 'six_months': '6 months', 'one_year': '1 year', 'name': 'Name', 'email': 'Email', 'send_request': 'Send subscription request', 'add_media': 'Add a film / drama', 'add_live': 'Add a live stream', 'customers': 'Subscription requests', 'pending': 'Pending verification', 'payment_note': 'Online payment is not connected; this saves a local request.', 'select_plan': 'Choose a plan'},
    };
    return messages[_language]?[key] ?? messages['ku']![key] ?? key;
  }

  Future<void> _changeLanguage(String value) async {
    setState(() => _language = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('million-language', value);
  }

  Future<void> _subscribe(String plan, String price) async {
    final name = TextEditingController();
    final email = TextEditingController();
    await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text('${_text('subscriptions')} · $price'),
      content: SizedBox(width: 380, child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: _text('name'))), const SizedBox(height: 8), TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: _text('email'))), const SizedBox(height: 10), Text(_text('payment_note'), style: const TextStyle(color: muted, fontSize: 11))])),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('ڤەگەرە')), FilledButton(onPressed: () async { if (name.text.trim().isEmpty) return; setState(() => _subscriptions.add({'name': name.text.trim(), 'email': email.text.trim(), 'plan': plan, 'price': price, 'status': 'pending', 'date': DateTime.now().toIso8601String()})); await _persist(); if (dialogContext.mounted) Navigator.pop(dialogContext); if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('داواکاری ل ناڤ ئامێرێ تە هاتە پاراستن.'))); }, child: Text(_text('send_request')))],
    ));
    name.dispose(); email.dispose();
  }

  Future<void> _addMediaDialog() async {
    final title = TextEditingController(), image = TextEditingController(), genre = TextEditingController(text: 'Drama'), year = TextEditingController(text: '${DateTime.now().year}'), description = TextEditingController(), stream = TextEditingController();
    bool drama = false;
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, update) => AlertDialog(
      title: Text(_text('add_media')),
      content: SizedBox(width: 430, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: title, decoration: InputDecoration(labelText: _text('name'))), const SizedBox(height: 8), DropdownButtonFormField<bool>(value: drama, decoration: InputDecoration(labelText: _text('kind')), items: [DropdownMenuItem(value: false, child: Text(_pages[1])), DropdownMenuItem(value: true, child: Text(_pages[2]))], onChanged: (v) => update(() => drama = v ?? false)), const SizedBox(height: 8), TextField(controller: genre, decoration: const InputDecoration(labelText: 'Genre')), const SizedBox(height: 8), TextField(controller: year, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Year')), const SizedBox(height: 8), TextField(controller: image, decoration: const InputDecoration(labelText: 'HD poster URL')), const SizedBox(height: 8), TextField(controller: stream, decoration: const InputDecoration(labelText: 'MP4 / M3U8 URL')), const SizedBox(height: 8), TextField(controller: description, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Description'))]))),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('ڤەگەرە')), FilledButton(onPressed: () async { if (title.text.trim().isEmpty) return; final url = stream.text.trim(); setState(() => _items.add(MediaItem(id: DateTime.now().millisecondsSinceEpoch, title: title.text.trim(), year: int.tryParse(year.text) ?? DateTime.now().year, genre: genre.text.trim().isEmpty ? 'Drama' : genre.text.trim(), drama: drama, duration: drama ? '١ ئەڵقە' : '—', rating: '—', image: image.text.trim().isEmpty ? photo('photo-1470252649378-9c29740c9fa8') : image.text.trim(), description: description.text.trim(), videoUrl: url, episodes: drama && url.isNotEmpty ? const ['ئەڵقەیا یەکێ'] : const [], episodeUrls: drama && url.isNotEmpty ? [url] : const []))); await _persist(); if (dialogContext.mounted) Navigator.pop(dialogContext); }, child: Text(_text('add_media')))],
    )));
    title.dispose(); image.dispose(); genre.dispose(); year.dispose(); description.dispose(); stream.dispose();
  }

  Future<void> _addLiveDialog() async {
    final name = TextEditingController(), url = TextEditingController();
    await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(title: Text(_text('add_live')), content: SizedBox(width: 390, child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: InputDecoration(labelText: _text('name'))), const SizedBox(height: 8), TextField(controller: url, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'HLS / M3U8 URL'))])), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('ڤەگەرە')), FilledButton(onPressed: () async { final uri = Uri.tryParse(url.text.trim()); if (name.text.trim().isEmpty || uri == null || !uri.hasScheme || !['http', 'https'].contains(uri.scheme)) return; setState(() => _liveChannels.add({'name': name.text.trim(), 'url': uri.toString(), 'type': uri.path.toLowerCase().endsWith('.m3u8') ? 'HLS / M3U8' : 'MP4'})); await _persist(); if (dialogContext.mounted) Navigator.pop(dialogContext); }, child: Text(_text('add_live')))]));
    name.dispose(); url.dispose();
  }

  Future<void> _playStream(String url, String title) async {
    if (!await _hasWatchAccess()) return;
    VideoPlayerController? controller;
    try {
      final isHls = url.toLowerCase().contains('.m3u8');
      controller = VideoPlayerController.networkUrl(Uri.parse(url), formatHint: isHls ? VideoFormat.hls : null);
      await controller.initialize();
      _activeController = controller;
      await controller.play();
      if (!mounted) { await controller.dispose(); return; }
      await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(title: Text(title), content: AspectRatio(aspectRatio: controller!.value.aspectRatio, child: VideoPlayer(controller!)), actions: [ValueListenableBuilder<VideoPlayerValue>(valueListenable: controller!, builder: (_, value, __) => IconButton(onPressed: () => value.isPlaying ? controller!.pause() : controller!.play(), icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow))), TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('داخستن'))]));
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ڤیدیۆ نەشیا پەخش بکرێت؛ لینک، CORS و مۆڵەتا پەخشێ بپشکنە.'))); }
    finally { if (identical(_activeController, controller)) _activeController = null; await controller?.dispose(); }
  }

  Future<void> _showProfileDialog() async {
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final verificationCode = TextEditingController();
    var creatingAccount = true;
    var codeSent = false;
    var working = false;
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) {
          final user = _accountUser;
          return AlertDialog(
            backgroundColor: const Color(0xFF13271E),
            title: const Text('هەژمار و پڕۆفایلێ MILLION'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (user != null) ...[
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: const Color(0xFF34533C),
                        foregroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                        child: user.photoURL == null ? const Icon(Icons.person_outline, size: 38, color: gold) : null,
                      ),
                      const SizedBox(height: 12),
                      Text(user.displayName ?? 'بەکارهێنەرێ MILLION', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (user.email != null) Text(user.email!, style: const TextStyle(color: muted)),
                      const SizedBox(height: 6),
                      Text(_premium ? 'اشتراک چالاکە' : 'اشتراک چالاک نینە', style: const TextStyle(color: gold)),
                      TextButton.icon(
                        onPressed: () async { await _signOutAccount(); if (dialogContext.mounted) update(() {}); },
                        icon: const Icon(Icons.logout),
                        label: const Text('دەرکەڤتن ژ هەژمارێ'),
                      ),
                    ] else ...[
                      if (!DefaultFirebaseOptions.isConfigured)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Text(
                            'Firebase ڕێک نەهاتییە؛ بۆ چالاککرنا دروستکرنا هەژمارێ firebase_options.dart ئامادە بکە.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: gold, fontSize: 11, height: 1.5),
                          ),
                        ),
                      if (creatingAccount)
                        TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'ناڤ و نازناڤ')),
                      const SizedBox(height: 8),
                      TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        onChanged: (_) {
                          if (codeSent) update(() { codeSent = false; verificationCode.clear(); error = 'ئیمەیڵ گوهۆڕا؛ کۆدەکا نوی بخوازە.'; });
                        },
                        decoration: const InputDecoration(labelText: 'ئیمەیڵ'),
                      ),
                      const SizedBox(height: 8),
                      TextField(controller: password, obscureText: true, autofillHints: [creatingAccount ? AutofillHints.newPassword : AutofillHints.password], decoration: const InputDecoration(labelText: 'وشەیا نهێنی · لانیکەم ٨ پیت')),
                      if (creatingAccount && codeSent) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: verificationCode,
                          keyboardType: TextInputType.number,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          maxLength: 6,
                          decoration: const InputDecoration(labelText: 'کۆدی ٦ ژمارەیی ژ ئیمەیڵێ'),
                        ),
                        TextButton(
                          onPressed: working ? null : () async {
                            update(() { working = true; error = null; });
                            try {
                              await FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('requestEmailSignupCode').call({'email': email.text.trim()});
                              verificationCode.clear();
                              update(() => error = 'کۆدەکا نوی بۆ ئیمەیڵێ تە هات.');
                            } on FirebaseFunctionsException catch (exception) {
                              update(() => error = exception.message ?? 'کۆدەکا نوی نەهاتە ناردن؛ کەمێک چاوەڕێ بکە.');
                            } finally {
                              if (dialogContext.mounted) update(() => working = false);
                            }
                          },
                          child: const Text('کۆدێ نوی بخوازە'),
                        ),
                      ],
                      if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: Colors.redAccent))),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: !DefaultFirebaseOptions.isConfigured || working ? null : () async {
                            final cleanEmail = email.text.trim();
                            if (cleanEmail.isEmpty || (creatingAccount && (password.text.length < 8 || name.text.trim().isEmpty))) {
                              update(() => error = 'تکایە ناڤ، ئیمەیڵ و وشەیا نهێنی یا دروست بنڤیسە.');
                              return;
                            }
                            update(() { working = true; error = null; });
                            try {
                              UserCredential credential;
                              if (creatingAccount) {
                                final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
                                if (!codeSent) {
                                  await functions.httpsCallable('requestEmailSignupCode').call({'email': cleanEmail});
                                  update(() {
                                    codeSent = true;
                                    error = 'کۆدی ٦ ژمارەیی بۆ ئیمەیڵێ تە هات؛ کۆدەکە بنڤیسە و دووبارە دابگرە.';
                                  });
                                  return;
                                }
                                if (!RegExp(r'^\d{6}$').hasMatch(verificationCode.text.trim())) {
                                  update(() => error = 'کۆدی ٦ ژمارەیی بنڤیسە.');
                                  return;
                                }
                                await functions.httpsCallable('completeEmailSignup').call({
                                  'email': cleanEmail,
                                  'code': verificationCode.text.trim(),
                                  'name': name.text.trim(),
                                  'password': password.text,
                                });
                                credential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: cleanEmail, password: password.text);
                              } else {
                                credential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: cleanEmail, password: password.text);
                              }
                              await _refreshAccount(credential.user);
                              if (dialogContext.mounted) Navigator.pop(dialogContext);
                            } on FirebaseFunctionsException catch (exception) {
                              update(() => error = switch (exception.code) {
                                'invalid-argument' => 'کۆد یان زانیاری نەراستە، یان کۆد کۆتایی هاتییە.',
                                'already-exists' => 'ئەڤ ئیمەیڵە پێشتر هەژمارەکا هەیە؛ بچۆ ژوور.',
                                'resource-exhausted' => 'هەوڵ زۆر بوو؛ کەمێک چاوەڕێ بکە و جارەکا دی تاقی بکە.',
                                'not-found' => 'سێرڤەرێ کۆدێ پشتڕاستکرنێ نەهاتییە چالاککرن.',
                                _ => exception.message ?? 'چوونەژوورێ ب سێرڤەرێ نەسەرکەفت.',
                              });
                            } on FirebaseAuthException catch (exception) {
                              update(() => error = switch (exception.code) {
                                'email-already-in-use' => 'ئەڤ ئیمەیڵە پێشتر هەژمارەکا هەیە؛ بچۆ ژوور.',
                                'invalid-email' => 'فۆرماتا ئیمەیڵێ نەراستە.',
                                'weak-password' => 'وشەیا نهێنی لانیکەم ٨ پیت بنڤیسە.',
                                'invalid-credential' => 'ئیمەیڵ یان وشەیا نهێنی نەراستە.',
                                _ => exception.message ?? 'دروستکرنا هەژمارێ نەسەرکەفت.',
                              });
                            } catch (exception) {
                              update(() => error = 'هەڵە ل دروستکرنا هەژمارێ: $exception');
                            } finally {
                              if (dialogContext.mounted) update(() => working = false);
                            }
                          },
                          child: Text(creatingAccount ? (codeSent ? 'کۆد پشتڕاست بکە و هەژمار دروست بکە' : 'کۆدێ پشتڕاستکرنێ بنێرە') : 'بچۆ ژوور'),
                        ),
                      ),
                      TextButton(
                        onPressed: () => update(() { creatingAccount = !creatingAccount; codeSent = false; verificationCode.clear(); error = null; }),
                        child: Text(creatingAccount ? 'هەژمارا تە هەیە؟ بچۆ ژوور' : 'هەژمارا تە نینە؟ هەژمارا نوی دروست بکە'),
                      ),
                      OutlinedButton.icon(
                        onPressed: !DefaultFirebaseOptions.isConfigured ? null : () async {
                          await _signInWithGoogle();
                          if (dialogContext.mounted && _accountUser != null) Navigator.pop(dialogContext);
                        },
                        icon: const Icon(Icons.account_circle_outlined),
                        label: const Text('ب Google / Gmail بچۆ ژوور'),
                      ),
                      OutlinedButton.icon(
                        onPressed: !DefaultFirebaseOptions.isConfigured ? null : () async {
                          await _signInWithApple();
                          if (dialogContext.mounted && _accountUser != null) Navigator.pop(dialogContext);
                        },
                        icon: const Icon(Icons.apple),
                        label: const Text('ب Apple بچۆ ژوور'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('داخستن'))],
          );
        },
      ),
    );
    name.dispose();
    email.dispose();
    password.dispose();
    verificationCode.dispose();
  }

  Future<void> _toggleSaved(MediaItem item) async {
    setState(() { if (_saved.contains(item.id)) { _saved.remove(item.id); } else { _saved.add(item.id); } });
    await _persist();
  }

  void _openDetails(MediaItem item) {
    showModalBottomSheet<void>(context: context, isScrollControlled: true, backgroundColor: const Color(0xFF13271E), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))), builder: (context) => DraggableScrollableSheet(expand: false, initialChildSize: .78, maxChildSize: .94, builder: (context, controller) => ListView(controller: controller, padding: const EdgeInsets.fromLTRB(20, 14, 20, 28), children: [Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)))), const SizedBox(height: 18), ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(height: 210, child: _posterImage(item.image))), const SizedBox(height: 16), Text(item.drama ? 'دراما · ${item.genre}' : 'فلم · ${item.genre}', style: const TextStyle(color: gold)), const SizedBox(height: 5), Text(item.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), Text('${item.year} · ${item.duration} · ★ ${item.rating}', style: const TextStyle(color: muted)), const SizedBox(height: 12), Text(item.description, style: const TextStyle(height: 1.8)), if (item.episodes.isNotEmpty) ...[const SizedBox(height: 18), const Text('ئەڵقەیێن زنجیرێ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), ...item.episodes.asMap().entries.map((e) => ListTile(leading: const Icon(Icons.play_circle_outline, color: blue), title: Text('${e.key + 1}. ${e.value}'), onTap: () => e.key < item.episodeUrls.length ? _playStream(item.episodeUrls[e.key], '${item.title} · ${e.value}') : _showNoStream()))], const SizedBox(height: 14), if (!item.drama) FilledButton.icon(onPressed: () => item.videoUrl.isNotEmpty ? _playStream(item.videoUrl, item.title) : _showNoStream(), icon: const Icon(Icons.play_arrow), label: const Text('سەیرکرن')), OutlinedButton.icon(onPressed: () { Navigator.pop(context); _toggleSaved(item); }, icon: Icon(_saved.contains(item.id) ? Icons.favorite : Icons.favorite_border), label: Text(_saved.contains(item.id) ? 'ل بژاردەیانە' : 'زێدەکرن بۆ بژاردەیان'))]))));
  }

  void _showNoStream() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('بۆ پەخشکرنێ، لینکا ڤیدیۆیێ یا مۆڵەتپێدراو پێدڤییە.')));

  Future<void> _editItem(MediaItem item) async {
    final title = TextEditingController(text: item.title);
    final image = TextEditingController(text: item.image);
    String? pickedPath;
    await showDialog<void>(context: context, builder: (context) => StatefulBuilder(builder: (context, update) => AlertDialog(
      backgroundColor: const Color(0xFF13271E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(height: 170, width: double.infinity, child: _posterImage(pickedPath ?? image.text))), const SizedBox(height: 14), TextField(controller: title, decoration: const InputDecoration(labelText: 'ناڤێ فلم یان درامایێ')), const SizedBox(height: 10), TextField(controller: image, onChanged: (_) => update(() => pickedPath = null), decoration: const InputDecoration(labelText: 'لینکا وێنێ')), const SizedBox(height: 12), OutlinedButton.icon(onPressed: () async { final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 84, maxWidth: 1400); if (x == null) return; final dir = await getApplicationDocumentsDirectory(); final ext = x.path.split('.').last; final saved = await File(x.path).copy('${dir.path}/million_${item.id}_${DateTime.now().millisecondsSinceEpoch}.$ext'); update(() { pickedPath = saved.path; image.text = saved.path; }); }, icon: const Icon(Icons.add_photo_alternate_outlined), label: const Text('وێنە ژ ئامێرێ هەلبژێرە'))]))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ڤەگەرە')), FilledButton(onPressed: () async { if (title.text.trim().isEmpty) return; setState(() { item.title = title.text.trim(); item.image = pickedPath ?? image.text.trim(); }); await _persist(); if (context.mounted) Navigator.pop(context); }, child: const Text('پاراستن'))],
    )));
    title.dispose(); image.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width > 900;
    return Directionality(textDirection: _language == 'en' ? TextDirection.ltr : TextDirection.rtl, child: Scaffold(
      appBar: AppBar(titleSpacing: 18, title: Row(children: [Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(10)), child: const Text('M', style: TextStyle(fontWeight: FontWeight.w900))), const SizedBox(width: 9), const Text('MILLION', style: TextStyle(fontSize: 16, letterSpacing: 2, fontWeight: FontWeight.bold))]), actions: [IconButton(onPressed: () => setState(() => _searchOpen = !_searchOpen), icon: const Icon(Icons.search)), IconButton(onPressed: _showProfileDialog, tooltip: _accountUser?.displayName ?? _accountUser?.email ?? 'هەژمار و پڕۆفایل', icon: CircleAvatar(radius: 14, backgroundColor: const Color(0xFF34533C), foregroundImage: _accountUser?.photoURL != null ? NetworkImage(_accountUser!.photoURL!) : null, child: _accountUser?.photoURL == null ? const Icon(Icons.person_outline, size: 18, color: gold) : null)), const SizedBox(width: 6)]),
      body: Column(children: [if (_searchOpen) Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 10), child: TextField(controller: _searchController, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: .2), onChanged: (v) => setState(() => _query = v), decoration: InputDecoration(hintText: _language == 'en' ? 'Search films and shows…' : _language == 'ar' ? 'ابحث عن فيلم أو مسلسل…' : 'لێگەڕین بۆ فلم و دراما…', prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(onPressed: () { _searchController.clear(); setState(() => _query = ''); }, icon: const Icon(Icons.close))))), Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _buildPage(desktop))]),
      bottomNavigationBar: _bottomNav(),
      floatingActionButton: _searchOpen && _query.trim().toLowerCase() == 'million' && _page != 6 ? FloatingActionButton.small(backgroundColor: blue, foregroundColor: Colors.white, tooltip: 'Admin', onPressed: _showAdminLogin, child: const Icon(Icons.admin_panel_settings_outlined)) : null,
    ));
  }

  Widget _bottomNav() {
    const icons = [Icons.home_rounded, Icons.movie_creation_outlined, Icons.theaters_outlined, Icons.live_tv_outlined, Icons.favorite_border, Icons.settings_outlined];
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
        decoration: BoxDecoration(
          color: _dark ? const Color(0xE90B1311) : const Color(0xF7FFFFFF),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _dark ? const Color(0x333F5B3D) : const Color(0xFFD5E2D1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(_dark ? .28 : .1), blurRadius: 28, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: List.generate(_pages.length, (i) {
            final selected = _page == i;
            final selectedColor = _dark ? const Color(0xFFC6DDA5) : const Color(0xFFE5F0DA);
            return Expanded(
              child: Semantics(
                button: true,
                selected: selected,
                label: _pages[i],
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _goTo(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: selected ? (_dark ? const Color(0x803A593A) : const Color(0xFFE7F0E0)) : Colors.transparent,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(color: selected ? (_dark ? const Color(0x33C6DDA5) : const Color(0xFFD1E2C6)) : Colors.transparent),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: selected ? selectedColor : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icons[i],
                            size: 19,
                            color: selected ? const Color(0xFF203321) : _mutedText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _pages[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            height: 1.2,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? (_dark ? Colors.white : const Color(0xFF345338)) : _mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPage(bool desktop) {
    if (_page == 3) return _livePage();
    if (_page == 5) return _settingsPage();
    if (_page == 6) return _adminPage();
    if (_page == 0) return _homePage(desktop);
    final items = _visible;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 30), children: [Text(_pages[_page], style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)), const SizedBox(height: 14), _genreFilters(), const SizedBox(height: 14), if (items.isEmpty) _empty() else _grid(items, desktop)]);
  }

  Widget _homePage(bool desktop) {
    if (_query.isNotEmpty) {
      final matches = _items.where((item) => '${item.title} ${item.genre} ${item.year}'.toLowerCase().contains(_query.toLowerCase())).toList();
      return ListView(padding: const EdgeInsets.all(16), children: [Text('ئەنجامێن لێگەڕینێ · ${matches.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 14), if (matches.isEmpty) _empty() else _grid(matches, desktop)]);
    }
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 30), children: [SizedBox(height: 390, child: _heroCarousel()), const SizedBox(height: 14), _posterSection('بەردەوامبوون ل سەیرکرنێ', _items.where((e) => e.drama).take(3).toList() + _items.where((e) => !e.drama).take(1).toList(), landscape: true), _posterSection('فلمێن بەلڤبووی', _items.where((e) => !e.drama).toList()), _posterSection('دراما و زنجیرەیێن نوی', _items.where((e) => e.drama).toList()), _genreSection(), _posterSection('فلمێن خەڵات‌وەرگرتی', _items.reversed.take(7).toList())]);
  }
  Widget _heroCarousel() {
    final featured = [_items[0], _items[3], _items[10]];
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: featured.length,
          onPageChanged: (i) => setState(() => _hero = i),
          itemBuilder: (context, i) => _heroCard(featured[i]),
        ),
        Positioned(
          bottom: 13,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(featured.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _hero ? 21 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _hero ? Colors.white : Colors.white38,
                borderRadius: BorderRadius.circular(8),
              ),
            )),
          ),
        ),
      ],
    );
  }

  Widget _heroCard(MediaItem item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _posterImage(item.image),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [ink.withOpacity(.96), ink.withOpacity(.75), Colors.transparent],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 400,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('پێشنیارا تایبەت ژ MILLION', style: TextStyle(color: gold, fontSize: 11)),
                    const SizedBox(height: 10),
                    Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 31, height: 1.1, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFD0D9E3), height: 1.6)),
                    const SizedBox(height: 10),
                    Text('${item.year}  ·  ${item.genre}  ·  ★ ${item.rating}', style: const TextStyle(fontSize: 11, color: gold)),
                    const SizedBox(height: 14),
                    Wrap(spacing: 8, children: [
                      FilledButton.icon(onPressed: () => _openDetails(item), icon: const Icon(Icons.play_arrow), label: const Text('سەیرکرن')),
                      OutlinedButton.icon(onPressed: () => _toggleSaved(item), icon: Icon(_saved.contains(item.id) ? Icons.favorite : Icons.favorite_border), label: const Text('بژاردە')),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _posterSection(String title, List<MediaItem> items, {bool landscape = false}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.only(top: 14, bottom: 10), child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))), SizedBox(height: landscape ? 170 : 260, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(width: 11), itemBuilder: (context, i) => _mediaCard(items[i], landscape: landscape)))]);

  Widget _mediaCard(MediaItem item, {bool landscape = false, double? cardWidth}) => SizedBox(width: landscape ? 220 : (cardWidth ?? 142), child: InkWell(onTap: () => _openDetails(item), borderRadius: BorderRadius.circular(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Stack(fit: StackFit.expand, children: [ClipRRect(borderRadius: BorderRadius.circular(9), child: _posterImage(item.image)), Positioned(top: 6, right: 6, child: _pill('★ ${item.rating}', gold)), Positioned(top: 4, left: 4, child: IconButton.filledTonal(onPressed: () => _toggleSaved(item), iconSize: 16, visualDensity: VisualDensity.compact, icon: Icon(_saved.contains(item.id) ? Icons.favorite : Icons.favorite_border))), if (landscape) const Center(child: Icon(Icons.play_circle_fill, size: 35, color: Colors.white))])), const SizedBox(height: 6), Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), Text('${item.year} · ${item.genre}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 9))])));

  Widget _pill(String text, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: ink.withOpacity(.8), borderRadius: BorderRadius.circular(7)), child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)));

  Widget _genreSection() { final genres = ['دراما', 'زانستی', 'تریلەر', 'ئەڤین', 'بەلگەنامەیی']; return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Padding(padding: EdgeInsets.only(top: 14, bottom: 10), child: Text('جۆرێن بەلڤ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))), Wrap(spacing: 8, runSpacing: 8, children: genres.map((g) => ActionChip(avatar: const Icon(Icons.category_outlined, size: 16), label: Text(g), onPressed: () { _goTo(1); setState(() => _genre = g); })).toList())]); }

  Widget _genreFilters() { final options = _page == 2 ? ['هەمی', 'دراما یا خێزانی', 'دراما یا تاوانێ', 'دراما یا گەشتێ'] : ['هەمی', 'دراما', 'تریلەر', 'زانستی', 'ئەڤین', 'بەلگەنامەیی']; return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: options.map((g) => Padding(padding: const EdgeInsetsDirectional.only(end: 7), child: ChoiceChip(label: Text(g), selected: _genre == g, onSelected: (_) => setState(() => _genre = g)))).toList())); }

  Widget _grid(List<MediaItem> items, bool desktop) => LayoutBuilder(builder: (context, c) { final columns = c.maxWidth > 1000 ? 6 : c.maxWidth > 650 ? 4 : 3; return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: items.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, childAspectRatio: .51, crossAxisSpacing: 12, mainAxisSpacing: 14), itemBuilder: (_, i) => _mediaCard(items[i], cardWidth: double.infinity)); });

  Widget _empty() => Padding(padding: const EdgeInsets.all(40), child: Column(children: [const Icon(Icons.search_off, size: 40, color: muted), const SizedBox(height: 8), const Text('چ ناڤەرۆک نەهاتە دیتن'), TextButton(onPressed: () { _searchController.clear(); setState(() { _query = ''; _genre = 'هەمی'; }); }, child: const Text('لێگەڕیانێ پاک بکە'))]));

  Widget _livePage() => ListView(padding: const EdgeInsets.all(18), children: [
    Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: const LinearGradient(colors: [Color(0xFF1B392A), Color(0xFF13271E)])), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('MILLION · LIVE', style: TextStyle(color: gold, fontSize: 11)), SizedBox(height: 8), Text('پەخشا ڕاستەوخۆ', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)), SizedBox(height: 4), Text('کاناڵێن لایڤ ل ڤێرێ دێ دەرکەڤن.', style: TextStyle(color: muted))])),
    if (_liveChannels.isEmpty) const Padding(padding: EdgeInsets.all(18), child: Text('هێشتا چ لینکێن لایڤ نەهاتینە زێدەکرن.', style: TextStyle(color: muted))),
    ..._liveChannels.map((channel) => Card(color: _surface, child: ListTile(leading: const CircleAvatar(backgroundColor: Color(0xFF2C4735), child: Icon(Icons.live_tv, color: gold)), title: Text(channel['name'] ?? 'MILLION LIVE'), subtitle: Text(channel['type'] ?? 'HLS / M3U8'), trailing: const Icon(Icons.play_circle_fill, color: blue), onTap: () => _playStream(channel['url'] ?? '', channel['name'] ?? 'MILLION LIVE')))),
  ]);

  Widget _settingsPage() => ListView(padding: const EdgeInsets.all(16), children: [
    Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(colors: _dark ? const [Color(0xFF21422F), Color(0xFF13271E)] : const [Color(0xFFEAF2E2), Color(0xFFFFFFFF)])), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('MILLION · SETTINGS', style: TextStyle(color: _dark ? gold : blue, fontSize: 11, letterSpacing: 1)), const SizedBox(height: 7), Text('ڕێکخستنێن بەرنامێ', style: TextStyle(color: _primaryText, fontSize: 23, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text('ڕەنگ و زانیاریێن پەیوەندیێ ڕێک بخە.', style: TextStyle(color: _mutedText))])),
    const SizedBox(height: 14),
    Card(color: _surface, child: SwitchListTile(value: _dark, onChanged: _setDarkMode, secondary: Icon(_dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined, color: blue), title: const Text('دیزاینێ بەرنامێ'), subtitle: Text(_dark ? 'شێوازی تاریک چالاکە' : 'شێوازی ڕوون چالاکە'), activeColor: blue)),
    Card(color: _surface, child: ListTile(leading: const Icon(Icons.language, color: blue), title: Text(_text('language')), trailing: DropdownButton<String>(value: _language, items: const [DropdownMenuItem(value: 'ku', child: Text('کوردی')), DropdownMenuItem(value: 'ar', child: Text('العربية')), DropdownMenuItem(value: 'en', child: Text('English'))], onChanged: (v) { if (v != null) _changeLanguage(v); }))),
    Card(color: _surface, child: ExpansionTile(leading: const Icon(Icons.workspace_premium_outlined, color: blue), title: Text(_text('subscriptions')), subtitle: const Text('٥$ · ١٥$ · ٢٥$'), children: [ListTile(title: Text(_text('one_month')), trailing: const Text('\$5'), onTap: () => _subscribe(_text('one_month'), '\$5')), ListTile(title: Text(_text('six_months')), trailing: const Text('\$15'), onTap: () => _subscribe(_text('six_months'), '\$15')), ListTile(title: Text(_text('one_year')), trailing: const Text('\$25'), onTap: () => _subscribe(_text('one_year'), '\$25')), const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 12), child: Text('پارەدان هێشتا بە gateway ڤە نەهاتە گرێدان.', style: TextStyle(color: muted, fontSize: 10))])),
    Card(color: _surface, child: Column(children: [ListTile(leading: const Icon(Icons.support_agent, color: blue), title: const Text('Contact Us · پەیوەندی'), subtitle: const Text('پەیامەک بۆ تیمێ MILLION بنێرە'), trailing: const Icon(Icons.chevron_left), onTap: _showContactDialog), Divider(height: 1, color: _dark ? Colors.white12 : Colors.black12), ListTile(leading: const Icon(Icons.privacy_tip_outlined, color: blue), title: const Text('Privacy Policy · پاراستنا نهێنیێ'), subtitle: const Text('بزانە زانیاریێن تە چەوا دهێن پاراستن'), trailing: const Icon(Icons.chevron_left), onTap: _showPrivacyDialog)])),
  ]);

  Widget _adminPage() {
    final filtered = _items.where((e) => (_settingsKind == 'هەمی' || (_settingsKind == 'دراما' ? e.drama : !e.drama)) && '${e.title} ${e.genre} ${e.year}'.toLowerCase().contains(_settingsQuery.toLowerCase())).toList();
    final films = _items.where((e) => !e.drama).length;
    final dramas = _items.length - films;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(colors: _dark ? const [Color(0xFF21422F), Color(0xFF13271E)] : const [Color(0xFFEAF2E2), Color(0xFFFFFFFF)]), border: Border.all(color: _dark ? const Color(0xFF3D5B45) : const Color(0xFFD5E2D1))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('MILLION · ADMIN', style: TextStyle(color: _dark ? gold : blue, fontSize: 11, letterSpacing: 1)), const SizedBox(height: 7), Text('بەڕێڤەبرنا فلم و درامایان', style: TextStyle(color: _primaryText, fontSize: 23, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text('ناڤ و وێنە ل ڤێرێ بگوهۆڕە؛ گوهۆڕین دێ ل بەشێ سەرەکی دیار بن.', style: TextStyle(color: _mutedText))])),
      const SizedBox(height: 12),
      Row(children: [_stat('هەمی ناڤەرۆک', '${_items.length}'), _stat('فلم', '$films'), _stat('دراما', '$dramas')]),
      const SizedBox(height: 14),
      Wrap(spacing: 8, runSpacing: 8, children: [FilledButton.icon(onPressed: _addMediaDialog, icon: const Icon(Icons.add), label: Text(_text('add_media'))), OutlinedButton.icon(onPressed: _addLiveDialog, icon: const Icon(Icons.live_tv), label: Text(_text('add_live')))]),
      const SizedBox(height: 12),
      Card(color: _surface, child: ExpansionTile(leading: const Icon(Icons.people_outline, color: blue), title: Text('${_text('customers')} · ${_subscriptions.length}'), children: _subscriptions.isEmpty ? const [ListTile(title: Text('هێشتا داواکارییەک تۆمار نەکراوە.'))] : _subscriptions.reversed.map((s) => ListTile(leading: const Icon(Icons.person_outline), title: Text(s['name'] ?? '—'), subtitle: Text('${s['email'] ?? '—'} · ${s['plan'] ?? ''} · ${s['price'] ?? ''}'), trailing: Text(_text('pending'), style: const TextStyle(color: gold, fontSize: 10)))).toList())),
      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('داواکاری و ناوەکان ل ڤێ ئامێرێ دپارێزرێن؛ بۆ دیتنا بەکارهێنەرێن ئامێرێن دی backend پێدڤییە. پارەدان gateway پێدڤییە.', style: TextStyle(color: muted, height: 1.7, fontSize: 10))),
      TextField(onChanged: (v) => setState(() => _settingsQuery = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ل ناڤ و جۆرێ بگەڕێ…')),
      const SizedBox(height: 10),
      Wrap(spacing: 7, children: ['هەمی', 'فلم', 'دراما'].map((kind) => ChoiceChip(label: Text(kind), selected: _settingsKind == kind, onSelected: (_) => setState(() => _settingsKind = kind))).toList()),
      const SizedBox(height: 12),
      Text('لیستا ناڤەرۆکان · ${filtered.length}', style: TextStyle(color: _primaryText, fontSize: 15, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ...filtered.map((item) => Card(color: _surface, clipBehavior: Clip.antiAlias, child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), leading: ClipRRect(borderRadius: BorderRadius.circular(7), child: SizedBox(width: 52, height: 68, child: _posterImage(item.image))), title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text('${item.drama ? 'دراما' : 'فلم'} · ${item.year} · ${item.genre}', maxLines: 1), trailing: IconButton(onPressed: () => _editItem(item), icon: const Icon(Icons.edit_outlined, color: blue)), onTap: () => _editItem(item)))),
    ]);
  }
  Future<void> _showContactDialog() async {
    final name = TextEditingController();
    final email = TextEditingController();
    final message = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('پەیوەندی ب MILLION'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'ناڤ')),
              const SizedBox(height: 8),
              TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'ئیمەیڵ')),
              const SizedBox(height: 8),
              TextField(controller: message, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'پەیاما تە')),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('ڤەگەرە')),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('فۆڕمەک ئامادەیە؛ بۆ ناردنا پەیامان پێدڤی ب سێرڤەری پەیوەندیێ هەیە.')));
            },
            icon: const Icon(Icons.send_outlined),
            label: const Text('پەیام بنێرە'),
          ),
        ],
      ),
    );
    name.dispose();
    email.dispose();
    message.dispose();
  }

  void _showPrivacyDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Privacy Policy · پاراستنا نهێنیێ'),
        content: const SingleChildScrollView(
          child: Text('بژاردە، پڕۆفایل، ڕەنگ و گوهۆڕینێن ناڤەرۆکێ ل ناڤ ئامێرێ تە دپارێزرێن. وێنێن ئۆنلاین ژ خزمەتگوزارێن دەرەکی دهێن بارکرن. ئەڤ وەشانە هەژمار یان سێرڤەرێ بۆ کۆمکرنا زانیاریان نینە.', style: TextStyle(height: 1.8)),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('تێگەهشتم'))],
      ),
    );
  }
  Widget _stat(String title, String value) => Expanded(child: Container(margin: const EdgeInsetsDirectional.only(end: 7), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _dark ? const Color(0xFF35503F) : const Color(0xFFD5E2D1))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: _mutedText, fontSize: 10)), const SizedBox(height: 5), Text(value, style: TextStyle(color: _primaryText, fontSize: 20, fontWeight: FontWeight.bold))])));
}
