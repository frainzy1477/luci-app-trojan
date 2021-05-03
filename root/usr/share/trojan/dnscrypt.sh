#!/bin/bash /etc/rc.common
. /lib/functions.sh


USE_PROCD=1
CONFIG_DIR=/var/etc
USER=nobody
PROG=/usr/sbin/dnscrypt-proxy

dnscrypt_instance() {
    local config_path="$CONFIG_DIR/dnscrypt-proxy-ns1.conf"
    create_config_file $1 "$config_path"
    $PROG "$config_path" >/dev/null 2>&1 &

}

create_config_file() {

    local address port resolver resolvers_list ephemeral_keys client_key log_level syslog syslog_prefix local_cache query_log_file provider_name provider_key resolver_address
    local config_path="$2"


    [ ! -d "$CONFIG_DIR" ] && mkdir -p "$CONFIG_DIR"
    [ -f "$config_path" ] && rm "$config_path"

    config_get      address         $1 'address'        '127.0.0.1'
    config_get      port            $1 'port'           '8888'
    config_get      resolver        $1 'resolver'       ''
    config_get      provider_name   $1 'providername'   ''
    config_get      provider_key    $1 'providerkey'    ''
    config_get      resolver_address $1 'resolveraddress'    ''
    config_get      resolvers_list  $1 'resolvers_list' '/usr/share/dnscrypt-proxy/dnscrypt-resolvers.csv'
    config_get      client_key      $1 'client_key'     ''
    config_get      syslog_prefix   $1 'syslog_prefix'  'dnscrypt-proxy'
    config_get      query_log_file  $1 'query_log_file' ''
    config_get      log_level       $1 'log_level'      '6'
    config_get      blacklist       $1 'blacklist'      ''
    config_get_bool syslog          $1 'syslog'         '1'
    config_get_bool ephemeral_keys  $1 'ephemeral_keys' '0'
    config_get_bool local_cache     $1 'local_cache'    '0'
    config_get_bool block_ipv6      $1 'block_ipv6'     '0'
 

    append_param_not_empty  "ResolverName"  "$resolver"         $config_path
    append_param            "ResolversList" "$resolvers_list"   $config_path
    append_param_not_empty  "ProviderName"  "$provider_name"    $config_path
    append_param_not_empty  "ProviderKey"   "$provider_key"     $config_path
    append_param_not_empty  "ResolverAddress" "$resolver_address" $config_path
    append_param            "User"          "$USER"             $config_path
    append_param            "LocalAddress"  "$address:$port"    $config_path
    append_param_not_empty  "ClientKey"     "$client_key"       $config_path
    append_on_off           "EphemeralKeys" $ephemeral_keys     $config_path
    append_param            "LogLevel"      "$log_level"        $config_path
    append_on_off           "Syslog"        $syslog             $config_path
    append_param            "SyslogPrefix"  "$syslog_prefix"    $config_path
    append_on_off           "LocalCache"    $local_cache        $config_path
    append_param_not_empty  "QueryLogFile"  "$query_log_file"   $config_path

}


append_on_off() {
    local param_name=$1
    local param_value=$2
    local config_path=$3
    local value

    if [ $param_value -eq 1 ]
    then
        value="on"
    else
        value="off"
    fi

    echo "$param_name $value" >> $config_path
}


append_param() {
    local param_name=$1
    local param_value=$2
    local config_path=$3

    echo "$param_name $param_value" >> $config_path
}

append_param_not_empty() {
    local param_name=$1
    local param_value=$2
    local config_path=$3

    if [ ! -z "$param_value" -a "$param_value" != " " ]
    then
        append_param "$param_name" "$param_value" "$config_path"
    fi
}


dnscrypt_start_service() {
    if [ -n "${dnscrypt_boot}" ]
    then
        return 0
    fi
    config_load trojan
    config_foreach dnscrypt_instance settings
}

dnscrypt_start_service
