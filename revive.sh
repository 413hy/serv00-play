#!/bin/bash

AUTOUPDATE=${AUTOUPDATE:-Y}
SENDTYPE=${SENDTYPE:-null}
TELEGRAM_TOKEN=${TELEGRAM_TOKEN:-null}
TELEGRAM_USERID=${TELEGRAM_USERID:-null}
WXSENDKEY=${WXSENDKEY:-null}
BUTTON_URL=${BUTTON_URL:-null}
LOGININFO=${LOGININFO:-N}
export TELEGRAM_TOKEN TELEGRAM_USERID BUTTON_URL


# 使用 jq 提取 JSON 数组，并将其加载为 Bash 数组
hosts_info=($(echo "${HOSTS_JSON}" | jq -c ".info[]"))
summary=""

for info in "${hosts_info[@]}"; do
  user=$(echo "$info" | jq -r ".username")
  host=$(echo "$info" | jq -r ".host")
  port=$(echo "$info" | jq -r ".port")
  pass=$(echo "$info" | jq -r ".password")

  # 选择脚本参数
  if [[ "$AUTOUPDATE" == "Y" ]]; then
    update_mode="autoupdate"
  else
    update_mode="noupdate"
  fi

  # SSH 远程执行命令
  output=$(sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$host" \
    "/home/$user/serv00-play/keepalive.sh $update_mode \"$SENDTYPE\" \"$TELEGRAM_TOKEN\" \"$TELEGRAM_USERID\" \"$WXSENDKEY\" \"$BUTTON_URL\" \"$pass\"")

  echo "output: $output"

  # 检查 SSH 登录和脚本执行是否成功
  if [[ "$output" == *"keepalive.sh"* ]]; then
    echo "登录成功"
    msg="🟢主机 ${host}, 用户 ${user}，\n
    🎉（keepalive）登录成功!\n"
  else
    echo "登录失败"
    msg="🔴主机 ${host}, 用户 ${user}， 登录失败!\n"
    chmod +x ./tgsend.sh
    export PASS=$pass
    ./tgsend.sh "Host:$host, user:$user, 登录失败，请检查!"
  fi

  summary=$summary$(echo -n "$msg")
done

if [[ "$LOGININFO" == "Y" ]]; then
  chmod +x ./tgsend.sh
  ./tgsend.sh "$summary"
fi
