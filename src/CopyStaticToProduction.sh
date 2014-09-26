#!/bin/bash

#
# post-receive hook,
# for the "hub" repo on the AWS instance.
#
# So, if hub dir on AWS instance is:
#   ~/yesod-app/staticfiles.git
# then, run
#   $ git remote add aws ubuntu@54.169.54.108:~/yesod-app/staticfiles.git
# and keep the static files on the branch `staticfiles`.
#
# Then, to update the static files served by the yesod app (or nginx),
# From the repo just run
#   $ git push aws staticfiles
#

# Caveats:
# * Assumes the yesodapp binary doesn't depend on any static files which aren't
#   in the repo.
#   (It doesn't. This assumption is sound for a JSON REST API).
# * Is non-destructive; any files which get *removed* from staticfiles will
#   linger on the server, and have to be removed manually.

echo
echo "*** AWS, Copy Static Files to Production ***"
echo

APPDIR=$HOME/yesod-app

# 'Staging' repo,
# a non-bare repo so that we can 'pull' from this
# Just create this with, like,
#   $ git clone staticfiles.git staticfiles-staging
staging_repo=$APPDIR/staticfiles-staging

echo "Using staging repo: $staging_repo"


# Branch to use when pulling
staticfiles_branch="staticfiles"

echo "Using branch: $staticfiles_branch"


cd $staging_repo
unset GIT_DIR
# Can use origin, if we cloned it from ~/yesod-app/staticfiles.git
# (Otherwise, use whatever is in .git/config)
git fetch origin staticfiles

# Ensure there are no tracked/untracked changes
git clean -df
git checkout -- .

git checkout staticfiles

# Where to copy the static files to.
# e.g. copy $REPO_WORKING_DIR/html to $staticfiles_dest_dir/html
staticfiles_dest_dir=$APPDIR/current/static

echo "Copying to $staticfiles_dest_dir"



echo "Assuming static files in folders: html, js, css, themes"

for staticfolder in html js css themes
do

  src=$staging_repo/$staticfolder
  dest=$staticfiles_dest_dir
  
  # This confuses me, so note that:
  #   $ cp -R path/to/html path/to/static
  # is going to ensure there's
  #   path/to/static/html 
  # with everything from path/to/html copied into it.
  
  # To copy folder
  echo "Copy $src to $dest"
  cp -R $src $dest

done

echo "Done!"
echo
