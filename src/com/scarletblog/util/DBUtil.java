package com.scarletblog.util;

import java.sql.*;

/**
 * 红魔馆博客 - 数据库工具 (Aiven MySQL · Render 部署用)
 * 连接 Aiven 云端 MySQL，首次启动自动建表并插入示例数据
 */
public class DBUtil {

    // 数据库连接 — 优先从环境变量读取（Render 部署用），fallback 为 Aiven 默认值
    private static final String DB_HOST = env("DB_HOST", "mysql-scarlet-blog-scarlet-blog.e.aivencloud.com");
    private static final String DB_PORT = env("DB_PORT", "11400");
    private static final String DB_NAME = env("DB_NAME", "defaultdb");
    private static final String DB_USER = env("DB_USER", "avnadmin");
    private static final String DB_PASS = env("DB_PASS", "");

    private static final String URL =
        "jdbc:mysql://" + DB_HOST + ":" + DB_PORT + "/" + DB_NAME
        + "?useUnicode=true&characterEncoding=UTF-8"
        + "&serverTimezone=Asia/Shanghai"
        + "&sslMode=REQUIRED"
        + "&connectTimeout=20000"
        + "&socketTimeout=20000";

    /** CA 证书路径（Docker 容器内） */
    private static String getCaPath() {
        String path = System.getenv("CA_CERT_PATH");
        return (path != null) ? path : "/usr/local/tomcat/ca.pem";
    }
    private static final String USER = DB_USER;
    private static final String PASS = DB_PASS;

    private static String env(String key, String fallback) {
        String val = System.getenv(key);
        return (val != null && !val.isEmpty()) ? val : fallback;
    }

