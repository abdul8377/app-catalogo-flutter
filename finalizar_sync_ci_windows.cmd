@echo off
setlocal
cd /d "%~dp0"

set "DART=D:\flutter\bin\dart.bat"
set "FLUTTER=D:\flutter\bin\flutter.bat"

if not exist "%DART%" (
  echo ERROR: %DART% was not found.
  exit /b 1
)

if not exist "%FLUTTER%" (
  echo ERROR: %FLUTTER% was not found.
  exit /b 1
)

echo.
echo == Apply Dart format ==
call "%DART%" format lib test
if errorlevel 1 exit /b %errorlevel%

echo.
echo == Verify GitHub CI format gate ==
call "%DART%" format --output=none --set-exit-if-changed lib test
if errorlevel 1 exit /b %errorlevel%

echo.
echo == Verify git diff ==
git diff --check
if errorlevel 1 exit /b %errorlevel%

echo.
echo == Pending files ==
git status --short
if errorlevel 1 exit /b %errorlevel%

if /I not "%~1"=="verify" goto success

echo.
echo == Flutter pub get ==
call "%FLUTTER%" pub get
if errorlevel 1 exit /b %errorlevel%

echo.
echo == Dart analyze ==
call "%DART%" analyze --no-fatal-warnings
if errorlevel 1 exit /b %errorlevel%

echo.
echo == Flutter CI tests ==
call "%FLUTTER%" test --no-pub --exclude-tags baseline-known-failure
if errorlevel 1 exit /b %errorlevel%

echo.
echo == Build debug APK ==
call "%FLUTTER%" build apk --debug --no-pub
if errorlevel 1 exit /b %errorlevel%

:success
echo.
echo SUCCESS
echo.
echo Publish with:
echo   git add lib
echo   git commit -m "fix(sync): reconcile remote master identities"
echo   git push origin main
echo.
echo Full verification:
echo   finalizar_sync_ci_windows.cmd verify
exit /b 0
