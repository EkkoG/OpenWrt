#!/bin/bash -e

OPENWRT_VERSION=24.10
IS_SNAPSHOT_BUILD=0

# Detect OpenWrt version from image builder tag
# Parse version number from IMAGEBUILDER_IMAGE if provided
if [ ! -z "$IMAGEBUILDER_IMAGE" ]; then
    # Extract version number, handling -snapshot and -master suffixes
    extracted_version=$(echo "$IMAGEBUILDER_IMAGE" | grep -oE '[0-9]+\.[0-9]+' | head -1)
    if [ ! -z "$extracted_version" ]; then
        OPENWRT_VERSION=$extracted_version
    fi

    if [[ $IMAGEBUILDER_IMAGE =~ "-SNAPSHOT" ]]; then
        IS_SNAPSHOT_BUILD=1
    fi
fi


DEFAULT_MODULE_SET="add-all-device-to-lan argon base opkg-mirror prefer-ipv6-settings statistics system tools"

# 加载构建设置脚本
source ./setup/build-setup.sh

log_info() {
    # Print info messages when logging is enabled
    if [ "$LOG_ENABLE" == "1" ]; then
        echo -e "\033[32m[INFO]\033[0m $1"
    fi
}

log_error() {
    if [ "$LOG_ENABLE" == "1" ]; then
        echo -e "\033[31m[ERROR]\033[0m $1"
    fi
}

log_debug() {
    if [ "$LOG_ENABLE" == "1" ] && [ "$DEBUG" == "1" ]; then
        echo -e "\033[33m[DEBUG]\033[0m $1"
    fi
}

log_info "OpenWrt version detected: $OPENWRT_VERSION"
log_info "Default module set: $DEFAULT_MODULE_SET"
log_info "MODULES: $MODULES"

# Check if ENABLE_MODULES is defined, if so use it directly
if [ ! -z "$ENABLE_MODULES" ]; then
    ACTIVE_MODULE_LIST="$ENABLE_MODULES"
    log_info "Using ENABLE_MODULES directly: $ACTIVE_MODULE_LIST"
else
    # Use legacy DEFAULT_MODULE_SET + MODULES logic
    ACTIVE_MODULE_LIST=$DEFAULT_MODULE_SET
    for module in $MODULES; do
        # Check if module starts with "-" (exclusion prefix)
        if [ "${module:0:1}" == "-" ]; then
            # Remove module from active list
            module_to_remove="${module:1}"
            new_list=""
            for active_module in $ACTIVE_MODULE_LIST; do
                if [ "$active_module" != "$module_to_remove" ]; then
                    if [ -z "$new_list" ]; then
                        new_list="$active_module"
                    else
                        new_list="$new_list $active_module"
                    fi
                fi
            done
            ACTIVE_MODULE_LIST="$new_list"
        else
            # Add module to active list
            ACTIVE_MODULE_LIST="$ACTIVE_MODULE_LIST $module"
        fi
    done
    
    ACTIVE_MODULE_LIST="$(echo "$ACTIVE_MODULE_LIST" | tr '\n' ' ')"
    log_info "Active modules: $ACTIVE_MODULE_LIST"
fi

cp -r modules_in_container modules
cp -r user_modules_in_container user_modules

PACKAGE_COLLECTION=
# Load system environment variables
SYSTEM_ENVIRONMENT=""
if [ $USE_SYTEM_ENV ]; then
    SYSTEM_ENVIRONMENT="$(cat .env)"
fi


process_module_directory() {
    module_directory=$1

    for module_name in $ACTIVE_MODULE_LIST; do
        if [ ! -d "$module_directory/$module_name" ]; then
            continue
        fi
        log_info "Processing module: $module_name from $module_directory"

        if [ -f "$module_directory/$module_name/packages" ]; then
            res=$(. $module_directory/$module_name/packages 2>/dev/null || cat $module_directory/$module_name/packages)
            if [ ! -z "$res" ]; then
                PACKAGE_COLLECTION="$PACKAGE_COLLECTION $res"
            fi
        fi

        if [ -f "$module_directory/$module_name/.env" ]; then
            . $module_directory/$module_name/.env
            module_environment="$(cat $module_directory/$module_name/.env)"
            # Merge with system environment
            module_environment="$module_environment"$'\n'"$SYSTEM_ENVIRONMENT"
        else
            module_environment="$SYSTEM_ENVIRONMENT"
        fi

        # Process UCI defaults with environment variable substitution
        if [ -d "$module_directory/$module_name/files/etc/uci-defaults" ]; then
            for config_file in $(find "$module_directory/$module_name/files/etc/uci-defaults" -type f); do
                echo "$module_environment" | while IFS= read -r env_line; do
                    variable_name="$(echo "$env_line" | cut -d '=' -f 1)"
                    if [ ! -z "$variable_name" ]; then
                        variable_value="${!variable_name}"
                        log_debug "Substituting $variable_name with $variable_value in $config_file"
                        sed -e "s|\$$variable_name|$variable_value|g" -i $config_file
                    fi
                done
            done
        fi

        if [ -d "$module_directory/$module_name/files" ]; then
            mkdir -p files
            # Copy module files to build directory

            # Copy files, ensuring no duplicates
            # Exclude .DS_Store files
            for source_file in $(find "$module_directory/$module_name/files" -type f | grep -v .DS_Store); do
                target_file="files/${source_file#$module_directory/$module_name/files/}"
                if [ -f "$target_file" ]; then
                    log_error "Duplicate file detected: $target_file"
                    exit 1
                fi
                mkdir -p $(dirname $target_file)
                cp $source_file $target_file
            done
        fi

        if [ -f "$module_directory/$module_name/post-files.sh" ]; then
            log_info "Executing post-processing script for $module_name"
            . $module_directory/$module_name/post-files.sh
        fi
    done
}

log_info "Validating module availability"
for module_name in $ACTIVE_MODULE_LIST; do
    if [ ! -d "modules/$module_name" ] && [ ! -d "user_modules/$module_name" ]; then
        log_error "Module not found: $module_name"
        exit 1
    fi
done


# 设置构建环境
setup_build_environment

process_module_directory modules
process_module_directory user_modules

log_info "Package collection complete: $PACKAGE_COLLECTION"

log_info ""
ls files -R
log_info ""

make info
cat ./repositories.conf
if [ -z "$PROFILE" ]; then
    make image PACKAGES="$PACKAGE_COLLECTION" FILES="files" -S
else
    make PROFILE="$PROFILE" image PACKAGES="$PACKAGE_COLLECTION" FILES="files" -S
fi
