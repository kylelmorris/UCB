#!/bin/bash

if [[ -f .lftprc ]] ; then
  echo "Found .lftprc file and reading previous settings!"
  echo ""
  PROTOCOL=$(grep protocol .lftprc | awk '{print $2}')
  URL=$(grep url .lftprc | awk '{print $2}')
  LOCALDIR=$(grep localdir .lftprc | awk '{print $2}')
  REMOTEDIR=$(grep remotedir .lftprc | awk '{print $2}')
  USER=$(grep username .lftprc | awk '{print $2}')
  PASS=$(grep password .lftprc | awk '{print $2}')
  REGEX=$(grep regex .lftprc | awk '{print $2}')
else
  echo "No previous settings found, continuing..."
fi

echo "Enter ftp protocol: "
read -i $PROTOCOL -e PROTOCOL
echo "Enter ftp server address: "
read -i $URL -e URL
echo  "Enter local dir for transfer: "
read -i $LOCALDIR -e LOCALDIR
echo "Enter remote directory to download from: "
read -i $REMOTEDIR -e REMOTEDIR
echo "Enter your username (Stored in .lftprc): "
read -i $USER -e USER
echo "Enter your password (Never stored): "
read -s -i $PASS -e PASS
echo ''
echo "Enter a regular expression to identify the files (\"*.mrc\"): "
read -i $REGEX -e REGEX

LOG="./lftp_script.log"

echo "exe:       "$0 > .lftprc
echo "protocol:  "$PROTOCOL >> .lftprc
echo "url:       "$URL >> .lftprc
echo "localdir:  "$LOCALDIR >> .lftprc
echo "remotedir: "$REMOTEDIR >> .lftprc
echo "username:  "$USER >> .lftprc
echo "password:  " >> .lftprc
echo "regex:     "$REGEX >> .lftprc

#
i="0"

while [ $i == 0 ] ; do

echo "Checking for new files"

lftp  $PROTOCOL://$URL <<- DOWNLOAD

    user $USER "$PASS"

    set ssl:verify-certificate no

    cd $REMOTEDIR

    mget -E $REGEX

DOWNLOAD

echo "Sleeping for 60 seconds"
sleep 60

done
