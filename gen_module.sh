#!/usr/bin/env bash

#------------------------------------------------------------------------------
# Module Generator Script
# Compatible with: Magisk and KernelSU
# Author: Taylo @ https://github.com/i-taylo
# Version: 2.0.0
#------------------------------------------------------------------------------

readonly BIM_VERSION="2.0.0"
readonly BIN_SCRIPT=$(basename "$0")
readonly BIM_ROOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo() { :; }   # ovr
printf() { :; } # ovr

declare -A COLORS=(
	# Basic Colors
	[RED]='\033[0;31m'
	[GREEN]='\033[0;32m'
	[YELLOW]='\033[0;33m'
	[BLUE]='\033[0;34m'
	[PURPLE]='\033[0;35m'
	[CYAN]='\033[0;36m'
	[WHITE]='\033[0;37m'
	[BLACK]='\033[0;30m'
	[GRAY]='\033[0;90m'
	[DARK_GRAY]='\033[0;30m'
	[LIGHT_GRAY]='\033[0;37m'

	# Bold Colors
	[BOLD_RED]='\033[1;31m'
	[BOLD_GREEN]='\033[1;32m'
	[BOLD_YELLOW]='\033[1;33m'
	[BOLD_BLUE]='\033[1;34m'
	[BOLD_PURPLE]='\033[1;35m'
	[BOLD_CYAN]='\033[1;36m'
	[BOLD_WHITE]='\033[1;37m'
	[BOLD_GRAY]='\033[1;90m'

	# Light Colors
	[LIGHT_RED]='\033[91m'
	[LIGHT_GREEN]='\033[92m'
	[LIGHT_YELLOW]='\033[93m'
	[LIGHT_BLUE]='\033[94m'
	[LIGHT_PURPLE]='\033[95m'
	[LIGHT_CYAN]='\033[96m'

	# Custom RGB Colors
	[ORANGE]='\033[38;2;255;165;0m'
	[PINK]='\033[38;2;255;192;203m'
	[GOLD]='\033[38;2;255;215;0m'
	[LIME]='\033[38;2;50;205;50m'
	[TEAL]='\033[38;2;0;128;128m'
	[SILVER]='\033[38;2;192;192;192m'

	# Text Styles
	[BOLD]='\033[1m'
	[DIM]='\033[2m'
	[ITALIC]='\033[3m'
	[UNDERLINE]='\033[4m'
	[BLINK]='\033[5m'
	[REVERSE]='\033[7m'

	# Reset
	[RESET]='\033[0m'
)

get_color() { # Using this function for color retrieval.
	local color_name="${1:-RESET}"
	command echo "${COLORS[${color_name^^}]:-${COLORS[RESET]}}"
}

status_print() {
	local w="P"
	local message="$2"
	local cm="$message"

	cm=$(command echo "$cm" | sed 's/\(ignore\|Ignore\|ignored\)/\x1b[38;2;0;128;128m\1\x1b[0m/g')
	cm=$(command echo "$cm" | sed 's/\(Solution\|solution\)/\x1b[38;2;255;215;0m\1\x1b[0m/g')
	cm=$(command echo "$cm" | sed 's/\(successfully\|success\|Successfully\)/\x1b[0;32m\1\x1b[0m/g')
	LC="$(get_color "LIGHT_CYAN")"
	s="$(get_color "SILVER")"
	r="$(get_color "RESET")"
	bl="$(get_color "BOLD")"

	case $1 in
	"?")
		w="$(get_color "CYAN")Q$(get_color "RESET")"
		plain_w="Q"
		;;
	"0")
		w="$(get_color "GOLD")D$(get_color "RESET")"
		plain_w="D"
		;;
	"!" | "i")
		w="$(get_color "YELLOW")W$(get_color "RESET")"
		plain_w="W"
		;;
	"-")
		w="$(get_color "RED")E$(get_color "RESET")"
		plain_w="E"
		;;
	"+")
		w="$LC*$r"
		plain_w="*"
		;;
	"~l")
		w="o"
		plain_w="o"
		;;
	*)
		w="P"
		plain_w="P"
		;;
	esac

	command echo -e "$s[$r$w$s]$r $cm"

	if [ "$1" == "-" ]; then
		exit 1
	fi
}

