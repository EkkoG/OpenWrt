uci set network.lan.ipaddr='CUSTOM_LAN_IP'
uci set network.wan.proto='pppoe'
uci set network.wan.username='CUSTOM_PPPOE_USERNAME'
uci set network.wan.password='CUSTOM_PPPOE_PASSWORD'
uci commit network


while uci -q delete clash.@dnsservers[0]; do :; done
uci add clash dnsservers
uci set clash.@dnsservers[-1]=dnsservers
uci set clash.@dnsservers[-1].enabled='1'
uci set clash.@dnsservers[-1].ser_type='nameserver'
uci set clash.@dnsservers[-1].ser_address='114.114.114.114'
uci set  clash.@dnsservers[-1].protocol='udp://''

uci add clash dnsservers
uci set clash.@dnsservers[-1]=dnsservers
uci set clash.@dnsservers[-1].enabled='1'
uci set clash.@dnsservers[-1].ser_type='nameserver'
uci set clash.@dnsservers[-1].ser_address='223.5.5.5.5'
uci set  clash.@dnsservers[-1].protocol='udp://''

uci add clash dnsservers
uci set clash.@dnsservers[-1]=dnsservers
uci set clash.@dnsservers[-1].enabled='1'
uci set clash.@dnsservers[-1].ser_type='nameserver'
uci set clash.@dnsservers[-1].ser_address='119.29.29.29'
uci set  clash.@dnsservers[-1].protocol='udp://''

uci add clash dnsservers
uci set clash.@dnsservers[-1]=dnsservers
uci set clash.@dnsservers[-1].enabled='1'
uci set clash.@dnsservers[-1].ser_type='nameserver'
uci set clash.@dnsservers[-1].ser_address='8.8.8.8'
uci set  clash.@dnsservers[-1].protocol='udp://''

uci add clash dnsservers
uci set clash.@dnsservers[-1]=dnsservers
uci set clash.@dnsservers[-1].enabled='1'
uci set clash.@dnsservers[-1].ser_type='nameserver'
uci set clash.@dnsservers[-1].ser_address='1.1.1.1'
uci set  clash.@dnsservers[-1].protocol='udp://''

uci add clash dnsservers
uci set clash.@dnsservers[-1]=dnsservers
uci set clash.@dnsservers[-1].enabled='1'
uci set clash.@dnsservers[-1].ser_type='nameserver'
uci set clash.@dnsservers[-1].ser_address='1.2.4.8'
uci set  clash.@dnsservers[-1].protocol='udp://''

uci add clash dnsservers
uci set clash.@dnsservers[-1]=dnsservers
uci set clash.@dnsservers[-1].enabled='1'
uci set clash.@dnsservers[-1].ser_type='fallback'
uci set clash.@dnsservers[-1].ser_address='114.114.115.115'
uci set  clash.@dnsservers[-1].protocol='udp://''

uci add clash dnsservers
uci set clash.@dnsservers[-1]=dnsservers
uci set clash.@dnsservers[-1].enabled='1'
uci set clash.@dnsservers[-1].ser_type='fallback'
uci set clash.@dnsservers[-1].ser_address='223.6.6.6'
uci set  clash.@dnsservers[-1].protocol='udp://''

uci add clash dnsservers
uci set clash.@dnsservers[-1]=dnsservers
uci set clash.@dnsservers[-1].enabled='1'
uci set clash.@dnsservers[-1].ser_type='fallback'
uci set clash.@dnsservers[-1].ser_address='182.254.116.116'
uci set  clash.@dnsservers[-1].protocol='udp://''

uci add clash dnsservers
uci set clash.@dnsservers[-1]=dnsservers
uci set clash.@dnsservers[-1].enabled='1'
uci set clash.@dnsservers[-1].ser_type='fallback'
uci set clash.@dnsservers[-1].ser_address='1.1.1.1'
uci set  clash.@dnsservers[-1].protocol='tcp://''

uci add clash addtype
uci set clash.@addtype[-1]=addtype
uci set clash.@addtype[-1].type='SRC-IP-CIDR'
uci set clash.@addtype[-1].pgroup='DIRECT'
uci set clash.@addtype[-1].ipaaddr='::211:32ff:fe88:b001/-64'

uci add clash addtype
uci set clash.@addtype[-1]=addtype
uci set clash.@addtype[-1].type='SRC-IP-CIDR'
uci set clash.@addtype[-1].pgroup='DIRECT'
uci set clash.@addtype[-1].ipaaddr='::cd5/-112'

uci set clash.config.clash_url='CUSTOM_CLASH_CONFIG_URL'
uci set clash.config.config_name='config'
uci set clash.config.enable_ipv6='true'
uci set clash.config.enhanced_mode='redir-host'

uci set clash.config.auto_clear_log='1'
uci set clash.config.clear_time='12'

uci set clash.config.auto_update='1'
uci set clash.config.auto_update_time='12'

uci set clash.config.auto_update_geoip='1'
uci set clash.config.auto_update_geoip_time='3'
uci set clash.config.geoip_source='2'
uci set clash.config.geoip_update_day='1'
uci set clash.config.append_rules='1'
uci uci commit clash

uci set system.@system[0].zonename='Asia/Shanghai'
uci set system.@system[0].timezone='CST-8'
system.@system[0].cronloglevel='8'
system.@system[0].conloglevel='7'
uci commit system

uci set luci.main.lang='zh_cn'
uci commit luci