# Auto generated customize.sh script
# This script handles initial module setup and environment preparation

SKIPUNZIP=1
WORKSPACE="/data/adb/modules/bash_example"
DEFAULT_PATH="/data/adb/magisk"

#----------------------------------------
# File extraction utility
#----------------------------------------
extract() {
    local filename=$1
    local dst=$2
    unzip -qo "$ZIPFILE" "$filename" -d "$dst"
}

#----------------------------------------
# Root interface detection
#----------------------------------------
KSUDIR="/data/adb/ksu"
KSU=false
if [ -d $KSUDIR ]; then
    KSU=true
    DEFAULT_PATH=$KSUDIR
fi

#----------------------------------------
# Extract required files
#----------------------------------------
extract "module.prop" $MODPATH

#----------------------------------------
# Setup bash environment
#----------------------------------------
ADBROOT="/data/adb"
BASHENV="$ADBROOT/.bashenv"
INSTALLER="$MODPATH/installer.bash"

extract ".bashenv/*" $ADBROOT
extract "$IDENTIFIER_KEY" $BASHENV
extract "installer.bash" $MODPATH

#----------------------------------------
# Environment validation
#----------------------------------------
# Check environment directory existence
if [ ! -d $BASHENV ]; then
    abort "Error: Bash environment directory not found."
fi

# Verify required files
if [ ! -f "$BASHENV/bash" ] && [ ! -f "$BASHENV/arch.data" ] && [ ! -f "$BASHENV/busybox" ]; then
    abort "Error: required files are not found."
fi

#----------------------------------------
# Set file permissions
#----------------------------------------
chmod 755 "$BASHENV/bash" || abort "Couldn't change -> $BASHENV/bash permission"
chmod 600 "$BASHENV/arch.data" || abort "Couldn't change -> $BASHENV/arch.data permission"
chmod 755 "$BASHENV/busybox" || abort "Couldn't change -> $BASHENV/busybox permission"
chmod +x "$INSTALLER" || abort "Couldn't change -> $INSTALLER permission"

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
    $BASHENV/bash "$@"
}

#----------------------------------------
# Execute installer
#----------------------------------------
bashexe -c ". $DEFAULT_PATH/util_functions.sh; source $INSTALLER"    

#----------------------------------------
# Cleanup
#----------------------------------------
[ -d $BASHENV ] && rm -rf $BASHENV
[ -f $MODPATH/installer.bash ] && rm $MODPATH/installer.bash

