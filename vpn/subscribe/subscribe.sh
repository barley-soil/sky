#!/bin/sh

# 全局变量: 输入文件路径
FILE_NAME=""

# 全局变量: 输出文件目录
OUTPUT_SS_FILE="./ss"

# 全局变量: 输出文件目录
OUTPUT_CLASH_FILE="./clash"

echo "======================================================"
echo "    AWK 订阅文件转换工具 (高效率版)"
echo "======================================================"

# 提示用户输入文件名
echo "请输入您要处理的 CSV/TXT 文件名："
read -r FILE_NAME

# 检查输入是否为空
if [ -z "$FILE_NAME" ]; then
  echo "未输入文件名，操作取消。" >&2
  exit 1
fi

# 检查文件是否存在
if [ ! -f "$FILE_NAME" ]; then
  echo "错误：文件 $FILE_NAME 不存在。" >&2
  exit 1
fi

# ----------------------------------------------------
# AWK 核心处理逻辑
# ----------------------------------------------------
echo "正在生成配置文件 ..."
(
  awk -F ',' '
{
    # 左右去空 (去除整行前后空格)
    line = $0
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)

    # 如果去空后变空，跳过
    if (line == "") {
        next
    }

    # 跳过注释行
    if (line ~ /^#/) {
        next
    }

    # 将处理后的行重新设置字段 ($0 = line; $1=$1)
    $0 = line

    # 重新设置字段分隔符（保持为逗号）
    # 重新解析字段（这步很关键，确保 $1, $2, $3 是新的）
    split($0, fields, FS)

    f1 = fields[1]
    f2 = fields[2]
    f3 = fields[3]
    f4 = fields[4]
    f5 = fields[5]

    # AWK 内部去空 (去除字段周围的空格，例如 " val1 , val2 ")
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", f1)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", f2)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", f3)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", f4)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", f5)

    # 字段验证：检查 f3 是否存在
    if (f3 == "") {
        # 打印警告到标准错误 (stderr)
        print "警告：跳过行 \047" $0 "\047，数据字段不足三个。" > "/dev/stderr"
        next
    }

    if (f4 == "") {
        f4 = "aes-128-gcm"
    }

    if (f5 == "") {
        f5 = "wvzrAcSja4b2rmdo"
    }

    payload = f4 ":" f5 "@" f3 ":" f2
    command = "echo -n \047" payload "\047 | base64 | tr -d \047\n\047"
    command | getline base64_output
    close(command)

    input_str = $1;
    command = "printf %s " input_str " | jq -sRr @uri";
    command | getline encoded_str;
    close(command)

    printf "ss://%s#%s\n", base64_output, encoded_str
}
' "$FILE_NAME"
) >"$OUTPUT_SS_FILE"

echo "✅  配置文件已成功输出到 $OUTPUT_SS_FILE"

(
  echo "port: 7890"
  echo "socks-port: 7891"
  echo "redir-port: 7892"
  echo "allow-lan: false"
  echo "mode: Rule"
  echo "log-level: info"
  echo "proxies:"
  awk -F ',' '
{
    # 左右去空 (去除整行前后空格)
    line = $0
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)

    # 如果去空后变空，跳过
    if (line == "") {
        next
    }

    # 跳过注释行
    if (line ~ /^#/) {
        next
    }

    # 将处理后的行重新设置字段 ($0 = line; $1=$1)
    $0 = line

    # 重新设置字段分隔符（保持为逗号）
    # 重新解析字段（这步很关键，确保 $1, $2, $3 是新的）
    split($0, fields, FS)

    f1 = fields[1]
    f2 = fields[2]
    f3 = fields[3]
    f4 = fields[4]
    f5 = fields[5]

    # AWK 内部去空 (去除字段周围的空格，例如 " val1 , val2 ")
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", f1)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", f2)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", f3)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", f4)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", f5)

    # 字段验证：检查 f3 是否存在
    if (f3 == "") {
        # 打印警告到标准错误 (stderr)
        print "警告：跳过行 \047" $0 "\047，数据字段不足三个。" > "/dev/stderr"
        next
    }

    if (f4 == "") {
        f4 = "aes-128-gcm"
    }

    if (f5 == "") {
        f5 = "wvzrAcSja4b2rmdo"
    }

    printf "  - name: \"%s\"\n", f1
    printf "    type: ss\n"
    printf "    server: %s\n", f3
    printf "    port: %s\n", f2
    printf "    cipher: %s\n", f4
    printf "    password: \"%s\"\n", f5
    printf "    udp: false\n"
}
' "$FILE_NAME"

  echo "proxy-groups:"
  echo "  - name: \"Proxy\""
  echo "    type: select"
  echo "    proxies: "
  echo "      - \"DIRECT\""

  awk -F ',' '
{
    # 左右去空 (去除整行前后空格)
    line = $0
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)

    # 如果去空后变空，跳过
    if (line == "") {
        next
    }

    # 跳过注释行
    if (line ~ /^#/) {
        next
    }

    # 将处理后的行重新设置字段 ($0 = line; $1=$1)
    $0 = line

    # 重新设置字段分隔符（保持为逗号）
    split($0, fields, FS)

    f1 = fields[1]

    # AWK 内部去空 (去除字段周围的空格，例如 " val1 , val2 ")
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", f1)

    # 字段验证：检查 f1 是否存在
    if (f1 == "") {
        print "警告：跳过行 \047" $0 "\047，数据字段不足三个。" > "/dev/stderr"
        next
    }

    printf "      - \"%s\"\n", f1
}
' "$FILE_NAME"

  echo "rules: "
  echo "  - IP-CIDR,127.0.0.0/8,DIRECT"
  echo "  - IP-CIDR,10.0.0.0/8,DIRECT"
  echo "  - IP-CIDR,172.16.0.0/12,DIRECT"
  echo "  - IP-CIDR,192.168.0.0/16,DIRECT"
  echo "  - IP-CIDR,169.254.0.0/16,DIRECT"
  echo "  - IP-CIDR,100.64.0.0/10,DIRECT"
  echo "  - GEOIP,CN,DIRECT"
  echo "  - MATCH,Proxy"
) >"$OUTPUT_CLASH_FILE"

echo "✅  配置文件已成功输出到 $OUTPUT_CLASH_FILE"

exit 0
