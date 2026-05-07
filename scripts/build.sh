#!/bin/bash

set -e # stop script when error occures
set -u # stop when undefined variable is used
#set -x # print all execution (good for debugging)

SCRIPT_FOLDER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

pushd "${SCRIPT_FOLDER}/.."

echo "Resolving Swift package dependencies"
xcrun xcodebuild \
    -project "WultraMobileTokenSDK.xcodeproj" \
    -resolvePackageDependencies \
    -onlyUsePackageVersionsFromResolvedFile

xcrun xcodebuild \
    -project "WultraMobileTokenSDK.xcodeproj" \
    -scheme "WultraMobileTokenSDK" \
    -configuration "Release" \
    -sdk "iphonesimulator" \
    -onlyUsePackageVersionsFromResolvedFile \
    build

popd
