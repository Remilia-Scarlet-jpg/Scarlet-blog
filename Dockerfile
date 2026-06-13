FROM tomcat:9.0-jdk21

# 删除默认 ROOT 应用
RUN rm -rf /usr/local/tomcat/webapps/ROOT

# 创建红魔馆博客作为 ROOT 应用
RUN mkdir -p /usr/local/tomcat/webapps/ROOT/WEB-INF/classes/com/scarletblog \
    /usr/local/tomcat/webapps/ROOT/WEB-INF/lib

# 静态资源
COPY WebContent/ /usr/local/tomcat/webapps/ROOT/

# 编译好的 Java 类
COPY bin/com/scarletblog/ /usr/local/tomcat/webapps/ROOT/WEB-INF/classes/com/scarletblog/

# MySQL 数据库驱动
COPY mysql-connector-*.jar /usr/local/tomcat/webapps/ROOT/WEB-INF/lib/

# 暴露 Tomcat 端口（Render 会自动设置 PORT=8080）
EXPOSE 8080

# ─────── 启动 ───────
# 启动 Tomcat（Aiven MySQL 云端数据库，无需本地存储）
CMD catalina.sh run
