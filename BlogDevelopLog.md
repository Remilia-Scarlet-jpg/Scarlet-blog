# 红魔馆博客 — 开发日志

## 2026-06-14 安全加固 + 体验优化

### 一、注册流程修复

**问题**：新用户注册后跳转到管理室 `/blog/admin` 而非大厅。

**根因**：
1. 注册接口只创建用户，未自动登录（session 无 user 属性）
2. 登录成功后 JS 硬编码跳转 `/blog/admin`，不区分角色

**修改**：
- `BlogServlet.java` — 注册成功后自动入馆：设置 session、返回 `toUserJson`（含 role 字段）
- `login.jsp` / `register.jsp` — JS 按角色跳转：馆主/女仆长 → 管理室，住人 → 大厅

### 二、头像裁剪器（QQ 风格）

**问题**：头像上传只有「选图→直接上传」，无法裁剪/缩放/预览。

**修改**：`profile.jsp` 新增纯 vanilla JS 裁剪模态框
- 圆形蒙版（radial-gradient）+ 金色圆环裁剪区
- 拖拽（mouse/touch）+ 缩放滑块（50%~300%，圆心锚点缩放）
- 80px 圆形实时预览 Canvas
- 确认后 400×400 Canvas 裁剪 → PNG blob → FormData 上传
- 移动端响应式适配（240px 裁剪容器）
- 服务端无需改动

### 三、登录/注册按钮防重复提交

**问题**：async fetch 期间按钮未禁用，快速多次点击导致验证码被消耗、后续请求全部失败。

**修改**：
- `login.jsp` — 点击后 `btn.disabled = true` + 文字变「⏳ 入馆中...」
- `register.jsp` — 同上「⏳ 登记中...」
- 失败/异常时恢复按钮状态
- `showError()` 移除 5 秒自动消失，错误持久显示

### 四、XSS 全站防护

**问题**：所有 JSP 用 `<%= ... %>` 输出用户/数据库内容，无 HTML 转义。攻击者可注入 `<script>` 标签。

**修改**：
- 新增 `HtmlUtil.java` — `escape(s)` HTML 实体转义 + `escapeJs(s)` JS 字符串转义
- `post.jsp` — 标题/作者/标签/评论作者/评论内容全部转义（9 处），博文正文保留 HTML
- `index.jsp` — 标题/摘要/分类/搜索/tag 全部转义（9 处）
- `admin.jsp` — 表格行全部转义；**内联 onclick 改为 data 属性 + 事件委托**（消除 JS 注入面）
- `profile.jsp` — 昵称/用户名/角色全部转义（8 处）

### 五、admin.jsp 内联 JS 注入修复

**问题**：
```jsp
onclick="editPost(<%=id%>, '<%=title.replace("'", "\\'")%>', ...)"
```
只转义了单引号，`\` `"` `<` `>` `</script>` 均未处理，可突破 JS 字符串上下文。

**修改**：改为 data 属性 + 事件委托：
```jsp
<button class="btn-edit-post"
    data-id="<%=id%>"
    data-title="<%=HtmlUtil.escape(title)%>"
    ...>
```
JS 通过 `e.target.closest('.btn-edit-post')` 读取 `dataset` 调用函数。

### 六、硬编码凭证移除

**问题**：`DBUtil.java` 硬编码 Aiven MySQL 主机名 `mysql-scarlet-blog-scarlet-blog.e.aivencloud.com:11400`、用户名 `avnadmin`。

**修改**：
- 默认值改为无害的 `localhost:3306 / scarletblog / scarletblog`
- `DB_PASS` 为空时启动即抛异常（fail-fast），不再静默尝试空密码连接

### 七、CSRF 防护

**问题**：所有 POST/PUT/DELETE API 无 CSRF 保护，登录态下可被跨站伪造请求。

**修改**：
- `BlogServlet.doGet()` — 状态变更 API 验证 `Origin`/`Referer` 头
- Session Cookie 注入 `SameSite=Lax`
- `web.xml` 加 `<http-only>true</http-only>` + `<secure>true</secure>`

### 八、路径穿越修复

**问题**：头像文件名直接拼接用户名，`../` 序列可穿越到任意目录。

**修改**：用户名脱敏 `replaceAll("[^a-zA-Z0-9_\\u4e00-\\u9fff]", "_")`

### 九、其他安全加固

| 项目 | 修改 |
|------|------|
| `/api/health` 端点 | 改为需登录，移除数据库主机名和密码状态泄露 |
| `.gitignore` | 添加 `bin/`，仓库删除全部 12 个编译产物 `.class` |
| `.dockerignore` | 修正 `.auth_migration.sql` → `auth_migration.sql` |

### 十、验证码升级

**问题**：`a + b = ?`（a,b 为 1~10），脚本一行即可破解。

**修改**：改为 20 题随机题库，每次刷新随机抽题

| 类型 | 数量 | 示例 |
|------|------|------|
| 混合运算 | 8 题 | `3 × 7 + 2 = ?` `144 ÷ 12 = ?` |
| 红魔馆/东方问答 | 12 题 | `红魔馆的主人叫什么？` `十六夜咲夜的能力是操纵？` |

验证改为 `equalsIgnoreCase` 不区分大小写。

---

## 提交记录

| commit | 内容 |
|--------|------|
| `6a1f106` | 注册自动登录 + 角色分流 + QQ头像裁剪 + 按钮防重复 |
| `acd52f0` | XSS全站防护 + CSRF + 硬编码移除 + Session加固 + 路径穿越 + .gitignore |
| `43ac067` | 验证码升级为随机题库 |

---

## 未处理项

| 项目 | 原因 |
|------|------|
| Git 历史含演示账号 | `git filter-branch` 风险较高，个人仓库暂不处理 |
| Git author 邮箱（假邮箱） | 无需处理 |
| 验证码升级为图形 CAPTCHA | 当前方案已足够，图形方案需额外依赖 |
