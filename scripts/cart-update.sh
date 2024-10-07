#!/bin/bash

set -e # stop sript when error occures

SCRIPT_FOLDER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

pushd "${SCRIPT_FOLDER}/.."
carthage update --use-xcframeworks --use-submodules --platform ios --configuration Debug
popd