#!/usr/bin/env bash
#
# Build and upload a TestFlight build.
#
#   ./scripts/release.sh              # bump build number, archive, upload
#   ./scripts/release.sh --no-upload  # bump + archive only (upload by hand in Xcode)
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
[[ "${1:-}" == "--no-upload" ]] && UPLOAD=0

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

echo "==> uploading to App Store Connect"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist scripts/ExportOptions.plist \
  -allowProvisioningUpdates \
  -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
  -authenticationKeyPath "$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8"

echo "==> uploaded. Processing takes ~5-15 min, then it appears in TestFlight."
echo "==> remember to commit the bumped build number:"
echo "    git commit -am 'Bump build to ${NEXT}'"