set_up() {
	utilities=("bash" "zip" "git" "wget")
	# installing utilities
	for ((u = 0; u < ${#utilities[@]}; u++)); do
		if ! command -v ${utilities[u]} >/dev/null 2>&1; then
			status_print + "${utilities[u]} is not installed. Installing it now..."
			if [[ "$OSTYPE" == "linux-gnu"* ]]; then
				if command -v apt >/dev/null 2>&1; then
					sudo apt update && sudo apt install -y ${utilities[u]}
				elif command -v yum >/dev/null 2>&1; then
					sudo yum install -y ${utilities[u]}
				elif command -v dnf >/dev/null 2>&1; then
					sudo dnf install -y ${utilities[u]}
				elif command -v pacman >/dev/null 2>&1; then
					sudo pacman -S --noconfirm ${utilities[u]}
				elif command -v zypper >/dev/null 2>&1; then
					sudo zypper install -y ${utilities[u]}
				else
					status_print - "Unsupported Linux package manager. Please install ${utilities[u]} manually."
				fi
			elif [[ "$OSTYPE" == "darwin"* ]]; then
				if command -v brew >/dev/null 2>&1; then
					brew install ${utilities[u]}
				else
					status_print - "Homebrew is not installed. Please install it first: https://brew.sh/"
				fi
			elif [[ "$OSTYPE" == "linux-android"* ]]; then
				if command -v pkg >/dev/null 2>&1; then
					pkg update && pkg install ${utilities[u]}
				else
					status_print - "No package manager installed in your system."
				fi
			elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
				status_print - "Please download ${utilities[u]} for Windows manually"
			else
				status_print - "Unsupported OS. Please install ${utilities[u]} manually."
			fi
		else
			status_print + "${utilities[u]} is already installed."
		fi
	done
}

# Directory Management
enter_directory() {
	local dir="${1:?Directory not specified}"

	if [[ "$dir" == "l" ]]; then
		status_print 0 "Leaving -> $(pwd)"
		cd - >/dev/null || status_print - "Failed to return to previous directory"
		return 0
	fi

	if [[ ! -d "$dir" ]]; then
		status_print - "Directory does not exist: $dir"
	fi

	status_print 0 "Entering -> $dir"
	cd "$dir" || status_print - "Failed to change directory to $dir"
}

# Create File or Directory
create_item() {
	local type="${1:?Type not specified}"
	local path="${2:?Path not specified}"

	case "$type" in
	directory | d)
		mkdir -p "$path" || status_print - "Failed to create directory: $path"
		status_print + "Created directory: ${path##*/}"
		return 0
		;;
	file | f)
		touch "$path" || status_print - "Failed to create file: $path"
		status_print + "Created file: ${path##*/}"
		return 0
		;;
	*)
		status_print - "Unknown item type: $type"
		;;
	esac
}

redi() {
	local opr="[ ${1:-BUILD} ]"

	while IFS= read -r line || [[ -n $line ]]; do
		command echo -e "$(get_color "ORANGE") ${opr} $(get_color "RESET") $line"
	done
}

