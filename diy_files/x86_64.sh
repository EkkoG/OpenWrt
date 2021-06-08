
uci set overture.@overture[0].VerboseMode='0'
uci set overture.@overture[0].LogToFile='/var/overture.log'
uci commit overture


while uci -q delete clash.@dnsservers[0]; do :; done
uci add clash dnsservers
uci set clash.@dnsservers[-1]=dnsservers
uci set clash.@dnsservers[-1].enabled='1'
uci set clash.@dnsservers[-1].ser_type='nameserver'
uci set clash.@dnsservers[-1].ser_address='127.0.0.1'
uci set clash.@dnsservers[-1].ser_port='7053'
uci set clash.@dnsservers[-1].protocol='udp://'


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

uci commit clash