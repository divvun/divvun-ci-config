# divvun-ci-config

This repo contains encrypted environment variables, secrets, and setup scripts used by Divvun CI. It's used by the [taskcluster-gha](https://github.com/divvun/taskcluster-gha) repo. During a CI run, this repo is downloaded and decrypted with `$DIVVUN_KEY`, which is stored in [taskcluster secrets](https://divvun-tc.giellalt.org/secrets) (you'll need access).

### Decrypting

The following command will decrypt and decompress everything into a folder called `enc/`:

`openssl aes-256-cbc -d -in ./config.txz.enc -pass pass:$DIVVUN_KEY -md md5 | xz -d | tar xvf -`

### Encrypting

Take the unencrypted data and run:

`tar cf - enc | xz -9c | openssl aes-256-cbc -md md5 -pass pass:$DIVVUN_KEY -out config.txz.enc`

Commit the encrypted file, delete the unencrypted content.

### Development

For development purposes, the unencrypted Android store `dev.jks` is added. This is purely for testing locally, but normally signing should be done on CI.

Store parameters:
- keyAlias: "developmentStore"
- storePassword: "amazingStorePassword"
- keyPassword: "amazingKeyPassword",
