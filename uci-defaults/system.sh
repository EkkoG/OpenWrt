
uci batch << EOF

set system.@system[0].zonename='Asia/Shanghai'
set system.@system[0].timezone='CST-8'
set system.@system[0].cronloglevel='8'
set system.@system[0].conloglevel='7'

set luci.main.lang='zh_cn'

commit
EOF