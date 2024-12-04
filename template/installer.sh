# Extraction function.
function extract() {
    local filename="$1"
    local dst="${2:-.}"
    
    if ! $BUSYBOX unzip -qo "$ZIPFILE" "$filename" -d "$dst"; then
        ui_print "ERROR" "Failed to extract: $filename"
        return 1
    fi
    ui_print "Successfully extracted: $filename"
    return 0
}

# Extracting files.
NEEDED=(
    "module.prop"
#    "system/*" # when extracting dirs make sure to use /*
#    "service.sh"
)
for ((f=0; f<${#NEEDED[@]}; f++)); do
    extract "${NEEDED[f]}" "$MODPATH"
done
