#!/bin/bash

# This file expects to be in
#   /home/ubuntu/yesod-app/UpdateBinary.sh
# 
# Also make sure it's executable, with
#   $ chmod +x UpdateBinary.sh

echo "** UPDATING THE BINARY **"

APPDIR=$HOME/yesod-app

# Expects file to be scp'd to:
#   ~/yesod-app/latest/yesodapp.gz



# Unzip the file
echo "* Unzipping *"
gunzip $APPDIR/latest/yesodapp.gz



# Replace the binary in
# $APPDIR/current/yesodbin with the uploaded one
echo "* Moving *"
mv $APPDIR/latest/yesodapp $APPDIR/current/yesodapp



# Replace the currently running binary in the tmux pane.
# This assumes a tmux session is running with:
session_name=yesodapp
window=${session_name}:0
pane=${window}.0

# n.b. yesodapp requires current working directory to have:
#   static/
#   config/settings.yml
#   config/sqlite.yml

# Let's replace the currently running yesodapp.
echo "* Replacing *"
echo $pane
replace_cmd="/bin/bash -c 'cd $APPDIR/current; $APPDIR/current/yesodapp Production'"
echo $replace_cmd
tmux respawn-pane -t $pane -k "$replace_cmd"
