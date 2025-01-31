#!/bin/bash

# Make symbolic links to files you want to watch to files.d directory.
# Whenever a file changes all hooks in hooks.d/FILE are run, all hooks
# get variables FILE pointing to the symbolic file name in hooks.d and
# REAL_FILE pointing to the resolved real file.
# Right now only modify time is checked, whenever modify time changes
# the hooks are run and latest modify time is stored to cache.

SCRIPT_DIR="$(dirname $(realpath -s $0))"
HOOK_DIR="$SCRIPT_DIR/hooks.d"
FILE_DIR="$SCRIPT_DIR/files.d"
CACHE_DIR="$SCRIPT_DIR/cache"

for DIR in $HOOK_DIR $FILE_DIR $CACHE_DIR; do
    if [ ! -d "$DIR" ]; then
        mkdir -p "$DIR"
    fi
done

run_hooks() {
    local FILE="$1"
    local REAL_FILE="$2"

    for HOOK in $(ls -1 $HOOK_DIR/$FILE); do
        if [ -x "$HOOK_DIR/$FILE/$HOOK" ]; then
            FILE="$FILE" REAL_FILE="$REAL_FILE" $HOOK_DIR/$FILE/$HOOK
        fi
    done
}

for FILE in $(ls -1 $FILE_DIR); do
    if [ ! -d "$HOOK_DIR/$FILE" ]; then
        >&2 echo "No hooks for $FILE - skipping"
        continue
    fi
    REAL_FILE="$(readlink $FILE_DIR/$FILE)"
    NEW_MTIME=$(stat $REAL_FILE -c %Y)
    RET=$?
    if [ $RET -ne 0 ]; then
        >&2 echo "Could not stat $FILE - skipping"
        continue
    fi
    OLD_MTIME=
    if [ -f "$CACHE_DIR/$FILE" ]; then
        OLD_MTIME=$(cat $CACHE_DIR/$FILE)
    fi
    if [ "$NEW_MTIME" != "$OLD_MTIME" ]; then
        run_hooks "$FILE" "$REAL_FILE"
        echo "$NEW_MTIME" > "$CACHE_DIR/$FILE"
    fi
done
