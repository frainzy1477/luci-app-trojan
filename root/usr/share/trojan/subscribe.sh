#!/bin/bash /etc/rc.common
. /lib/functions.sh

lang=$(uci get luci.main.lang 2>/dev/null)
server_file="/tmp/server_file.yaml"
single_server="/tmp/single_server.yaml"
REAL_LOG="/usr/share/trojan/readlog.txt"
CFG_FILE="/etc/config/trojan"

name=trojan
subscribe_url=($(uci get $name.@server_subscribe[0].subscribe_url))
[ ${#subscribe_url[@]} -eq 0 ] && exit 1
for ((o=0;o<${#subscribe_url[@]};o++))
do

subscribe_data=$(wget --user-agent="Trojan Client OpenWRT" --no-check-certificate -T 3 -O- ${subscribe_url[o]})

echo $subscribe_data  | base64 -d | sed 's/\r//g' | sed 's/\:\/\//password=/g'| sed 's/\/?/\&/g'  | sed 's/\@/\&server=/g'| sed 's/#/\&remarks=/g'|sed 's/trojan-go//g'|sed '/^$/d' >>$server_file

urldecode(){
  echo -e "$(sed 's/+/ /g;s/%\(..\)/\\x\1/g;')"
}

num=$(grep -c "password=" $server_file 2>/dev/null)
count=1

while [[ "$( grep -c "config servers" $CFG_FILE )" -ne 0 ]]
do
  uci delete trojan.@servers[0] && uci commit trojan >/dev/null 2>&1
done

cfg_get()
{
 echo "$(grep "$1" $2 2>/dev/null |awk -v tag=$1 'BEGIN{FS=tag} {print $2}' 2>/dev/null |sed 's/,.*//' 2>/dev/null |sed 's/^ \{0,\}//g' 2>/dev/null |sed 's/ \{0,\}$//g' 2>/dev/null |sed 's/ \{0,\}\}\{0,\}$//g' 2>/dev/null)"
}

while [[ $count -le $num ]]
do
  sed -n "${count}"p $server_file |sed 's/&/\n/g' >/dev/null  >>$single_server

  server_passwd="$(cfg_get "password=" "$single_server")"

  name="$(cfg_get "remarks=" "$single_server")"

  server="$(cfg_get "server=" "$single_server")"

  port=$(echo "$server" | grep ":" |awk -F ":" '{print $2}')
  servers=$(echo "$server" | grep ":" |awk -F ":" '{print $1}')

  sni="$(cfg_get "sni=" "$single_server")"

  ws_type="$(cfg_get "type=" "$single_server")"

  ws_host="$(cfg_get "host=" "$single_server")"

  ws_path="$(cfg_get "path=" "$single_server")"

  ss="$(cfg_get "encryption=" "$single_server")"

  sever_name=$(echo $name | urldecode )
  if [ $ss ];then
   ss_type=$(echo "$ss" | grep ";" |awk -F ";" '{print $1}' )
   ss_cipher=$(echo "$ss" | grep ";" | awk -F ";" '{print $2}' |  grep ":" |awk -F ":" '{print tolower($1)}')
   ss_pass=$(echo "$ss" | grep ";" |awk -F ":" '{print $2}' )
  fi

  if [ $lang == "en" ] || [ $lang == "auto" ];then
	echo "Now Reading 【Trojan-Go】 - 【$sever_name】 Servers..." >$REAL_LOG
  elif [ $lang == "zh_cn" ];then
	echo "正在读取 【Trojan-Go】 - 【$sever_name】 代理..." >$REAL_LOG
  fi

  name=trojan
  uci_name_tmp=$(uci add $name servers)

  uci_set="uci -q set $name.$uci_name_tmp."
  uci_add="uci -q add_list $name.$uci_name_tmp."

  ${uci_set}name="$sever_name"
  ${uci_set}remote_addr="$servers" >/dev/null 2>&1
  ${uci_set}remote_port="$port" >/dev/null 2>&1
  ${uci_set}password="$server_passwd"  >/dev/null 2>&1
  ${uci_set}sni="$sni" >/dev/null 2>&1
  ${uci_set}fingerprint="firefox" >/dev/null 2>&1

  if [ $ws_type == "ws" ];then >/dev/null 2>&1
    ${uci_set}websocket="true" >/dev/null 2>&1
    ${uci_set}path="$ws_path" >/dev/null 2>&1
    ${uci_set}websocket_host="$ws_host" >/dev/null 2>&1
  fi >/dev/null 2>&1

  if [ $ss ];then  >/dev/null 2>&1
    ${uci_set}shadowdocks="true"  >/dev/null 2>&1
    ${uci_set}cipher="$ss_cipher" >/dev/null 2>&1
    ${uci_set}shadowdocks_passw="$ss_pass" >/dev/null 2>&1
  fi >/dev/null 2>&1

  count=$(( $count + 1))
  uci commit trojan
  rm -rf  $single_server >/dev/null 2>&1
done
rm -rf  $single_server $server_file >/dev/null 2>&1
	sleep 3
	echo "Trojan-GO for OpenWRT" >$REAL_LOG
	exit 0
done
/etc/init.d/trojan restart >/dev/null 2>&1
