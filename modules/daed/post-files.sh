. ./work_modules/add-feed-base/base.sh

mkdir -p files/etc/opkg/
add_packages "dae"
add_geodata "geodata/Loyalsoldier"

cp files/etc/opkg/keys/* keys