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

#latest=$(curl -sL https://github.com/t2linux/T2-Ubuntu/releases/latest/ | grep "<title>Release" | awk -F " " '{print $2}' )
latest=GITHUBRELEASE
latestkver=$(echo $latest | cut -d "v" -f 2 | cut -d "-" -f 1)

cat <<EOF

Choose the flavour of Ubuntu you wish to install:

1. Ubuntu
2. Kubuntu
3. Ubuntu Unity

Type your choice (1, 2 etc.) from the above list and press return.
EOF

read flavinput

case "$flavinput" in
	(1)
		flavour=ubuntu
		;;
	(2)
		flavour=kubuntu
		;;
	(3)
		flavour=ubuntu-unity
		;;
	(*)
		echo "Invalid input. Aborting!"
		exit 1
		;;
esac

cat <<EOF

Choose the version of Ubuntu you wish to install:

1. 24.04 LTS - Noble Numbat
2. 25.04 - Plucky Puffin

Type your choice (1 or 2) from the above list and press return.
EOF

read verinput

case "$verinput" in
	(1)
		iso="${flavour}-24.04-${latestkver}-t2-noble"
		ver="24.04 LTS - Noble Numbat"
		;;
	(2)
		iso="${flavour}-25.04-${latestkver}-t2-plucky"
		ver="25.04 - Plucky Puffin"
		;;
	(*)
		echo "Invalid input. Aborting!"
		exit 1
		;;
esac

if [[ ${flavour} = ubuntu-unity ]]
then
flavourcap="Ubuntu Unity"
else
firstChar=$(echo "$flavour" | cut -c1 | tr '[a-z]' '[A-Z]')
restOfString=$(echo "$flavour" | cut -c2-)
flavourcap="${firstChar}${restOfString}"
fi

echo -e "\nDownloading Part 1 for ${flavourcap} ${ver}\n"
curl -#L https://github.com/t2linux/T2-Ubuntu/releases/download/${latest}/${iso}.iso.00 > ${iso}.iso

echo -e "\nDownloading Part 2 for ${flavourcap} ${ver}\n"
curl -#L https://github.com/t2linux/T2-Ubuntu/releases/download/${latest}/${iso}.iso.01 >> ${iso}.iso

echo -e "\nDownloading Part 3 for ${flavourcap} ${ver}\n"
curl -#L https://github.com/t2linux/T2-Ubuntu/releases/download/${latest}/${iso}.iso.02 >> ${iso}.iso

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
exit 1
fi

echo -e "\nISO saved to Downloads"
