import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../profile/presentation/academic_profile_page.dart';

class OnboardingPage extends StatelessWidget {
  final ApiClient apiClient;
  final VoidCallback onComplete;
  final VoidCallback? onSkip;
  const OnboardingPage(
      {super.key,
      required this.apiClient,
      required this.onComplete,
      this.onSkip});
  @override
  Widget build(BuildContext context) =>
      AcademicProfilePage(apiClient: apiClient);
}
