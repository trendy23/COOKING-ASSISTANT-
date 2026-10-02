$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot

try {
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed.' }

    flutter test
    if ($LASTEXITCODE -ne 0) { throw 'flutter test failed.' }

    flutter build apk --release
    if ($LASTEXITCODE -ne 0) { throw 'Release APK build failed.' }

    Write-Output "Offline Android APK: $PSScriptRoot\build\app\outputs\flutter-apk"
}
finally {
    Pop-Location
}