    static {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            initDatabase();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASS);
    }

    public static void close(Connection conn, Statement stmt, ResultSet rs) {
        try { if (rs != null) rs.close(); } catch (SQLException e) {}
        try { if (stmt != null) stmt.close(); } catch (SQLException e) {}
        try { if (conn != null) conn.close(); } catch (SQLException e) {}
    }

    public static void close(Connection conn, PreparedStatement pstmt, ResultSet rs) {
        try { if (rs != null) rs.close(); } catch (SQLException e) {}
        try { if (pstmt != null) pstmt.close(); } catch (SQLException e) {}
        try { if (conn != null) conn.close(); } catch (SQLException e) {}
    }

    /** 首次启动时自动建表和种子数据 */
    private static void initDatabase() {
        try (Connection conn = DriverManager.getConnection(URL, USER, PASS);
             Statement stmt = conn.createStatement()) {

            // 检查是否已有表
            ResultSet rs = stmt.executeQuery("SHOW TABLES LIKE 'posts'");
            if (rs.next()) { rs.close(); return; }
            rs.close();

            // 创建表
            stmt.execute("CREATE TABLE categories (" +
                "id INT AUTO_INCREMENT PRIMARY KEY," +
                "name VARCHAR(50) NOT NULL UNIQUE," +
                "description VARCHAR(200)," +
                "icon VARCHAR(50) DEFAULT '📜'," +
                "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

            stmt.execute("CREATE TABLE posts (" +
                "id INT AUTO_INCREMENT PRIMARY KEY," +
                "title VARCHAR(200) NOT NULL," +
                "content TEXT NOT NULL," +
                "excerpt VARCHAR(500)," +
                "author VARCHAR(50) DEFAULT '红魔馆之主'," +
                "category_id INT," +
                "cover_image VARCHAR(500)," +
                "tags VARCHAR(200)," +
                "view_count INT DEFAULT 0," +
                "is_published TINYINT DEFAULT 1," +
                "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP," +
                "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP," +
                "FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

            stmt.execute("CREATE TABLE comments (" +
                "id INT AUTO_INCREMENT PRIMARY KEY," +
                "post_id INT NOT NULL," +
                "author VARCHAR(50) DEFAULT '匿名访客'," +
                "content TEXT NOT NULL," +
                "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP," +
                "FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

            stmt.execute("CREATE TABLE users (" +
                "id INT AUTO_INCREMENT PRIMARY KEY," +
                "username VARCHAR(50) NOT NULL UNIQUE," +
                "password VARCHAR(255) NOT NULL," +
                "nickname VARCHAR(50) DEFAULT '匿名访客'," +
                "avatar VARCHAR(500) DEFAULT NULL," +
                "role VARCHAR(20) DEFAULT '住人'," +
                "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

            // 种子数据 - 分类
            stmt.execute("INSERT INTO categories (name, description, icon) VALUES " +
                "('幻想乡日记', '记录红魔馆的日常生活', '🏰')," +
                "('魔法研究', '帕秋莉的魔法研究笔记', '📖')," +
                "('红茶时间', '咲夜的红茶与点心记录', '🫖')," +
                "('技术笔记', '编程与技术的学习记录', '💻')," +
                "('公告', '红魔馆的通知公告', '📢')");

            // 种子数据 - 文章
            stmt.execute("INSERT INTO posts (title, content, excerpt, author, category_id, tags, view_count) VALUES " +
                "('欢迎来到红魔馆 - 关于本博客', '<h2>🏰 欢迎来到红魔馆</h2><p>这里是<strong>东方Project</strong>世界中的红魔馆主题个人博客。</p><p>红魔馆的主人<strong>蕾米莉亚·斯卡雷特</strong>会在这里记录馆中的日常以及一些技术笔记。</p><h3>博客功能</h3><ul><li>🎨 红魔馆风格的深红哥特式设计</li><li>📝 文章的创建、编辑、删除管理功能</li><li>💬 访客评论功能</li><li>🔍 文章搜索与分类筛选</li></ul><p>请慢慢享受吧！</p><p class=\"signature\">—— 蕾米莉亚·斯卡雷特</p>', '欢迎来到红魔馆主题博客。蕾米莉亚·斯卡雷特为您带来幻想乡的日常与技术笔记。', '蕾米莉亚·斯卡雷特', 1, '红魔馆,欢迎,东方Project', 128)," +
                "('魔法图书馆的数据库设计入门', '<h2>📖 帕秋莉的数据库讲座</h2><p>嗯…今天来讲讲<strong>MySQL</strong>的基础知识。</p><h3>什么是CRUD</h3><table class=\"scarlet-table\"><tr><th>操作</th><th>SQL</th><th>说明</th></tr><tr><td>创建</td><td>INSERT</td><td>创建新的数据记录</td></tr><tr><td>读取</td><td>SELECT</td><td>查询读取数据</td></tr><tr><td>更新</td><td>UPDATE</td><td>更新已有数据</td></tr><tr><td>删除</td><td>DELETE</td><td>删除数据记录</td></tr></table><p class=\"signature\">—— 帕秋莉·诺蕾姬</p>', '帕秋莉教你数据库基础知识，包括CRUD操作和SELECT语句的基本用法。', '帕秋莉·诺蕾姬', 2, '数据库,CRUD,SQL', 86)," +
                "('完美红茶的冲泡方法 - 咲夜的下午茶时间', '<h2>🫖 咲夜的完美红茶冲泡法</h2><p>为了大小姐，我一直在冲泡完美的红茶。</p><h3>所需物品</h3><ol><li>最顶级的红茶叶</li><li>新鲜的泉水</li><li>银制茶壶</li><li>白瓷茶杯</li><li>操纵时间的能力（这是必须的）</li></ol><h3>步骤</h3><p>先将茶壶温热，放入茶叶。注入沸腾的热水，<strong>恰好等待3分钟</strong>——即便暂停了时间，也要遵守红茶的萃取时间。</p><p>以完美的温度呈给大小姐。这就是我的职责。</p><p class=\"signature\">—— 十六夜 咲夜</p>', '紅魔館的女仆长十六夜咲夜教你如何为大小姐冲泡完美红茶。', '十六夜 咲夜', 3, '红茶,兴趣,咲夜,完美', 215)," +
                "('与芙兰朵露一起玩JavaScript的魔法', '<h2>🎲 用JavaScript做弹幕游戏</h2><p>和芙兰酱一起用<strong>JavaScript</strong>写了个好玩的程序！</p><pre><code>function createDanmaku(count, speed, angle) {\n  const bullets = [];\n  for (let i = 0; i < count; i++) {\n    const rad = (2 * Math.PI / count) * i + angle;\n    bullets.push({\n      x: Math.cos(rad) * speed,\n      y: Math.sin(rad) * speed,\n      color: `hsl(${Math.random() * 360}, 80%, 60%)`\n    });\n  }\n  return bullets;\n}\n\nconst spellCard = createDanmaku(144, 3, Math.PI / 4);\nconsole.log(\"弹幕发动！\", spellCard.length, \"发子弹！\");</code></pre><p>不过千万别真的破坏东西哦！会被姐姐大人骂的…</p><p class=\"signature\">—— 芙兰朵露·斯卡雷特</p>', '和芙兰朵露一起用JavaScript写弹幕生成代码。', '芙兰朵露·斯卡雷特', 4, 'JavaScript,弹幕,游戏,芙兰', 342)," +
                "('用Node.js与Express构建幻想乡API', '<h2>🔮 用Node.js搭建API服务器</h2><p>这是为管理红魔馆数据而创建<strong>REST API</strong>的记录。</p><h3>使用技术</h3><ul><li><strong>Node.js</strong> - 服务器端JavaScript</li><li><strong>Express</strong> - Web框架</li><li><strong>MySQL2</strong> - 数据库连接</li></ul><p>这样就能将红魔馆的知识传播到幻想乡各处了！</p><p class=\"signature\">—— 帕秋莉·诺蕾姬</p>', '使用Node.js + Express + MySQL构建REST API。', '帕秋莉·诺蕾姬', 4, 'Node.js,Express,API,REST', 167)," +
                "('红魔馆夏日之夜宴公告', '<h2>🎆 夏日之夜宴 举办通知</h2><p>红魔馆将举办例行的<strong>夏日之夜宴</strong>。</p><h3>详情</h3><ul><li>📅 时间：满月之夜 19:00~</li><li>📍 地点：红魔馆 大厅</li><li>👗 着装要求：哥特式/维多利亚风格</li></ul><h3>活动安排</h3><ol><li>开幕致辞 —— 蕾米莉亚·斯卡雷特</li><li>魔法研究会发表 —— 帕秋莉·诺蕾姬</li><li>红茶与点心盛宴 —— 十六夜 咲夜</li><li>弹幕烟花大会 —— 芙兰朵露·斯卡雷特</li><li>幻想乡大宴会 —— 全体参加者</li></ol><p>幻想乡的各位，敬请光临！</p><p class=\"signature\">—— 红魔馆 全体</p>', '红魔馆夏日之夜宴即将举办！', '蕾米莉亚·斯卡雷特', 5, '活动,宴会,红魔馆,公告', 423)");

            // 种子数据 - 评论
            stmt.execute("INSERT INTO comments (post_id, author, content) VALUES " +
                "(1, '博丽灵梦', '看起来是个不错的博客呢。不过赛钱箱在哪？')," +
                "(1, '雾雨魔理沙', '我来借东西啦！…什么嘛原来是个博客。挺有意思的！')," +
                "(2, '爱丽丝·玛格特罗伊德', '数据库设计很有参考价值。用来管理人偶数据应该很适合。')," +
                "(3, '魂魄妖梦', '咲夜小姐…真不愧是您。我也会努力为幽幽子大人泡出好茶的。')," +
                "(4, '蕾米莉亚·斯卡雷特', '芙兰！又在玩危险的东西…不过看起来挺有趣的。下次也让我加入。')," +
                "(5, '八云紫', '连外界的技术都引入了，真有两下子呢。我会从结界的缝隙中注视着你们的。')," +
                "(6, '西行寺幽幽子', '宴会吗~？好期待啊~。我带樱花饼过去哦~。')," +
                "(6, '伊吹萃香', '有酒吗！？我带酒来！！')");

            // 种子数据 - 用户（PBKDF2 哈希: admin123 / maid123）
            stmt.execute("INSERT INTO users (username, password, nickname, avatar, role) VALUES " +
                "('remilia', '" + SecurityUtil.hashPassword("admin123") + "', '蕾米莉亚·斯卡雷特', 'uploads/avatars/remilia.jpg', '馆主')," +
                "('sakuya', '" + SecurityUtil.hashPassword("maid123") + "', '十六夜 咲夜', NULL, '女仆长')");

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}
