#!/bin/bash

set -e # stop sript when error occures
set -u # stop when undefined variable is used
#set -x # print all execution (good for debugging)

SCRIPT_FOLDER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

DESTINATION="platform=iOS Simulator,OS=13.4.1,name=iPhone 11"

# Parse parameters of this script
while [[ $# -gt 0 ]]
do
	case "$1" in
		-destination)
			DESTINATION="$2"
			shift
			shift
			;;
		*)
			echo "Unknown parameter ${1}"
			exit 1
			;;
	esac
done

pushd "${SCRIPT_FOLDER}"
sh cart-update.sh
popd

pushd "${SCRIPT_FOLDER}/.."

xcrun xcodebuild \
    -project "WultraMobileTokenSDK.xcodeproj" \
    -scheme "WultraMobileTokenSDKTests" \
    -configuration "Release" \
    -destination "${DESTINATION}" \
    test | xcpretty

popd