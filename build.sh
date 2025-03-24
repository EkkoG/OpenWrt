#!/bin/bash -e

default_modules="add-all-device-to-lan add-feed-key add-feed ib argon base opkg-mirror prefer-ipv6-settings statistics system tools"

LOG() {
    # echo when $LOG_ENABLE set to 1
    if [ "$LOG_ENABLE" == "1" ]; then
        echo -e "\033[32m$1\033[0m"
    fi
}

LOG_ERR() {
    if [ "$LOG_ENABLE" == "1" ]; then
        echo -e "\033[31m$1\033[0m"
    fi
}

LOG_DEBUG() {
    if [ "$LOG_ENABLE" == "1" ] && [ "$DEBUG" == "1" ]; then
        echo -e "\033[33m$1\033[0m"
    fi
}

LOG "Default enabled modules: $default_modules"

# Get TARGET_VERSION and IMAGEBUILDER_IMAGE from environment variables
TARGET_VERSION="${TARGET_VERSION:-24.10}" # Default to 24.10 if not set
IMAGEBUILDER_IMAGE="$IMAGEBUILDER_IMAGE"
PACKAGES_FILE="./modules_in_container/base/packages" # Path inside container
VERSION_REGEX="^[0-9]+\.[0-9]+(\.[0-9]+)?$" # Regex for major.minor or major.minor.patch

if [[ ! "$IMAGEBUILDER_IMAGE" =~ ":" ]] || ! [[ "$VERSION_TAG" =~ $VERSION_REGEX ]]; then
    VERSION="23.05.4" # Default version if no colon or tag is not a version number
    echo "Using default VERSION: $VERSION for IMAGEBUILDER_IMAGE: $IMAGEBUILDER_IMAGE"
else
    VERSION="$VERSION_TAG"
    echo "Extracted VERSION: $VERSION from IMAGEBUILDER_IMAGE: $IMAGEBUILDER_IMAGE"
fi

# Function to compare versions (major.minor)
is_version_greater_equal() {
  local version1="$1"
  local version2="$2"

  local major1=$(echo "$version1" | cut -d'.' -f1)
  local minor1=$(echo "$version1" | cut -d'.' -f2)
  local major2=$(echo "$version2" | cut -d'.' -f1)
  local minor2=$(echo "$version2" | cut -d'.' -f2)

  if [ -z "$minor1" ]; then
    minor1=0
  fi
  if [ -z "$minor2" ]; then
    minor2=0
  fi

  if [ "$major1" -gt "$major2" ]; then
    return 0
  elif [ "$major1" -lt "$major2" ]; then
    return 1
  else
    if [ "$minor1" -ge "$minor2" ]; then
      return 0
    else
      return 1
    fi
  fi
}

# Check if the version is >= TARGET_VERSION
if is_version_greater_equal "$VERSION" "$TARGET_VERSION"; then
  echo "Version $VERSION is >= $TARGET_VERSION. Performing replacement in container '$PACKAGES_FILE'..."

  # Check if the packages file exists inside the container
  if [ -f "$PACKAGES_FILE" ]; then
    sed -i 's/luci-i18n-opkg-zh-cn/luci-i18n-package-manager-zh-cn/g' "$PACKAGES_FILE"
    echo "Replacement completed in container '$PACKAGES_FILE'."
  else
    echo "Error: Packages file not found in container '$PACKAGES_FILE'."
  fi
else
  echo "Version $VERSION is < $TARGET_VERSION. No replacement needed in container."
fi

echo "Starting the rest of the build process..."

final_modules=$default_modules
for module in $MODULES; do
    # check if module fisrt char is "-"
    if [ "${module:0:1}" == "-" ]; then
        # remove module from final_modules
        temp="$(echo "$final_modules" | tr ' ' '\n')"
        final_modules=""
        for m in $temp; do
            if [ "$m" != "${module:1}" ]; then
                final_modules="$final_modules $m"
            fi
        done
    else
        # add module to final_modules
        final_modules="$final_modules $module"
    fi
done

final_modules="$(echo "$final_modules" | tr '\n' ' ')"
LOG "Final enabled modules: $final_modules"

cp -r modules_in_container modules
cp -r user_modules_in_container user_modules

all_packages=
# system env by calling env
system_env=""
if [ $USE_SYTEM_ENV ]; then
    system_env="$(env)"
fi

deal() {
    modules_dir=$1

    for module in $final_modules; do
        if [ ! -d "$modules_dir/$module" ]; then
            continue
        fi
        LOG "Processing $module in $modules_dir"

        if [ -f "$modules_dir/$module/packages" ]; then
            all_packages="$all_packages $(cat $modules_dir/$module/packages)"
        fi

        if [ -f "$modules_dir/$module/.env" ]; then
            . $modules_dir/$module/.env
            all_env="$(cat $modules_dir/$module/.env)"
            # merge system env
            all_env="$all_env"$'\n'"$system_env"
        else
            all_env="$system_env"
        fi

        # ensure uci-defaults dir exists
        if [ -d "$modules_dir/$module/files/etc/uci-defaults" ]; then
            for file in $(find "$modules_dir/$module/files/etc/uci-defaults" -type f); do
                echo "$all_env" | while IFS= read -r env; do
                    env_name="$(echo "$env" | cut -d '=' -f 1)"
                    if [ ! -z "$env_name" ]; then
                        env_value="${!env_name}"
                        LOG_DEBUG "Replacing $env_name with $env_value in $file"
                        sed -e "s|\$$env_name|$env_value|g" -i $file
                    fi
                done
            done
        fi

        if [ -d "$modules_dir/$module/files" ]; then
            mkdir -p files
            # cp -r $modules_dir/$module/files/** files/

            # copy files to files dir, exit when destination file exists
            # ignore .DS_Store
            for file in $(find "$modules_dir/$module/files" -type f | grep -v .DS_Store); do
                dest_file="files/${file#$modules_dir/$module/files/}"
                if [ -f "$dest_file" ]; then
                    LOG_ERR "File $dest_file already exists"
                    exit 1
                fi
                mkdir -p $(dirname $dest_file)
                cp $file $dest_file
            done
        fi

        if [ -f "$modules_dir/$module/post-files.sh" ]; then
            LOG "Running post-files.sh for $module"
            . $modules_dir/$module/post-files.sh
        fi
    done
}

LOG "Ensure all modules exist"
for module in $final_modules; do
    if [ ! -d "modules/$module" ] && [ ! -d "user_modules/$module" ]; then
        LOG_ERR "Module $module does not exist"
        exit 1
    fi
done


deal modules
deal user_modules

LOG "All packages will be installed: $all_packages"

LOG ""
ls files -R
LOG ""

make info
cat ./repositories.conf
if [ -z "$PROFILE" ]; then
    make image PACKAGES="$all_packages" FILES="files" -S
else
    make PROFILE="$PROFILE" image PACKAGES="$all_packages" FILES="files" -S
fi
