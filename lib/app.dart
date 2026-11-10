import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/launch/presentation/launch_pages.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'core/files/report_files.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/register_page.dart';
import 'features/home/presentation/home_page.dart';

class OrientiaApp extends StatefulWidget {
  final ApiClient? apiClient;
  const OrientiaApp({super.key, this.apiClient});
  @override
  State<OrientiaApp> createState() => _OrientiaAppState();
}

class _OrientiaAppState extends State<OrientiaApp> {
  late final api = widget.apiClient ?? ApiClient();
  bool register = false;
  bool launchComplete = false;
  bool? introSeen;
  bool completingIntro = false;
  static const introKey = 'orientia_intro_seen_v1';
  int observedEpoch = -1;
  @override
  void initState() {
    super.initState();
    api.addListener(changed);
    unawaited(loadIntroduction());
    unawaited(cleanup());
    Future.microtask(api.restore);
  }

  Future<void> loadIntroduction() async {
    bool seen = false;
    try {
      seen = (await SharedPreferences.getInstance()).getBool(introKey) ?? false;
    } catch (_) {/* Preferences must not block the presentation. */}
    if (mounted) setState(() => introSeen = seen);
  }

  Future<void> completeIntroduction() async {
    if (completingIntro) return;
    completingIntro = true;
    try {
      await (await SharedPreferences.getInstance()).setBool(introKey, true);
    } catch (_) {/* Preferences must not block access to the application. */}
    if (mounted) {
      setState(() {
        introSeen = true;
        completingIntro = false;
      });
    }
  }

  Future<void> cleanup() async {
    await clearPrivateFiles();
    try {
      await FilePicker.platform.clearTemporaryFiles();
    } catch (_) {}
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  void changed() {
    if (observedEpoch != api.sessionEpoch) {
      observedEpoch = api.sessionEpoch;
      unawaited(cleanup());
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    api.removeListener(changed);
    if (widget.apiClient == null) api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        key: ValueKey(api.status == SessionStatus.authenticated
            ? 'account-${api.user?['id']}-${api.sessionEpoch}'
            : 'signed-out'),
        title: 'Orientia',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: !launchComplete || introSeen == null
            ? LaunchSplash(onFinished: () {
                if (mounted && !launchComplete) {
                  setState(() => launchComplete = true);
                }
              })
            : !introSeen!
                ? WelcomePage(onContinue: completeIntroduction)
                : switch (api.status) {
                    SessionStatus.restoring => const Scaffold(
                        body: Center(
                            child: CircularProgressIndicator(
                                semanticsLabel: 'Vérification de la session'))),
                    SessionStatus.unavailable => Scaffold(
                        body: SafeArea(
                            child: Center(
                                child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.cloud_off, size: 48),
                                          const Text(
                                              'Session à vérifier. Le serveur est actuellement inaccessible. Vos données privées restent verrouillées.'),
                                          FilledButton(
                                              onPressed: api.restore,
                                              child: const Text('Réessayer')),
                                          TextButton(
                                              onPressed: () async {
                                                try {
                                                  await api.logout();
                                                } catch (_) {}
                                              },
                                              child: const Text(
                                                  'Supprimer la session locale')),
                                        ]))))),
                    SessionStatus.authenticated => HomePage(
                        apiClient: api,
                        onLogout: () {
                          if (mounted) setState(() => register = false);
                        }),
                    SessionStatus.signedOut => register
                        ? RegisterPage(
                            apiClient: api,
                            onRegisterSuccess: () =>
                                setState(() => register = false),
                            onBackToLogin: () =>
                                setState(() => register = false))
                        : LoginPage(
                            apiClient: api,
                            onIntroduction: () =>
                                setState(() => introSeen = false),
                            onLoginSuccess: () {
                              if (mounted) setState(() => register = false);
                            },
                            onRegister: () => setState(() => register = true)),
                  },
      );
}
