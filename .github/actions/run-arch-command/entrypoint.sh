#!/usr/bin/env bash

if [ -n "$INPUT_CHOWN" -a "$INPUT_CHOWN" = "true" ]
then
    echo "Chown-ing folders to the 'build' user..."
    [ -d "/github/workspace" ] && sudo chown -R build /github/workspace
    [ -d "/github/home" ] && sudo chown -R build /github/home
fi

# The variable expansion converts all new lines to ';', thus making it a single line and compatible with '-c'
exec bash -c "${INPUT_RUN//$'\n'/;}"
