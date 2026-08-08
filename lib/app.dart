import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/register_page.dart';
import 'features/onboarding/presentation/onboarding_page.dart';
import 'features/home/presentation/home_page.dart';

class OrientiaApp extends StatefulWidget {
  const OrientiaApp({super.key});

  @override
  State<OrientiaApp> createState() => _OrientiaAppState();
}

class _OrientiaAppState extends State<OrientiaApp> {
  late final ApiClient _apiClient;
  late final AuthRepository _authRepo;
  late final FlutterSecureStorage _storage;
  
  bool _isLoggedIn = false;
  bool _isLoading = true;
  bool _showRegister = false;
  bool _onboardingDone = false;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _authRepo = AuthRepository(_apiClient);
    _storage = FlutterSecureStorage();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await _authRepo.isLoggedIn();
    final onboardingDone = await _storage.read(key: AppConstants.onboardingDone);
    setState(() {
      _isLoggedIn = loggedIn;
      _onboardingDone = onboardingDone == 'true';
      _isLoading = false;
    });
  }

  void _onLoginSuccess() => setState(() {
    _isLoggedIn = true;
    _showRegister = false;
  });

  void _onLogout() => setState(() {
    _isLoggedIn = false;
    _showRegister = false;
    _onboardingDone = false;
  });

  void _showRegisterPage() => setState(() => _showRegister = true);
  void _showLoginPage() => setState(() => _showRegister = false);

  Future<void> _completeOnboarding() async {
    await _storage.write(key: AppConstants.onboardingDone, value: 'true');
    setState(() => _onboardingDone = true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orientia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _isLoading
          ? Scaffold(
              body: Container(
                decoration: BoxDecoration(gradient: AppTheme.darkGradient),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(20)),
                        child: Icon(Icons.school_rounded, color: Colors.white, size: 32),
                      ),
                      SizedBox(height: 24),
                      Text('Orientia', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                      SizedBox(height: 8),
                      Text('Chargement...', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                      SizedBox(height: 24),
                      SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
                    ],
                  ),
                ),
              ),
            )
          : _isLoggedIn
              ? _onboardingDone
                  ? HomePage(apiClient: _apiClient, onLogout: _onLogout)
                  : OnboardingPage(apiClient: _apiClient, onComplete: _completeOnboarding)
              : _showRegister
                  ? RegisterPage(
                      apiClient: _apiClient,
                      onRegisterSuccess: _showLoginPage,
                      onBackToLogin: _showLoginPage,
                    )
                  : LoginPage(
                      apiClient: _apiClient,
                      onLoginSuccess: _onLoginSuccess,
                      onRegister: _showRegisterPage,
                    ),
    );
  }
}
