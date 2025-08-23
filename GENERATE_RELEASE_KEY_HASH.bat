@echo off
echo 生成 Facebook Release Key Hash
echo ================================
echo.

cd android
keytool -exportcert -alias odt-release -keystore app/release-key.keystore | openssl sha1 -binary | openssl base64

echo.
echo ================================
echo 请将上面生成的 Hash 添加到 Facebook 开发者控制台
echo.
pause