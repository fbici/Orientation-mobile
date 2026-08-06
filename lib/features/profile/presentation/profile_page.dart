import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  final ApiClient apiClient;
  final VoidCallback onLogout;

  const ProfilePage({super.key, required this.apiClient, required this.onLogout});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  List<String> _roles = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await widget.apiClient.getMe();
      if (mounted) {
        setState(() {
          _firstName = response.data['firstName'] ?? '';
          _lastName = response.data['lastName'] ?? '';
          _email = response.data['email'] ?? '';
          _roles = List<String>.from(response.data['roles'] ?? []);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = (_firstName.isNotEmpty ? _firstName[0] : '') + (_lastName.isNotEmpty ? _lastName[0] : '');

    return SafeArea(
      child: _loading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Profil', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 24),

                    // Carte profil
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                initials.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '$_firstName $_lastName',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _email,
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          if (_roles.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _roles.join(', '),
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Menu
                    Text('Parametres', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    _buildMenuItem(Icons.person_outline_rounded, 'Modifier le profil', AppTheme.primary, () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bientot disponible')));
                    }),
                    _buildMenuItem(Icons.lock_outline_rounded, 'Changer le mot de passe', AppTheme.info, () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bientot disponible')));
                    }),
                    _buildMenuItem(Icons.notifications_outlined, 'Notifications', AppTheme.warning, () {
                      _showNotificationsSheet(context);
                    }),
                    _buildMenuItem(Icons.school_outlined, 'Mes candidatures', AppTheme.success, () {
                      _showCandidaturesSheet(context);
                    }),
                    _buildMenuItem(Icons.help_outline_rounded, 'Aide et support', AppTheme.accent, () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bientot disponible')));
                    }),
                    _buildMenuItem(Icons.info_outline_rounded, 'A propos d\'Orientia', AppTheme.gray500, () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Orientia',
                        applicationVersion: '1.0.0',
                        applicationLegalese: 'Plateforme d\'orientation universitaire intelligente',
                      );
                    }),
                    const SizedBox(height: 24),

                    // Deconnexion
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text('Deconnexion'),
                              content: Text('Voulez-vous vraiment vous deconnecter ?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    widget.onLogout();
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                                  child: Text('Deconnecter'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: Icon(Icons.logout_rounded, size: 20, color: AppTheme.danger),
                        label: Text('Se deconnecter', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w600, fontSize: 15)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.danger.withOpacity(0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text('Orientia v1.0.0', style: TextStyle(fontSize: 12, color: AppTheme.gray400)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.gray300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              _buildNotifItem(Icons.info_outline_rounded, 'Bienvenue !', 'Votre compte a ete cree avec succes.', 'A l\'instant', AppTheme.info),
              _buildNotifItem(Icons.school_rounded, 'Nouvelles universites', '153 universites disponibles dans la base.', 'Aujourd\'hui', AppTheme.success),
              _buildNotifItem(Icons.auto_awesome_rounded, 'IA disponible', 'Lancez votre premiere recommandation IA.', 'Aujourd\'hui', AppTheme.accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotifItem(IconData icon, String title, String body, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.gray200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.gray900)),
                  const SizedBox(height: 2),
                  Text(body, style: TextStyle(fontSize: 12, color: AppTheme.gray500, height: 1.4)),
                ],
              ),
            ),
            Text(time, style: TextStyle(fontSize: 11, color: AppTheme.gray400)),
          ],
        ),
      ),
    );
  }

  void _showCandidaturesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.gray300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Mes candidatures', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.gray100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.folder_open_rounded, size: 48, color: AppTheme.gray400),
                  const SizedBox(height: 12),
                  Text('Aucune candidature', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.gray700)),
                  const SizedBox(height: 8),
                  Text(
                    'Vos candidatures apparaitront ici apres avoir obtenu des recommandations.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppTheme.gray500, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Fermer'),
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.gray200),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray800)),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.gray300),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
