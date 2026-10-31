import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
  runApp(const AamirApp());
}

class AamirApp extends StatelessWidget {
  const AamirApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'AAMIR MULTIMEDIA',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF08766B), brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF102A2A),
      useMaterial3: true,
    ),
    home: const HomePage(),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final player = AudioPlayer();
  List<Map<String, dynamic>> tracks = [];
  bool loading = false;
  String status = '';
  bool get configured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  @override
  void initState() { super.initState(); loadTracks(); }

  Future<void> loadTracks() async {
    if (!configured) {
      setState(() { loading = false; status = 'Supabase qindeessuun booda nashiidaawwan asitti mul’atu.'; });
      return;
    }
    setState(() => loading = true);
    try {
      final data = await Supabase.instance.client.from('nasheeds')
          .select('id,title,artist,cover_url,audio_path,created_at')
          .order('created_at', ascending: false);
      setState(() { tracks = List<Map<String, dynamic>>.from(data); status = ''; });
    } catch (e) {
      setState(() => status = 'Nashiidaa fe’uun hin milkoofne. Database qindeessi.');
    } finally { if (mounted) setState(() => loading = false); }
  }

  String audioUrl(String path) =>
      Supabase.instance.client.storage.from('nasheeds').getPublicUrl(path);

  Future<void> playTrack(Map<String, dynamic> track) async {
    if (!configured) { setState(() => status = 'Backend ammaaf hin qindaa’inne.'); return; }
    try {
      await player.setUrl(audioUrl(track['audio_path'] as String));
      await player.play();
    } catch (e) { setState(() => status = 'Sagalee kana taphachiisuun hin danda’amne.'); }
  }

  Future<void> downloadTrack(Map<String, dynamic> track) async {
    if (!configured) { setState(() => status = 'Backend ammaaf hin qindaa’inne.'); return; }
    final uri = Uri.parse(audioUrl(track['audio_path'] as String));
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() { player.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('AAMIR MULTIMEDIA'),
      actions: [IconButton(onPressed: loadTracks, icon: const Icon(Icons.refresh))],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLoginPage())),
      icon: const Icon(Icons.admin_panel_settings),
      label: const Text('Admin'),
    ),
    body: RefreshIndicator(
      onRefresh: loadTracks,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset('assets/aamir_logo.jpg', height: 150, fit: BoxFit.contain),
          )),
          const SizedBox(height: 12),
          const Center(child: Text('NASHEED • LISTEN • DOWNLOAD',
            style: TextStyle(letterSpacing: 1.1, color: Colors.white70))),
          const SizedBox(height: 24),
          const Text('Nashiidaawwan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (loading) const Center(child: CircularProgressIndicator()),
          if (status.isNotEmpty) Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(status, style: const TextStyle(color: Colors.amber)),
          ),
          if (!loading && tracks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: Text('Nashiidaawwan haaraa yeroo Admin ol fe’u asitti mul’atu.')),
            ),
          ...tracks.map((track) => Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.music_note)),
              title: Text(track['title']?.toString() ?? 'Nashiidaa'),
              subtitle: Text(track['artist']?.toString() ?? 'Aamir Multimedia'),
              trailing: Wrap(spacing: 2, children: [
                IconButton(tooltip: 'Dhaggeeffadhu', onPressed: () => playTrack(track), icon: const Icon(Icons.play_arrow)),
                IconButton(tooltip: 'Buufadhu', onPressed: () => downloadTrack(track), icon: const Icon(Icons.download)),
              ]),
            ),
          )),
          const SizedBox(height: 90),
        ],
      ),
    ),
  );
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});
  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  String message = '';
  bool busy = false;
  bool get configured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  Future<void> login() async {
    if (!configured) { setState(() => message = 'Supabase qindeessi; README.md ilaali.'); return; }
    setState(() => busy = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email.text.trim(), password: password.text);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UploadPage()));
    } on AuthException catch (e) {
      setState(() => message = e.message);
    } catch (_) { setState(() => message = 'Login hin milkoofne.'); }
    finally { if (mounted) setState(() => busy = false); }
  }

  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin Login')),
    body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      TextField(controller: email, decoration: const InputDecoration(labelText: 'Admin email')),
      TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
      const SizedBox(height: 16),
      FilledButton(onPressed: busy ? null : login, child: const Text('Seeni')),
      if (message.isNotEmpty) Text(message),
    ])),
  );
}

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});
  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final title = TextEditingController();
  final audioPath = TextEditingController();
  String message = 'Fuula kana keessatti upload UI guutuu itti aanu keessatti dabalama.';
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin Dashboard')),
    body: Padding(padding: const EdgeInsets.all(20), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Admin seeneera.', style: TextStyle(fontSize: 20)),
        const SizedBox(height: 12),
        const Text('Kun admin dashboard jalqabaa dha. File picker, upload permission fi upload form guutuu ijaarsa itti aanu keessatti dabaluu qabna.'),
        const SizedBox(height: 12),
        Text(message),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () async { await Supabase.instance.client.auth.signOut(); if (context.mounted) Navigator.pop(context); },
          child: const Text('Logout'),
        ),
      ],
    )),
  );
}
