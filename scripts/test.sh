#!/bin/bash

set -e # stop sript when error occures
set -u # stop when undefined variable is used
#set -x # print all execution (good for debugging)

SCRIPT_FOLDER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

DESTINATION="platform=iOS Simulator,OS=13.5,name=iPhone SE (2nd generation)"
PA_URL=""
ER_URL=""
OP_URL=""
NS_URL=""
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
		-pa)
			PA_URL="$2"
			shift
			shift
			;;
		-er)
			ER_URL="$2"
			shift
			shift
			;;
		-op)
			OP_URL="$2"
			shift
			shift
			;;
		-ns)
			NS_URL="$2"
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

rm -rf "build" # clear build folder

echo """{
    \"paServerUrl\"           : \"${PA_URL}\",
    \"nextStepServerUrl\"     : \"${NS_URL}\",
    \"enrollmentServerUrl\"   : \"${ER_URL}\",
    \"operationsServerUrl\"   : \"${OP_URL}\",
    \"appKey\"                : \"${APPKEY}\",
    \"appSecret\"             : \"${APPSECRET}\",
    \"masterServerPublicKey\" : \"${MASTERSPK}\",
    \"appId\"                 : \"${APPID}\"
}""" > "WultraMobileTokenSDKTests/Configs/config.json"

xcrun xcodebuild \
	-derivedDataPath "build" \
    -project "WultraMobileTokenSDK.xcodeproj" \
    -scheme "WultraMobileTokenSDKTests" \
    -destination "${DESTINATION}" \
    -parallel-testing-enabled NO \
    -configuration "Debug" \
    test

popd