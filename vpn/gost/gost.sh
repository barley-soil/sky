#!/bin/sh

# 全局变量: 输入文件路径
FILE_NAME=""

# 全局变量: 输出文件目录
OUTPUT_FILE="/opt/docker/docker-compose2.yaml"

echo "======================================================"
echo "    AWK 配置转换工具 (高效率版)"
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
mkdir -p /opt/docker
echo "正在生成配置文件 ..."
(
  echo "services:"
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

    # AWK 内部去空 (去除字段周围的空格，例如 " val1 , val2 ")
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", f1)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", f2)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", f3)

    # 字段验证：检查 f3 是否存在
    if (f3 == "") {
        # 打印警告到标准错误 (stderr)
        print "警告：跳过行 \047" $0 "\047，数据字段不足三个。" > "/dev/stderr"
        next
    }

    # 格式化输出 (使用 printf 进行精确 YAML 格式化)
    # 注意：YAML 的缩进需要精确

    # 打印 container_name
    printf "  %s:\n", f1
    printf "    container_name: %s\n", f1
    printf "    image: ginuerzh/gost:2.12\n"
    printf "    network_mode: host\n"
    printf "    restart: always\n"

    # 打印 command 字段
    # 使用 \42 代表双引号 (")，避免在 awk 字符串中嵌套引号的复杂性
    printf "    command: [\42-L=ss://aes-256-gcm:wvzrAcSja4b2rmdo@:%s\42, \42-F=%s\42]\n", f2, f3
}
' "$FILE_NAME"
) >"$OUTPUT_FILE"

echo "✅  配置文件已成功输出到 $OUTPUT_FILE"

exit 0
