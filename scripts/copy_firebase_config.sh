#!/bin/bash
# Copies the correct GoogleService-Info.plist into the app bundle based on
# the FIREBASE_CLIENT build setting.
#
# Setup:
#   1. Add this as a Run Script build phase in Xcode, AFTER "Copy Bundle Resources".
#   2. Add a User-Defined build setting: FIREBASE_CLIENT = TheLightUI
#   3. For each new client scheme, set FIREBASE_CLIENT to the matching subfolder name
#      under Firebase/ (e.g., FIREBASE_CLIENT = AcmeCorp).

CLIENT="${FIREBASE_CLIENT:-TheLightUI}"
SOURCE="${SRCROOT}/Firebase/${CLIENT}/GoogleService-Info.plist"
DEST="${BUILT_PRODUCTS_DIR}/${CONTENTS_FOLDER_PATH}/GoogleService-Info.plist"

if [ ! -f "${SOURCE}" ]; then
    echo "error: Firebase config not found at ${SOURCE}. Add Firebase/${CLIENT}/GoogleService-Info.plist or fix the FIREBASE_CLIENT build setting."
    exit 1
fi

cp "${SOURCE}" "${DEST}"
echo "note: Installed Firebase config for client '${CLIENT}' → ${DEST}"
