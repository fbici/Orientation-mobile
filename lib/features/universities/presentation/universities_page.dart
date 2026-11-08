import '../../catalog/presentation/catalog_page.dart';

class UniversitiesPage extends CatalogPage {
  const UniversitiesPage({super.key, required super.apiClient})
      : super(resource: 'universities', title: 'Universités');
}
