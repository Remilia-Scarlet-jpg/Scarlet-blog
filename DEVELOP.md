# 红魔馆博客 — 开发文档

> 东方 Project 红魔馆主题个人博客系统  
> Java Servlet + JSP + MySQL / Tomcat 9 + Aiven MySQL  
> 线上：https://scarlet-blog.onrender.com

---

## 1. 项目结构

```
myblog-src/
├── src/com/scarletblog/
│   ├── model/          # 数据模型
│   │   ├── User.java
│   │   ├── Post.java
│   │   ├── Comment.java
│   │   ├── Category.java
│   │   ├── CarouselSlide.java
│   │   ├── Friend.java
│   │   ├── ChatRoom.java
│   │   └── Message.java
│   ├── dao/            # 数据访问层
│   │   ├── UserDAO.java
│   │   ├── PostDAO.java
│   │   ├── CategoryDAO.java
│   │   ├── CarouselDAO.java
│   │   ├── FriendDAO.java
│   │   └── ChatDAO.java
│   ├── servlet/        # 控制器（单 Servlet）
│   │   └── BlogServlet.java
│   └── util/           # 工具类
│       ├── DBUtil.java     # 连接池 + 自动建表/迁移
│       ├── SecurityUtil.java  # PBKDF2 密码 + 登录限流
│       └── HtmlUtil.java     # HTML 转义
├── WebContent/
│   ├── *.jsp           # 页面
│   ├── css/scarlet.css # 全局样式
│   └── js/api.js       # 前端 API 客户端
└── DEVELOP.md          # 本文档
```

## 2. 技术栈

| 层 | 技术 |
|------|------|
| 后端 | Java Servlet 4.0 + JSP 2.3 |
| 数据库 | MySQL 8 (本地) / Aiven MySQL (云端) |
| 连接池 | Tomcat JDBC Pool (maxActive=20, minIdle=3) |
| 安全 | PBKDF2-SHA256 (12万次迭代) + Session + CSRF + XSS 转义 |
| 前端 | 原生 JS + CSS，无框架 |
| 部署 | Tomcat 9 (本地) / Docker tomcat:9.0-jdk21 (Render) |

## 3. 数据库表

| 表 | 说明 | 关键列 |
|------|------|------|
| `users` | 用户 | username, password(HASH), nickname, avatar(MEDIUMTEXT), background(MEDIUMTEXT), role |
| `posts` | 文章 | title, content, excerpt, author, category_id, view_count |
| `categories` | 分类 | name, description, icon |
| `comments` | 评论 | post_id, author, content |
| `friends` | 好友 | user_id, friend_id, status(pending/accepted) |
| `chat_rooms` | 茶室 | name, type(public/private), created_by |
| `chat_room_members` | 茶室成员 | room_id, user_id |
| `messages` | 消息 | room_id, sender_id, content |
| `carousel_slides` | 轮播图 | type(image/video), image_path, video_url, poster, sort_order |

**迁移策略**：`DBUtil.initDatabase()` 首次启动全量建表 + 种子数据；后续通过 `else` 分支增量 `ALTER TABLE` 添加新列，不丢数据。

## 4. 角色权限

| 角色 | 权限 |
|------|------|
| 馆主 (remilia) | 全部权限：管理文章/分类/轮播图/用户/任命管理员 |
| 女仆长 (sakuya) | 管理员：文章/分类/轮播图 CRUD，查看用户列表 |
| 住人 (默认) | 发布文章、评论、茶话会、个人主页编辑 |

`User.isAdmin()` = `"馆主".equals(role) || "女仆长".equals(role)`

## 5. API 路由一览

### 认证 `/api/auth/`
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/auth/login` | 登录（含验证码 + 限流） |
| POST | `/api/auth/register` | 注册 |
| GET | `/api/auth/me` | 当前用户信息 |
| POST | `/api/auth/profile` | 更新资料（昵称/头像/背景图） |
| POST | `/api/auth/password` | 修改密码 |
| GET | `/api/auth/captcha` | 获取验证码 |
| POST | `/api/auth/forgot-password` | 忘记密码步骤1：验证用户名 |
| POST | `/api/auth/reset-password` | 忘记密码步骤2：验证昵称+重置密码 |
| GET | `/api/auth/logout` | 登出 |

### 文章 `/api/posts`
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/posts` | 文章列表（分页/搜索/分类筛选） |
| GET | `/api/posts/:id` | 文章详情 |
| POST | `/api/posts` | 新建文章 |
| PUT | `/api/posts/:id` | 编辑文章 |
| DELETE | `/api/posts/:id` | 删除文章（仅管理员） |

### 管理 `/api/admin/`
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/admin/users` | 用户列表（管理员） |
| PUT | `/api/admin/users/:id/role` | 任命/解除管理员（仅馆主） |
| GET/POST/PUT/DELETE | `/api/admin/carousel` | 轮播图 CRUD |
| PUT | `/api/admin/carousel/:id/sort` | 轮播图排序 |

### 其他
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/categories` | 分类列表 |
| GET | `/api/comments?post_id=` | 评论列表 |
| GET | `/api/stats` | 网站统计 |
| GET | `/api/users/:id` | 用户主页 JSON |
| GET/POST | `/api/friends` | 好友系统 |
| GET/POST | `/api/chat` | 茶话会聊天 |

## 6. 页面路由

