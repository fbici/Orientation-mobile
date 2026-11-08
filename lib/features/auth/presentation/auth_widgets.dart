import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_failure.dart';

class AuthShell extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const AuthShell({super.key, required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Scaffold(
      body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
          child: SafeArea(
              child: Center(
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Center(
                                            child: Image.asset(
                                                'assets/images/orientia.png',
                                                height: 64,
                                                width: 64,
                                                errorBuilder: (_, e, s) =>
                                                    const Icon(
                                                        Icons.school_outlined,
                                                        size: 48))),
                                        const SizedBox(height: 16),
                                        Text(title,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall),
                                        const SizedBox(height: 20),
                                        ...children,
                                      ])))))))));
}

class AuthError extends StatelessWidget {
  final Object error;
  const AuthError(this.error, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(ApiFailure.from(error).message,
          style: TextStyle(color: Theme.of(context).colorScheme.error)));
}

String? emailValidator(String? v) =>
    v != null && RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())
        ? null
        : 'Adresse email valide requise.';
