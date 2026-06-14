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

### 十一、Docker 构建修复

**问题**：`bin/` 目录从仓库移除后，Dockerfile 仍引用 `COPY bin/...`，Render 部署报 500。

**修改**：
- `Dockerfile` — 改为容器内 `javac` 现场编译 Java 源码，不再依赖预编译 class
- `.dockerignore` — `src/` → `bin/`（Docker 构建需源码）

### 十二、管理员用户列表 API

**新增**：`GET /api/admin/users` — 仅馆主/女仆长可访问，返回全部用户（id/username/nickname/role/avatar/createdAt，不含密码）

**修改**：`UserDAO.java` 新增 `getAllUsers()` 方法

### 十三、离馆跳转 + 移动端适配

**离馆**：`/api/auth/logout` 原来返回 JSON 不跳转，改为 `resp.sendRedirect("/blog")` 直接回大厅。

**移动端**：`scarlet.css` 三层响应式断点

| 断点 | 适配内容 |
|------|----------|
| ≤900px | 侧栏下移、header 纵向、管理表格横向滚动、文章 meta 换行、轮播缩小 |
| ≤600px | 导航紧凑、模态框全宽、分页按钮缩小、评论卡片缩进、裁剪区纵向布局 |
| ≤400px | 超小屏：导航最小化、统计 2 列、认证卡片紧凑、轮播 150px、Logo 缩小、Toast 全宽 |

### 十四、DB 连接恢复

**问题**：改动 6 将 `DB_HOST` 等默认值改为 `localhost`，但 Render 仅有 `DB_PASS` 环境变量，导致连不上 Aiven MySQL。

**修复**：在 Render Dashboard 添加 `DB_HOST` / `DB_PORT` / `DB_NAME` / `DB_USER` 四个环境变量，代码维持无害默认值。

---

## 提交记录

| commit | 内容 |
|--------|------|
| `6a1f106` | 注册自动登录 + 角色分流 + QQ头像裁剪 + 按钮防重复 |
| `acd52f0` | XSS全站防护 + CSRF + 硬编码移除 + Session加固 + 路径穿越 + .gitignore |
| `43ac067` | 验证码升级为随机题库 |
| `c9cb8ca` | Dockerfile 改为构建时编译 Java 源码 |
| `84d5777` | 管理员用户列表 API |
| `d32db6b` | 开发日志 BlogDevelopLog.md |
| `90b2f52` | 管理室拒绝页重做 + 登录/注册角色感知跳转 |
| `9dd8553` | **茶话会聊天系统 + 文章权限开放 + 分类管理** |
| `e516753` | 数据库增量迁移（老数据库自动建新表） |
| `3844841` | 修正验证码东方问答字数提示 |
| `cdea286` | 头像持久化：Base64 存数据库防容器重启丢失 |
| `fe9f945` | 新注册用户自动加入所有公共茶室 |

---

## 2026-06-14 茶话会 + 文章权限 + 分类管理

### 功能总览

| 功能 | 说明 |
|------|------|
| 文章权限开放 | 所有登录用户可创建/编辑文章（编辑限本人或管理员） |
| 分类 CRUD | 管理员在管理室标签页管理分类 |
| 茶话会 | 友人系统 + 私人茶室 + 公共茶室 + 实时消息 |

### 数据库新增表

- `friends` — 友人关系（pending/accepted/rejected）
- `chat_rooms` — 茶室（private/public）
- `chat_room_members` — 茶室成员
- `messages` — 消息记录

### 新增文件

| 文件 | 说明 |
|------|------|
| `src/.../model/Friend.java` | 友人模型 |
| `src/.../model/ChatRoom.java` | 茶室模型 |
| `src/.../model/Message.java` | 消息模型 |
| `src/.../dao/FriendDAO.java` | 友人数据访问 |
| `src/.../dao/ChatDAO.java` | 聊天数据访问 |
| `WebContent/chat.jsp` | 茶话会主页 |
| `WebContent/chat_room.jsp` | 茶室消息页 |

### 新增 API

| 方法 | 路径 | 说明 |
|------|------|------|
| GET/POST/PUT/DELETE | `/api/friends[/:id]` | 友人 CRUD |
| GET/POST | `/api/chat/rooms` | 茶室列表/创建 |
| GET | `/api/chat/rooms/:id` | 茶室详情 |
| GET | `/api/chat/rooms/:id/messages` | 消息列表（支持 ?since= 增量轮询） |
| POST | `/api/chat/messages` | 发送消息 |
| POST/PUT/DELETE | `/api/categories[/:id]` | 分类 CRUD（管理员） |

### 安全/修复

- 头像从文件系统改为 Base64 存数据库（防 Render 容器重启丢失）
- 验证码东方问答字数提示修正（5 题）
- 数据库增量迁移机制（新表按需创建，不影响已有数据）
- 管理室导航链接仅管理员可见
- 新注册用户自动加入所有公共茶室

---

## 未处理项

| 项目 | 原因 |
|------|------|
| 茶话会消息搜索/翻页 | 当前 50 条限制，后续可加 |
| 茶室邀请链接 | 未实现 |
| 离线消息通知 | 需要 WebSocket，当前 AJAX 轮询够用 |
| 内容审核 | 小博客暂不需要 |
