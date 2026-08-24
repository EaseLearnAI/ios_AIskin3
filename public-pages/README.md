# 析肤AI公开合规页面

这组页面是无构建步骤、无 JavaScript、无 Cookie、无外部样式依赖的单文件静态 HTML。每个文件都内嵌完整 CSS，可以被单独复制、上传或直接打开：

- `privacy.html` → `/privacy`
- `terms.html` → `/terms`
- `support.html` → `/support`
- `account-deletion.html` → `/account-deletion`

兼容别名：`/privacy-policy` 指向隐私政策，`/terms-of-use` 指向使用条款。

## 本地预览

在项目根目录运行：

```bash
python3 -m http.server 8080 --directory public-pages
```

线上由 Nginx 使用精确路由映射静态文件，避免被 Vue SPA 的 `try_files ... /index.html` 接管。四个 HTML 之间不共享 CSS 或 JavaScript 文件。
