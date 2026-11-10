import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orientia/features/launch/presentation/launch_pages.dart';

// Image decoding uses real async work; drive it before advancing the fake clock.
Future<void> loadSplashLogo(WidgetTester tester) =>
    tester.runAsync(() => precacheImage(
        const AssetImage('assets/images/orientia_transparent.png'),
        tester.element(find.byType(LaunchSplash))));
