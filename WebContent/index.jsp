<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, com.scarletblog.model.Post, com.scarletblog.model.Category, com.scarletblog.model.User, com.scarletblog.model.CarouselSlide" %>
<%@ page import="com.scarletblog.util.HtmlUtil" %>
<%
    List<Post> posts = (List<Post>) request.getAttribute("posts");
    List<Category> categories = (List<Category>) request.getAttribute("categories");
    Integer currentPage = (Integer) request.getAttribute("currentPage");
    Integer totalPages = (Integer) request.getAttribute("totalPages");
    String search = (String) request.getAttribute("search");
    String currentCategory = (String) request.getAttribute("currentCategory");
    Integer totalPosts = (Integer) request.getAttribute("totalPosts");
    Integer totalComments = (Integer) request.getAttribute("totalComments");
    Integer totalViews = (Integer) request.getAttribute("totalViews");
    User currentUser = (User) request.getAttribute("currentUser");
    List<CarouselSlide> slides = (List<CarouselSlide>) request.getAttribute("slides");
    String ctxPath = request.getContextPath();
    if (currentPage == null) currentPage = 1;
    if (totalPages == null) totalPages = 1;
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🏰 红魔馆博客 - Scarlet Devil Mansion Blog</title>
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
                <a href="<%=ctxPath%>/blog" class="active" title="大厅">🏠 大厅</a>
                <% if (currentUser != null && currentUser.isAdmin()) { %>
                    <a href="<%=ctxPath%>/blog/admin" title="管理室">⚙️ 管理室</a>
                <% } %>
                <% if (currentUser != null) { %>
                    <a href="<%=ctxPath%>/blog/chat" title="茶话会" id="navChatLink">🍵 茶话会<span id="navChatBadge" class="nav-badge" style="display:none;">0</span></a>
                    <a href="#" onclick="openCreatePostModal();return false;" title="撰写文章">📝 撰写</a>
                    <a href="<%=ctxPath%>/blog/user?id=<%=currentUser.getId()%>" title="访客档案" style="display:flex;align-items:center;gap:6px;">
                        <img src="<%= currentUser.getAvatar() != null ? (currentUser.getAvatar().startsWith("data:") ? currentUser.getAvatar() : ctxPath + "/" + currentUser.getAvatar()) : "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Ccircle cx='12' cy='12' r='12' fill='%234a0000'/%3E%3Ctext x='12' y='16' text-anchor='middle' font-size='12'%3E👤%3C/text%3E%3C/svg%3E" %>"
                             style="width:28px;height:28px;border-radius:50%;object-fit:cover;border:1px solid var(--gold);">
                        <%= HtmlUtil.escape(currentUser.getNickname()) %>
                    </a>
                    <a href="<%=ctxPath%>/blog/user?id=<%=currentUser.getId()%>" title="我的主页">🏷️ 我的主页</a>
                    <a href="<%=ctxPath%>/api/auth/logout" title="离馆" style="color:var(--scarlet-light)">🚪 离馆</a>
                <% } else { %>
                    <a href="<%=ctxPath%>/blog/login" title="入馆通行">⚜️ 入馆</a>
                <% } %>
            </nav>
        </div>
    </header>

    <div class="main-container">
        <div class="content-area">
            <div class="hero-section">
                <h2>✦ 红魔馆博客 ✦</h2>
                <p>欢迎来到幻想乡一隅的红魔馆</p>
            </div>

            <%-- 轮播图（数据库驱动，统一海报模式） --%>
            <div class="carousel-container">
                <div class="carousel-track" id="carouselTrack">
                    <% if (slides != null && !slides.isEmpty()) {
                        for (int si = 0; si < slides.size(); si++) {
                            CarouselSlide s = slides.get(si);
                            String posterUrl = s.getPosterUrl(ctxPath);
                            if (posterUrl == null) posterUrl = ctxPath + "/images/slide_1.jpg";
                            String videoSrc = null;
                            if ("video".equals(s.getType())) {
                                if (s.getImagePath() != null && !s.getImagePath().isEmpty())
                                    videoSrc = ctxPath + "/" + s.getImagePath();
                                else if (s.getVideoUrl() != null)
                                    videoSrc = s.getVideoUrl();
                            }
                    %>
                    <div class="carousel-slide<%= si == 0 ? " active" : "" %>"
                         data-type="<%= s.getType() %>"
                         data-poster="<%= posterUrl %>"
                         <% if (videoSrc != null) { %>data-video-src="<%= videoSrc %>"<% } %>
                         onclick="openCarouselSlide(this)">
                        <img src="<%= posterUrl %>" alt="<%= HtmlUtil.escape(s.getTitle() != null ? s.getTitle() : "") %>">
                        <% if (videoSrc != null) { %>
                        <div class="carousel-play-overlay">▶</div>
                        <% } %>
                    </div>
                    <%     }
                       } else { %>
                    <div class="carousel-slide active" data-type="image" data-poster="<%=ctxPath%>/images/slide_1.jpg" onclick="openCarouselSlide(this)">
                        <img src="<%=ctxPath%>/images/slide_1.jpg" alt="红魔馆">
                    </div>
                    <% } %>
                </div>
                <button class="carousel-arrow carousel-prev" onclick="changeSlide(-1)" title="上一张">◀</button>
                <button class="carousel-arrow carousel-next" onclick="changeSlide(1)" title="下一张">▶</button>
                <div class="carousel-dots" id="carouselDots">
                    <% if (slides != null) {
                        for (int si = 0; si < slides.size(); si++) { %>
                    <span class="carousel-dot<%= si == 0 ? " active" : "" %>" onclick="goToSlide(<%=si%>)"></span>
                    <%     }
                       } %>
                </div>
            </div>

            <%-- 图片灯箱 --%>
            <div class="lightbox-overlay" id="lightbox" onclick="closeLightbox()">
                <span class="lightbox-close" onclick="closeLightbox()">✕</span>
                <img id="lightboxImg" src="" alt="">
            </div>

            <%-- 视频弹窗 --%>
            <div class="video-modal-overlay" id="videoModal" onclick="closeVideoModal(event)">
                <div class="video-modal-box" onclick="event.stopPropagation()">
                    <span class="video-modal-close" onclick="closeVideoModal()">✕</span>
                    <video id="videoModalPlayer" controls autoplay playsinline></video>
                </div>
            </div>

            <div id="posts-container">
                <% if (posts != null && !posts.isEmpty()) {
                    for (Post p : posts) {
                        String excerpt = p.getExcerpt();
                        if (excerpt == null || excerpt.isEmpty()) {
                            String content = p.getContent();
                            excerpt = content != null ? content.replaceAll("<[^>]*>", "") : "";
                            if (excerpt.length() > 200) excerpt = excerpt.substring(0, 200) + "...";
                        }
                %>
                <article class="post-card">
                    <div class="post-card-body">
                        <div class="post-card-meta">
                            <span class="post-card-category"><%= HtmlUtil.escape(p.getCategoryIcon() != null ? p.getCategoryIcon() : "📜") %> <%= HtmlUtil.escape(p.getCategoryName() != null ? p.getCategoryName() : "未分类") %></span>
                            <span>🕐 <%= p.getCreatedAt() != null ? new java.text.SimpleDateFormat("yyyy年MM月dd日").format(p.getCreatedAt()) : "" %></span>
                            <span>✍️ <%= HtmlUtil.escape(p.getAuthor() != null ? p.getAuthor() : "红魔馆之主") %></span>
                        </div>
                        <h2 class="post-card-title">
                            <a href="<%=ctxPath%>/blog/post?id=<%=p.getId()%>"><%= HtmlUtil.escape(p.getTitle()) %></a>
                        </h2>
                        <p class="post-card-excerpt"><%= HtmlUtil.escape(excerpt) %></p>
                        <div class="post-card-footer">
                            <div class="post-card-stats">
                                <span>👁️ <%= p.getViewCount() %></span>
                            </div>
                            <div class="post-card-tags">
                                <% if (p.getTags() != null && !p.getTags().isEmpty()) {
                                    for (String tag : p.getTags().split(",")) { %>
                                        <a href="?search=<%= java.net.URLEncoder.encode(tag.trim(), "UTF-8") %>" class="post-card-tag">🏷️ <%= HtmlUtil.escape(tag.trim()) %></a>
                                <%  }
                                   } %>
                            </div>
                        </div>
                    </div>
                </article>
                <%     }
                   } else { %>
                <div class="empty-state">
                    <div class="empty-icon">📜</div>
                    <p>该分类下暂无文章</p>
                </div>
                <% } %>
            </div>

            <%-- 分页 --%>
            <div class="pagination" id="pagination">
                <% if (totalPages > 1) {
                    String queryStr = (search != null ? "&search=" + java.net.URLEncoder.encode(search, "UTF-8") : "")
                        + (currentCategory != null ? "&category=" + java.net.URLEncoder.encode(currentCategory, "UTF-8") : "");
                    if (currentPage > 1) { %>
                        <a href="<%=ctxPath%>/blog?page=<%=currentPage-1%><%=queryStr%>"><button>◀ 上一页</button></a>
                <%  }
                    for (int i = 1; i <= totalPages; i++) {
                        if (i == currentPage) { %>
                        <button class="active"><%=i%></button>
                <%      } else { %>
                        <a href="<%=ctxPath%>/blog?page=<%=i%><%=queryStr%>"><button><%=i%></button></a>
                <%      }
                    }
                    if (currentPage < totalPages) { %>
                        <a href="<%=ctxPath%>/blog?page=<%=currentPage+1%><%=queryStr%>"><button>下一页 ▶</button></a>
                <%  }
                   } %>
            </div>
        </div>

        <aside class="sidebar">
            <div class="scarlet-card">
                <div class="scarlet-card-header">🔍 搜索</div>
                <div class="scarlet-card-body">
                    <form class="search-box" action="<%=ctxPath%>/blog" method="get">
                        <input type="text" name="search" id="searchInput" placeholder="输入关键词..." value="<%= search != null ? HtmlUtil.escape(search) : "" %>">
                        <% if (currentCategory != null) { %><input type="hidden" name="category" value="<%=HtmlUtil.escape(currentCategory)%>"><% } %>
                        <button type="submit">搜索</button>
                    </form>
                </div>
            </div>

            <div class="scarlet-card">
                <div class="scarlet-card-header">📂 分类</div>
                <div class="scarlet-card-body">
                    <ul id="categoryList">
                        <li><a href="<%=ctxPath%>/blog">📜 全部文章</a></li>
                        <% if (categories != null) {
                            for (Category c : categories) { %>
                        <li><a href="<%=ctxPath%>/blog?category=<%= java.net.URLEncoder.encode(c.getName(), "UTF-8") %>">
                            <%= HtmlUtil.escape(c.getIcon() != null ? c.getIcon() : "📜") %> <%= HtmlUtil.escape(c.getName()) %>
                            <span style="color:var(--text-muted);font-size:0.8rem;">(<%=c.getPostCount()%>)</span>
                        </a></li>
                        <%     }
                           } %>
                    </ul>
                </div>
            </div>

            <div class="scarlet-card">
                <div class="scarlet-card-header">📊 红魔馆统计</div>
                <div class="scarlet-card-body" id="statsBox">
                    <p>📝 文章: <strong style="color:var(--gold)"><%= totalPosts != null ? totalPosts : 0 %></strong></p>
                    <p>💬 评论: <strong style="color:var(--gold)"><%= totalComments != null ? totalComments : 0 %></strong></p>
                    <p>👁️ 浏览: <strong style="color:var(--gold)"><%= totalViews != null ? totalViews : 0 %></strong></p>
                </div>
            </div>

            <div class="scarlet-card">
                <div class="scarlet-card-header">👥 馆中住人</div>
                <div class="scarlet-card-body">
                    <ul>
                        <li><span>🧛‍♀️</span> 蕾米莉亚·斯卡雷特 — 馆主</li>
                        <li><span>🎲</span> 芙兰朵露·斯卡雷特 — 妹妹大人</li>
                        <li><span>⏱️</span> 十六夜 咲夜 — 女仆长</li>
                        <li><span>📖</span> 帕秋莉·诺蕾姬 — 魔法使</li>
                        <li><span>🚪</span> 红 美铃 — 门卫</li>
                    </ul>
                </div>
            </div>
        </aside>
    </div>

    <footer class="scarlet-footer">
        <div class="footer-ornament">◆ ◇ ◆</div>
        <p>🏰 红魔馆博客 — Scarlet Devil Mansion Blog</p>
        <p>© 2024 红魔馆 | Powered by Java Servlet &amp; MySQL</p>
        <p>当前路径: <%= request.getRequestURI() %></p>
    </footer>

    <script src="<%=ctxPath%>/js/lightbox.js"></script>
    <script>
        // ============================================
        // 🎠 红魔馆轮播（统一海报模式：图片+封面 → 点击出灯箱/视频）
        // ============================================
        var currentSlide = 0;
        var totalSlides = document.querySelectorAll('.carousel-slide').length || 1;
        var slideInterval;

        function showSlide(index) {
            var track = document.getElementById('carouselTrack');
            var dots = document.querySelectorAll('.carousel-dot');
            if (index >= totalSlides) index = 0;
            if (index < 0) index = totalSlides - 1;

            // 更新 active 状态
            var slides = document.querySelectorAll('.carousel-slide');
            slides.forEach(function(s, i) { s.classList.toggle('active', i === index); });

            currentSlide = index;
            track.style.transform = 'translateX(-' + (currentSlide * 100) + '%)';
            dots.forEach(function(d, i) {
                d.classList.toggle('active', i === currentSlide);
            });
        }

        function changeSlide(dir) {
            showSlide(currentSlide + dir);
            resetTimer();
        }

        function goToSlide(index) {
            showSlide(index);
            resetTimer();
        }

        function resetTimer() {
            clearInterval(slideInterval);
            slideInterval = setInterval(function() { changeSlide(1); }, 5000);
        }

        // 点击幻灯片 → 图片灯箱 || 视频弹窗
        function openCarouselSlide(el) {
            clearInterval(slideInterval);  // 暂停自动轮播
            if (el.dataset.type === 'video' && el.dataset.videoSrc) {
                openVideoModal(el.dataset.videoSrc);
            } else {
                openLightbox(el.dataset.poster);
            }
        }

        // === 图片灯箱 ===
        function openLightbox(src) {
            document.getElementById('lightboxImg').src = src;
            document.getElementById('lightbox').classList.add('active');
            document.body.style.overflow = 'hidden';
        }
        function closeLightbox() {
            document.getElementById('lightbox').classList.remove('active');
            document.body.style.overflow = '';
            resetTimer();
        }

        // === 视频弹窗 ===
        function openVideoModal(src) {
            var player = document.getElementById('videoModalPlayer');
            player.src = src;
            document.getElementById('videoModal').classList.add('active');
            document.body.style.overflow = 'hidden';
        }
        function closeVideoModal(e) {
            if (e && e.target !== document.getElementById('videoModal')) return;
            var player = document.getElementById('videoModalPlayer');
            player.pause();
            player.src = '';
            document.getElementById('videoModal').classList.remove('active');
            document.body.style.overflow = '';
            resetTimer();
        }

        // 启动
        if (totalSlides > 1) {
            resetTimer();
        }

        // 触摸滑动
        (function() {
            var container = document.querySelector('.carousel-container');
            var startX = 0;
            container.addEventListener('touchstart', function(e) {
                startX = e.touches[0].clientX;
            });
            container.addEventListener('touchend', function(e) {
                var diff = startX - e.changedTouches[0].clientX;
                if (Math.abs(diff) > 50) changeSlide(diff > 0 ? 1 : -1);
            });
        })();
    </script>

    <% if (currentUser != null) { %>
    <script>var CTX_PATH = '<%=ctxPath%>';</script>
    <script src="<%=ctxPath%>/js/api.js?v=20260616"></script>
    <script src="<%=ctxPath%>/js/blog.js?v=20260616"></script>
    <%-- 撰写文章模态框 --%>
    <div class="modal-overlay" id="postModalIndex">
        <div class="modal-dialog">
            <div class="modal-header">
                <h3>📝 撰写文章</h3>
                <button class="modal-close" onclick="closeCreatePostModal()">✕</button>
            </div>
            <div class="modal-body">
                <form id="createPostForm" onsubmit="createPost(event)">
                    <div class="form-group">
                        <label>📌 标题 *</label>
                        <input type="text" id="createPostTitle" placeholder="文章标题" maxlength="200" required>
                    </div>
                    <div class="form-group">
                        <label>📂 分类</label>
                        <select id="createPostCategory">
                            <option value="">无分类</option>
                            <% if (categories != null) {
                                for (com.scarletblog.model.Category c : categories) { %>
                            <option value="<%=c.getId()%>"><%= HtmlUtil.escape(c.getIcon() != null ? c.getIcon() : "") %> <%= HtmlUtil.escape(c.getName()) %></option>
                            <%     }
                               } %>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>🏷️ 标签（逗号分隔）</label>
                        <input type="text" id="createPostTags" placeholder="例: 东方,红魔馆,Java" maxlength="200">
                    </div>
                    <div class="form-group">
                        <label>📝 内容 *（支持HTML）</label>
                        <textarea id="createPostContent" placeholder="在这里写下文章内容..." rows="10" required></textarea>
                    </div>
                    <div class="form-actions">
                        <button type="button" class="btn-scarlet-outline" onclick="closeCreatePostModal()">取消</button>
                        <button type="submit" class="btn-scarlet">💾 发布</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    <script>
        function openCreatePostModal() {
            document.getElementById('createPostTitle').value = '';
            document.getElementById('createPostTags').value = '';
            document.getElementById('createPostContent').value = '';
            document.getElementById('postModalIndex').classList.add('active');
        }
        function closeCreatePostModal() {
            document.getElementById('postModalIndex').classList.remove('active');
        }
        function createPost(e) {
            e.preventDefault();
            var params = 'title=' + encodeURIComponent(document.getElementById('createPostTitle').value)
                + '&category_id=' + (parseInt(document.getElementById('createPostCategory').value) || 0)
                + '&tags=' + encodeURIComponent(document.getElementById('createPostTags').value)
                + '&content=' + encodeURIComponent(document.getElementById('createPostContent').value);
            var xhr = new XMLHttpRequest();
            xhr.open('POST', '<%=ctxPath%>/api/posts', true);
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            xhr.onload = function() {
                try {
                    var resp = JSON.parse(xhr.responseText);
                    if (resp.success) {
                        alert(resp.message);
                        closeCreatePostModal();
                        location.reload();
                    } else {
                        alert(resp.error || '发布失败');
                    }
                } catch(e) { alert('操作失败'); }
            };
            xhr.send(params);
        }
        document.getElementById('postModalIndex').addEventListener('click', function(e) {
            if (e.target === this) closeCreatePostModal();
        });
    </script>
    <% } %>

    <%-- 全局茶话会通知轮询（仅登录用户） --%>
    <% if (currentUser != null) { %>
    <script>
    (function() {
        var lastInviteCount = 0;
        function pollFriendRequests() {
            fetch('<%=ctxPath%>/api/friends')
                .then(function(r) { return r.json(); })
                .then(function(d) {
                    if (!d.success) return;
                    var count = (d.received && d.received.length) ? d.received.length : 0;
                    var badge = document.getElementById('navChatBadge');
                    if (badge) {
                        if (count > 0) {
                            badge.textContent = count;
                            badge.style.display = 'inline-block';
                        } else {
                            badge.style.display = 'none';
                        }
                    }
                    // 检测到新邀请函时弹通知
                    if (count > lastInviteCount && lastInviteCount > 0) {
                        var toast = document.createElement('div');
                        toast.className = 'toast success';
                        toast.textContent = '📨 收到新邀请函！点击茶话会查看';
                        toast.style.cssText = 'position:fixed;top:80px;right:20px;z-index:9999;';
                        document.body.appendChild(toast);
                        setTimeout(function() {
                            toast.style.opacity = '0';
                            toast.style.transition = 'all 0.5s';
                            setTimeout(function() { toast.remove(); }, 500);
                        }, 4000);
                    }
                    lastInviteCount = count;
                })
                .catch(function() {});  // 静默失败
        }
        // 每 30 秒检查一次（大厅页面低频轮询）
        pollFriendRequests();
        setInterval(pollFriendRequests, 30000);
    })();
    </script>
    <% } %>
</body>
</html>
