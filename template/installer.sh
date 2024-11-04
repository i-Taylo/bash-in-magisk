#!/data/adb/.bashenv/bash

#==============================================================================
# Module Installer Script
# Author: Taylo @ https://github.com/i-taylo
#==============================================================================

# The code provided is only an example
# you may need to implement your own code.

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------
# Debug configuration - set to true to enable logging
DEBUG="${DEBUG:-true}"
declare -r LOGDIR="$MODPATH/logs"
[[ ! -d $LOGDIR ]] && mkdir -p $LOGDIR
declare -r LOGFILE="$LOGDIR/module_install.log"
declare -ra FILES_TO_EXTRACT=(
    "example.file"
    "example_dir/*"
)

# System files to be replaced
declare -ra REPLACE=(
    "/system/product/app/ViaBrowser/ViaBrowser.apk"
)
#------------------------------------------------------------------------------
# Utility Functions.
#------------------------------------------------------------------------------
function log() {
    if [[ "$DEBUG" == "true" ]]; then
        local -r level="$1"
        local -r message="$2"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$LOGFILE"
    fi
}

# Enhanced extraction function ( recommended to use ).
function extract() {
    local -r filename="$1"
    local -r dst="$2"
    
    if ! $BUSYBOX unzip -qo "$ZIPFILE" "$filename" -d "$dst"; then
        log "ERROR" "Failed to extract: $filename"
        ui_print "! Failed to extract: $filename"
        return 1
    fi
    log "INFO" "Successfully extracted: $filename to $dst"
    return 0
}

# property reader or you can simply use `grep_get_prop`
function catprop() {
    local -r key="$1"
    local prop_value
    
    prop_value="$(grep_get_prop "$key")"
    if [[ -n "$prop_value" ]]; then
        echo "$prop_value"
        log "INFO" "Read property $key: $prop_value"
    else
        log "WARN" "Property $key not found or empty"
        echo "unknown"
    fi
}

# Directory creation func.
function ensure_dir() {
    local -r dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || {
            log "ERROR" "Failed to create directory: $dir"
            ui_print "! Failed to create directory: $dir"
            return 1
        }
    fi
}

#------------------------------------------------------------------------------
# Installation Process
#------------------------------------------------------------------------------

# Extract required files
function install_files() {
    ui_print "- Extracting module files..."
    log "INFO" "Starting file extraction process"
    
    for ((i = 0; i < ${#FILES_TO_EXTRACT[@]}; i++)); do
        ui_print "  Extracting: ${FILES_TO_EXTRACT[i]}"
        extract "${FILES_TO_EXTRACT[i]}" "$MODPATH" || return 1
    done
    
    log "INFO" "File extraction completed successfully"
    return 0
}

# Setup replacement markers
function setup_replacements() {
    ui_print "- Setting up file replacements..."
    log "INFO" "Starting replacement setup"
    
    for ((i = 0; i < ${#REPLACE[@]}; i++)); do
        ui_print "  Setting up replacement for: ${REPLACE[i]}"
        local replace_dir="$MODPATH${REPLACE[i]%/*}"
        
        ensure_dir "$replace_dir" || return 1
        
        if ! mktouch "$MODPATH${REPLACE[i]}/.replace"; then
            log "ERROR" "Failed to create replacement marker for: ${REPLACE[i]}"
            ui_print "! Failed to setup replacement for: ${REPLACE[i]}"
            return 1
        fi
        
        log "INFO" "Successfully set up replacement for: ${REPLACE[i]}"
    done
    
    return 0
}

# Print device information
function print_device_info() {
    ui_print "- Device Information:"
    ui_print "  Architecture: $ARCH"
    ui_print "  Model: $(catprop ro.product.model)"
    ui_print "  Manufacturer: $(catprop ro.product.manufacturer)"
    ui_print "  Device: $(catprop ro.product.device)"
    
    log "INFO" "Device Info - Arch: $ARCH, Model: $(catprop ro.product.model)"
}

#------------------------------------------------------------------------------
# Main Installation
#------------------------------------------------------------------------------
function main() {
    ui_print "********************************"
    ui_print "   Module Installation Started"
    ui_print "********************************"
    
    # Initialize logging if debug is enabled
    if [[ "$DEBUG" == "true" ]]; then
        ensure_dir "${LOGFILE%/*}"
        log "INFO" "Debug logging enabled"
        log "INFO" "Starting installation process"
        ui_print "- Debug logging enabled: $LOGFILE"
    fi
    
    # Print device information
    print_device_info
    
    # Install files
    install_files || {
        ui_print "! Installation failed during file extraction"
        log "ERROR" "Installation failed during file extraction"
        return 1
    }
    
    # Setup replacements
    setup_replacements || {
        ui_print "! Installation failed during replacement setup"
        log "ERROR" "Installation failed during replacement setup"
        return 1
    }
    
    ui_print "- Installation completed successfully"
    log "INFO" "Installation completed successfully"
    
    ui_print "********************************"
    ui_print "   Installation Complete"
    ui_print "********************************"
}

main "$@"
