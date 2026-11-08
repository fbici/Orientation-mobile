import '../../catalog/presentation/catalog_page.dart';

class ProgramsPage extends CatalogPage {
  const ProgramsPage({super.key, required super.apiClient})
      : super(resource: 'programs', title: 'Formations');
}
