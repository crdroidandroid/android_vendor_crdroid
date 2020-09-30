#!/bin/bash
#
# Copyright (C) 2017-2022 crDroid Android Project
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
#

Changelog=Changelog.txt

DEVICE=$1

if [ -f $Changelog ];
then
	rm -f $Changelog
fi

touch $Changelog

# define changelog_days using 'export changelog_days=10'
# this can be done before intiate build environment (. build/envsetup.sh)
if [ -z $changelog_days ];then
	changelog_days=10
else
	if (($changelog_days > 30 )); then
        echo "Changelog can not generated for more than 30 days. For how many days do you want to generate changelog again? (🕑 timeout 15 seconds - default to 10 days)"
        read -r -t 15 changelog_days || changelog_days=10
	fi
fi

REPO_LIST="$(cat .repo/project.list | sed '\?^vendor/crDroidOTA?d')"
for i in $(seq $changelog_days); do
    After_Date=`date --date="$i days ago" +%m-%d-%Y`
    k=$(expr $i - 1)
    Until_Date=`date --date="$k days ago" +%m-%d-%Y`

    # Line with after --- until was too long for a small ListView
    echo '====================' >> $Changelog
    echo  "     "$Until_Date    >> $Changelog
    echo '====================' >> $Changelog

    # Cycle through all available repos
    for repo_path in $REPO_LIST; do
        # Find commits between 2 dates
        GIT_LOG="$(git -C "$repo_path" log --oneline --after="$After_Date" --until="$Until_Date")"
        [ -n "$GIT_LOG" ] && {
            printf '\n   * '; echo "$repo_path"
            echo "$GIT_LOG"
        } >> $Changelog
    done
    echo >> $Changelog
done

sed -i 's/project/   */g' $Changelog

cp $Changelog $OUT_DIR/target/product/$DEVICE/system/etc/
mv $Changelog $OUT_DIR/target/product/$DEVICE/