gen_zygisk_template() {
	local zygisk_dir="${BIM_ROOTDIR}/zygisk"
	local CPP_MODULE_FILE="${zygisk_dir}/jni/${MODULE_NAME// /-}.cpp"
	local INCLUDE_DIR="${zygisk_dir}/jni/include"
	local ANDROID_MK="${zygisk_dir}/jni/Android.mk"
	local APPLICATION_MK="${zygisk_dir}/jni/Application.mk"
	local empty=1

	# Generating include dir
	status_print + "Generating: ${INCLUDE_DIR##*/}"
	[ ! -d $INCLUDE_DIR ] && {
		if create_item d $INCLUDE_DIR; then
			status_print + "Successfully created: ${INCLUDE_DIR##*/}"
			empty=0
		fi
	} || {
		status_print + "${CPP_MODULE_FILE##*/} already exists, ignored"
	}
	[[ $empty -eq 0 ]] && {
		ZYGISK_API_HEADER="https://raw.githubusercontent.com/topjohnwu/zygisk-module-sample/refs/heads/master/module/jni/zygisk.hpp"
		status_print + "Downloading zygisk api header file..."
		if wget --no-check-certificate -q "$ZYGISK_API_HEADER" -O "$INCLUDE_DIR/zygisk.hpp"; then
			status_print + "Successfully downloaded and saved to -> $INCLUDE_DIR"
		else
			status_print ! "Couldn't download zygisk api header file!!! it's required for developing zygisk module, please download it manually from $ZYGISK_API_HEADER"
		fi
	}

	status_print + "Generating ${CPP_MODULE_FILE##*/}..."
	[ ! -f $CPP_MODULE_FILE ] && {
		if create_item f $CPP_MODULE_FILE; then
			status_print + "Successfully created: ${CPP_MODULE_FILE##*/}"
			empty=0
		fi
	} || {
		status_print + "${CPP_MODULE_FILE##*/} already exists, ignored"
	}

	# Now generating an example <From->https://github.com/topjohnwu/zygisk-module-sample.git>
	[[ $empty -eq 0 ]] && {
		cat >"$CPP_MODULE_FILE" <<EOF
#include <cstdlib>
#include <unistd.h>
#include <fcntl.h>
#include <android/log.h>
#include "include/zygisk.hpp"

#define LOGTAG "$MODULE_ID"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOGTAG, __VA_ARGS__)

using zygisk::Api;
using zygisk::AppSpecializeArgs;
using zygisk::ServerSpecializeArgs;

class MyModule : public zygisk::ModuleBase {
public:
    void onLoad(Api *api, JNIEnv *env) override {
        this->api = api;
        this->env = env;
    }

    void preAppSpecialize(AppSpecializeArgs *args) override {
        // Use JNI to fetch our process name
        const char *process = env->GetStringUTFChars(args->nice_name, nullptr);
        preSpecialize(process);
        env->ReleaseStringUTFChars(args->nice_name, process);
    }

    void preServerSpecialize(ServerSpecializeArgs *args) override {
        preSpecialize("system_server");
    }

private:
    Api *api;
    JNIEnv *env;

    void preSpecialize(const char *process) {
        // Demonstrate connecting to to companion process
        // We ask the companion for a random number
        unsigned r = 0;
        int fd = api->connectCompanion();
        read(fd, &r, sizeof(r));
        close(fd);
        LOGD("process=[%s], r=[%u]\n", process, r);

        // Since we do not hook any functions, we should let Zygisk dlclose ourselves
        api->setOption(zygisk::Option::DLCLOSE_MODULE_LIBRARY);
    }

};

static int urandom = -1;

static void companion_handler(int i) {
    if (urandom < 0) {
        urandom = open("/dev/urandom", O_RDONLY);
    }
    unsigned r;
    read(urandom, &r, sizeof(r));
    LOGD("companion r=[%u]\n", r);
    write(i, &r, sizeof(r));
}

// Register our module class and the companion handler function
REGISTER_ZYGISK_MODULE(MyModule)
REGISTER_ZYGISK_COMPANION(companion_handler)
EOF
	}

	# Now generating Android.mk and Application.mk
	status_print + "Generating ${ANDROID_MK##*/}..."
	empty=1
	[ ! -f $ANDROID_MK ] && {
		if create_item f $ANDROID_MK; then
			status_print + "Successfully created: ${ANDROID_MK##*/}"
			empty=0
		fi
	} || {
		status_print + "${ANDROID_MK##*/} already exists, ignored"
	}

	[[ $empty -eq 0 ]] && {
		cat >"$ANDROID_MK" <<EOF
LOCAL_PATH := \$(call my-dir)

include \$(CLEAR_VARS)
LOCAL_MODULE := ${MODULE_NAME// /_}
LOCAL_SRC_FILES := ${MODULE_NAME// /-}.cpp
LOCAL_STATIC_LIBRARIES := libcxx
LOCAL_LDLIBS := -llog

include \$(BUILD_SHARED_LIBRARY)
include jni/libcxx/Android.mk
EOF
	}

	status_print + "Generating ${APPLICATION_MK##*/}..."
	empty=1
	[ ! -f $APPLICATION_MK ] && {
		if create_item f $APPLICATION_MK; then
			status_print + "Successfully created: ${APPLICATION_MK##*/}"
			empty=0
		fi
	} || {
		status_print + "${APPLICATION_MK##*/} already exists, changing ABI list..."
		APP_ABI_LINE="APP_ABI := "
		for arch in "${abi_filter[@]}"; do
			APP_ABI_LINE+=" $arch"
		done

		sed -i '/^APP_ABI[[:space:]]*:=/d' "$APPLICATION_MK"
		sed -i "1s|^|$APP_ABI_LINE\n|" "$APPLICATION_MK"

	}

	[[ $empty -eq 0 ]] && {
		APP_ABI_LINE="APP_ABI      :="
		for arch in "${abi_filter[@]}"; do
			APP_ABI_LINE+=" $arch"
		done
		cat >"$APPLICATION_MK" <<EOF
$APP_ABI_LINE
APP_CPPFLAGS := -std=c++17 -fno-exceptions -fno-rtti -fvisibility=hidden -fvisibility-inlines-hidden
APP_STL      := none
APP_PLATFORM := android-21
EOF
	}

}

generate_zygisk_build_script() { # This function is for generating zygisk build script.
	local build_script_path="${1:?Build script path not specified}"
	local module_id="${2:?Module ID not specified}"

	cat >"$build_script_path" <<'EOBUILDSCRIPT'
#!/bin/bash
# Auto generated by gen_module.sh

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ ! "${BASH_SOURCE[1]}" =~ gen_module.sh$ ]]; then
    command echo "Error: This script must be sourced from gen_module.sh"
    return 1
fi

readonly LIBCXX_GITURL="https://github.com/topjohnwu/libcxx.git"

status_print + "Cloning libcxx..."
[ ! -d jni/libcxx ] && {
    if git clone --quiet $LIBCXX_GITURL jni/libcxx; then
        status_print + "Cloned libcxx"
    else
        status_print - "Couldn't clone libcxx! it's required"
    fi
}


# Check if NDK_HOME is valid
if [ ! -d "$NDK_HOME" ]; then
    status_print - "The $(get_color "LIGHT_RED")NDK_HOME$(get_color "RESET") directory was not found or is not correctly declared!\n[ Solution ] Please open -> ${GREEN}configuration.cfg${RESET} and navigate to ${YELLOW}NDK_HOME${RESET} variable and add the full path of NDK home.\nExample: \n$(get_color "LIGHT_RED")NDK_HOME$(get_color "RESET")=$(get_color "YELLOW")\"/home/username/Android/ndk/android-ndk-r27c$(get_color "RESET")\"\nOr simply run \`$(get_color "ORANGE")export$(get_color "LIGHT_GRAY") NDK_HOME=\"<path/to/ndk_home>$(get_color "RESET")\""
else
    export NDK_HOME
    export ANDROID_NDK_ROOT="$NDK_HOME"
    export _NDK_TOOLCHAIN_="$NDK_HOME/toolchains/llvm/prebuilt/linux-$(uname -m)"

    # Python paths
    export PYTHON_HOME="$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/python3"
    export PYTHON_LIB_PATH="$PYTHON_HOME/lib"

    # Add NDK and Python tools to PATH
    export PATH="$_NDK_TOOLCHAIN_/bin:$PYTHON_HOME/bin:$PATH:$NDK_HOME"
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$PYTHON_LIB_PATH"

    # Common build flags
    export ANDROID_TOOLCHAIN="$_NDK_TOOLCHAIN_"
    export ANDROID_SYSROOT="$_NDK_TOOLCHAIN_/sysroot"    
fi

status_print + "Running ndk-build..."

# Check if ndk-build is available
if ! command -v ndk-build > /dev/null 2>&1; then
    status_print - "ndk-build not found!!\nDid you correctly set the NDK_HOME environment variable?"
fi

# Checking for Android.mk & Application.mk content.
if [ -z "$(cat jni/Android.mk)" ] && [ -z "$(cat jni/Application.mk)" ]; then
    status_print - "Cannot build with empty build files."
fi

# Build using ndk-build with parallel jobs
if ! ndk-build -j"$(nproc)" 2>&1 | redi "ZYGISK BUILD"; then
    status_print - "Failure during building JNI libs"
fi
EOBUILDSCRIPT

	chmod +x "$build_script_path"
}

