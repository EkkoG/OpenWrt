
PACKAGES_ARCH=$(cat .config | grep CONFIG_TARGET_ARCH_PACKAGES | awk -F '=' '{print $2}' | sed 's/"//g')

feed="src/gz nikki https://nikkinikki.pages.dev/openwrt-23.05/$PACKAGES_ARCH/nikki"
mkdir -p files/etc/opkg/
echo "$feed" >> files/etc/opkg/customfeeds.conf
# 添加软件源到第一行
echo "$feed" | cat - ./repositories.conf > temp && mv temp ./repositories.conf

cp files/etc/opkg/keys/* keys

mkdir -p files/etc/nikki/subscriptions
wget --user-agent='clash' $CLASH_CONFIG_URL -O files/etc/nikki/subscriptions/default.yaml
