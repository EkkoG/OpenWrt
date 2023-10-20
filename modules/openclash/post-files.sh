mkdir -p files/etc/openclash/config
wget --user-agent='clash' $CLASH_CONFIG_URL -O files/etc/openclash/config/config.yaml

. ./work_modules/add-feed-base/base.sh

mkdir -p files/etc/opkg/
add_packages "clash"

cp files/etc/opkg/keys/* keys