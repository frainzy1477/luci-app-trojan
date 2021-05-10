#!/bin/bash /etc/rc.common
. /lib/functions.sh

rule()
{
	   local section="$1"
	   config_get "type" "$section" "type" ""
	   config_get "format" "$section" "format" ""
	   config_get "name" "$section" "name" ""
	   
	   if [ -z "$name" ]; then
		  return
	   fi 
	   
	   if [ "$type" == "bypass" ]; then
			echo "   \"$format:$name\"">>/tmp/rules_bypass.conf
	   elif [ "$type" == "block" ]; then
			echo "   \"$format:$name\"">>/tmp/rules_block.conf	   
	   elif [ "$type" == "proxy" ]; then
			echo "   \"$format:$name\"">>/tmp/rules_proxy.conf	   
	   fi
	
}

config_load trojan
config_foreach rule "rules"

bypass_rule(){
 num=$(grep -c '' /tmp/rules_bypass.conf 2>/dev/null)
 if [ $num ];then
 count_num=1
 while [[ $count_num -le $num ]]
 do 
  line=$(sed -n "$count_num"p /tmp/rules_bypass.conf)
  if [ $count_num == $num ];then
	echo "        $line" >> "/tmp/bypass.conf"
  else
	echo "        $line," >> "/tmp/bypass.conf"
  fi
  count_num=$(( $count_num + 1))	
 done
 else
	echo "" >> "/tmp/bypass.conf"
 fi				
 sed -i "1i\     \"bypass\": [" /tmp/bypass.conf 2>/dev/null
 sed -i -e '$a\     ],' /tmp/bypass.conf  2>/dev/null
}
 
block_rule(){ 
 num=$(grep -c '' /tmp/rules_block.conf 2>/dev/null)
 if [ $num ];then
 count_num=1
 while [[ $count_num -le $num ]]
 do 
  line=$(sed -n "$count_num"p /tmp/rules_block.conf)
  if [ $count_num == $num ];then
	echo "        $line" >> "/tmp/block.conf"
  else
	echo "        $line," >> "/tmp/block.conf"
  fi
  count_num=$(( $count_num + 1))	
 done
 else
	echo "" >> "/tmp/block.conf"
 fi
 sed -i "1i\     \"block\": [" /tmp/block.conf 2>/dev/null
 sed -i -e '$a\     ],' /tmp/block.conf  2>/dev/null
}

proxy_rule(){
 num=$(grep -c '' /tmp/rules_proxy.conf 2>/dev/null)
 if [ $num ];then
 count_num=1
 while [[ $count_num -le $num ]]
 do 
  line=$(sed -n "$count_num"p /tmp/rules_proxy.conf)
  if [ $count_num == $num ];then
	echo "        $line" >> "/tmp/proxy.conf"
  else
	echo "        $line," >> "/tmp/proxy.conf"
  fi
  count_num=$(( $count_num + 1)) 	
 done 
 else
	echo "" >> "/tmp/proxy.conf"
 fi
 sed -i "1i\     \"proxy\": [" /tmp/proxy.conf 2>/dev/null
 sed -i -e '$a\     ],' /tmp/proxy.conf  2>/dev/null
} 
 
bypass_rule && block_rule && proxy_rule
 
cat /tmp/bypass.conf /tmp/block.conf >> /tmp/rules
cat /tmp/rules /tmp/proxy.conf >> /tmp/rules.json

sed -i "1i\   \"router\":{" /tmp/rules.json 2>/dev/null  
sed -i "2i\     \"enabled\": $(uci get trojan.@global[0].router)," /tmp/rules.json 2>/dev/null 
sed -i -e '$a\     \"default_policy\": \"proxy\",' /tmp/rules.json
sed -i -e '$a\     \"domain_strategy\": \"ip_if_non_match\",' /tmp/rules.json
sed -i -e '$a\     \"geoip\": \"/usr/bin/geoip.dat\",' /tmp/rules.json
sed -i -e '$a\     \"geosite\": \"/usr/bin/geosite.dat\"' /tmp/rules.json
sed -i -e '$a\   },' /tmp/rules.json
 #sed -i -e '$a\}' /tmp/rules.json
rm -rf /tmp/rules_proxy.conf /tmp/rules_block.conf  /tmp/rules_bypass.conf /tmp/bypass.conf /tmp/rules \
/tmp/proxy.conf /tmp/block.conf /tmp/bypass.conf
 