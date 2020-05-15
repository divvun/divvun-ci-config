#!/usr/bin/env bash

source ./scripts/env.sh
source ~/pyenv/bin/activate

if [[ "$TARGET" == "ios" ]] || [[ "$TARGET" == "android" ]]; then
    source $HOME/.cargo/env
fi

if [[ "$TARGET" == "android" ]]; then
    source ./scripts/env-android.sh
fi

git submodule update --init

build_number=$(yq r project.yaml targets.$TARGET.build)
let "build_number+=1"
yq w -i project.yaml targets.$TARGET.build $build_number
echo "Incrementing build number to: $build_number"

~/pyenv/bin/kbdgen -R -t $TARGET \
    -o output \
    --github-username $GITHUB_USERNAME \
    --github-token $GITHUB_TOKEN \
    --logging=debug \
    project.yaml
