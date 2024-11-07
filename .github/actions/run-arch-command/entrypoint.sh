#!/usr/bin/env bash

if [ -n "$INPUT_CHOWN" -a "$INPUT_CHOWN" = "true" ]
then
    echo "Chown-ing folders to the 'build' user..."
    [ -d "/github/workspace" ] && sudo chown -R build /github/workspace
    [ -d "/github/home" ] && sudo chown -R build /github/home
fi

# Convert the input to an array for nice formatting
# Thanks: https://stackoverflow.com/a/57178833

mapfile -t INPUT_ARRAY <<< $INPUT_RUN
for command in "${INPUT_ARRAY[@]}"
do
    if [ ! -n "$command" ]
    then
        continue
    fi

    # Grouping guide here: https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions#grouping-log-lines
    echo "::group::Running the command '$command'..."
    $command
done
