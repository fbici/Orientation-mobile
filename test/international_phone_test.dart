import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_form_field/phone_form_field.dart' show CountryButton;
import 'package:orientia/core/widgets/international_phone_field.dart';

void main() {
  testWidgets(
      'the country picker searches France and updates flag and calling code',
      (tester) async {
    final controller = PhoneController(
        initialValue: const PhoneNumber(isoCode: IsoCode.BJ, nsn: ''));
    final form = GlobalKey<FormState>();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Form(
                key: form,
                child: InternationalPhoneField(controller: controller)))));
    await tester.pumpAndSettle();
    expect(tester.widget<CountryButton>(find.byType(CountryButton)).isoCode,
        IsoCode.BJ);
    expect(find.text('+ 229'), findsOneWidget);
    await tester.tap(find.byType(CountryButton));
    await tester.pumpAndSettle();
    // Simulate typing rather than country autofill: the selector automatically
    // submits a whole country name inserted into a previously empty field.
    await tester.enterText(find.byType(TextField), 'Fra');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'France');
    await tester.pumpAndSettle();
    final france = find.byKey(const ValueKey('FR'));
    expect(france, findsOneWidget);
    expect(find.descendant(of: france, matching: find.text('France')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('circle-flag-FR')), findsOneWidget);
    await tester.tap(france);
    await tester.pumpAndSettle();
    expect(controller.value.isoCode, IsoCode.FR);
    final selected = tester.widget<CountryButton>(find.byType(CountryButton));
    expect(selected.isoCode, IsoCode.FR);
    expect(selected.showFlag, isTrue);
    expect(selected.showDialCode, isTrue);
    expect(find.text('+ 33'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '06 12 34 56 78');
    await tester.pumpAndSettle();
    expect(form.currentState!.validate(), isTrue);
    expect(normalizedPhone(controller.value), '+33612345678');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  test('international metadata covers Benin and other numbering plans', () {
    for (final value in [
      '+2290197123456',
      '+33612345678',
      '+12025550123',
      '+2348031234567',
      '+5511987654321',
      '+919876543210'
    ]) {
      final number = PhoneNumber.parse(value);
      expect(number.isValid(), isTrue, reason: value);
      expect(normalizedPhone(number), value);
    }
    expect(const PhoneNumber(isoCode: IsoCode.BJ, nsn: '97123456').isValid(),
        isFalse);
    expect(normalizedPhone(const PhoneNumber(isoCode: IsoCode.BJ, nsn: '')),
        isNull);
    expect(const PhoneNumber(isoCode: IsoCode.FR, nsn: '6').isValid(), isFalse);
  });
  testWidgets(
      'country selection is not limited to Benin and optional empty input is accepted',
      (tester) async {
    final controller = PhoneController(
        initialValue: const PhoneNumber(isoCode: IsoCode.BJ, nsn: ''));
    final form = GlobalKey<FormState>();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Form(
                key: form,
                child: InternationalPhoneField(controller: controller)))));
    await tester.pumpAndSettle();
    expect(form.currentState!.validate(), isTrue);
    controller.value = const PhoneNumber(isoCode: IsoCode.FR, nsn: '612345678');
    await tester.pumpAndSettle();
    expect(form.currentState!.validate(), isTrue);
    expect(normalizedPhone(controller.value), '+33612345678');
    controller.value =
        const PhoneNumber(isoCode: IsoCode.US, nsn: '2025550123');
    await tester.pumpAndSettle();
    expect(form.currentState!.validate(), isTrue);
    expect(normalizedPhone(controller.value), '+12025550123');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
