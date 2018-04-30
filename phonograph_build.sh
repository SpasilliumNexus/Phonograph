#!/bin/bash

set -e

# Let us give this script some colors
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"

# Configure variables
BUILD_TOOLS=$HOME/Android/android-sdk/build-tools/27.0.3
OUTPUT_DIR=$HOME/Development/phonograph/app/build/outputs/apk/release
SIGNING_KEY=$HOME/Android/signing-keys/app_signing_key.jks
ANDROID_SDK=$HOME/Android/android-sdk

reset

function clean_source {
  reset
  echo ""
  echo -e $COL_BLUE"Cleaning out the previous application build..."$COL_RESET
  export ANDROID_HOME=$ANDROID_SDK
  ./gradlew clean
  git clean -xfd
}

function confirm_build {
  reset
  echo ""
  echo -e $COL_YELLOW"Building..."$COL_RESET
  export ANDROID_HOME=$ANDROID_SDK
  ./gradlew assembleRelease
}

function confirm_zipalign {
  echo ""
  echo -e $COL_YELLOW"Zipaligning..."$COL_RESET
  $BUILD_TOOLS/zipalign -v -p 4 $OUTPUT_DIR/app-release-unsigned.apk $OUTPUT_DIR/app-release-unsigned-zipaligned.apk
  rm $OUTPUT_DIR/app-release-unsigned.apk
}

function confirm_sign {
  echo ""
  echo -e $COL_YELLOW"Signing..."$COL_RESET
  if [ -f "$OUTPUT_DIR/app-release-unsigned-zipaligned.apk" ]; then
     PACKAGENAME=`aapt d badging "$OUTPUT_DIR/app-release-unsigned-zipaligned.apk" | grep "package: name" | cut -d\' -f2`
     VERSIONCODE=`aapt d badging "$OUTPUT_DIR/app-release-unsigned-zipaligned.apk" | grep "versionCode" | cut -d\' -f4`
     $BUILD_TOOLS/apksigner sign --ks $SIGNING_KEY --out $OUTPUT_DIR/app-release-signed-zipaligned.apk $OUTPUT_DIR/app-release-unsigned-zipaligned.apk
     rm $OUTPUT_DIR/app-release-unsigned-zipaligned.apk
  else
     PACKAGENAME=`aapt d badging "$OUTPUT_DIR/app-release-unsigned.apk" | grep "package: name" | cut -d\' -f2`
     VERSIONCODE=`aapt d badging "$OUTPUT_DIR/app-release-unsigned.apk" | grep "versionCode" | cut -d\' -f4`
     $BUILD_TOOLS/apksigner sign --ks $SIGNING_KEY --out $OUTPUT_DIR/app-release-signed.apk $OUTPUT_DIR/app-release-unsigned.apk
     rm $OUTPUT_DIR/app-release-unsigned.apk
  fi
}

function finish_build {
  for file in $OUTPUT_DIR/app-release-* ; do mv $file ${file//app-release/$PACKAGENAME-$VERSIONCODE} ; done
  echo ""
  echo -e $COL_GREEN"Build of Phonograph completed in $OUTPUT_DIR"$COL_RESET
  exit 0
}

function quit_script {
  echo "Goodbye."
  exit 0
}


# Confirm cleaning before building
if [ -d .gradle ] || [ -d build ]; then
  while read -p "Do you want to clean out the source before building? (yes/no) " dchoice
    do
      case "$dchoice" in
        y|Y|yes|Yes )
        clean_source
        break
        ;;
        n|N|no|No )
        break
        ;;
        * )
        echo -e $COL_RED"Invalid input. Please choose again."$COL_RESET
        sleep 2
        ;;
    esac
  done
fi


# Confirm compiling
while read -p "Do you want to begin compiling the application (yes), start over (no), or quit (quit)? " dchoice
  do
    case "$dchoice" in
      y|Y|yes|Yes )
      confirm_build
      break
      ;;
      n|N|no|No|NO )
      echo -e $COL_RED"Starting over..."$COL_RESET
      sleep 2
      exec bash "$0"
      ;;
      q|Q|quit|Quit )
      quit_script
      ;;
      * )
      echo -e $COL_RED"Invalid input. Please choose again."$COL_RESET
      sleep 2
      ;;
  esac
done


# Confirm zipaligning
while read -p "Do you want to zipalign the application? (yes/no) " dchoice
  do
    case "$dchoice" in
      y|Y|yes|Yes )
      confirm_zipalign
      break
      ;;
      n|N|no|No|NO )
      break
      ;;
      * )
        echo -e $COL_RED"Invalid input. Please choose again."$COL_RESET
      sleep 2
      ;;
  esac
done


# Confirm signing
while read -p "Do you want to sign the application? (yes/no) " dchoice
  do
    case "$dchoice" in
      y|Y|yes|Yes )
      confirm_sign
      finish_build
      ;;
      n|N|no|No|NO )
      finish_build
      break
      ;;
      * )
      echo -e $COL_RED"Invalid input. Please choose again."$COL_RESET
      sleep 2
      ;;
  esac
done
