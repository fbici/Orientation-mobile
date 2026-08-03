import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../data/auth_repository.dart';

class RegisterPage extends StatefulWidget {
  final ApiClient apiClient;
  final VoidCallback onRegisterSuccess;
  final VoidCallback onBackToLogin;

  const RegisterPage({
    super.key,
    required this.apiClient,
    required this.onRegisterSuccess,
    required this.onBackToLogin,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final AuthRepository _authRepo;
  bool _loading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _acceptTerms = false;
  String? _error;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _authRepo = AuthRepository(widget.apiClient);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      setState(() => _error = 'Veuillez accepter les conditions d\'utilisation.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _authRepo.register({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        'password': _passwordController.text,
      });

      setState(() => _success = true);
    } on DioException catch (e) {
      setState(() {
        if (e.response?.statusCode == 400) {
          // Server returned a business error (e.g. email already used)
          final data = e.response?.data;
          _error = data is Map<String, dynamic> ? (data['message'] ?? 'Cet email est deja utilise.') : 'Cet email est deja utilise.';
        } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
          _error = 'Impossible de joindre le serveur. Verifiez votre connexion.';
        } else {
          _error = 'Une erreur est survenue (${e.response?.statusCode ?? 'inconnu'}).';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Une erreur inattendue est survenue.';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF1E3A5F)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/orientia.png',
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    if (!_success) ...[
                      // Title
                      const Text('Creer un compte', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                      const SizedBox(height: 6),
                      Text('Rejoignez la plateforme Orientation', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.45))),
                      const SizedBox(height: 36),

                      // Form card
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 20))],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Name row
                              Row(
                                children: [
                                  Expanded(child: _buildField(controller: _firstNameController, label: 'Prenom', icon: Icons.person_outline_rounded, validator: (v) => v!.isEmpty ? 'Requis' : null)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildField(controller: _lastNameController, label: 'Nom', icon: Icons.person_outline_rounded, validator: (v) => v!.isEmpty ? 'Requis' : null)),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Email
                              _buildField(
                                controller: _emailController,
                                label: 'Adresse email',
                                icon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Requis';
                                  if (!v.contains('@')) return 'Email invalide';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Phone
                              _buildField(
                                controller: _phoneController,
                                label: 'Telephone (optionnel)',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 16),

                              // Password
                              _buildField(
                                controller: _passwordController,
                                label: 'Mot de passe',
                                icon: Icons.lock_outline_rounded,
                                obscure: !_showPassword,
                                suffixIcon: IconButton(
                                  icon: Icon(_showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white.withOpacity(0.3), size: 20),
                                  onPressed: () => setState(() => _showPassword = !_showPassword),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Requis';
                                  if (v.length < 8) return 'Minimum 8 caracteres';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Confirm password
                              _buildField(
                                controller: _confirmPasswordController,
                                label: 'Confirmer le mot de passe',
                                icon: Icons.lock_outline_rounded,
                                obscure: !_showConfirmPassword,
                                suffixIcon: IconButton(
                                  icon: Icon(_showConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white.withOpacity(0.3), size: 20),
                                  onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                                ),
                                validator: (v) {
                                  if (v != _passwordController.text) return 'Les mots de passe ne correspondent pas';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Terms checkbox
                              GestureDetector(
                                onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: _acceptTerms ? AppTheme.primary : Colors.transparent,
                                        border: Border.all(color: _acceptTerms ? AppTheme.primary : Colors.white.withOpacity(0.2)),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: _acceptTerms ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'J\'accepte les conditions d\'utilisation et la politique de confidentialite',
                                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Error
                              if (_error != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.danger.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13))),
                                    ],
                                  ),
                                ),

                              // Submit
                              ElevatedButton(
                                onPressed: _loading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                child: _loading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text('Creer mon compte', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_rounded, size: 20),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Back to login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Deja un compte ?', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                          GestureDetector(
                            onTap: widget.onBackToLogin,
                            child: const Text(' Se connecter', style: TextStyle(color: AppTheme.primaryLight, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],

                    // Success state
                    if (_success) ...[
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppTheme.success.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Icon(Icons.mark_email_read_rounded, color: AppTheme.success, size: 32),
                            ),
                            const SizedBox(height: 20),
                            const Text('Verifiez votre email', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                            const SizedBox(height: 12),
                            Text(
                              'Un email de confirmation a ete envoye a :',
                              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _emailController.text,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            const SizedBox(height: 20),
                            // Spam notice
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: AppTheme.warning, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Si vous ne trouvez pas l\'email, verifiez votre dossier spam ou courrier indesirable.',
                                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6), height: 1.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: widget.onBackToLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Aller a la connexion', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.3), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.5), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.danger)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.danger, width: 1.5)),
      ),
    );
  }
}
