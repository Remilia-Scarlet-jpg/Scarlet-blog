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
                <% if (currentUser != null && currentUser.isAdmin()) { %><a href="<%=ctxPath%>/blog/admin">⚙️ 管理室</a><% } %>
                <% if (currentUser != null) { %>
                    <a href="<%=ctxPath%>/blog/chat" title="茶话会" id="navChatLink">🍵 茶话会<span id="navChatBadge" class="nav-badge" style="display:none;">0</span></a>
                    <a href="<%=ctxPath%>/blog/profile" title="访客档案" style="display:flex;align-items:center;gap:6px;">
                        <img src="<%= currentUser.getAvatar() != null ? (currentUser.getAvatar().startsWith("data:") ? currentUser.getAvatar() : ctxPath + "/" + currentUser.getAvatar()) : "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Ccircle cx='12' cy='12' r='12' fill='%234a0000'/%3E%3Ctext x='12' y='16' text-anchor='middle' font-size='12'%3E👤%3C/text%3E%3C/svg%3E" %>"
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
                <h3>💬 访客留言 (<span id="commentCount"><%= comments != null ? comments.size() : 0 %></span>)</h3>

                <div id="commentsContainer">
                <% if (comments != null && !comments.isEmpty()) {
                    for (Comment c : comments) { %>
                <div class="comment-item" data-comment-id="<%=c.getId()%>">
                    <div class="comment-author">👤 <%= HtmlUtil.escape(c.getAuthor() != null ? c.getAuthor() : "匿名访客") %></div>
                    <div class="comment-date">🕐 <%= c.getCreatedAt() != null ? sdf.format(c.getCreatedAt()) : "" %></div>
                    <div class="comment-content"><%= HtmlUtil.escape(c.getContent()) %></div>
                </div>
                <%     }
                   } else { %>
                <p id="noCommentsMsg" style="color:var(--text-muted);">暂无评论，来留下第一条吧~</p>
                <% } %>
                </div>

                <div class="comment-form">
                    <h4 style="color:var(--gold);margin-bottom:15px;">✎ 留下评论</h4>
                    <form id="commentForm" onsubmit="return submitCommentForm(this)">
                        <input type="hidden" name="post_id" value="<%=post.getId()%>">
                        <input type="text" name="author" id="commentAuthor" placeholder="你的名字（幻想乡的住人）" maxlength="50">
                        <textarea name="content" id="commentContent" placeholder="在这里写下你的评论..." maxlength="1000" required></textarea>
                        <button type="submit" class="btn-scarlet" id="commentSubmitBtn">📝 发布评论</button>
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
        var postId = <%= post != null ? post.getId() : 0 %>;
        var lastCommentId = 0;
        var renderedIds = {};

        // 记录服务端已渲染的评论ID
        (function() {
            var items = document.querySelectorAll('#commentsContainer .comment-item');
            items.forEach(function(el) {
                var cid = parseInt(el.getAttribute('data-comment-id'));
                if (cid > 0) {
                    renderedIds[cid] = true;
                    if (cid > lastCommentId) lastCommentId = cid;
                }
            });
        })();

        function submitCommentForm(form) {
            var content = document.getElementById('commentContent');
            var author = document.getElementById('commentAuthor');
            var btn = document.getElementById('commentSubmitBtn');
            if (!content.value.trim()) {
                alert('评论内容不能为空！');
                return false;
            }
            btn.disabled = true;
            btn.textContent = '⏳ 发送中...';

            var xhr = new XMLHttpRequest();
            xhr.open('POST', '<%=ctxPath%>/api/comments', true);
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            xhr.onload = function() {
                btn.disabled = false;
                btn.textContent = '📝 发布评论';
                if (xhr.status === 200) {
                    try {
                        var resp = JSON.parse(xhr.responseText);
                        if (resp.success) {
                            // 立即追加新评论到 DOM（乐观更新）
                            var now = new Date();
                            var timeStr = now.getFullYear() + '年' +
                                String(now.getMonth()+1).padStart(2,'0') + '月' +
                                String(now.getDate()).padStart(2,'0') + '日 ' +
                                String(now.getHours()).padStart(2,'0') + ':' +
                                String(now.getMinutes()).padStart(2,'0');
                            var authorName = escHtml(author.value.trim() || '匿名访客');
                            var commentContent = escHtml(content.value.trim());
                            appendCommentHtml(resp.id, authorName, timeStr, commentContent);
                            // 清空输入框
                            content.value = '';
                            // 更新计数
                            updateCommentCount(1);
                            // 移除"暂无评论"
                            var noMsg = document.getElementById('noCommentsMsg');
                            if (noMsg) noMsg.remove();
                        } else {
                            alert(resp.error || '评论提交失败，请重试。');
                        }
                    } catch(e) { alert('评论提交失败，请重试。'); }
                } else {
                    alert('评论提交失败，请重试。');
                }
            };
            var data = 'post_id=' + encodeURIComponent(postId)
                + '&author=' + encodeURIComponent(author.value || '匿名访客')
                + '&content=' + encodeURIComponent(content.value);
            xhr.send(data);
            return false;
        }

        function appendCommentHtml(id, author, time, content) {
            if (renderedIds[id]) return;  // 已渲染，跳过
            renderedIds[id] = true;
            if (id > lastCommentId) lastCommentId = id;

            var container = document.getElementById('commentsContainer');
            var div = document.createElement('div');
            div.className = 'comment-item';
            div.setAttribute('data-comment-id', id);
            div.style.cssText = 'animation:commentFadeIn 0.4s ease;';
            div.innerHTML =
                '<div class="comment-author">👤 ' + author + '</div>' +
                '<div class="comment-date">🕐 ' + time + '</div>' +
                '<div class="comment-content">' + content + '</div>';
            container.appendChild(div);

            // 滚动到新评论
            div.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }

        function updateCommentCount(delta) {
            var el = document.getElementById('commentCount');
            if (el) {
                el.textContent = parseInt(el.textContent) + delta;
            }
        }

        // 30 秒轮询检查新评论
        function pollNewComments() {
            fetch('<%=ctxPath%>/api/posts/' + postId + '/comments')
                .then(function(r) { return r.json(); })
                .then(function(d) {
                    if (!d.success || !d.data) return;
                    var newCount = 0;
                    d.data.forEach(function(c) {
                        if (!renderedIds[c.id]) {
                            renderedIds[c.id] = true;
                            if (c.id > lastCommentId) lastCommentId = c.id;
                            var time = c.created_at ? new Date(c.created_at).toLocaleString('zh-CN', {year:'numeric',month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit'}) : '';
                            appendCommentHtml(c.id, escHtml(c.author || '匿名访客'), time, escHtml(c.content));
                            newCount++;
                        }
                    });
                    if (newCount > 0) {
                        updateCommentCount(newCount);
                        var noMsg = document.getElementById('noCommentsMsg');
                        if (noMsg) noMsg.remove();
                    }
                })
                .catch(function() {});  // 静默失败
        }

        var commentPollTimer = setInterval(pollNewComments, 30000);
        window.addEventListener('beforeunload', function() { clearInterval(commentPollTimer); });

        function escHtml(s) {
            if (!s) return '';
            return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
        }

        // 注入淡入动画 CSS
        var style = document.createElement('style');
        style.textContent = '@keyframes commentFadeIn{from{opacity:0;transform:translateY(10px)}to{opacity:1;transform:translateY(0)}}';
        document.head.appendChild(style);
    </script>
<% if (currentUser != null) { %>
<script>
(function(){fetch('<%=ctxPath%>/api/friends').then(function(r){return r.json()}).then(function(d){if(d.success){var c=(d.received&&d.received.length)||0;var b=document.getElementById('navChatBadge');if(b){if(c>0){b.textContent=c;b.style.display='inline-block'}else{b.style.display='none'}}}}).catch(function(){})})();
</script>
<% } %>
</body>
</html>
