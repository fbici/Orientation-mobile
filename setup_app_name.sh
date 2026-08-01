#!/bin/bash
# Script pour configurer le nom "Orientia" dans les plateformes Android/iOS
# Exécutez ce script après "flutter create ."

echo "Configuration du nom de l'app : Orientia"

# Android - AndroidManifest.xml
ANDROID_MANIFEST="android/app/src/main/AndroidManifest.xml"
if [ -f "$ANDROID_MANIFEST" ]; then
  sed -i 's/android:label="[^"]*"/android:label="Orientia"/' "$ANDROID_MANIFEST"
  echo "✅ Android: label mis à jour"
fi

# Android - strings.xml
STRINGS="android/app/src/main/res/values/strings.xml"
if [ -f "$STRINGS" ]; then
  sed -i 's/<string name="app_name">[^<]*<\/string>/<string name="app_name">Orientia<\/string>/' "$STRINGS"
  echo "✅ Android: strings.xml mis à jour"
fi

# iOS - Info.plist
INFO_PLIST="ios/Runner/Info.plist"
if [ -f "$INFO_PLIST" ]; then
  # Replace the app name
  sed -i '' 's/<key>CFBundleDisplayName<\/key>\n\t<string>[^<]*<\/string>/<key>CFBundleDisplayName<\/key>\n\t<string>Orientia<\/string>/' "$INFO_PLIST"
  echo "✅ iOS: DisplayName mis à jour"
fi

# pubspec.yaml - already done
echo "✅ pubspec.yaml: déjà configuré"

echo ""
echo "Maintenant exécutez :"
echo "  flutter pub run flutter_launcher_icons"
echo "  flutter run"
