#!/bin/bash

os=$(uname -s)
case "$os" in
	(Darwin)
		true
		;;
	(Linux)
		true
		;;
	(*)
		echo "This script is meant to be run only on Linux or macOS"
		exit 1
		;;
esac

echo -e "GET http://github.com HTTP/1.0\n\n" | nc github.com 80 > /dev/null 2>&1

if [ $? -eq 0 ]; then
    true
else
    echo "Please connect to the internet"
    exit 1
fi

set -e

cd $HOME/Downloads

latest=$(curl -sL https://github.com/t2linux/T2-Ubuntu/releases/latest/ | grep "<title>Release" | awk -F " " '{print $2}' )
latestkver=$(echo $latest | cut -d "v" -f 2 | cut -d "-" -f 1)

cat <<EOF

Choose the flavour of Ubuntu you wish to install:

1. Ubuntu
2. Kubuntu

Type your choice (1 or 2) from the above list and press return.
EOF

read flavinput

case "$flavinput" in
	(1)
		flavour=ubuntu
		;;
	(2)
		flavour=kubuntu
		;;
	(*)
		echo "Invalid input. Aborting!"
		exit 1
		;;
esac

cat <<EOF

Choose the version of Ubuntu you wish to install:

1. 22.04 LTS - Jammy Jellyfish
2. 23.04 - Lunar Lobstar

Type your choice (1 or 2) from the above list and press return.
EOF

read verinput

case "$verinput" in
	(1)
		iso="${flavour}-22.04-${latestkver}-t2-jammy"
		ver="22.04 LTS - Jammy Jellyfish"
		;;
	(2)
		iso="${flavour}-23.04-${latestkver}-t2-lunar"
		ver="23.04 - Lunar Lobstar"
		;;
	(*)
		echo "Invalid input. Aborting!"
		exit 1
		;;
esac

flavourcap=`echo ${flavour:0:1} | tr  '[a-z]' '[A-Z]'`${flavour:1}

echo -e "\nDownloading ${flavourcap} ${ver}"
echo -e "\nPart 1"
curl -#L https://github.com/t2linux/T2-Ubuntu/releases/download/${latest}/${iso}.z01 > ${iso}.z01
echo -e "\nPart 2"
curl -#L https://github.com/t2linux/T2-Ubuntu/releases/download/${latest}/${iso}.zip > ${iso}.zip
echo -e "\nCreating ISO"

isofinal=$RANDOM
zip -F ${iso}.zip --out ${isofinal}.zip > /dev/null
unzip ${isofinal}.zip > /dev/null
mv $HOME/Downloads/repo/${iso}.iso $HOME/Downloads

echo -e "\nVerifying sha256 checksums"

actual_iso_chksum=$(curl -sL https://github.com/t2linux/T2-Ubuntu/releases/download/${latest}/sha256-${flavour}-$(echo ${ver} | cut -d " " -f 1) | cut -d " " -f 1)

case "$os" in
	(Darwin)
		downloaded_iso_chksum=$(shasum -a 256 $HOME/Downloads/${iso}.iso | cut -d " " -f 1)
		;;
	(Linux)
		downloaded_iso_chksum=$(sha256sum $HOME/Downloads/${iso}.iso | cut -d " " -f 1)
		;;
	(*)
		echo "This script is meant to be run only on Linux or macOS"
		exit 1
		;;
esac

if [[ ${actual_iso_chksum} != ${downloaded_iso_chksum} ]]
then
echo -e "\nError: Failed to verify sha256 checksums of the ISO"
rm $HOME/Downloads/${iso}.iso
fi

rm -r $HOME/Downloads/repo
rm $HOME/Downloads/${isofinal}.zip
rm $HOME/Downloads/${iso}.z??

if [[ ${actual_iso_chksum} != ${downloaded_iso_chksum} ]]
then
exit 1
fi

echo -e "\nISO saved to Downloads"
