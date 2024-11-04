#!/bin/bash

#==============================================================================
# Module Generator Script
# Compatible with: Magisk and KernelSU
# Author: Taylo @ https://github.com/i-taylo
#==============================================================================

#------------------------------------------------------------------------------
# Module Configuration
#------------------------------------------------------------------------------
MODULE_ID="bash_example"
MODULE_NAME="bash-example-name"
MODULE_VERSION="1.0"
MODULE_VERSION_CODE="1000"
AUTHOR="example@author"
DESCRIPTION="This is a description of an example"
UPDATE_JSON="#<json file link>"

# File path definitions
LAUNCHER_CODE="template/customize.sh"
INSTALLATION_CODE="template/installer.sh"

#------------------------------------------------------------------------------
# Generate Launcher Script (customize.sh)
#------------------------------------------------------------------------------
cat > "$LAUNCHER_CODE" << EOF
# Auto generated customize.sh script
# This script handles initial module setup and environment preparation

SKIPUNZIP=1
WORKSPACE="/data/adb/modules/$MODULE_ID"
DEFAULT_PATH="/data/adb/magisk"

#----------------------------------------
# File extraction utility
#----------------------------------------
extract() {
    local filename=\$1
    local dst=\$2
    unzip -qo "\$ZIPFILE" "\$filename" -d "\$dst"
}

#----------------------------------------
# Root interface detection
#----------------------------------------
KSUDIR="/data/adb/ksu"
KSU=false
if [ -d \$KSUDIR ]; then
    KSU=true
    DEFAULT_PATH=\$KSUDIR
fi

#----------------------------------------
# Extract required files
#----------------------------------------
extract "module.prop" \$MODPATH

#----------------------------------------
# Setup bash environment
#----------------------------------------
ADBROOT="/data/adb"
BASHENV="\$ADBROOT/.bashenv"
INSTALLER="\$MODPATH/installer.sh"

extract ".bashenv/*" \$ADBROOT
extract "\$IDENTIFIER_KEY" \$BASHENV
extract "installer.sh" \$MODPATH

#----------------------------------------
# Environment validation
#----------------------------------------
# Check environment directory existence
if [ ! -d \$BASHENV ]; then
    abort "Error: Bash environment directory not found."
fi

# Verify required files
if [ ! -f "\$BASHENV/bash" ] && [ ! -f "\$BASHENV/arch.data" ] && [ ! -f "\$BASHENV/busybox" ]; then
    abort "Error: required files are not found."
fi

#----------------------------------------
# Set file permissions
#----------------------------------------
chmod 755 "\$BASHENV/bash" || abort "Couldn't change -> \$BASHENV/bash permission"
chmod 600 "\$BASHENV/arch.data" || abort "Couldn't change -> \$BASHENV/arch.data permission"
chmod 755 "\$BASHENV/busybox" || abort "Couldn't change -> \$BASHENV/busybox permission"
chmod +x "\$INSTALLER" || abort "Couldn't change -> \$INSTALLER permission"

#----------------------------------------
# Setup module environment
#----------------------------------------
export ZIPFILE
export MODPATH
export OUTFD
export TMPDIR
export DEFAULT_PATH
export KSU
export BASHENV
export ABI32
export IS64BIT
export ARCH

#----------------------------------------
# Define bash executor
#----------------------------------------
bashexe() {
    \$BASHENV/bash "\$@"
}

#----------------------------------------
# Execute installer
#----------------------------------------
bashexe -c ". \$DEFAULT_PATH/util_functions.sh; source \$INSTALLER"    

#----------------------------------------
# Cleanup
#----------------------------------------
[ -d \$BASHENV ] && rm -rf \$BASHENV
[ -f \$MODPATH/installer.sh ] && rm \$MODPATH/installer.sh

EOF

#------------------------------------------------------------------------------
# Generate module.prop
#------------------------------------------------------------------------------
cat > "template/module.prop" << EOF
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
echo "Generating module zipfile..."
cd template || { echo "Error: template directory not found"; exit 1; }
ZIPFILE_NAME="$MODULE_NAME-$MODULE_VERSION.zip"

# Create zip with maximum compression
if ! zip -9 -qr "$ZIPFILE_NAME" .; then
    echo "Error: Failed to create zip package"
    cd ..
    exit 1
fi

# Move package to parent directory
cd ..
if ! mv "template/$ZIPFILE_NAME" .; then
    echo "Error: Failed to move zip package"
    exit 1
fi

echo "Successfully created: $ZIPFILE_NAME"