# Module Properties Generation.
generate_module_prop() {
	local prop_path="${1:?Prop file path not specified}"
	local module_id="${2:?Module ID not specified}"
	local module_name="${3:?Module Name not specified}"
	local module_version="${4:?Module Version not specified}"
	local module_version_code="${5:?Module Version Code not specified}"
	local author="${6:?Author not specified}"
	local description="${7:?Description not specified}"
	local update_json="${8:-}"

	cat >"$prop_path" <<EOPROPERTIES
id=$module_id
name=$module_name
version=$module_version
versionCode=$module_version_code
author=$author
description=$description
updateJson=$update_json
EOPROPERTIES

	status_print + "Generated ${prop_path##*/}"
}

# Generate Customize Script ( Contains bash environment setup )
generate_customize_script() {
	local script_path="${1:?Customize script path not specified}"
	local is_zygisk="${2:?Zygisk flag not specified}"
	local module_id="${3:?Module ID not specified}"
	local installer_filename="${4:?Installer filename not specified}"

	cat >"$script_path" <<EOCUSTOMIZESCRIPT
#!/system/bin/sh
# Auto-generated customize.sh script

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

# Extract zygisk libraries
isZygisk=$is_zygisk
if \$isZygisk; then
    DEVICE_ABI="\$(getprop ro.product.cpu.abi)"
    if [ "\$DEVICE_ABI" = "arm64-v8a" ] || [ "\$DEVICE_ABI" = "armeabi-v7a" ] || [ "\$DEVICE_ABI" = "x86_64" ] || [ "\$DEVICE_ABI" = "x86" ]; then
        extract "zygisk/\$DEVICE_ABI.so" \$MODPATH
    else
        abort "Unknown architecture: \$DEVICE_ABI"
    fi
fi

# Setup bash environment
INSTALLER="\$TMPDIR/$installer_filename"

extract "$installer_filename" \$TMPDIR
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
sed -i "1i\\ " "\$INSTALLER"
sed -i "1s|.*|#!\$TMPDIR/bin/bash|" \$INSTALLER
bashexe -c ". \$DEFAULT_PATH/util_functions.sh; source \$INSTALLER"
EOCUSTOMIZESCRIPT

	chmod +x "$script_path"
	status_print + "Generated ${script_path##*/}"
}

