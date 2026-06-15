#!/usr/bin/env bash
# gitlab_backup —
#   Back up all accessible GitLab projects via HTTPS using a personal access token.
# Usage: gitlab_backup -c host=[your gitlab] -token=[your gitlab token]

set -euo pipefail

# # Gitlab 地址
# BASE_URL="https://gitlab.liexiong.net/api/v4"

# # Gitlab 令牌
# TOKEN="glpat-JXsziswXTyzEZhCxoMSJ"

# ===============================
# 获取所有项目列表
function project_list() {
  PAGE=1
  ALL_GROUPS="[]"

  while true; do
    RESPONSE=$(curl -sS --header "PRIVATE-TOKEN: $TOKEN" "$BASE_URL/projects?per_page=100&page=$PAGE")
    ALL_GROUPS=$(jq -s 'add' <<<"$ALL_GROUPS $RESPONSE")
    if [ $(jq 'length' <<<"$RESPONSE") -eq 0 ]; then
      break
    fi
    PAGE=$((PAGE + 1))
  done

  echo "$ALL_GROUPS" | jq .
}

# ===============================
# 获取所有分组
function group_list() {
  PAGE=1
  ALL_GROUPS="[]"

  while true; do
    RESPONSE=$(curl -sS --header "PRIVATE-TOKEN: $TOKEN" "$BASE_URL/groups?per_page=100&page=$PAGE")
    ALL_GROUPS=$(jq -s 'add' <<<"$ALL_GROUPS $RESPONSE")
    if [ $(jq 'length' <<<"$RESPONSE") -eq 0 ]; then
      break
    fi
    PAGE=$((PAGE + 1))
  done

  echo "$ALL_GROUPS" | jq .
}

