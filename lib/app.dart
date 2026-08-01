import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/register_page.dart';
import 'features/home/presentation/home_page.dart';

class OrientationApp extends StatefulWidget {
  const OrientationApp({super.key});

  @override
  State<OrientationApp> createState() => _OrientationAppState();
}

class _OrientationAppState extends State<OrientationApp> {
  late final ApiClient _apiClient;
  late final AuthRepository _authRepo;
  bool _isLoggedIn = false;
  bool _isLoading = true;
  bool _showRegister = false;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _authRepo = AuthRepository(_apiClient);
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await _authRepo.isLoggedIn();
    setState(() {
      _isLoggedIn = loggedIn;
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
  });

  void _showRegisterPage() => setState(() => _showRegister = true);
  void _showLoginPage() => setState(() => _showRegister = false);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orientia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _isLoading
          ? const Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Chargement...', style: TextStyle(color: AppTheme.gray500)),
                  ],
                ),
              ),
            )
          : _isLoggedIn
              ? HomePage(apiClient: _apiClient, onLogout: _onLogout)
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
