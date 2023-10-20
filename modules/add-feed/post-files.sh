. ./work_modules/add-feed-base/base.sh

mkdir -p files/etc/opkg/

add_packages "luci"
add_packages "packages"

cp files/etc/opkg/keys/* keys