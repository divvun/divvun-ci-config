Take the unencrypted data and run:

`tar cf - enc | xz -9c | openssl aes-256-cbc -md md5 -pass pass:$DIVVUN_KEY -out config.txz.enc`

Commit the encrypted file, delete the unencrypted content.

To decrypt:

`openssl aes-256-cbc -d -in config.txz.enc -pass pass:$DIVVUN_KEY | tar xf -`

# Development

For development purposes, the unencrypted Android store `dev.jks` is added. This is purely for testing locally, but normally signing should be done on CI.

Store parameters:
- keyAlias: "developmentStore"
- storePassword: "amazingStorePassword"
- keyPassword: "amazingKeyPassword",
