#!/bin/bash
# Copyright (c) 2003-2013, CKSource - Frederico Knabben. All rights reserved.
# For licensing, see http://ckeditor.com/license

# Build CKEditor using the default settings (and build.js)

set -e

echo "CKEditor Presets Builder"
echo "========================"

case $1 in
	basic) name="Basic" ;;
	standard) name="Standard" ;;
	full) name="Full" ;;
	*)
		echo "Usage: $0 basic|standard|full [all]" >&2
		echo ""
		exit 1
		;;
esac

skip="-s"

if [ "$2" == "all" ]
then
	skip=""
fi

# User the ckeditor-dev commit hash as the revision.
cd ckeditor/
rev=`git rev-parse --verify --short HEAD`
cd ..


CKBUILDER_VERSION="1.6"
CKBUILDER_URL="http://download.cksource.com/CKBuilder/$CKBUILDER_VERSION/ckbuilder.jar"

PROGNAME=$(basename $0)
MSG_UPDATE_FAILED="Warning: The attempt to update ckbuilder.jar failed. The existing file will be used."
MSG_DOWNLOAD_FAILED="It was not possible to download ckbuilder.jar"

function error_exit
{
	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
	exit 1
}

function command_exists
{
	command -v "$1" > /dev/null 2>&1;
}

# Move to the script directory.
cd $(dirname $0)

# Download/update ckbuilder.jar
mkdir -p ckbuilder/$CKBUILDER_VERSION
cd ckbuilder/$CKBUILDER_VERSION
if [ -f ckbuilder.jar ]; then
	echo "Checking/Updating CKBuilder..."
	if command_exists curl ; then
	curl -O -R -z ckbuilder.jar $CKBUILDER_URL || echo "$MSG_UPDATE_FAILED"
	else
	wget -N $CKBUILDER_URL || echo "$MSG_UPDATE_FAILED"
	fi
else
	echo "Downloading CKBuilder..."
	if command_exists curl ; then
	curl -O -R $CKBUILDER_URL || error_exit "$MSG_DOWNLOAD_FAILED"
	else
	wget -N $CKBUILDER_URL || error_exit "$MSG_DOWNLOAD_FAILED"
	fi
fi
cd ../..

echo ""
echo "Copying extra plugins..."
cp -r plugins/* ckeditor/plugins/


echo ""
echo "Deleting build/$1..."
rm -rf build/$1


# Run the builder.
echo ""
echo "Building the '$1' preset..."

java -jar ckbuilder/$CKBUILDER_VERSION/ckbuilder.jar --build ckeditor build/$1 $skip --version="4.1.1 DEV ($name)" --revision $rev --build-config presets/$1-build-config.js --overwrite "$@"

rm build/$1/*.gz
rm build/$1/*.zip

cp presets/$1-ckeditor-config.js build/$1/ckeditor/config.js
cp presets/README.md build/$1/ckeditor/


echo "Removing added plugins..."
cd ckeditor
git clean -d -f -f
cd ..


echo ""
echo "Build created into the \"build\" directory."
echo ""
