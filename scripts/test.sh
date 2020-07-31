#!/bin/bash

set -e # stop sript when error occures
set -u # stop when undefined variable is used
#set -x # print all execution (good for debugging)

SCRIPT_FOLDER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

DESTINATION="platform=iOS Simulator,OS=13.5,name=iPhone SE (2nd generation)"
SERVER=""
APPKEY=""
APPSECRET=""
MASTERSPK=""
APPID=""

# Parse parameters of this script
while [[ $# -gt 0 ]]
do
	case "$1" in
		-destination)
			DESTINATION="$2"
			shift
			shift
			;;
		-server)
			SERVER="$2"
			shift
			shift
			;;
		-appkey)
			APPKEY="$2"
			shift
			shift
			;;
		-appsecret)
			APPSECRET="$2"
			shift
			shift
			;;
		-masterspk)
			MASTERSPK="$2"
			shift
			shift
			;;
		-appid)
			APPID="$2"
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

rm -rf "build"

xcrun xcodebuild \
	-derivedDataPath "build" \
    -project "WultraMobileTokenSDK.xcodeproj" \
    -scheme "WultraMobileTokenSDKTests" \
    -destination "${DESTINATION}" \
    -parallel-testing-enabled NO \
    -configuration "Debug" \
    build-for-testing | xcpretty

xctestrunfile=$(find build/Build/Products -name '*.xctestrun')

eval "/usr/libexec/PlistBuddy -c 'Add :WultraMobileTokenSDKTests:EnvironmentVariables:SERVER_IP string ${SERVER}' ${xctestrunfile}"
eval "/usr/libexec/PlistBuddy -c 'Add :WultraMobileTokenSDKTests:EnvironmentVariables:APP_KEY string ${APPKEY}' ${xctestrunfile}"
eval "/usr/libexec/PlistBuddy -c 'Add :WultraMobileTokenSDKTests:EnvironmentVariables:APP_SECRET string ${APPSECRET}' ${xctestrunfile}"
eval "/usr/libexec/PlistBuddy -c 'Add :WultraMobileTokenSDKTests:EnvironmentVariables:MASTER_SERVER_PUBLIC_KEY string ${MASTERSPK}' ${xctestrunfile}"
eval "/usr/libexec/PlistBuddy -c 'Add :WultraMobileTokenSDKTests:EnvironmentVariables:APP_ID string ${APPID}' ${xctestrunfile}"

xcrun xcodebuild \
	-configuration "Debug" \
    -destination "${DESTINATION}" \
    -xctestrun "${xctestrunfile}" \
    test-without-building | xcpretty

popd