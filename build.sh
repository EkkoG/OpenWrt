#!/bin/bash -e

default_modules="add-all-device-to-lan add-feed-key add-feed ib argon base opkg-mirror prefer-ipv6-settings statistics system tools"

LOG() {
    # echo when $LOG_ENABLE is not set or set to 1
    if [ -z "$LOG_ENABLE" ] || [ "$LOG_ENABLE" == "1" ]; then
        echo -e "\033[32m$1\033[0m"
    fi
    
}

echo "Default modules: $default_modules"

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
echo "Final modules: $final_modules"

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
                    echo "env_name: $env_name"
                    if [ ! -z "$env_name" ]; then
                        env_value="${!env_name}"
                        LOG "Replacing $env_name with $env_value in $file"
                        sed -e "s|\$$env_name|$env_value|g" -i $file
                    fi
                done
            done
        fi

        if [ -d "$modules_dir/$module/files" ]; then
            mkdir -p files
            cp -r $modules_dir/$module/files/** files/
        fi

        if [ -f "$modules_dir/$module/post-files.sh" ]; then
            echo "Running post-files.sh for $module"
            . $modules_dir/$module/post-files.sh
        fi
    done
}

echo "Checking module existence..."
for module in $final_modules; do
    echo "$module"

    if [ ! -d "modules/$module" ]; then
        if [ ! -d "user_modules/$module" ]; then
            echo "Module $module does not exist"
            exit 1
        fi
    fi
done


deal modules
deal user_modules

echo "All packages: $all_packages"

echo ""
ls files -R
echo ""

make info
cat ./repositories.conf
if [ -z "$PROFILE" ]; then
    make image PACKAGES="$all_packages" FILES="files"
else
    make PROFILE="$PROFILE" image PACKAGES="$all_packages" FILES="files"
fi
