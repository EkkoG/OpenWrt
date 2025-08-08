mkdir -p files/etc/openclash/config
if [ -z "$CLASH_CONFIG_URL" ]; then
    echo "CLASH_CONFIG_URL is not set"
    exit 1
fi
wget --user-agent='clash' $CLASH_CONFIG_URL -O files/etc/openclash/config/config.yaml

. ./setup/build-setup.sh

add_packages "mihomo"