#!/bin/bash

set -e

BUILD_TOOLS=$HOME/Android/android-sdk/build-tools/27.0.3
OUTPUT_DIR=$HOME/Development/phonograph/app/build/outputs/apk/release
SIGNING_KEY=$HOME/Android/signing-keys/app_signing_key.jks
ANDROID_SDK=$HOME/Android/android-sdk/

echo ""
echo "Checking if cleaning is needed before building..."
if [ -f $OUTPUT_DIR/app-release-unsigned.apk ] || [ -f $OUTPUT_DIR/app-release-signed.apk ] || [ -f $OUTPUT_DIR/com.* ]; then
   echo ""
   echo "Cleaning out the previous build..."
   export ANDROID_HOME=$ANDROID_SDK
   ./gradlew clean
   reset
fi

echo ""
echo "Building application..."
export ANDROID_HOME=$ANDROID_SDK
./gradlew assembleRelease

echo ""
echo "Signing application..."
PACKAGENAME=`aapt d badging "$OUTPUT_DIR/app-release-unsigned.apk" | grep "package: name" | cut -d\' -f2`
VERSIONCODE=`aapt d badging "$OUTPUT_DIR/app-release-unsigned.apk" | grep "versionCode" | cut -d\' -f4`
$BUILD_TOOLS/apksigner sign --ks $SIGNING_KEY --out $OUTPUT_DIR/app-release-signed.apk $OUTPUT_DIR/app-release-unsigned.apk

echo ""
echo "Zipaligning application..."
$BUILD_TOOLS/zipalign -v -p 4 $OUTPUT_DIR/app-release-signed.apk $OUTPUT_DIR/$PACKAGENAME-$VERSIONCODE.apk

echo ""
echo "Build of Phonograph ($PACKAGENAME-$VERSIONCODE.apk) completed in $OUTPUT_DIR"
