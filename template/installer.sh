#!/dev/tmp/bin/bash

# If you don't want below extraction function 
# remove it and use your own.
function extract() {
    local -r filename="$1"
    local -r dst="$2"
    if ! $BUSYBOX unzip -qo "$ZIPFILE" "$filename" -d "$dst"; then
        ui_print "! Failed to extract: $filename"
        return 1
    fi
    return 0
}

# ...
extract "module.prop" $MODPATH

# Your code goes below
ui_print "Hello, World!"