#!/bin/bash -e

default_modules="add-feed ib argon base network opkg-mirror prefer-ipv6-settings statistics system tools"

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
cp -r modules work_modules
ls work_modules

for module in $final_modules; do

    if [ -f "work_modules/$module/packages" ]; then
        all_packages="$all_packages $(cat work_modules/$module/packages)"
    fi

    if [ -f "work_modules/$module/.env" ]; then
        echo "Running envsubst for $module"
        mv work_modules/$module/.env work_modules/$module/.env.tmp
        # add export to .env, every line
        sed -i 's/^/export /' work_modules/$module/.env.tmp
        . work_modules/$module/.env.tmp
        # envsubst
        for file in $(find "work_modules/$module/files/etc/uci-defaults" -type f); do
            envsubst < $file | sed -e 's/§/$/g' > $file.tmp
            mv $file.tmp $file
        done
    fi

    if [ -d "work_modules/$module/files" ]; then
        mkdir -p files
        cp -r work_modules/$module/files/** files/
    fi

    if [ -f "work_modules/$module/post-files.sh" ]; then
        echo "Running post-files.sh for $module"
        . work_modules/$module/post-files.sh
    fi
done

echo "All packages: $all_packages"

make info
cat ./repositories.conf
if [ -z "$PROFILE" ]; then
    make image PACKAGES="$all_packages" FILES="files"
else
    make PROFILE="$PROFILE" image PACKAGES="$all_packages" FILES="files"
fi