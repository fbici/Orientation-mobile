@echo off
REM =============================================
REM  Script de configuration Orientia
REM  Exécuter APRÈS "flutter create ."
REM =============================================

echo.
echo ========================================
echo   Configuration de l'app : ORIENTIA
echo ========================================
echo.

REM Android - AndroidManifest.xml
set MANIFEST=android\app\src\main\AndroidManifest.xml
if exist %MANIFEST% (
    powershell -Command "(Get-Content %MANIFEST%) -replace 'android:label=\"[^\"]*\"', 'android:label=\"Orientia\"' | Set-Content %MANIFEST%"
    echo [OK] Android manifest mis a jour
) else (
    echo [!!] AndroidManifest.xml non trouve
)

REM Android - strings.xml
set STRINGS=android\app\src\main\res\values\strings.xml
if exist %STRINGS% (
    powershell -Command "(Get-Content %STRINGS%) -replace '<string name=\"app_name\">[^<]*</string>', '<string name=\"app_name\">Orientia</string>' | Set-Content %STRINGS%"
    echo [OK] Android strings.xml mis a jour
) else (
    echo [!!] strings.xml non trouve
)

REM iOS
set PLIST=ios\Runner\Info.plist
if exist %PLIST% (
    powershell -Command "(Get-Content %PLIST%) -replace 'CFBundleDisplayName.*?(\r?\n).*?<string>[^<]*</string>', 'CFBundleDisplayName\$1\t<string>Orientia</string>' | Set-Content %PLIST%"
    echo [OK] iOS Info.plist mis a jour
)

REM Générer les icônes d'app
echo.
echo Generation des icones d'app...
call flutter pub run flutter_launcher_icons
echo.
echo ========================================
echo   Configuration terminee !
echo   Lancez : flutter run
echo ========================================
