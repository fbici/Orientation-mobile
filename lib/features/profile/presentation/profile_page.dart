import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';

/// Page de profil
class ProfilePage extends StatefulWidget {
  final ApiClient apiClient;
  final VoidCallback onLogout;

  const ProfilePage({super.key, required this.apiClient, required this.onLogout});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final AuthRepository _authRepo;
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _authRepo = AuthRepository(widget.apiClient);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _authRepo.getProfile();
      setState(() {
        _user = user;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: Text(
                  _getInitials(),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Name
            Text(
              '${_user?['firstName'] ?? ''} ${_user?['lastName'] ?? ''}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.gray900),
            ),
            const SizedBox(height: 4),
            Text(
              _user?['email'] ?? '',
              style: const TextStyle(fontSize: 13, color: AppTheme.gray500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                for (final role in _user?['roles'] ?? [])
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySurface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(role, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryDark)),
                  ),
              ],
            ),
            const SizedBox(height: 32),

            // Menu items
            _buildMenuItem(Icons.person_outline, 'Modifier le profil', () {}),
            _buildMenuItem(Icons.lock_outline, 'Changer le mot de passe', () {}),
            _buildMenuItem(Icons.notifications_outlined, 'Notifications', () {}),
            _buildMenuItem(Icons.help_outline, 'Aide et support', () {}),
            _buildMenuItem(Icons.info_outline, 'A propos', () {}),

            const SizedBox(height: 24),

            // Logout button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _authRepo.logout();
                  widget.onLogout();
                },
                icon: const Icon(Icons.logout, size: 18, color: AppTheme.danger),
                label: const Text('Se deconnecter', style: TextStyle(color: AppTheme.danger)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials() {
    final first = _user?['firstName'] ?? '';
    final last = _user?['lastName'] ?? '';
    return '${first.isNotEmpty ? first[0].toUpperCase() : ''}${last.isNotEmpty ? last[0].toUpperCase() : ''}';
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.gray200),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.gray500),
                const SizedBox(width: 14),
                Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.gray800))),
                const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.gray400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
