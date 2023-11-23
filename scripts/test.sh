#!/bin/bash

set -e # stop sript when error occures
set -u # stop when undefined variable is used
#set -x # print all execution (good for debugging)

SCRIPT_FOLDER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

IOS_VERSION=$(xcrun simctl list | grep "\-\- iOS" | tr -d - | tr -d " " | tr -d "iOS")
DESTINATION="platform=iOS Simulator,OS=${IOS_VERSION},name=iPhone 15"

CL_URL=""
CL_LGN=""
CL_PWD=""
CL_AID=""
ER_URL=""
OP_URL=""
IN_URL=""
SDKCONFIG=""

# Parse parameters of this script
while [[ $# -gt 0 ]]
do
	case "$1" in
		-destination)
			DESTINATION="$2"
			shift
			shift
			;;
		-cl)
			CL_URL="$2"
			shift
			shift
			;;
		-clu)
			CL_LGN="$2"
			shift
			shift
			;;
		-clp)
			CL_PWD="$2"
			shift
			shift
			;;
		-cla)
			CL_AID="$2"
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
        -in)
            IN_URL="$2"
            shift
            shift
            ;;
		-sdkconfig)
			SDKCONFIG="$2"
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
    \"cloudServerUrl\"        : \"${CL_URL}\",
    \"cloudServerLogin\"      : \"${CL_LGN}\",
    \"cloudServerPassword\"   : \"${CL_PWD}\",
    \"cloudApplicationId\"    : \"${CL_AID}\",
    \"enrollmentServerUrl\"   : \"${ER_URL}\",
    \"operationsServerUrl\"   : \"${OP_URL}\",
    \"inboxServerUrl\"        : \"${IN_URL}\",
    \"sdkConfig\"             : \"${SDKCONFIG}\"
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