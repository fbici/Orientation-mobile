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

  // Pays et villes
  int _currentStep = 0; // 0 = infos, 1 = pays
  List<dynamic> _countries = [];
  List<dynamic> _cities = [];
  String? _selectedCountryId;
  String? _selectedCityId;
  bool _loadingLocations = false;

  @override
  void initState() {
    super.initState();
    _authRepo = AuthRepository(widget.apiClient);
    _loadCountries();
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

  Future<void> _loadCountries() async {
    setState(() => _loadingLocations = true);
    try {
      final response = await widget.apiClient.getCountries();
      if (mounted) setState(() { _countries = response.data ?? []; _loadingLocations = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingLocations = false);
    }
  }

  Future<void> _loadCities(String countryId) async {
    setState(() { _cities = []; _selectedCityId = null; });
    try {
      final response = await widget.apiClient.getCities(countryId);
      if (mounted) setState(() => _cities = response.data ?? []);
    } catch (e) {}
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;
      if (!_acceptTerms) {
        setState(() => _error = 'Veuillez accepter les conditions.');
        return;
      }
      setState(() { _currentStep = 1; _error = null; });
    } else {
      _register();
    }
  }

  Future<void> _register() async {
    setState(() { _loading = true; _error = null; });

    try {
      await _authRepo.register({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        'password': _passwordController.text,
        if (_selectedCountryId != null) 'countryId': _selectedCountryId,
        if (_selectedCityId != null) 'cityId': _selectedCityId,
      });
      setState(() => _success = true);
    } on DioException catch (e) {
      setState(() {
        if (e.response?.statusCode == 400) {
          final data = e.response?.data;
          _error = data is Map ? (data['message'] ?? 'Cet email est deja utilise.') : 'Cet email est deja utilise.';
        } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
          _error = 'Impossible de joindre le serveur.';
        } else {
          _error = 'Une erreur est survenue.';
        }
      });
    } catch (e) {
      setState(() => _error = 'Une erreur inattendue est survenue.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
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
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          'assets/images/orientia.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    if (!_success) ...[
                      // Title
                      Text(
                        _currentStep == 0 ? 'Creer un compte' : 'Votre pays',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentStep == 0 ? 'Rejoignez Orientia' : 'Pour des recommandations adaptees',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      // Steps indicator
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStepDot(0, 'Informations'),
                          Container(width: 40, height: 2, color: _currentStep >= 1 ? AppTheme.primary : Colors.white.withOpacity(0.2)),
                          _buildStepDot(1, 'Pays'),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Form card
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: _currentStep == 0 ? _buildStep1() : _buildStep2(),
                      ),
                      const SizedBox(height: 24),

                      // Back to login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Deja un compte ?',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13,
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onBackToLogin,
                            child: Text(
                              ' Se connecter',
                              style: TextStyle(
                                color: AppTheme.primaryLight,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Success
                    if (_success) ...[
                      Container(
                        padding: const EdgeInsets.all(36),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppTheme.success.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Icon(
                                Icons.mark_email_read_rounded,
                                color: AppTheme.success,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Verifiez votre email',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Un email de confirmation a ete envoye a :',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _emailController.text,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, color: AppTheme.warning, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Verifiez votre dossier spam si vous ne trouvez pas l\'email.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.6),
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: widget.onBackToLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  'Aller a la connexion',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
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

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: isActive && _currentStep > step
                ? Icon(Icons.check, size: 14, color: Colors.white)
                : Text('${step + 1}', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(isActive ? 0.8 : 0.4))),
      ],
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _buildField(controller: _firstNameController, label: 'Prenom', icon: Icons.person_outline_rounded, validator: (v) => v!.isEmpty ? 'Requis' : null)),
              const SizedBox(width: 12),
              Expanded(child: _buildField(controller: _lastNameController, label: 'Nom', icon: Icons.person_outline_rounded, validator: (v) => v!.isEmpty ? 'Requis' : null)),
            ],
          ),
          const SizedBox(height: 16),
          _buildField(controller: _emailController, label: 'Adresse email', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress, validator: (v) { if (v == null || v.isEmpty) return 'Requis'; if (!v.contains('@')) return 'Email invalide'; return null; }),
          const SizedBox(height: 16),
          _buildField(controller: _phoneController, label: 'Telephone (optionnel)', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _buildField(controller: _passwordController, label: 'Mot de passe', icon: Icons.lock_outline_rounded, obscure: !_showPassword, suffixIcon: IconButton(icon: Icon(_showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white.withOpacity(0.3), size: 20), onPressed: () => setState(() => _showPassword = !_showPassword)), validator: (v) { if (v == null || v.isEmpty) return 'Requis'; if (v.length < 8) return 'Minimum 8 caracteres'; return null; }),
          const SizedBox(height: 16),
          _buildField(controller: _confirmPasswordController, label: 'Confirmer le mot de passe', icon: Icons.lock_outline_rounded, obscure: !_showConfirmPassword, suffixIcon: IconButton(icon: Icon(_showConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white.withOpacity(0.3), size: 20), onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword)), validator: (v) { if (v != _passwordController.text) return 'Les mots de passe ne correspondent pas'; return null; }),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => setState(() => _acceptTerms = !_acceptTerms),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 22, height: 22, decoration: BoxDecoration(color: _acceptTerms ? AppTheme.primary : Colors.transparent, border: Border.all(color: _acceptTerms ? AppTheme.primary : Colors.white.withOpacity(0.2)), borderRadius: BorderRadius.circular(6)), child: _acceptTerms ? const Icon(Icons.check, size: 14, color: Colors.white) : null),
                const SizedBox(width: 12),
                Expanded(child: Text('J\'accepte les conditions d\'utilisation', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5)))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_error != null)
            Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.danger.withOpacity(0.2))), child: Row(children: [Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 18), const SizedBox(width: 10), Expanded(child: Text(_error!, style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 13)))])),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Continuer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)), const SizedBox(width: 8), Icon(Icons.arrow_forward_rounded, size: 20)]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Selectionnez votre pays', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (_loadingLocations)
          Center(child: CircularProgressIndicator(color: AppTheme.primary))
        else
          ..._countries.map((c) => _buildCountryOption(c)).toList(),
        if (_selectedCountryId != null && _cities.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Selectionnez votre ville (optionnel)', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._cities.take(10).map((c) => _buildCityOption(c)).toList(),
        ],
        const SizedBox(height: 24),
        if (_error != null)
          Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.danger.withOpacity(0.2))), child: Row(children: [Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 18), const SizedBox(width: 10), Expanded(child: Text(_error!, style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 13)))])),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 0),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.white.withOpacity(0.2)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text('Retour'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                child: _loading
                    ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Creer mon compte', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)), const SizedBox(width: 8), Icon(Icons.check_rounded, size: 20)]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCountryOption(dynamic country) {
    final isSelected = _selectedCountryId == country['id'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedCountryId = country['id']);
          _loadCities(country['id']);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withOpacity(0.15) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppTheme.primary : Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Icon(Icons.public_rounded, color: isSelected ? AppTheme.primary : Colors.white.withOpacity(0.4), size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(country['name'] ?? '', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400))),
              if (isSelected) Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityOption(dynamic city) {
    final isSelected = _selectedCityId == city['id'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCityId = city['id']),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withOpacity(0.15) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppTheme.primary : Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Icon(Icons.location_city_rounded, color: isSelected ? AppTheme.primary : Colors.white.withOpacity(0.4), size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(city['name'] ?? '', style: TextStyle(color: Colors.white, fontSize: 13))),
              if (isSelected) Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 18),
            ],
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
      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.3), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.5), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.danger),
        ),
      ),
    );
  }
}
