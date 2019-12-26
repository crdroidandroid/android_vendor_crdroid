#!/bin/bash
#
# Copyright (C) 2019-2022 crDroid Android Project
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

#$1=TARGET_DEVICE, $2=PRODUCT_OUT, $3=FILE_NAME
existingOTAjson=./vendor/crDroidOTA/$1.json
output=$2/$1.json

#cleanup old file
if [ -f $output ]; then
	rm $output
fi

if [ -f $existingOTAjson ]; then
	#get data from already existing device json
	#there might be a better way to parse json yet here we try without adding more dependencies like jq
	maintainer=`grep -n "\"maintainer\"" $existingOTAjson | cut -d ":" -f 3 | sed 's/"//g' | sed 's/,//g' | xargs`
	oem=`grep -n "\"oem\"" $existingOTAjson | cut -d ":" -f 3 | sed 's/"//g' | sed 's/,//g' | xargs`
	device=`grep -n "\"device\"" $existingOTAjson | cut -d ":" -f 3 | sed 's/"//g' | sed 's/,//g' | xargs`
	filename=$3
	version=`echo "$3" | cut -d'-' -f5`
	v_max=`echo "$version" | cut -d'.' -f1 | cut -d'v' -f2`
	v_min=`echo "$version" | cut -d'.' -f2`
	version=`echo $v_max.$v_min`
	download="https://sourceforge.net/projects/crdroid/files/'$device'/'$v_max'.x/'$4'/download"
	buildprop=$2/system/build.prop
	linenr=`grep -n "ro.system.build.date.utc" $buildprop | cut -d':' -f1`
	timestamp=`sed -n $linenr'p' < $buildprop | cut -d'=' -f2`
	md5=`md5sum "$2/$3" | cut -d' ' -f1`
	sha256=`sha256sum "$2/$3" | cut -d' ' -f1`
	size=`stat -c "%s" "$2/$3"`
	buildtype=`grep -n "\"buildtype\"" $existingOTAjson | cut -d ":" -f 3 | sed 's/"//g' | sed 's/,//g' | xargs`
	forum=`grep -n "\"forum\"" $existingOTAjson | cut -d ":" -f 4 | sed 's/"//g' | sed 's/,//g' | xargs`
	if [ ! -z "$forum" ]; then
		forum="https:"$forum
	fi
	gapps=`grep -n "\"gapps\"" $existingOTAjson | cut -d ":" -f 4 | sed 's/"//g' | sed 's/,//g' | xargs`
	if [ ! -z "$gapps" ]; then
		gapps="https:"$gapps
	fi
	firmware=`grep -n "\"firmware\"" $existingOTAjson | cut -d ":" -f 4 | sed 's/"//g' | sed 's/,//g' | xargs`
	if [ ! -z "$firmware" ]; then
		firmware="https:"$firmware
	fi
	modem=`grep -n "\"modem\"" $existingOTAjson | cut -d ":" -f 4 | sed 's/"//g' | sed 's/,//g' | xargs`
	if [ ! -z "$modem" ]; then
		modem="https:"$modem
	fi
	bootloader=`grep -n "\"bootloader\"" $existingOTAjson | cut -d ":" -f 4 | sed 's/"//g' | sed 's/,//g' | xargs`
	if [ ! -z "$bootloader" ]; then
		bootloader="https:"$bootloader
	fi
	recovery=`grep -n "\"recovery\"" $existingOTAjson | cut -d ":" -f 4 | sed 's/"//g' | sed 's/,//g' | xargs`
	if [ ! -z "$recovery" ]; then
		recovery="https:"$recovery
	fi
	paypal=`grep -n "\"paypal\"" $existingOTAjson | cut -d ":" -f 4 | sed 's/"//g' | sed 's/,//g' | xargs`
	if [ ! -z "$paypal" ]; then
		paypal="https:"$paypal
	fi
	telegram=`grep -n "\"telegram\"" $existingOTAjson | cut -d ":" -f 4 | sed 's/"//g' | sed 's/,//g' | xargs`
	if [ ! -z "$telegram" ]; then
		telegram="https:"$telegram
	fi
	dt=`grep -n "\"dt\"" $existingOTAjson | cut -d ":" -f 4 | sed 's/"//g' | sed 's/,//g' | xargs`
	if [ ! -z "$dt" ]; then
		dt="https:"$dt
	fi
	common=`grep -n "\"common-dt\"" $existingOTAjson | cut -d ":" -f 4 | sed 's/"//g' | sed 's/,//g' | xargs`
	if [ ! -z "$common" ]; then
		common="https:"$common
	fi
	kernel=`grep -n "\"kernel\"" $existingOTAjson | cut -d ":" -f 4 | sed 's/"//g' | sed 's/,//g' | xargs`
	if [ ! -z "$kernel" ]; then
		kernel="https:"$kernel
	fi

	echo '{
	"response": [
		{
			"maintainer": "'$maintainer'",
			"oem": "'$oem'",
			"device": "'$device'",
			"filename": "'$filename'",
			"download": "https://sourceforge.net/projects/crdroid/files/'$1'/'$v_max'.x/'$3'/download",
			"timestamp": '$timestamp',
			"md5": "'$md5'",
			"sha256": "'$sha256'",
			"size": '$size',
			"version": "'$version'",
			"buildtype": "'$buildtype'",
			"forum": "'$forum'",
			"gapps": "'$gapps'",
			"firmware": "'$firmware'",
			"modem": "'$modem'",
			"bootloader": "'$bootloader'",
			"recovery": "'$recovery'",
			"paypal": "'$paypal'",
			"telegram": "'$telegram'",
			"dt": "'$dt'",
			"common-dt": "'$common'",
			"kernel": "'$kernel'"
		}
	]
}' >> $output

        echo "JSON file data for OTA support:"
else
	#if not already supported, create dummy file with info in it on how to
	echo 'There is no official support for this device yet' >> $output;
	echo 'Consider adding official support by reading the documentation at https://github.com/crdroidandroid/android_vendor_crDroidOTA/blob/13.0/README.md' >> $output;
fi

cat $output
echo ""