# Add Extraction Function ( only if->useExtractionFunction=true, in-> configuration.cfg )
add_extraction_function() {
	local installer_path="${1:?Installer path not specified}"

	if ! grep -Fq 'function extract() {' "$installer_path"; then
		cat >>"$installer_path" <<'EOEXTRACTFUNC'
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
EOEXTRACTFUNC
		status_print + "Added extraction function to $installer_path"
	else
		status_print + "Extraction function already exists in $installer_path"
	fi
}

# Add Simple Logger Function ( Only if->useLoggerFunction=true, in-> configuration.cfg )
add_logger_function() {
	local installer_path="${1:?Installer path not specified}"
	local module_id="${2:?Module ID not specified}"

	if ! grep -Fq 'function log() {' "$installer_path"; then
		cat >>"$installer_path" <<EOLOGGERFUNC

# Logging function.
function log() {
    local level logfile="/sdcard/$module_id.log"
    case "\$1" in
        e) level="ERROR" ;;
        d) level="DEBUG" ;;
        w) level="WARNING" ;;
        i) level="INFO" ;;
        *) level="+" ;;
    esac

    local message="[ \$level ] \$2"
    echo -e "\$2"
    echo "\$(date '+%Y-%m-%d %H:%M:%S') \$message" >> "\$logfile"

    if [[ "\$level" == "ERROR" ]]; then
        abort
    fi
}
EOLOGGERFUNC
		status_print + "Added logger function to $installer_path"
	else
		status_print + "Logger function already exists in $installer_path"
	fi
}

