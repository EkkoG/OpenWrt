uci set network.lan.ipaddr='CUSTOM_LAN_IP'
uci set network.wan.proto='pppoe'
uci set network.wan.username='CUSTOM_PPPOE_USERNAME'
uci set network.wan.password='CUSTOM_PPPOE_PASSWORD'
uci commit network

uci add smartdns server
uci set smartdns.@server[-1]=server
uci set smartdns.@server[-1].enabled='1'
uci set smartdns.@server[-1].type='udp'
uci set smartdns.@server[-1].blacklist_ip='0'
uci set smartdns.@server[-1].ip='114.114.114.114'
uci add smartdns server
uci smartdns.@server[-1]=server
uci set smartdns.@server[-1].enabled='1'
uci set smartdns.@server[-1].type='udp'
uci set smartdns.@server[-1].blacklist_ip='0'
uci set smartdns.@server[-1].ip='223.5.5.5'
uci add smartdns server
uci smartdns.@server[-1]=server
uci set smartdns.@server[-1].enabled='1'
uci set smartdns.@server[-1].type='udp'
uci set smartdns.@server[-1].blacklist_ip='0'
uci set smartdns.@server[-1].ip='1.1.1.1'
uci add smartdns server
uci smartdns.@server[-1]=server
uci set smartdns.@server[-1].enabled='1'
uci set smartdns.@server[-1].type='https'
uci set smartdns.@server[-1].blacklist_ip='0'
uci set smartdns.@server[-1].no_check_certificate='0'
uci set smartdns.@server[-1].ip='1.1.1.1/dns-query'
uci add smartdns server
uci smartdns.@server[-1]=server
uci set smartdns.@server[-1].enabled='1'
uci set smartdns.@server[-1].type='udp'
uci set smartdns.@server[-1].blacklist_ip='0'
uci set smartdns.@server[-1].ip='8.8.8.8'
uci add smartdns server
uci smartdns.@server[-1]=server
uci set smartdns.@server[-1].enabled='1'
uci set smartdns.@server[-1].type='tls'
uci set smartdns.@server[-1].blacklist_ip='0'
uci set smartdns.@server[-1].no_check_certificate='0'
uci set smartdns.@server[-1].ip='dns.google'
uci add smartdns server
uci smartdns.@server[-1]=server
uci set smartdns.@server[-1].enabled='1'
uci set smartdns.@server[-1].type='https'
uci set smartdns.@server[-1].blacklist_ip='0'
uci set smartdns.@server[-1].no_check_certificate='0'
uci set smartdns.@server[-1].ip='dns.google/dns-query'
uci add smartdns server
uci smartdns.@server[-1]=server
uci set smartdns.@server[-1].enabled='1'
uci set smartdns.@server[-1].type='https'
uci set smartdns.@server[-1].blacklist_ip='0'
uci set smartdns.@server[-1].no_check_certificate='0'
uci set smartdns.@server[-1].ip='cloudflare-dns.com/dns-query'
uci add smartdns server
uci smartdns.@server[-1]=server
uci set smartdns.@server[-1].enabled='1'
uci set smartdns.@server[-1].type='udp'
uci set smartdns.@server[-1].blacklist_ip='0'
uci set smartdns.@server[-1].ip='119.29.29.29'
uci set smartdns.@smartdns[0].prefetch_domain='1'
uci set smartdns.@smartdns[0].ipv6_server='1'
uci set smartdns.@smartdns[0].tcp_server='1'
uci set smartdns.@smartdns[0].enabled='1'
uci set smartdns.@smartdns[0].dualstack_ip_selection='1'
uci uci commit smartdns

uci add openclash config_subscribe
uci set openclash.@config_subscribe[-1]=config_subscribe
uci set openclash.@config_subscribe[-1].enabled='1'
uci set openclash.@config_subscribe[-1].address='CUSTOM_CLASH_CONFIG_URL'
uci set openclash.@config_subscribe[-1].sub_convert='0'
uci set openclash.config.auto_update='1'
uci set openclash.config.config_auto_update_mode='0'
uci set openclash.config.config_update_week_time='*'
uci set openclash.config.auto_update_time='5'
uci set openclash.config.core_version='linux-amd64'
uci set openclash.config.ipv6_enable='1'
uci set openclash.config.log_level='info'

while uci -q delete openclash.@dns_servers[0]; do :; done
uci add openclash dns_servers
uci set openclash.@dns_servers[-1]=dns_servers
uci set openclash.@dns_servers[-1].enabled='1'
uci set openclash.@dns_servers[-1].group='nameserver'
uci set openclash.@dns_servers[-1].type='udp'
uci set openclash.@dns_servers[-1].ip='127.0.0.1'
uci set openclash.@dns_servers[-1].port='6053'
uci set openclash.config.geo_auto_update='1'
uci set openclash.config.enable_custom_dns='1'
uci uci commit openclash

uci set system.@system[0].zonename='Asia/Shanghai'
uci set system.@system[0].timezone='CST-8'
uci commit system
