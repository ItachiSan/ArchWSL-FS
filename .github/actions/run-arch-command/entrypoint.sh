#!/bin/sh -l

if [ -d "/github" ]; then
    sudo chown -R build /github/workspace /github/home
fi

# The variable expansion converts all new lines to ';', thus making it a single line and compatible with '-c'
exec bash -c "${INPUT_RUN//$'\n'/;}"
