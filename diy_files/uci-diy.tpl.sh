
uci set system.@system[0].zonename='Asia/Shanghai'
uci set system.@system[0].timezone='CST-8'
uci set system.@system[0].cronloglevel='8'
uci set system.@system[0].conloglevel='7'
uci commit system

uci set luci.main.lang='zh_cn'
uci commit luci

uci set passwall.@global_forwarding[0].udp_no_redir_ports='disable'
uci set passwall.@global_forwarding[0].tcp_no_redir_ports='disable'
uci set passwall.@global_other[0].ipv6_tproxy='1'

uci set passwall.@global_subscribe[0].auto_update_subscribe='1'
uci set passwall.@global_subscribe[0].week_update_subscribe='7'
uci set passwall.@global_subscribe[0].time_update_subscribe='5'

uci add passwall subscribe_list
uci set passwall.@subscribe_list[-1]=subscribe_list
uci set passwall.@subscribe_list[-1].enabled='1'
uci set passwall.@subscribe_list[-1].remark='neo'
uci set passwall.@subscribe_list[-1].url='CUSTOM_PASSWALL_SUBSCRIBE_URL'
uci commit passwall


while uci -q delete openclash.@dns_servers[0]; do :; done
uci add openclash dns_servers
uci set openclash.@dns_servers[-1]=dns_servers
uci set openclash.@dns_servers[-1].group='nameserver'
uci set openclash.@dns_servers[-1].type='udp'
uci set openclash.@dns_servers[-1].enabled='1'
uci set openclash.@dns_servers[-1].ip='127.0.0.1'
uci set openclash.@dns_servers[-1].port='7053'

while uci -q delete openclash.@config_subscribe[0]; do :; done
uci add openclash config_subscribe
uci set openclash.@config_subscribe[-1]=config_subscribe
uci set openclash.@config_subscribe[-1].enabled='1'
uci set openclash.@config_subscribe[-1].address='CUSTOM_CLASH_CONFIG_URL'
uci set openclash.@config_subscribe[-1].sub_convert='0'
uci set openclash.config.ipv6_enable='1'
uci set openclash.config.china_ip6_route='1'
uci set openclash.config.china_ip_route='1'
uci set openclash.config.geo_auto_update='1'
uci set openclash.config.geo_update_day_time='10'
uci set openclash.config.chnr_auto_update='1'
uci set openclash.config.auto_restart='1'
uci set openclash.config.auto_restart_day_time='3'
uci set openclash.config.enable_custom_dns='1'
uci set openclash.config.ipv6_dns='1'
uci set openclash.config.append_wan_dns='0'
uci set openclash.config.disable_udp_quic='0'

uci commit openclash

uci set network.lan.ipaddr='CUSTOM_LAN_IP'
uci commit network

mkdir -p /etc/dnsmasq.d/
echo "conf-dir=/etc/dnsmasq.d/" >> /etc/dnsmasq.conf