# ===============================
# 导出数据到CSV
# $1 输出文件名称
# $2 字段列
# $3 JSON 内容
function export_data() {

  # 输出 CSV 头部
  echo ${FIELDS//\"/} | tr -d '[]' >"$1"

  # 使用 jq 解析 JSON 并转换为 CSV
  echo "$3" | jq -r --argjson fields "$2" \
    '.[] | [(.[$fields[]] | tostring | gsub("\n"; " ") | gsub("\r"; " "))] | @csv' >>"$1"


  echo "[仓库索引] CSV 文件已生成并导出：$1"
}

# ===============================
# 导出数据到CSV
# $1 输出文件名称
# $2 字段列
# $3 JSON 内容
function write_repertory_index() {
  echo "[仓库索引] 正在获取仓库组 ..."
  FIELDS='["id","web_url","name","path","description","visibility","share_with_group_lock","require_two_factor_authentication","two_factor_grace_period","project_creation_level","auto_devops_enabled","subgroup_creation_level","emails_disabled","mentions_disabled","lfs_enabled","default_branch_protection","avatar_url","request_access_enabled","full_name","full_path","created_at","parent_id","ldap_cn","ldap_access","wiki_access_level"]'
  export_data "${OUTPUT}group.csv" "$FIELDS" "$(group_list)"

  echo "[仓库索引] 正在获取项目组 ..."
  FIELDS='["id","description","name","name_with_namespace","path","path_with_namespace","created_at","default_branch","tag_list","topics","ssh_url_to_repo","http_url_to_repo","web_url","readme_url","forks_count","avatar_url","star_count","last_activity_at","namespace.id","namespace.name","namespace.path","namespace.kind","namespace.full_path","namespace.parent_id","namespace.avatar_url","namespace.web_url","container_registry_image_prefix","_links.self","_links.issues","_links.merge_requests","_links.repo_branches","_links.labels","_links.events","_links.members","_links.cluster_agents","packages_enabled","empty_repo","archived","visibility","resolve_outdated_diff_discussions","container_expiration_policy.cadence","container_expiration_policy.enabled","container_expiration_policy.keep_n","container_expiration_policy.older_than","container_expiration_policy.name_regex","container_expiration_policy.name_regex_keep","container_expiration_policy.next_run_at","issues_enabled","merge_requests_enabled","wiki_enabled","jobs_enabled","snippets_enabled","container_registry_enabled","service_desk_enabled","service_desk_address","can_create_merge_request_in","issues_access_level","repository_access_level","merge_requests_access_level","forking_access_level","wiki_access_level","builds_access_level","snippets_access_level","pages_access_level","operations_access_level","analytics_access_level","container_registry_access_level","security_and_compliance_access_level","releases_access_level","environments_access_level","feature_flags_access_level","infrastructure_access_level","monitor_access_level","emails_disabled","shared_runners_enabled","group_runners_enabled","lfs_enabled","creator_id","import_url","import_type","import_status","open_issues_count","ci_default_git_depth","ci_forward_deployment_enabled","ci_job_token_scope_enabled","ci_separated_caches","ci_opt_in_jwt","ci_allow_fork_pipelines_to_run_in_parent_project","public_jobs","build_timeout","auto_cancel_pending_pipelines","ci_config_path","shared_with_groups","only_allow_merge_if_pipeline_succeeds","allow_merge_on_skipped_pipeline","restrict_user_defined_variables","request_access_enabled","only_allow_merge_if_all_discussions_are_resolved","remove_source_branch_after_merge","printing_merge_request_link_enabled","merge_method","squash_option","enforce_auth_checks_on_uploads","suggestion_commit_message","merge_commit_template","squash_commit_template","issue_branch_template","auto_devops_enabled","auto_devops_deploy_strategy","autoclose_referenced_issues","repository_storage","keep_latest_artifact","runner_token_expiration_interval","requirements_enabled","requirements_access_level","security_and_compliance_enabled","compliance_frameworks","permissions.project_access","permissions.group_access"]'
  export_data "${OUTPUT}projects.csv" "$FIELDS" "$(project_list)"
}

# ===============================
# 复制代码到本地
# $1 仓库地址
# $2 输出目录
function clone() {
  path="${OUTPUT}${2}"
  # 目录是否存在
  if [ -d "$path" ]; then
    # 目录已存在
    echo "[仓库复制] 跳过执行 ${1}"
  else
    # 复制代码
    git clone --mirror "${1}" "$path"
  fi
}

# ===============================
# 执行主方法
function main() {
  for arg in "$@"; do
    case $arg in
    host=*)
      BASE_URL="${arg#*=}"
      shift
      ;;
    token=*)
      TOKEN="${arg#*=}"
      shift
      ;;
    output=*)
      OUTPUT="${arg#*=}"
      shift
      ;;
    *) ;;
    esac
  done
  if [ -z "$BASE_URL" ]; then
    echo "请配置Gitlab 域名"
    exit 1
  fi
  BASE_URL="https://${BASE_URL}/api/v4"
  if [ -z "$TOKEN" ]; then
    echo "请配置Gitlab 令牌"
    exit 1
  fi
  if [ -z "$OUTPUT" ]; then
    OUTPUT="./"
  fi
  if [ "${OUTPUT: -1}" != "/" ]; then
    OUTPUT="${OUTPUT}/"
  fi
  # 导出索引
  write_repertory_index
  # 执行导出
  FILE="${OUTPUT}projects.csv"
  tail -n +2 "$FILE" | while IFS=, read -r id description name name_with_namespace path path_with_namespace created_at default_branch tag_list topics ssh_url_to_repo end; do
    id=$(echo "$id" | sed 's/^"\(.*\)"$/\1/')
    name=$(echo "$name" | sed 's/^"\(.*\)"$/\1/')
    ssh_url_to_repo=$(echo "$ssh_url_to_repo" | sed 's/^"\(.*\)"$/\1/')
    echo "[仓库复制] ID: $id, Name: $name, SSH: $ssh_url_to_repo"
    clone "$ssh_url_to_repo" "${id}"
  done

  # 压缩文件
    tar -cvf "${OUTPUT}gitlab_code.tar" --exclude="${OUTPUT}gitlab_code.tar" "${OUTPUT}"
}

# ===============================
# 输出帮助
function help() {
  echo "git_backup Gitlab备份 版本: 1.0.1"
  echo "Usage: -c <options>"
  echo "Options:"
  echo "  host    gitlab 域名"
  echo "  token   gitlab Token"
  echo "  output  gitlab 输出路径"
  exit 1
}

# 脚本入口函数
if [ $# -lt 1 ]; then
  help
fi

option=$1

case $option in
"-c")
  echo "[系统] 环境检查中 ..."
  main "$@"
  ;;
*)
  help
  ;;
esac
