#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
derived_data="${TMPDIR%/}/CodexPetsAppStoreValidation"

cd "$project_root"
xcodegen generate

plutil -lint Resources/Info.plist
plutil -lint Resources/CodexPets-AppStore.entitlements
plutil -lint Resources/PrivacyInfo.xcprivacy

xcodebuild \
  -quiet \
  -project CodexPets.xcodeproj \
  -scheme CodexPets \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath "$derived_data-tests" \
  CODE_SIGNING_ALLOWED=NO \
  test

xcodebuild \
  -quiet \
  -project CodexPets.xcodeproj \
  -scheme CodexPets \
  -configuration AppStore \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$derived_data-build" \
  CODE_SIGNING_ALLOWED=NO \
  build

app="$derived_data-build/Build/Products/AppStore/CodexPets.app"
test -d "$app"
test -f "$app/Contents/Resources/PrivacyInfo.xcprivacy"
test -f "$app/Contents/Resources/AppIcon.icns"

build_settings="$(xcodebuild \
  -project CodexPets.xcodeproj \
  -scheme CodexPets \
  -configuration AppStore \
  -showBuildSettings)"

grep -q 'ENABLE_APP_SANDBOX = YES' <<<"$build_settings"
grep -q 'CODE_SIGN_ENTITLEMENTS = Resources/CodexPets-AppStore.entitlements' <<<"$build_settings"
grep -q 'SWIFT_ACTIVE_COMPILATION_CONDITIONS = .*APP_STORE' <<<"$build_settings"

echo "Mac App Store static validation passed."
