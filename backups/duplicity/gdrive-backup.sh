#!/bin/bash

SCRIPTPATH=$(readlink -f "$0")
SCRIPTDIR=$(dirname $SCRIPTPATH)
VHOME=$SCRIPTDIR/..
SECRETS=$VHOME/secrets
CLIENT_ID=$(cat $SCRIPTDIR/.client-name)

export PASSPHRASE=$(pass show backup/duplicity)
export GOOGLE_CLIENT_SECRET_JSON_FILE=$SECRETS/"client_secret_$CLIENT_ID.json"
export GOOGLE_CREDENTIALS_FILE=$SECRETS/credentials.json
SRC="/home"
DEST="gdrive://$CLIENT_ID/backups?myDriveFolderID=root"

duplicity incr --full-if-older-than 1M --volsize 1024 \
    --exclude-device-files \
    --exclude-other-filesystems \
    --exclude-filelist $SCRIPTDIR/.backup-exclude \
    "${SRC}" "${DEST}"
duplicity remove-older-than 6M --force $DEST
unset PASSPHRASE
