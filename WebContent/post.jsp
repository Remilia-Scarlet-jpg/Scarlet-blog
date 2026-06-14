<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.scarletblog.model.Post, com.scarletblog.model.Comment, com.scarletblog.model.User, java.util.List, java.text.SimpleDateFormat" %>
<%@ page import="com.scarletblog.util.HtmlUtil" %>
<%
    Post post = (Post) request.getAttribute("post");
    List<Comment> comments = (List<Comment>) request.getAttribute("comments");
    User currentUser = (User) request.getAttribute("currentUser");
    String ctxPath = request.getContextPath();
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy年MM月dd日 HH:mm");
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= post != null ? HtmlUtil.escape(post.getTitle()) + " - " : "" %>红魔馆博客</title>
    <link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Ctext y='50' font-size='50'%3E🏰%3C/text%3E%3C/svg%3E">
    <link rel="stylesheet" href="<%=ctxPath%>/css/scarlet.css">
</head>
<body>
    <header class="scarlet-header">
        <div class="header-inner">
            <div class="logo-area">
                <div class="logo-icon">🏰</div>
                <div class="logo-text">
                    <h1>红 魔 馆</h1>
                    <span class="subtitle">Scarlet Devil Mansion</span>
                </div>
            </div>
            <nav class="nav-links">
                <a href="<%=ctxPath%>/blog">🏠 大厅</a>
                <a href="<%=ctxPath%>/blog/admin">⚙️ 管理室</a>
                <% if (currentUser != null) { %>
                    <a href="<%=ctxPath%>/blog/profile" title="访客档案" style="display:flex;align-items:center;gap:6px;">
                        <img src="<%= currentUser.getAvatar() != null ? ctxPath + "/" + currentUser.getAvatar() : "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Ccircle cx='12' cy='12' r='12' fill='%234a0000'/%3E%3Ctext x='12' y='16' text-anchor='middle' font-size='12'%3E👤%3C/text%3E%3C/svg%3E" %>"
                             style="width:28px;height:28px;border-radius:50%;object-fit:cover;border:1px solid var(--gold);">
                        <%= HtmlUtil.escape(currentUser.getNickname()) %>
                    </a>
                    <a href="<%=ctxPath%>/api/auth/logout" title="离馆" style="color:var(--scarlet-light)">🚪 离馆</a>
                <% } else { %>
                    <a href="<%=ctxPath%>/blog/login" title="入馆通行">⚜️ 入馆</a>
                <% } %>
            </nav>
        </div>
    </header>

    <div class="main-container full-width">
        <div class="content-area">
            <% if (post != null) { %>
            <article class="article-full">
                <div class="post-card-meta" style="margin-bottom:20px;">
                    <span class="post-card-category">
                        <%= HtmlUtil.escape(post.getCategoryIcon() != null ? post.getCategoryIcon() : "📜") %>
                        <%= HtmlUtil.escape(post.getCategoryName() != null ? post.getCategoryName() : "未分类") %>
                    </span>
                    <span>🕐 <%= post.getCreatedAt() != null ? sdf.format(post.getCreatedAt()) : "" %></span>
                    <span>✍️ <%= HtmlUtil.escape(post.getAuthor() != null ? post.getAuthor() : "红魔馆之主") %></span>
                    <span>👁️ <%= post.getViewCount() %> 次阅读</span>
                </div>
                <h1><%= HtmlUtil.escape(post.getTitle()) %></h1>
                <% if (post.getTags() != null && !post.getTags().isEmpty()) { %>
                <div class="post-card-tags" style="margin-bottom:20px;">
                    <% for (String tag : post.getTags().split(",")) { %>
                        <span class="post-card-tag">🏷️ <%= HtmlUtil.escape(tag.trim()) %></span>
                    <% } %>
                </div>
                <% } %>
                <div class="article-content">
                    <%= post.getContent() %>
                </div>
            </article>

            <%-- 评论区 --%>
            <section class="comments-section">
                <h3>💬 访客留言 (<%= comments != null ? comments.size() : 0 %>)</h3>

                <% if (comments != null && !comments.isEmpty()) {
                    for (Comment c : comments) { %>
                <div class="comment-item">
                    <div class="comment-author">👤 <%= HtmlUtil.escape(c.getAuthor() != null ? c.getAuthor() : "匿名访客") %></div>
                    <div class="comment-date">🕐 <%= c.getCreatedAt() != null ? sdf.format(c.getCreatedAt()) : "" %></div>
                    <div class="comment-content"><%= HtmlUtil.escape(c.getContent()) %></div>
                </div>
                <%     }
                   } else { %>
                <p style="color:var(--text-muted);">暂无评论，来留下第一条吧~</p>
                <% } %>

                <div class="comment-form">
                    <h4 style="color:var(--gold);margin-bottom:15px;">✎ 留下评论</h4>
                    <form action="<%=ctxPath%>/api/comments" method="post" onsubmit="return submitCommentForm(this)">
                        <input type="hidden" name="post_id" value="<%=post.getId()%>">
                        <input type="text" name="author" placeholder="你的名字（幻想乡的住人）" maxlength="50">
                        <textarea name="content" placeholder="在这里写下你的评论..." maxlength="1000" required></textarea>
                        <button type="submit" class="btn-scarlet">📝 发布评论</button>
                    </form>
                </div>
            </section>
            <% } else { %>
            <div class="empty-state">
                <div class="empty-icon">📜</div>
                <p>文章未找到，也许在幻想乡的某处...</p>
                <p><a href="<%=ctxPath%>/blog" style="color:var(--gold)">← 返回大厅</a></p>
            </div>
            <% } %>
        </div>
    </div>

    <footer class="scarlet-footer">
        <div class="footer-ornament">◆ ◇ ◆</div>
        <p>🏰 红魔馆博客 — Scarlet Devil Mansion Blog</p>
        <p>© 2024 红魔馆 | Powered by Java Servlet &amp; MySQL</p>
    </footer>

    <script src="<%=ctxPath%>/js/lightbox.js"></script>
    <script>
        function submitCommentForm(form) {
            var content = form.querySelector('textarea[name="content"]');
            if (!content.value.trim()) {
                alert('评论内容不能为空！');
                return false;
            }
            // Use AJAX to submit
            var xhr = new XMLHttpRequest();
            xhr.open('POST', form.action, true);
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            xhr.onload = function() {
                if (xhr.status === 200) {
                    location.reload();
                } else {
                    alert('评论提交失败，请重试。');
                }
            };
            var data = 'post_id=' + encodeURIComponent(form.post_id.value)
                + '&author=' + encodeURIComponent(form.author.value || '匿名访客')
                + '&content=' + encodeURIComponent(content.value);
            xhr.send(data);
            return false;
        }
    </script>
</body>
</html>
