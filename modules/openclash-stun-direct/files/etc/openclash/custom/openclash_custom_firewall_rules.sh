#!/bin/sh
. /usr/share/openclash/log.sh
. /lib/functions.sh

# This script is called by /etc/init.d/openclash
# Add your custom firewall rules here, they will be added after the end of the OpenClash iptables rules

LOG_OUT "Tip: Start Add Custom Firewall Rules..."

custom_white_list_nft() {
    nft 'insert rule inet fw4 openclash position 0 tcp dport 3478 counter return'
    nft 'insert rule inet fw4 openclash position 0 udp dport 3478 counter return'
    nft 'insert rule inet fw4 openclash_mangle position 0 tcp dport 3478 counter return'
    nft 'insert rule inet fw4 openclash_mangle position 0 udp dport 3478 counter return'
    nft 'insert rule inet fw4 openclash_output position 0 tcp dport 3478 counter return'
    nft 'insert rule inet fw4 openclash_output position 0 udp dport 3478 counter return'
}

custom_white_list_ipt() {
    iptables -t mangle -I openclash 1 -p tcp --dport 3478 -j RETURN
    iptables -t mangle -I openclash 1 -p udp --dport 3478 -j RETURN
    iptables -t nat -I openclash 1 -p tcp --dport 3478 -j RETURN
    iptables -t nat -I openclash 1 -p udp --dport 3478 -j RETURN
    iptables -t nat -I openclash_output 1 -p tcp --dport 3478 -j RETURN
    iptables -t nat -I openclash_output 1 -p udp --dport 3478 -j RETURN
}

FW4=$(command -v fw4)
if [ -n "$FW4" ]; then
    custom_white_list_nft
else
    custom_white_list_ipt
fi
exit 0