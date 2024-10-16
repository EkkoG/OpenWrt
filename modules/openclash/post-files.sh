mkdir -p files/etc/openclash/config
wget --user-agent='clash' $CLASH_CONFIG_URL -O files/etc/openclash/config/config.yaml

. ./modules/add-feed-base/base.sh

add_packages "mihomo"