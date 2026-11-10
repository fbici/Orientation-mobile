import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

const resourceRoot = 'android/app/src/main/res';

void main() {
  test('native startup uses the original transparent Orientia logo', () {
    expect(
        File('$resourceRoot/drawable/orientia_splash.png').readAsBytesSync(),
        orderedEquals(
            File('assets/images/orientia_transparent.png').readAsBytesSync()));
  });
}
