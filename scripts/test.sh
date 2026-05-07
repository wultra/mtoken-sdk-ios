#!/bin/bash

set -e # stop script when error occures
set -u # stop when undefined variable is used
#set -x # print all execution (good for debugging)

SCRIPT_FOLDER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
XCODE_PROJECT="WultraMobileTokenSDK.xcodeproj"
XCODE_SCHEME="WultraMobileTokenSDKTests"
BUILD_FOLDER="build"

# Function that resolved the best available simulator for the test run
function getSimulatorDestination {
  local scriptUrl="https://raw.githubusercontent.com/wultra/wultra-infrastructure/refs/heads/mobile/mobile/utils/ios-get-simulator/v1/get-ios-sim.js"
  curl -fsSL "${scriptUrl}" | node - -p "${SCRIPT_FOLDER}/.." "${XCODE_PROJECT}" "${XCODE_SCHEME}"
}

CL_URL=""
CL_LGN=""
CL_PWD=""
CL_AID=""
ER_URL=""
PU_URL=""
OP_URL=""
IN_URL=""
SDKCONFIG=""

# Parse parameters of this script
while [[ $# -gt 0 ]]
do
	case "$1" in
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
		-pu)
			PU_URL="$2"
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

# Resolve the newest available iOS Simulator destination through the shared Node helper.
echo "Resolving the best simulator for the ${XCODE_SCHEME}..."
DESTINATION=$(getSimulatorDestination)

echo "Simulator to use: ${DESTINATION}"

pushd "${SCRIPT_FOLDER}/.."

rm -rf "${BUILD_FOLDER}" # clear build folder

echo "Resolving Swift package dependencies"
xcrun xcodebuild \
    -project "${XCODE_PROJECT}" \
    -resolvePackageDependencies \
    -onlyUsePackageVersionsFromResolvedFile

echo """{
    \"cloudServerUrl\"        : \"${CL_URL}\",
    \"cloudServerLogin\"      : \"${CL_LGN}\",
    \"cloudServerPassword\"   : \"${CL_PWD}\",
    \"cloudApplicationId\"    : \"${CL_AID}\",
    \"enrollmentServerUrl\"   : \"${ER_URL}\",
    \"operationsServerUrl\"   : \"${OP_URL}\",
    \"pushServerUrl\"         : \"${PU_URL}\",
    \"inboxServerUrl\"        : \"${IN_URL}\",
    \"sdkConfig\"             : \"${SDKCONFIG}\"
}""" > "WultraMobileTokenSDKTests/Configs/config.json"

xcrun xcodebuild \
	-derivedDataPath "${BUILD_FOLDER}" \
    -project "${XCODE_PROJECT}" \
    -scheme "${XCODE_SCHEME}" \
    -destination "${DESTINATION}" \
    -parallel-testing-enabled NO \
    -configuration "Debug" \
    -onlyUsePackageVersionsFromResolvedFile \
    test

popd
