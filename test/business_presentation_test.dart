import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orientia/features/catalog/presentation/catalog_page.dart';
import 'package:orientia/features/navigation/presentation/workspace_pages.dart';
import 'support/fake_transport.dart';

void main() {
  testWidgets(
      'catalog appends results and refresh starts over without page controls',
      (tester) async {
    final requested = <int>[];
    final api = clientFor((r, s) {
      if (r.path != '/universities') return jsonResponse({'content': []});
      final page = r.queryParameters['page'] as int;
      requested.add(page);
      return jsonResponse({
        'content': [
          {'id': 'u$page', 'name': 'Université $page', 'verified': true}
        ],
        'number': page,
        'size': 1,
        'totalElements': 2,
        'last': page == 1
      });
    });
    await tester.runAsync(() => api.login('test', 'test'));
    await tester.pumpWidget(MaterialApp(home: CatalogPage(apiClient: api)));
    await tester.pumpAndSettle();
    expect(find.text('Université 0'), findsOneWidget);
    await tester.tap(find.text('Voir plus de résultats'));
    await tester.pumpAndSettle();
    expect(find.text('Université 0'), findsOneWidget);
    expect(find.text('Université 1'), findsOneWidget);
    expect(find.text('Précédent'), findsNothing);
    expect(find.text('Page 2'), findsNothing);
    expect(requested, [0, 1]);
    await tester.tap(find.byTooltip('Rechercher'));
    await tester.pumpAndSettle();
    expect(requested, [0, 1, 0]);
    expect(find.text('Université 1'), findsNothing);
    expect(tester.takeException(), isNull);
    api.dispose();
  });

  testWidgets('legal pages are readable at a narrow width with enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!),
        home: LegalDocumentPage(
            title: legalDocuments.first.$1,
            sections: legalDocuments.first.$2)));
    expect(find.text('Orientia · Le Studio Viral'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Vos demandes'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Vos demandes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
