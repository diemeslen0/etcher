#!/bin/bash

###
# Copyright 2016 resin.io
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###

# See http://www.davidpashley.com/articles/writing-robust-shell-scripts/
set -u
set -e
set -x

OS=`uname`
if [[ "$OS" != "Darwin" ]]; then
  echo "This script is only meant to be run in OS X" 1>&2
  exit 1
fi

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <command>" 1>&2
  exit 1
fi

COMMAND=$1
if [ "$COMMAND" != "install" ] && [ "$COMMAND" != "package" ] && [ "$COMMAND" != "all" ]; then
  echo "Unknown command: $COMMAND" 1>&2
  exit 1
fi

SIGN_IDENTITY_OSX="Developer ID Application: Rulemotion Ltd (66H43P8FRG)"
ELECTRON_VERSION=`node -e "console.log(require('./package.json').devDependencies['electron-prebuilt'])"`
APPLICATION_NAME=`node -e "console.log(require('./package.json').displayName)"`
APPLICATION_COPYRIGHT=`node -e "console.log(require('./package.json').copyright)"`
APPLICATION_VERSION=`node -e "console.log(require('./package.json').version)"`

if [ "$COMMAND" == "install" ] || [ "$COMMAND" == "all" ]; then
  ./scripts/darwin/dependencies.sh -r x64 -e $ELECTRON_VERSION
fi

if [ "$COMMAND" == "package" ] || [ "$COMMAND" == "all" ]; then
  ./scripts/darwin/package.sh \
    -n $APPLICATION_NAME \
    -r x64 \
    -v $APPLICATION_VERSION \
    -b io.resin.etcher \
    -c "$APPLICATION_COPYRIGHT" \
    -t public.app-category.developer-tools \
    -i assets/icon.icns \
    -e $ELECTRON_VERSION \
    -o etcher-release/$APPLICATION_NAME-darwin-x64

  ./scripts/darwin/installer-dmg.sh \
    -n $APPLICATION_NAME \
    -v $APPLICATION_VERSION \
    -p etcher-release/$APPLICATION_NAME-darwin-x64 \
    -d "$SIGN_IDENTITY_OSX" \
    -i assets/icon.icns \
    -b assets/osx/installer.png \
    -o etcher-release/installers/$APPLICATION_NAME-$APPLICATION_VERSION-darwin-x64.dmg

  ./scripts/darwin/sign.sh \
    -a etcher-release/$APPLICATION_NAME-darwin-x64/$APPLICATION_NAME.app \
    -i "$SIGN_IDENTITY_OSX"

  ./scripts/darwin/installer-zip.sh \
    -a etcher-release/$APPLICATION_NAME-darwin-x64/$APPLICATION_NAME.app \
    -o etcher-release/installers/$APPLICATION_NAME-$APPLICATION_VERSION-darwin-x64.zip
fi
