import 'dart:async';
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
  int observedEpoch = -1;
  @override
  void initState() {
    super.initState();
    api.addListener(changed);
    unawaited(cleanup());
    Future.microtask(api.restore);
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
        home: switch (api.status) {
          SessionStatus.restoring => const Scaffold(
              body: Center(
                  child: CircularProgressIndicator(
                      semanticsLabel: 'Vérification de la session'))),
          SessionStatus.unavailable => Scaffold(
              body: SafeArea(
                  child: Center(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
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
                                child:
                                    const Text('Supprimer la session locale')),
                          ]))))),
          SessionStatus.authenticated => HomePage(
              apiClient: api,
              onLogout: () {
                if (mounted) setState(() => register = false);
              }),
          SessionStatus.signedOut => register
              ? RegisterPage(
                  apiClient: api,
                  onRegisterSuccess: () => setState(() => register = false),
                  onBackToLogin: () => setState(() => register = false))
              : LoginPage(
                  apiClient: api,
                  onLoginSuccess: () {
                    if (mounted) setState(() => register = false);
                  },
                  onRegister: () => setState(() => register = true)),
        },
      );
}
