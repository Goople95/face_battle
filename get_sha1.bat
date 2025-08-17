@echo off
echo Getting SHA-1 fingerprint for debug keystore...
echo.

keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

echo.
echo ===================================
echo Please copy the SHA1 value above
echo ===================================
pause