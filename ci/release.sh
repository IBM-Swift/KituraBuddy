#!/bin/bash
##
# Copyright IBM Corporation 2016
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##

git remote rm origin
git remote add origin https://SwiftDevOps:${GH_TOKEN}@github.com/IBM-Swift/KituraKit
git fetch
git checkout tempMaster

cd ci

create_new_tag() {
  echo "Tagging version: v$1"
  git tag -a -m "Tagging version $1" "v$1"
  git push origin --tags
}

increment_patch () {
  VERSION_LIST_1=(`echo $1 | tr '.' ' '`)

  CV_MAJOR=${VERSION_LIST_1[0]}
  CV_MINOR=${VERSION_LIST_1[1]}
  CV_PATCH=${VERSION_LIST_1[2]}

  UPDATED_PATCH=$(($CV_PATCH + 1))
  NEW_VERSION="$CV_MAJOR.$CV_MINOR.$UPDATED_PATCH"
  echo $NEW_VERSION
}

# If git's current version >= the file's version. Increment the patch.
should_increment_patch() {
  VERSION_LIST_1=(`echo $1 | tr '.' ' '`)
  VERSION_LIST_2=(`echo $2| tr '.' ' '`)

  CV_MAJOR=${VERSION_LIST_1[0]}
  CV_MINOR=${VERSION_LIST_1[1]}
  CV_PATCH=${VERSION_LIST_1[2]}

  V_MAJOR=${VERSION_LIST_2[0]}
  V_MINOR=${VERSION_LIST_2[1]}
  V_PATCH=${VERSION_LIST_2[2]}

  if  [[ $1 == $2 ]] || \
      [[ $CV_MAJOR > $V_MAJOR ]] || \
      ([[ $CV_MAJOR == $V_MAJOR ]] && [[ $CV_MINOR > $V_MINOR ]]) || \
      ([[ $CV_MAJOR == $V_MAJOR ]] && [[ $CV_MINOR == $V_MINOR ]] && [[ $CV_PATCH > $V_PATCH ]]); then
    echo 1
  else
    echo 0
  fi

}

if [ -f VERSION ]; then
    CURRENT_VERSION_STRING="$( git describe --abbrev=0 --tags )"
    NORMALIZED_CURRENT_VERSION_STRING="$( echo $CURRENT_VERSION_STRING | sed "s/[a-zA-Z]*\([0-9\.]*\)[a-z]*$/\1/" )"
    BASE_VERSION_STRING=`cat VERSION`

    SHOULD_INCREMENT_PATCH=$(should_increment_patch $NORMALIZED_CURRENT_VERSION_STRING $BASE_VERSION_STRING)

    # If git's current tag is greater than the file's version. Increment the patch by default.
    if [[ $SHOULD_INCREMENT_PATCH == 1 ]]; then
      echo "Auto-incrementing Patch"
      create_new_tag $(increment_patch $NORMALIZED_CURRENT_VERSION_STRING)

    # If the provided file's version is greater than we should use the version file
    else
      echo "Using File Version"
      create_new_tag $BASE_VERSION_STRING
    fi
fi
