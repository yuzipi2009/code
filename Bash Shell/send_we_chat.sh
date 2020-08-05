#!/usr/bin/env bash
#!/bin/bash

user="YuXiao jonathan JingYiXiuShen guoqingzhong haiboli john prhunter WoJiaNaKouGuoNe vanessa jennyjiao ZhengYu zhangyu LuRenJia-walker"
#user="YuXiao"
corpid="ww2ca368b239e13444"
corpsecret="qQ07nic1XatXtwpQhrOsylNgZIq9GQyX-BRaFxLBiNg"
agentld=1000002


msg=$1
A=`curl -s https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=$corpid\&corpsecret=$corpsecret`
token=`echo $A | jq -c '.access_token'`
token=${token#*\"}
token=${token%*\"}
URL="https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=$token"


for I in $user;do
	JSON="{\"touser\": \"$I\",\"msgtype\": \"text\",\"agentid\": \"$agentld\",\"text\": {\"content\": \"$msg\"},\"safe\":0 }"
	curl -d "$JSON" "$URL"
done