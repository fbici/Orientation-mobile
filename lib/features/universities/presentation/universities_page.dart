import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class UniversitiesPage extends StatefulWidget {
  final ApiClient apiClient;
  const UniversitiesPage({super.key, required this.apiClient});

  @override
  State<UniversitiesPage> createState() => _UniversitiesPageState();
}

class _UniversitiesPageState extends State<UniversitiesPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Universites',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Explorez les etablissements et programmes disponibles.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),

            // Search bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.gray200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher une universite...',
                  hintStyle: TextStyle(color: AppTheme.gray400, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: AppTheme.gray400, size: 20),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Stats
            Row(
              children: [
                _buildChip('Toutes', true),
                const SizedBox(width: 8),
                _buildChip('Benin', false),
                const SizedBox(width: 8),
                _buildChip('France', false),
                const SizedBox(width: 8),
                _buildChip('Canada', false),
              ],
            ),
            const SizedBox(height: 24),

            // University list
            Text(
              '153 universites',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildUniversityCard('Universite d\'Abomey-Calavi', 'Abomey-Calavi, Benin', '12 facultes', AppTheme.primary),
            const SizedBox(height: 12),
            _buildUniversityCard('Universite de Parakou', 'Parakou, Benin', '8 facultes', AppTheme.success),
            const SizedBox(height: 12),
            _buildUniversityCard('EPAC', 'Abomey-Calavi, Benin', '5 programmes', AppTheme.accent),
            const SizedBox(height: 12),
            _buildUniversityCard('UAC - FAST', 'Cotonou, Benin', '15 programmes', AppTheme.warning),
            const SizedBox(height: 12),
            _buildUniversityCard('Universite de Lome', 'Lome, Togo', '10 facultes', AppTheme.info),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? AppTheme.primary : AppTheme.gray200,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.white : AppTheme.gray600,
        ),
      ),
    );
  }

  Widget _buildUniversityCard(String name, String location, String programs, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.gray200),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.school_rounded, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: AppTheme.gray400),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: TextStyle(fontSize: 12, color: AppTheme.gray500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        programs,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.gray300),
            ],
          ),
        ),
      ),
    );
  }
}
