FROM tomcat:9.0-jdk21

# 删除默认 ROOT 应用
RUN rm -rf /usr/local/tomcat/webapps/ROOT

# 创建目录结构
RUN mkdir -p /usr/local/tomcat/webapps/ROOT/WEB-INF/classes /usr/local/tomcat/webapps/ROOT/WEB-INF/lib

# 复制源码（编译用）
COPY src/ /tmp/src/

# 复制静态资源和配置
COPY WebContent/ /usr/local/tomcat/webapps/ROOT/

# MySQL 驱动 + Aiven CA 证书
COPY mysql-connector-*.jar /usr/local/tomcat/webapps/ROOT/WEB-INF/lib/
COPY ca.pem /usr/local/tomcat/

# Docker 内编译 Java 源码
# servlet-api.jar 来自 Tomcat 镜像自带，mysql-connector 来自上一步
RUN javac -encoding UTF-8 \
    -cp /usr/local/tomcat/lib/servlet-api.jar:/usr/local/tomcat/webapps/ROOT/WEB-INF/lib/* \
    -d /usr/local/tomcat/webapps/ROOT/WEB-INF/classes \
    $(find /tmp/src -name "*.java") \
    && rm -rf /tmp/src

EXPOSE 8080
CMD ["catalina.sh", "run"]
