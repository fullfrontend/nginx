#!/usr/bin/env bash

set -e
if [ "$1" = 'nginx' ]; then

    export LOG_FILE=${LOG_FILE:-nginx}
    export DOCUMENT_ROOT=${DOCUMENT_ROOT:-/var/www}

    # ensure the following environment variables are set. exit script and container if not set.
    test $VIRTUAL_HOST

    /usr/local/bin/confd -onetime -backend env

fi;

exec "$@"
