uci batch << EOF
set network.wan.proto='pppoe'
set network.wan.username='PPPOE_USERNAME'
set network.wan.password='PPPOE_PASSWORD'

set network.lan.ipaddr='LAN_IP'

commit
EOF