source ./scripts/env.sh
source ~/pyenv/bin/activate

if [[ "$TARGET" == "android" ]]; then
    source ./scripts/env-android.sh
fi

# Force add github.com to known hosts because nothing is good in the world.
ssh-keyscan github.com >> ~/.ssh/known_hosts

url=$(git config --get remote.origin.url | sed 's#https://#git@#' | sed 's#/#:#')

git stash

echo "Correcting branch and committing..."
git checkout $TRAVIS_BRANCH && \
    git stash pop && \
    git add project.yaml && \
    git commit -m "[ci skip] Increment build number"

echo "Pushing changes..."
git config --unset remote.origin.url && \
    git config --add remote.origin.url "$url" && \
    git pull --rebase && \
    git push

if [[ "$TARGET" == "ios" ]]; then
    fastlane pilot upload --skip_submission \
        --skip_waiting_for_build_processing \
        --ipa output/ios-build/ipa/HostingApp.ipa
elif [[ "$TARGET" == "android" ]]; then
    pushd output/deps/giella-ime && \
        ./gradlew publishApk && \
        popd
else 
    echo "$TARGET not known to deploy script; aborting."
    exit 1
fi

if [[ $? != 0 ]]; then
    echo "Deploy failed with exit code $?"
    exit 1
fi