# Finally Create Module Package
create_module_package() {
	local template_dir="${1:?Template directory not specified}"
	local output_dir="${2:?Output directory not specified}"
	local module_name="${3:?Module Name not specified}"
	local module_version="${4:?Module Version not specified}"

	local sanitized_name="${module_name// /-}"
	local zipfile_name="${sanitized_name}-${module_version}.zip"
	local zipfile_path="${output_dir}/${zipfile_name}"

	# Create output directory if not exists
	create_item d "$output_dir"

	# Change to template directory
	pushd "$template_dir" >/dev/null

	# let's clean up before making new one.
	[ -f $zipfile_path ] && {
		if rm $zipfile_path; then
			status_print + "Cleaned: ${zipfile_path##*/}"
		fi
	}
	# Create zip with maximum compression
	if ! zip -9 -qr "$zipfile_path" .; then
		status_print - "Failed to create zip package"
		return 1
	fi

	# Return to original directory
	popd >/dev/null

	status_print + "Successfully created module package: $(get_color "GOLD")$zipfile_path$(get_color "RESET")"
	return 0
}

validate_configuration() {
	local config_path="${1:?Configuration path not specified}"

	# Sourcing configuration.cfg
	source "$config_path"

	# Validating module.prop
	[[ -z "${MODULE_ID:-}" ]] && status_print - "MODULE_ID is required in configuration"
	[[ -z "${MODULE_NAME:-}" ]] && status_print - "MODULE_NAME is required in configuration"
	[[ -z "${MODULE_VERSION:-}" ]] && status_print - "MODULE_VERSION is required in configuration"
	[[ -z "${MODULE_VERSION_CODE:-}" ]] && status_print - "MODULE_VERSION_CODE is required in configuration"
	[[ -z "${AUTHOR:-}" ]] && status_print - "AUTHOR is required in configuration"
	[[ -z "${DESCRIPTION:-}" ]] && status_print - "DESCRIPTION is required in configuration"
}

prepare_template_dir() {
	local h_templatedir="${BIM_ROOTDIR}/template"
	status_print + "Creating $h_templatedir..."
	create_item d "$h_templatedir"

	# Create META-INF directory structure
	create_item d "$h_templatedir/META-INF/com/google/android"

	local update_binary="$h_templatedir/META-INF/com/google/android/update-binary"
	local update_script="$h_templatedir/META-INF/com/google/android/updater-script"

	# Generate the `update-binary` script
	cat >"$update_binary" <<'EOUPDATEBINARY'
#################
# Initialization
#################

umask 022

# echo before loading util_functions
ui_print() { echo "$1"; }

require_new_magisk() {
  ui_print "*******************************"
  ui_print " Please install Magisk v20.4+! "
  ui_print "*******************************"
  exit 1
}

#########################
# Load util_functions.sh
#########################

OUTFD=$2
ZIPFILE=$3

[ -f /data/adb/magisk/util_functions.sh ] || require_new_magisk
. /data/adb/magisk/util_functions.sh
[ "$MAGISK_VER_CODE" -lt 20400 ] && require_new_magisk

install_module
exit 0
EOUPDATEBINARY

	# Simply create updater-script
	command echo "#MAGISK" >"$update_script"
}

