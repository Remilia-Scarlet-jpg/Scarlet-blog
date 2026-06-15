# 🏰 红魔馆博客 · Scarlet Devil Mansion Blog

> *"ここは紅魔館、私の館よ。ゆっくりしていってね。"*  
> *"欢迎来到红魔馆。请慢慢享受吧。"*  
> —— 蕾米莉亚·斯卡雷特

---

基于 **Java Servlet + JSP** 的东方 Project 红魔馆主题个人博客系统。深红哥特风格，部署于 Render。

🌐 **线上地址**：[scarlet-blog.onrender.com](https://scarlet-blog.onrender.com)

## ✨ 功能

### 📝 博客
- 文章列表（分页、搜索、分类筛选）
- 文章详情（浏览量自增、HTML 富文本）
- 首页图片轮播（3 张，5 秒自动切换）
- 评论区（AJAX 提交 + 30 秒轮询新评论）

### 👤 用户系统
- 注册 / 登录 / 登出
- PBKDF2-SHA256 密码哈希（12 万次迭代 + 随机盐）
- 角色系统：馆主 / 女仆长 / 住人
- 个人档案页（QQ 风格头像裁剪器、改昵称、改密码）
- 头像 Base64 存数据库，容器重启不丢失

### 🛡️ 管理后台
- 文章 CRUD（所有登录用户可创作）
- 分类 CRUD（馆主 / 女仆长）
- 统计面板
- 用户列表

### 🍵 茶话会 · 聊天系统
- 友人系统（邀请函 / 接受 / 婉拒）
- 私人茶室 + 公共茶室（红魔馆大厅）
- AJAX 实时轮询（2~5 秒）
- 全局未读通知徽标（导航栏脉冲动画）
- 乐观 UI 更新 + Toast 通知

### 🔒 安全
- PBKDF2-SHA256 密码哈希
- 登录限流（5 次 / 15 分钟）
- Session 加固（登录后重新生成 Session ID）
- CSRF 防护（Origin / Referer 验证 + SameSite Cookie）
- XSS 全站防护（HTML 实体转义）
- 路径穿越防护
- 验证码（混合数学 + 东方题库，20 题随机）

### 🎨 主题
- 深红哥特式 CSS
- 三档响应式断点（≤900px / ≤600px / ≤400px）
- 移动端适配

### 📡 REST API
```
GET    /api/posts             文章列表
GET    /api/posts/:id         文章详情
POST   /api/posts             创建文章
PUT    /api/posts/:id         更新文章
DELETE /api/posts/:id         删除文章
GET    /api/posts/:id/comments 评论列表
POST   /api/comments          发表评论
GET    /api/categories        分类列表
POST   /api/categories        创建分类（管理员）
PUT    /api/categories/:id    更新分类（管理员）
DELETE /api/categories/:id    删除分类（管理员）
POST   /api/auth/login        登录
POST   /api/auth/register     注册
GET    /api/auth/captcha      获取验证码
GET    /api/auth/me           当前用户
POST   /api/auth/profile      更新资料
GET    /api/friends           友人列表
POST   /api/friends           发送邀请函
PUT    /api/friends/:id       接受 / 婉拒
DELETE /api/friends/:id       删除友人
GET    /api/chat/rooms        茶室列表
POST   /api/chat/rooms        创建茶室
GET    /api/chat/rooms/:id    茶室详情
GET    /api/chat/rooms/:id/messages  消息列表
POST   /api/chat/messages     发送消息
GET    /api/admin/users       用户列表（管理员）
```

## 🛠️ 技术栈

| 层 | 技术 |
|----|------|
| 后端 | Java Servlet, JSP |
| 数据库 | MySQL 8 |
| 连接池 | Tomcat JDBC Pool |
| 安全 | PBKDF2-SHA256, CSRF, XSS |
| 部署 | Docker (tomcat:9.0-jdk21) → Render |
| 云端 DB | Aiven MySQL (SSL) |
| 前端 | Vanilla JS + CSS（无框架） |

## 🚀 本地运行

### 前提
- JDK 21
- Tomcat 9
- MySQL 8

### 步骤
```bash
# 1. 创建数据库
mysql -u root -p -e "CREATE DATABASE scarlet_blog"

# 2. 设置环境变量
export DB_HOST=localhost
export DB_PORT=3306
export DB_NAME=scarlet_blog
export DB_USER=root
export DB_PASS=your_password

# 3. 编译
javac -encoding UTF-8 \
  -cp servlet-api.jar:mysql-connector-j-9.3.0.jar:tomcat-jdbc.jar \
  -d WebContent/WEB-INF/classes \
  $(find src -name "*.java")

# 4. 部署到 Tomcat webapps/

# 5. 启动 Tomcat，访问 http://localhost:8080/<app>/
```

首次启动自动建表 + 插入种子数据（6 篇东方主题文章 + 8 条评论 + 5 个分类）。

### 演示账号

| 角色 | 用户名 | 密码 |
|------|--------|------|
| 🧛 馆主 | `remilia` | `admin123` |
| 🔪 女仆长 | `sakuya` | `maid123` |

## 📂 项目结构

```
src/com/scarletblog/
├── dao/          数据访问层
│   ├── PostDAO.java
│   ├── UserDAO.java
│   ├── CategoryDAO.java
│   ├── FriendDAO.java
│   └── ChatDAO.java
├── model/        数据模型
│   ├── Post.java, User.java, Category.java
│   ├── Friend.java, ChatRoom.java, Message.java
│   └── Comment.java
├── servlet/      控制器
│   └── BlogServlet.java
└── util/         工具类
    ├── DBUtil.java       数据库连接池
    ├── SecurityUtil.java PBKDF2 密码哈希
    └── HtmlUtil.java     HTML 转义

WebContent/
├── *.jsp         页面模板
├── css/scarlet.css  深红哥特主题
├── js/           vanilla JS
└── images/       轮播图片
```

## 🏗️ 部署

推送 `main` 分支到 GitHub → Render 自动构建部署。

Docker 构建流程：
1. `COPY src/` → 容器内 `javac` 编译
2. `COPY WebContent/` → 静态资源
3. `COPY mysql-connector + ca.pem` → 数据库驱动 + SSL 证书
4. `EXPOSE 8080` → `catalina.sh run`

环境变量（Render Dashboard 配置）：
- `DB_HOST` / `DB_PORT` / `DB_NAME` / `DB_USER` / `DB_PASS`

## 📜 许可证

红魔馆主题同人作品。东方 Project © ZUN / 上海アリス幻樂団。

---

<p align="center">
  <img src="https://img.shields.io/badge/Java-Servlet-red?style=flat-square&logo=java" />
  <img src="https://img.shields.io/badge/MySQL-8.0-blue?style=flat-square&logo=mysql" />
  <img src="https://img.shields.io/badge/Tomcat-9.0-orange?style=flat-square&logo=apachetomcat" />
  <img src="https://img.shields.io/badge/Docker-tomcat:9.0--jdk21-2496ED?style=flat-square&logo=docker" />
  <img src="https://img.shields.io/badge/Render-live-46E3B7?style=flat-square&logo=render" />
</p>
