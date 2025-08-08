#!/bin/bash
# 构建环境设置脚本 - 合并自build-tools模块功能

# 获取架构信息
get_packages_arch() {
    cat .config | grep CONFIG_TARGET_ARCH_PACKAGES | awk -F '=' '{print $2}' | sed 's/"//g'
}

# 添加软件源
add_packages() {
    local feed_type="$1"
    local PACKAGES_ARCH=$(get_packages_arch)
    
    dist_path="$feed_type/$PACKAGES_ARCH"
    if [ "$feed_type" = "luci" ]; then
        dist_path="luci"
    fi
    
    EKKOG_FEED="src/gz ekkog_$feed_type https://ghproxy.imciel.com/https://downloads.sourceforge.net/project/ekko-openwrt-dist/$dist_path"
    mkdir -p files/etc/opkg/
    echo "$EKKOG_FEED" >> files/etc/opkg/customfeeds.conf
    # 添加软件源到第一行
    echo "$EKKOG_FEED" | cat - ./repositories.conf > temp && mv temp ./repositories.conf
}

# 添加地理数据源
add_geodata() {
    local geodata_path="$1"
    FEED_URL="src/gz ekkog_geodata https://ghproxy.imciel.com/https://downloads.sourceforge.net/project/ekko-openwrt-dist/$geodata_path" 
    echo "$FEED_URL" | cat - ./repositories.conf > temp && mv temp ./repositories.conf
    mkdir -p files/etc/opkg/
    echo "$FEED_URL" >> files/etc/opkg/customfeeds.conf
}

# 复制GPG密钥 (来自add-feed-key)
copy_build_keys() {
    if [ -d "setup/keys" ]; then
        # 复制到构建环境的keys目录（供opkg使用）
        cp setup/keys/* keys/ 2>/dev/null || true
        # 复制到files目录（打包到固件中）
        mkdir -p files/etc/opkg/keys
        cp setup/keys/* files/etc/opkg/keys/ 2>/dev/null || true
        log_info "GPG keys copied from setup"
    fi
}

# 应用环境变量配置 (来自ib模块)
apply_config_vars() {
    for config in $(printenv | grep '^CONFIG_'); do
        config_name=$(echo $config | awk -F '=' '{print $1}')
        config_value=$(echo $config | awk -F '=' '{print $2}')
        sed -i "/$config_name/ c\\$config_name=$config_value" .config
    done
}

# 检测项目类型
detect_project() {
    if [[ $PWD =~ "immortalwrt" ]]; then
        echo "immortalwrt"
    else
        echo "openwrt"
    fi
}

# 配置镜像源
configure_mirror() {
    if [ "$USE_MIRROR" = '1' ]; then
        PROJECT_NAME=$(detect_project)
        sed -i 's/https:\/\/downloads.'"$PROJECT_NAME"'.org/https:\/\/'"$MIRROR"'\/'"$PROJECT_NAME"'/g' ./repositories.conf
    fi
}

# 主要构建设置函数
setup_build_environment() {
    log_info "Setting up build environment..."
    
    # 1. 应用配置变量
    apply_config_vars
    
    # 2. 配置镜像源
    configure_mirror
    
    # 3. 复制GPG密钥
    copy_build_keys
    
    # 4. 添加基础软件源 (来自add-feed模块)
    add_packages "luci"
    add_packages "packages"
    
    log_info "Build environment setup complete"
}