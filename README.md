Take the unencrypted data and run:

`tar cf - enc | xz -9c | openssl aes-256-cbc -pass pass:$DIVVUN_KEY -out config.txz.enc`

Commit the encrypted file, delete the unencrypted content.

To decrypt:

`openssl aes-256-cbc -d -in config.txz.enc -pass pass:$DIVVUN_KEY | tar xf -`