| URL | 页面 | 说明 |
|------|------|------|
| `/blog` | index.jsp | 首页（轮播+文章列表） |
| `/blog/post?id=` | post.jsp | 文章详情 |
| `/blog/user?id=` | user.jsp | B站风格个人主页 |
| `/blog/profile` | → `/blog/user` | 302 重定向 |
| `/blog/login` | login.jsp | 登录 |
| `/blog/forgot-password` | forgot-password.jsp | 找回密码（用户名→昵称验证→重置） |
| `/blog/register` | register.jsp | 注册 |
| `/blog/admin` | admin.jsp | 管理室（文章/分类/轮播图/用户） |
| `/blog/chat` | chat.jsp | 茶话会大厅 |
| `/blog/chat/room?id=` | chat_room.jsp | 茶室 |

## 7. 功能演进

### v1 — 基础博客 (6/12)
- 文章 CRUD、分类、评论、用户注册/登录
- PBKDF2 密码、Session 管理
- 深红哥特主题 CSS

### v2 — 社交功能 (6/14)
- 茶话会聊天系统（友人 + 私人/公共茶室 + AJAX 4s 轮询）
- 实时通知徽标
- 连接池（Tomcat JDBC Pool）
- 增量数据库迁移

### v3 — 个人主页 + 轮播图 (6/15~16)
- user.jsp B站风格主页
- 头像 Base64 裁剪上传
- 轮播图数据库驱动 CRUD（图片+视频）
- Dockerfile + Aiven MySQL 部署

### v4 — 管理员任命 + 背景图 + B站布局 + QQ邮箱验证 (6/18)
- 馆主任命/解除女仆长
- 个人主页背景图（长方形裁剪器 1200×400）
- 轮播统一海报模式 + 灯箱/视频弹窗
- 个人主页 B 站三区域重构（全宽 Banner + 头像重叠 + 双栏）
- 忘记密码双选项（昵称验证 / QQ邮箱验证）
- 注册可选填邮箱 → 自动发验证邮件
- 个人主页邮箱绑定/解绑/更换
- 邮箱验证落地页
- 双模式发邮件：本地 QQ SMTP / 云端 Resend HTTP API
- 依赖：javax.mail-1.6.2.jar + jakarta.activation-1.2.2.jar

## 8. 本地编译部署（不用 IDE）

```bash
# === 1. 编译 Java ===
cd "C:\Users\dxy28\Desktop\Desktop\myblog-src"
javac -cp "C:\Users\dxy28\tools\tomcat9\lib\servlet-api.jar;\
C:\Users\dxy28\tools\tomcat9\lib\tomcat-jdbc.jar;\
WebContent\WEB-INF\lib\mysql-connector-j-9.3.0.jar;bin" \
  -d bin \
  src/com/scarletblog/model/*.java \
  src/com/scarletblog/dao/*.java \
  src/com/scarletblog/servlet/*.java \
  src/com/scarletblog/util/*.java

# === 2. 部署到 Tomcat ===
cp -r bin/com "C:\Users\dxy28\tools\tomcat9\webapps\myblog\WEB-INF\classes\"
cp -r WebContent/* "C:\Users\dxy28\tools\tomcat9\webapps\myblog\"

# === 3. 重启 Tomcat ===
"C:\Users\dxy28\tools\tomcat9\bin\shutdown.bat"
"C:\Users\dxy28\tools\tomcat9\bin\startup.bat"
```

> 💡 只改 JSP/CSS → 只需步骤 2+3（跳过编译）  
> 💡 改 Java → 必须全部 3 步

## 9. 邮件配置

| 环境 | 方式 | 配置变量 |
|------|------|---------|
| 本地 | QQ SMTP | `MAIL_USERNAME`=QQ邮箱, `MAIL_PASSWORD`=QQ授权码, `SITE_URL`=http://IP:8080/myblog |
| 云端 | Resend HTTP API | `MAIL_PROVIDER`=resend, `MAIL_API_KEY`=re_xxx, `MAIL_FROM`=红魔馆 <xxx@resend.dev>, `SITE_URL`=https://scarlet-blog.onrender.com |

> 本地需 `javax.mail-1.6.2.jar` + `jakarta.activation-1.2.2.jar`（JDK 21 缺 javax.activation）。云端用 HTTP API 不依赖 SMTP 端口。

## 10. 云端部署（Render）

源码目录：`myblog-render/`（与本地 `myblog-src/` 分开维护）

```bash
cd "C:\Users\dxy28\Desktop\Desktop\myblog-render"
git add -A && git commit -m "描述改动"
git push
# Render 自动构建 + 部署
```

### ⚠️ 双目录同步规则

| 类型 | 规则 |
|------|------|
| JSP / CSS / JS / Model / DAO / Servlet | 直接 cp，代码逻辑相同 |
| `DBUtil.java` | 手动合并！两边的 fallback 配置不同 |
| `Dockerfile` | Render 比本地多 `tomcat-jdbc.jar` |
| `auth_migration.sql` | 环境差异，手动处理 |

配置差异：
| 配置 | 本地 (myblog-src) | 云端 (myblog-render) |
|------|-------------------|---------------------|
| DB_HOST | localhost | mysql-scarlet-blog-...aivencloud.com |
| DB_PORT | 3306 | 11400 |
| sslMode | DISABLED | REQUIRED |
| allowPublicKeyRetrieval | true | 不需要 |

## 11. 文件路径

| 用途 | 路径 |
|------|------|
| 本地源码 | `C:\Users\dxy28\Desktop\Desktop\myblog-src` |
| 云端源码 | `C:\Users\dxy28\Desktop\Desktop\myblog-render` |
| Tomcat 部署 | `C:\Users\dxy28\tools\tomcat9\webapps\myblog` |
| Tomcat 安装 | `C:\Users\dxy28\tools\tomcat9` |
| JDK | `D:\Coding\JAVA\New Folder` |
| GitHub | https://github.com/Remilia-Scarlet-jpg/Scarlet-blog |
| 线上 URL | https://scarlet-blog.onrender.com |
