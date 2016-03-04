#!/bin/bash
# Simple script to deploy our `develop` branch to Pantheon continuously.

# Log into Pantheon
terminus auth login "$PEMAIL" --password="$PPASS"

# Change connection mode to Git
terminus site set-connection-mode --site="$PUUID" --env="$PENV" --mode=git

# We need to compile CSS
# Then, commit all to the current branch after fixing .gitignore
git config --global user.email "$CI_BOT_EMAIL"
git config --global user.name "$CI_BOT_NAME"

cd "$DRUPAL_TI_THEME_DIR"
git add --force css
git add --force js
cd "$TRAVIS_BUILD_DIR"

export CI_COMMIT_MSG="Branch $TRAVIS_BRANCH compiled CSS"
git commit -a -m "Built by CI - $CI_COMMIT_MSG"

# Add a new remote for Pantheon
git remote add pantheon ssh://codeserver.$PENV.$PUUID@codeserver.$PENV.$PUUID.drush.in:2222/~/repository.git

# And push all code
git push pantheon HEAD:master --force

# Change connection mode back to SFTP so we can install
terminus site set-connection-mode --site="$PUUID" --env="$PENV" --mode=sftp

# Install the site
terminus drush --site="$PUUID" --env="$PENV" "site-install --account-pass='$SITEPASS' --site-name='$SITE_NAME $NOW' -y"

# Now, wake up the site
terminus site wake --site="$PUUID" --env="$PENV"
