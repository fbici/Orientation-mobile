import '../../catalog/presentation/catalog_page.dart';

class ScholarshipsPage extends CatalogPage {
  const ScholarshipsPage({super.key, required super.apiClient})
      : super(resource: 'scholarships', title: 'Bourses');
}
