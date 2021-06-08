
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

uci set network.lan.ipaddr='CUSTOM_LAN_IP'
uci commit network