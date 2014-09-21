#!/bin/bash

# Build the executable file
cabal build


# Prepare for upload
cp dist/build/yesodapp/yesodapp deploy/
strip deploy/yesodapp
echo "** The md5sum is : "
md5sum deploy/yesodapp
echo "** Filesize : "
du -sh deploy/yesodapp
gzip deploy/yesodapp


# Upload zipped build file to server
scp deploy/yesodapp.gz ubuntu@54.169.54.108:~/yesod-app/latest/yesodapp.gz
ssh ubuntu@54.169.54.108 -C "~/yesod-app/UpdateBin.sh"


# Tidy up local working environment
rm deploy/yesodapp.gz