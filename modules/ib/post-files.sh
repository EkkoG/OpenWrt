for config in $(printenv | grep '^CONFIG_'); do
    config_name=$(echo $config | awk -F '=' '{print $1}')
    config_value=$(echo $config | awk -F '=' '{print $2}')
    sed -i "/$config_name/ c\\$config_name=$config_value" .config
done

if [ $USE_MIRROR = '1' ]; then
    sed -i 's/https:\/\/downloads.'"$PROJECT_NAME"'.org/https:\/\/mirrors.pku.edu.cn\/'"$PROJECT_NAME"'/g' ./repositories.conf
fi