#!/bin/bash

# Add a new puppet environment

# Verify at top of repo
# .git exists
puppet_env='bncloud'
puppet_env_src='Production'
git checkout $puppet_env_src
git branch $puppet_env
git checkout $puppet_env
sed -i "s/$puppet_env_src/$puppet_env/g" manifests/README.txt
sed -i "s/$puppet_env_src/$puppet_env/g" hieradata/README.txt
git rm *.pp hiera.yaml
git add --all
git commit -m "Initial creation of new puppet environment: $puppet_env"
# Look for git command to do this
# Needed??
#cat >> .git/config <<NewBranch
#[branch "$puppet_env"]
#	remote = origin
#	merge = refs/heads/$puppet_env
#NewBranch

git push --all

