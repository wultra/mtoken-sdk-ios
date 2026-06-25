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

CONFIG_JSON=""

# Parse parameters of this script
while [[ $# -gt 0 ]]
do
  case "$1" in
    -config)
      CONFIG_JSON="$2"
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

# Resolve the newest available iOS Simulator destination through the shared Node helper.
echo "Resolving the best simulator for the ${XCODE_SCHEME}..."
DESTINATION=$(getSimulatorDestination)

echo "Simulator to use: ${DESTINATION}"

pushd "${SCRIPT_FOLDER}/.."

rm -rf "${BUILD_FOLDER}" # clear build folder

# Write integration test config if provided
if [ -n "${CONFIG_JSON}" ]; then
  echo "Writing integration test config..."
  echo "${CONFIG_JSON}" > "WultraMobileTokenSDKTests/Configs/config.json"
fi

echo "Starting the test"

xcrun xcodebuild \
  -derivedDataPath "${BUILD_FOLDER}" \
  -project "${XCODE_PROJECT}" \
  -scheme "${XCODE_SCHEME}" \
  -destination "${DESTINATION}" \
  -parallel-testing-enabled NO \
  -configuration "Debug" \
  test

popd