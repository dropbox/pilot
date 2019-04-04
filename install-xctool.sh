#!/bin/bash
xctool_root="External/xctool"
xctool_location="External/xctool/bin/xctool"
xctool_version="0.3.5"

# check for xctool existing
if [ -f $xctool_location ]; then
    if [ `$xctool_location -v` != $xctool_version ]; then
        echo "xctool version incorrect; removing old one."
        rm -rf $xctool_root
    else
        echo "xctool already installed!"
        exit 0
    fi
fi

echo "Downloading xctool"

tmpfile="/tmp/xctool-download.$$"
curl -L -o $tmpfile https://github.com/facebook/xctool/releases/download/0.3.5/xctool-v0.3.5.zip

echo "Extracting xctool"
mkdir $xctool_root
unzip $tmpfile -d $xctool_root
rm $tmpfile

echo "Done!"