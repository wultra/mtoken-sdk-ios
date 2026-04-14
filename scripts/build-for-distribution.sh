#!/bin/bash

set -e # stop script when error occures
set -u # stop when undefined variable is used
#set -x # print all execution (good for debugging)

###############################################################################
# WultraMobileTokenSDK build for Apple platforms
#
# The purpose of this script is build and prepare WultraMobileTokenSDK.xcframework for the library distribution.
# 
# The result of the build process is:
#    WultraMobileTokenSDK.xcframework"
#      multi-architecture, multi-platform dynamic framework (also called as "fat")
#
# ----------------------------------------------------------------------------

###############################################################################
# Include common functions...
# -----------------------------------------------------------------------------
TOP=$(dirname $0)
SRC_ROOT="`( cd \"$TOP/..\" && pwd )`"


# Variables loaded from command line
OUT_DIR=''

# -----------------------------------------------------------------------------
# USAGE prints help and exits the script with error code from provided parameter
# Parameters:
#   $1   - error code to be used as return code from the script
# -----------------------------------------------------------------------------
function USAGE
{
    echo ""
    echo "Usage:  $CMD  [options]"
    echo ""
    echo "  Build WultraMobileTokenSDK.xcframework"
    echo ""
    echo "options are:"
    echo ""
    echo "  --out-dir path    changes directory where final framework"
    echo "                    will be stored"
    echo ""
    echo "  -h | --help       prints this help information"
    echo ""
    exit $1
}

# -----------------------------------------------------------------------------
# Build core library for all plaforms and create xcframework
# -----------------------------------------------------------------------------
function BUILD_LIB
{
    local xcver=$(GET_XCODE_VERSION --full)
    
    echo ""
    echo "Building WultraMobileTokenSDK with Xcode ${xcver}..."
    echo ""

    local ios_archive="${OUT_DIR}/ios.xcarchive"
    local sim_archive="${OUT_DIR}/ios_sim.xcarchive"
    local xcframework_path="${OUT_DIR}/WultraMobileTokenSDK.xcframework"
    local xcframework_zip="${OUT_DIR}/WultraMobileTokenSDK.xcframework.zip"
    local dsym_root="${OUT_DIR}/WultraMobileTokenSDK.dSYMs"
    local dsym_zip="${OUT_DIR}/WultraMobileTokenSDK.dSYMs.zip"

    rm -rf "${OUT_DIR}" # delete old builds
    mkdir -p "${OUT_DIR}"

    pushd "${SRC_ROOT}"

    ##
    ## BUILDING THE SDK
    ##

    # build for ios device
    xcodebuild archive \
        -project WultraMobileTokenSDK.xcodeproj \
        -scheme WultraMobileTokenSDK \
        -archivePath "${ios_archive}" \
        -configuration "Release" \
        -destination "generic/platform=iOS" \
        SKIP_INSTALL=NO \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_ALLOWED=NO \
        SWIFT_SERIALIZE_DEBUGGING_OPTIONS=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        DEBUG_INFORMATION_FORMAT=dwarf-with-dsym

    # build for ios simulator
    xcodebuild archive \
        -project WultraMobileTokenSDK.xcodeproj \
        -scheme WultraMobileTokenSDK \
        -archivePath "${sim_archive}" \
        -configuration "Release" \
        -destination "generic/platform=iOS Simulator" \
        SKIP_INSTALL=NO \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_ALLOWED=NO \
        SWIFT_SERIALIZE_DEBUGGING_OPTIONS=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        DEBUG_INFORMATION_FORMAT=dwarf-with-dsym

    # create xcframwork
    xcodebuild -create-xcframework \
        -framework "${ios_archive}/Products/Library/Frameworks/WultraMobileTokenSDK.framework" \
        -framework "${sim_archive}/Products/Library/Frameworks/WultraMobileTokenSDK.framework" \
        -output "${xcframework_path}"

    # copy dSYMs to separate folder
    mkdir -p "${dsym_root}/ios" "${dsym_root}/simulator"
    cp -R "${ios_archive}/dSYMs/WultraMobileTokenSDK.framework.dSYM" "${dsym_root}/ios/"
    cp -R "${sim_archive}/dSYMs/WultraMobileTokenSDK.framework.dSYM" "${dsym_root}/simulator/"

    # create zip files (of xcframework and dSYMs) for distribution
    ditto -c -k --sequesterRsrc --keepParent "${xcframework_path}" "${xcframework_zip}"
    ditto -c -k --sequesterRsrc --keepParent "${dsym_root}" "${dsym_zip}"
    
    popd
}

# -----------------------------------------------------------------------------
# Prints Xcode version into stdout or -1 in case of error.
# Parameters:
#   $1   - optional switch, can be:
#          '--full'  - prints a full version of Xcode (e.g. 11.7.1)
#          '--split' - prints a full, space separated version of Xcode (e.g. 11 7 1)
#          '--major' - prints only a major version (e.g. 11)
#          otherwise prints first line from `xcodebuild -version` result
# -----------------------------------------------------------------------------
function GET_XCODE_VERSION
{
    local xcodever=(`xcodebuild -version | grep ^Xcode`)
    local ver=${xcodever[1]}
    if [ -z "$ver" ]; then
        echo -1
        return
    fi
    local ver_array=( ${ver//./ } )
    case $1 in
        --full) echo $ver ;;
        --split) echo ${ver_array[@]} ;;
        --major) echo ${ver_array[0]} ;;
        *) echo ${xcodever[*]} ;;
    esac
}

###############################################################################
# Script's main execution starts here...
# -----------------------------------------------------------------------------

while [[ $# -gt 0 ]]
do
    opt="$1"
    case "$opt" in
        --out-dir)
            OUT_DIR="$2"
            shift
            ;;
        -h | --help)
            USAGE 0
            ;;
        *)
            USAGE 1
            ;;
    esac
    shift
done

# Defaulting target & temporary folders
if [ -z "$OUT_DIR" ]; then
    OUT_DIR="${TOP}/Lib"
fi

BUILD_LIB
