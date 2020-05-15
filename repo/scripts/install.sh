#!/usr/bin/env bash

echo -e "machine github.com\n  login $GITHUB_TOKEN" > ~/.netrc
echo Branch: $TRAVIS_BRANCH

echo Setting up Python environment...
python3 -m venv ~/pyenv
source ~/pyenv/bin/activate

echo Upgrading pip...
pip install --upgrade pip > /dev/null

# Install kbdgen
echo Installing kbdgen...
pip install kbdgen

echo Installing Fastlane...
sudo gem install fastlane > /dev/null

echo Updating Homebrew...
brew update > /dev/null

echo Installing Homebrew deps...
brew install imagemagick yq > /dev/null

if [[ "$TARGET" == "ios" ]]; then
  curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly -y
  source $HOME/.cargo/env

  echo Installing CocoaPods...
  sudo gem install cocoapods --pre > /dev/null

  rustup target add aarch64-apple-ios
  rustup target add armv7-apple-ios
  rustup target add i386-apple-ios
  rustup target add x86_64-apple-ios
  cargo install cargo-lipo
elif [[ "$TARGET" == "android" ]]; then
  brew tap homebrew/cask
  brew cask install homebrew/cask-versions/java8
  brew cask install android-sdk
  brew cask install android-ndk

  source ./scripts/env-android.sh

  mkdir -p ~/.android
  touch ~/.android/repositories.cfg

  yes | sdkmanager "build-tools;28.0.3" "platforms;android-28" > ./android-sdk.log

  curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly -y
  source $HOME/.cargo/env

  rustup target add aarch64-linux-android
  rustup target add armv7-linux-androideabi
  rustup target add i686-linux-android
  cargo install cargo-ndk
fi

