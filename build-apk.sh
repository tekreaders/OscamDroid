#!/usr/bin/env bash

#Path configuration
OSCAM_PATH=~/oscam-svn
OSCAMDROID_PATH=~/OscamDroid
OSCAMREPO_PATH=~/OscamRepo/OscamDroid
ANDROID_TOOLCHAIN=~/android-toolchain

echo "#### OscamDroid Auto-Builder 1.0 ####"

#Build Oscam binary and OscamDroid APK
function build {
  echo "Building revision $NEW_REV..."
  cd $OSCAM_PATH
  make clean
  make static OSCAM_BIN=Distribution/oscam_$NEW_REV EXTRA_FLAGS="-pie" LIB_RT= LIB_PTHREAD= CROSS=$ANDROID_TOOLCHAIN/bin/arm-linux-androideabi-
  cd Distribution
  cp oscam_$NEW_REV $OSCAMDROID_PATH/app/src/main/res/raw/oscam
  cd $OSCAMDROID_PATH/app
  APK_VER=`grep 'versionCode' build.gradle | awk '{print $2}'`
  cd $OSCAMDROID_PATH
  echo "Building APK version $APK_VER..."
  ./gradlew clean
  ./gradlew assembleRelease
  cp $OSCAMDROID_PATH/app/build/outputs/apk/app-release.apk $OSCAMREPO_PATH/releases/OscamDroid-b$APK_VER-svn$NEW_REV.apk
  cd $OSCAMREPO_PATH
  git pull
  echo "Deleting previous builds..."
  cd releases
  rm *
  cd ..
  echo "Building version.json for new release..."  
  echo "{\"apk\":\"$APK_VER\",\"revision\":\"$NEW_REV\",\"link\":\"https://raw.githubusercontent.com/tekreaders/OscamDroid/master/releases/OscamDroid-b$APK_VER-svn$NEW_REV.apk\"}" > version.json
  cat version.json
  echo "Pushing to repository..."  
  git add --all .
  git commit -m "New release OscamDroid-b$APK_VER-svn$NEW_REV"
  git push
}

#Update Oscam svn
function update_svn {
  cd $OSCAM_PATH
  CURRENT_REV=`svn info . |grep '^Revision:' | sed -e 's/^Revision: //'`
  echo "Local revision is :" $CURRENT_REV;
  echo "Updating SVN..."
  svn update --accept theirs-full > /dev/null
}

if [ "$1" == "-f" ]; then
 CURRENT_REV=0
 else
 update_svn
fi
cd $OSCAM_PATH
NEW_REV=`svn info . |grep '^Revision:' | sed -e 's/^Revision: //'`
echo "New revision is $NEW_REV"
if [ "$CURRENT_REV" == "$NEW_REV" ]; then
  if [ "$1" == "-f" ]; then
    echo "Forcing explicit build..."
    build
  else
    echo "Nothing new to build."
  fi
  else
  build
fi
echo "Process completed!"
sleep 2