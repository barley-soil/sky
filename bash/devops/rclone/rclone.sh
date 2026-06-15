curl --header "PRIVATE-TOKEN: ${GL_TOKEN}" \
     -L \
     -o ./rclone.conf \
     "https://gitlab.liexiong.net/api/v4/projects/yunzhou%2Fsecret/repository/files/rclone%2Frclone.conf/raw?ref=main"

# 同步「本地」静态资源 →「云上」存储（腾讯COS）
rclone --config ./rclone.conf copy ${CI_PROJECT_DIR} ${P_COS_URL} -P
