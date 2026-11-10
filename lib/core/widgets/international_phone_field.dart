import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:phone_form_field/phone_form_field.dart';

export 'package:phone_form_field/phone_form_field.dart'
    show PhoneController, PhoneNumber, IsoCode;

String? normalizedPhone(PhoneNumber number) =>
    number.nsn.trim().isEmpty ? null : number.international;

class InternationalPhoneField extends StatelessWidget {
  final PhoneController controller;
  final bool enabled;
  const InternationalPhoneField(
      {super.key, required this.controller, this.enabled = true});
  @override
  Widget build(BuildContext context) => Localizations.override(
      context: context,
      locale: const Locale('fr'),
      delegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        ...PhoneFieldLocalization.delegates,
      ],
      child: Builder(
          builder: (context) => PhoneFormField(
                controller: controller,
                enabled: enabled,
                key: const ValueKey('international-phone'),
                countrySelectorNavigator: const CountrySelectorNavigator.page(
                  favorites: [IsoCode.BJ],
                  sortCountries: true,
                ),
                isCountrySelectionEnabled: enabled,
                isCountryButtonPersistent: true,
                countryButtonStyle: const CountryButtonStyle(
                    showFlag: true,
                    showDialCode: true,
                    showIsoCode: false,
                    flagSize: 20),
                validator: PhoneValidator.valid(context,
                    errorText: 'Numéro invalide pour le pays sélectionné.'),
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                decoration:
                    const InputDecoration(hintText: 'Téléphone (facultatif)'),
              )));
}
