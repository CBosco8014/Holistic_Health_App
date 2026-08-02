#!/usr/bin/env bash
#
# Build and upload a TestFlight build.
#
#   ./scripts/release.sh               # bump build number, archive, upload
#   ./scripts/release.sh --no-upload   # bump + archive only (upload by hand in Xcode)
#   ./scripts/release.sh --upload-only # upload the existing archive, no bump/rebuild
#   MARKETING_VERSION=0.2.0 ./scripts/release.sh   # also bump the user-facing version
#
# Upload needs an App Store Connect API key. Create one at
# App Store Connect > Users and Access > Integrations > App Store Connect API,
# save the .p8 to ~/.appstoreconnect/private_keys/, then export:
#
#   export ASC_KEY_ID=XXXXXXXXXX
#   export ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
#
# Without those, the script stops after archiving and tells you what to do next.

set -euo pipefail

cd "$(dirname "$0")/.."

SCHEME=HolisticHealth
PROJECT=HolisticHealth.xcodeproj
ARCHIVE_PATH="build/release/${SCHEME}.xcarchive"
UPLOAD=1
BUILD=1
case "${1:-}" in
  --no-upload)   UPLOAD=0 ;;
  --upload-only) BUILD=0 ;;
  "")            ;;
  *) echo "unknown option: $1" >&2; exit 2 ;;
esac

if [[ $BUILD -eq 0 && ! -d "$ARCHIVE_PATH" ]]; then
  echo "no archive at ${ARCHIVE_PATH} — run without --upload-only first" >&2
  exit 1
fi

if [[ $BUILD -eq 1 ]]; then
# --- bump the build number -------------------------------------------------
# Every upload to App Store Connect needs a CURRENT_PROJECT_VERSION higher than
# the last one, for the same MARKETING_VERSION. This is the #1 upload rejection.
CURRENT=$(grep -E '^\s+CURRENT_PROJECT_VERSION:' project.yml | sed -E 's/.*"([0-9]+)".*/\1/')
NEXT=$((CURRENT + 1))
sed -i '' -E "s/(CURRENT_PROJECT_VERSION: )\"${CURRENT}\"/\1\"${NEXT}\"/" project.yml
echo "==> build number ${CURRENT} -> ${NEXT}"

if [[ -n "${MARKETING_VERSION:-}" ]]; then
  sed -i '' -E "s/(MARKETING_VERSION: )\".*\"/\1\"${MARKETING_VERSION}\"/" project.yml
  echo "==> marketing version -> ${MARKETING_VERSION}"
fi

# --- regenerate + archive --------------------------------------------------
echo "==> xcodegen generate"
xcodegen generate --quiet

echo "==> archiving"
rm -rf "$ARCHIVE_PATH"
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  -allowProvisioningUpdates \
  -quiet

echo "==> archived to ${ARCHIVE_PATH}"

if [[ $UPLOAD -eq 0 ]]; then
  echo "==> skipping upload (--no-upload)"
  exit 0
fi

else
  echo "==> uploading existing archive at ${ARCHIVE_PATH} (no bump, no rebuild)"
fi

if [[ -z "${ASC_KEY_ID:-}" || -z "${ASC_ISSUER_ID:-}" ]]; then
  cat <<EOF

==> No ASC_KEY_ID / ASC_ISSUER_ID set, so not uploading.

    Upload this archive by hand instead:
      open ${ARCHIVE_PATH}
    then in Xcode Organizer: Distribute App > TestFlight & App Store > Upload.

    Or set up API-key uploads (see the header of this script) to make it one command.
EOF
  exit 0
fi

KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8"
if [[ ! -f "$KEY_PATH" ]]; then
  echo "ASC_KEY_ID is ${ASC_KEY_ID} but no key file at:" >&2
  echo "  ${KEY_PATH}" >&2
  echo "Move the downloaded .p8 there, or fix ASC_KEY_ID to match the filename." >&2
  exit 1
fi

echo "==> uploading to App Store Connect"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist scripts/ExportOptions.plist \
  -allowProvisioningUpdates \
  -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
  -authenticationKeyPath "$KEY_PATH"

UPLOADED=$(plutil -extract CFBundleVersion raw \
  "${ARCHIVE_PATH}/Products/Applications/${SCHEME}.app/Info.plist" 2>/dev/null || echo "?")
echo "==> uploaded build ${UPLOADED}. Processing takes ~5-15 min, then it appears in TestFlight."
echo "==> remember to commit the bumped build number:"
echo "    git commit -am 'Bump build to ${UPLOADED}'"
