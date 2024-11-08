
PACKAGES_ARCH=$(cat .config | grep CONFIG_TARGET_ARCH_PACKAGES | awk -F '=' '{print $2}' | sed 's/"//g')

feed="src/gz morytyann_mihomo https://mirror.ghproxy.com/https://github.com/morytyann/OpenWrt-mihomo/blob/gh-pages/$PACKAGES_ARCH/mihomo"
mkdir -p files/etc/opkg/
echo "$feed" >> files/etc/opkg/customfeeds.conf
# 添加软件源到第一行
echo "$feed" | cat - ./repositories.conf > temp && mv temp ./repositories.conf

cp files/etc/opkg/keys/* keys

wget --user-agent='clash' $CLASH_CONFIG_URL -O files/etc/mihomo/subscriptions/default.yaml