# Main Module Generation Function
generate_module() {
	local config_path="${1:?Configuration path not specified}"

	# Validating configuration.cfg
	validate_configuration "$config_path"
	source "$config_path"

	local template_dir="${BIM_ROOTDIR}/template"
	local output_dir="${BIM_ROOTDIR}/output"
	local zygisk_dir="${BIM_ROOTDIR}/zygisk"

	# Prepare template directory
	[ ! -d $template_dir ] && {
		prepare_template_dir
	}

	# Generate Zygisk build script if Zygisk is enabled
	# But Let's check if THIS running through GitHub action.
	if [ "$GITHUB_ACTIONS" == "true" ]; then
		status_print ! "This script is running in GitHub Actions, skipping libraries build."
	else
		if [[ "${isZygisk:-false}" == "true" ]]; then
			create_item d "$zygisk_dir/jni"
			gen_zygisk_template
			generate_zygisk_build_script "$zygisk_dir/build.sh" "$MODULE_ID"
			chmod +x "$zygisk_dir/build.sh"
			enter_directory "$zygisk_dir"
			status_print 0 "Running zygisk build file..."
			source build.sh
			[ $? == 0 ] && {
				status_print + "Build success."
				enter_directory l
				status_print + "Adding libraries to template..."
				[ ! -d $BIM_ROOTDIR/template/zygisk ] && {
					create_item d $BIM_ROOTDIR/template/zygisk
				} || {
					if rm -rf $BIM_ROOTDIR/template/zygisk; then
						status_print + "Cleaned: $BIM_ROOTDIR/template/zygisk"
						create_item d $BIM_ROOTDIR/template/zygisk
					fi
				}

				for dir_arch in ${abi_filter[@]}; do
					if [ -d "$BIM_ROOTDIR/zygisk/libs/$dir_arch" ]; then
						mv $BIM_ROOTDIR/zygisk/libs/$dir_arch/*.so $BIM_ROOTDIR/zygisk/libs/$dir_arch/$dir_arch.so || status_print - "Something went wrong."
						mv "$BIM_ROOTDIR/zygisk/libs/$dir_arch/$dir_arch.so" "$BIM_ROOTDIR/template/zygisk/"
						status_print + "Added: $dir_arch to template."
					fi
				done

			}
		fi
	fi

	# Generate module files
	generate_module_prop "$template_dir/module.prop" \
		"$MODULE_ID" "$MODULE_NAME" "$MODULE_VERSION" \
		"$MODULE_VERSION_CODE" "$AUTHOR" "$DESCRIPTION" \
		"${UPDATE_JSON:-}"

	generate_customize_script "$template_dir/customize.sh" \
		"${isZygisk:-false}" "$MODULE_ID" "$INSTALLER_FILENAME"

	# Prepare installer script
	local installer_path="$template_dir/$INSTALLER_FILENAME"
	# Quick check before proceeding
	[[ ! -f "${installer_path}" ]] && {
		status_print ? "$INSTALLER_FILENAME missing from module template, cannot proceed without $INSTALLER_FILENAME it's required.\nDo you want to generate it?"
		command echo -e "1 ) - Yes\n2 ) - No"
		command echo -ne "Your choice: "
		read -r mGen_Install

		case "${mGen_Install,,}" in
		1 | y | yes | aye)
			create_item f "${installer_path}"
			status_print ? "Select editor to edit ${GREEN}$INSTALLER_FILENAME${RESET}:"
			command echo -e "1 ) - vim\n2 ) - nano\n3 ) just create it."
			command echo -ne "Your choice: "
			read -r installer_editor

			case "${installer_editor,,}" in
			vim | v | 1)
				vim "${installer_path}"
				;;
			nano | 2)
				nano "${installer_path}"
				;;
			*)
				status_print ! "Nothing selected and empty installer created and located at -> $installer_path"
				;;
			esac
			;;
		2 | n | no | nay)
			status_print - "Aborted due to missing installer script."
			;;
		*)
			status_print - "Aborted."
			;;
		esac
	}

	# Add optional functions if enabled
	[[ "${useExtractionFunction:-false}" == "true" ]] && add_extraction_function "$installer_path"
	[[ "${useLoggerFunction:-false}" == "true" ]] && add_logger_function "$installer_path" "$MODULE_ID"

	# cpBASH
	cp -af "${BIM_ROOTDIR}/bin" "$template_dir"

	# Create module package
	create_module_package "$template_dir" "$output_dir" "$MODULE_NAME" "$MODULE_VERSION"
}

# Script Entry Point
main() {
	set_up # for required utilities.
	# Check for configuration file
	local config_path="${BIM_ROOTDIR}/configuration.cfg"

	if [[ ! -f "$config_path" ]]; then
		status_print - "Configuration file not found at $config_path"
	fi

	# Generate Module
	generate_module "$config_path"
}

# Execute Main Function
main "$@"

cp -af ~/jnilab/magisk/output/bash-example-name-1.0.zip /storage/emulated/0/
