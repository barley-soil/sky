/**
 * GitLab Raw 文件流.
 * @param ctx Nginx 上下文.
 */
async function file_content(ctx) {
  // 路径
  const uri = ctx.uri;
  const separator = '/-/';
  const separatorIndex = uri.indexOf(separator);
  if (separatorIndex === -1) {
    ctx.return(404, 'Invalid GitLab URI.');
    return;
  }

  // 项目
  const projectPathWithSlash = uri.substring(0, separatorIndex);
  const projectPath = projectPathWithSlash.substring(1);
  const internalPath = uri.substring(separatorIndex + separator.length);

  const pathSegments = internalPath.split('/');
  if (pathSegments.length < 2) {
    ctx.return(404, 'Invalid GitLab URI.');
    return;
  }

  // 文件分支
  const branchRef = pathSegments[1];
  // 文件路径
  const filePath = pathSegments.slice(2).join('/');

  // 获取文件
  const encodedProjectPath = encodeURIComponent(projectPath);
  const encodedFilePath = encodeURIComponent(filePath);
  const apiURI = `/api/v4/files?file_id=${encodedProjectPath}&file_path=${encodedFilePath}&file_ref=${branchRef}`;

  // 转发
  ctx.internalRedirect(apiURI);
}

export default { file_content };
