#!/bin/bash

#==============================================================================
# Module Generator Script
# Compatible with: Magisk and KernelSU
# Author: Taylo @ https://github.com/i-taylo
#==============================================================================

# TEXT COLORS
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RESET='\033[0m'
BIM_ROOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    echo "$(basename $0) cannot be sourced."
    return 1
fi

# Module Configuration
# Customize these variables to reflect your module's information.
MODULE_ID="bash_example"
MODULE_NAME="bash-example-name"
MODULE_VERSION="1.0"
MODULE_VERSION_CODE="1000"
AUTHOR="example@author"
DESCRIPTION="This is a description of an example"
UPDATE_JSON="#<json file link>"

# File path definitions
INSTALLER_FILENAME="installer.sh" # Renemable 
LAUNCHER_CODE="$BIM_ROOTDIR/template/name.sh"
INSTALLATION_CODE="$BIM_ROOTDIR/template/$INSTALLER_FILENAME"

# Generate Launcher Script (customize.sh)
[[ "$LAUNCHER_CODE" != *"customize.sh" ]] && echo -e "${RED}Error${RESET}: The launcher code has been renamed to ${RED}$(basename "$LAUNCHER_CODE")${RESET}.\nPlease name it ${GREEN}customize.sh${RESET} or the installation will fail during module flashing." && exit 1
cat > "$LAUNCHER_CODE" << EOF
# Auto generated customize.sh script
# This script handles initial module setup and environment preparation
# Please don't modify or add anything here, instead use the installer.sh script.

SKIPUNZIP=1
DEFAULT_PATH="/data/adb/magisk"

extract() {
    local filename=\$1
    local dst=\$2
    unzip -qo "\$ZIPFILE" "\$filename" -d "\$dst"
}

# Root interface detection
KSUDIR="/data/adb/ksu"
BUSYBOX="\$DEFAULT_PATH/busybox"
KSU=false
if [ -d \$KSUDIR ]; then
    KSU=true
    DEFAULT_PATH=\$KSUDIR
    BUSYBOX="\$DEFAULT_PATH/bin/busybox"
fi

# Setup bash environment
INSTALLER="\$TMPDIR/$INSTALLER_FILENAME"

extract "$INSTALLER_FILENAME" \$TMPDIR
extract "bin/bash.xz" \$TMPDIR

if [ ! -f "\$TMPDIR/bin/bash.xz" ]; then
    abort "Error: required files are not found."
else
    \$BUSYBOX xz -d \$TMPDIR/bin/bash.xz
fi

# Setting up files permissions
chmod 755 "\$TMPDIR/bin/bash" || abort "Couldn't change -> \$TMPDIR/bin/bash permission"
chmod +x "\$INSTALLER" || abort "Couldn't change -> \$INSTALLER permission"

# Setup module environment
export OUTFD ABI API MAGISKBIN NVBASE BOOTMODE MAGISK_VER_CODE MAGISK_VER ZIPFILE MODPATH TMPDIR DEFAULT_PATH KSU ABI32 IS64BIT ARCH BMODID BUSYBOX

# bash executor
bashexe() {
    \$TMPDIR/bin/bash "\$@"
}

# Finally execute the installer
BMODID="\$(bashexe --set-module-id $MODULE_ID)"
sed -i "1s|^#!.*|#!\$TMPDIR/bin/bash|" \$INSTALLER
bashexe -c ". \$DEFAULT_PATH/util_functions.sh; source \$INSTALLER"    

EOF

#------------------------------------------------------------------------------
# Generate module.prop
#------------------------------------------------------------------------------

if [ -z "$MODULE_ID" ]; then
    echo "Warning: Module ID is empty and it cannot be empty..."
    while [ -z "$modid" ]; do
        echo -ne "Enter module ID: "
        read modid
        if [ -z "$modid" ]; then
            echo "Error: Module ID cannot be empty. Please enter a valid ID."
        fi
    done
    MODULE_ID="$modid"
fi


cat > "$BIM_ROOTDIR/template/module.prop" << EOF
id=$MODULE_ID
name=$MODULE_NAME
version=$MODULE_VERSION
versionCode=$MODULE_VERSION_CODE
author=$AUTHOR
description=$DESCRIPTION
updateJson=$UPDATE_JSON

EOF

#------------------------------------------------------------------------------
# Create Module Package
#------------------------------------------------------------------------------
# Quick check before proceeding.
if [ ! -f $INSTALLATION_CODE ]; then
    echo -e "$INSTALLER_FILENAME missing from module template, cannot proceed without $INSTALLER_FILENAME it's required."
    exit 1
fi

echo "Generating module zipfile..."
cd template || { echo "Error: template directory not found"; exit 1; }
MODULE_NAME="${MODULE_NAME// /-}"
ZIPFILE_NAME="$MODULE_NAME-$MODULE_VERSION.zip"

# Create zip with maximum compression
if ! zip -9 -qr "$ZIPFILE_NAME" .; then
    echo "Error: Failed to create zip package"
    cd ..
    exit 1
fi

# Move package to output dir.
cd ..

OUTDIR="$BIM_ROOTDIR/output"; [ ! -d $OUTDIR ] && mkdir -p $OUTDIR

if ! mv "$BIM_ROOTDIR/template/$ZIPFILE_NAME" "$OUTDIR"; then
    echo "Error: Failed to move zip package"
    exit 1
fi

echo "Successfully created: $OUTDIR/$ZIPFILE_NAME"