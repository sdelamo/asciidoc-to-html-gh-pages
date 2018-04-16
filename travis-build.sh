#!/bin/bash
set -e

EXIT_STATUS=0

./gradlew clean || EXIT_STATUS=$?

if [[ $EXIT_STATUS -ne 0 ]]; then
    echo "Clean failed"
    exit $EXIT_STATUS
fi

./gradlew check || EXIT_STATUS=$?

if [[ $EXIT_STATUS -ne 0 ]]; then
    echo "Check failed"
    exit $EXIT_STATUS
fi

./gradlew docs || EXIT_STATUS=$?

if [[ $EXIT_STATUS -ne 0 ]]; then
    echo "Docs generation failed"
    exit $EXIT_STATUS
fi

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global credential.helper "store --file=~/.git-credentials"
echo "https://$GH_TOKEN:@github.com" > ~/.git-credentials

git clone https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG}.git -b gh-pages gh-pages --single-branch > /dev/null
cd gh-pages

# If this is the master branch then update the snapshot
docspath = '../build/asciidoc/html5/.'
if [[ $TRAVIS_BRANCH == 'master' ]]; then
  mkdir -p snapshot
  cp -r $docspath ./snapshot/
  git add snapshot/*
fi

# If there is a tag present then this becomes the latest
if [[ -n $TRAVIS_TAG ]]; then
  mkdir -p latest
  git rm -rf latest/
  cp -r $docspath ./latest/
  git add latest/*

  version="$TRAVIS_TAG" # eg: v3.0.1
  version=${version:1} # 3.0.1
  majorVersion=${version:0:4} # 3.0.
  majorVersion="${majorVersion}x" # 3.0.x

  mkdir -p "$version"
  git rm -rf "$version"
  cp -r $docspath "./$version/"
  git add "$version/*"

  mkdir -p "$majorVersion"
  git rm -rf "$majorVersion"
  cp -r $docspath "./$majorVersion/"
  git add "$majorVersion/*"
fi

git commit -a -m "Updating docs for Travis build: https://travis-ci.org/$TRAVIS_REPO_SLUG/builds/$TRAVIS_BUILD_ID"
git push origin HEAD
cd ..
rm -rf gh-pages

exit $EXIT_STATUS
