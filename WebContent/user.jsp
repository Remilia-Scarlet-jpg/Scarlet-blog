<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, com.scarletblog.model.Post, com.scarletblog.model.User" %>
<%@ page import="com.scarletblog.util.HtmlUtil, java.text.SimpleDateFormat" %>
<%
    User currentUser = (User) request.getAttribute("currentUser");
    User profileUser = (User) request.getAttribute("profileUser");
    Integer postCount = (Integer) request.getAttribute("postCount");
    Integer commentCount = (Integer) request.getAttribute("commentCount");
    Integer friendCount = (Integer) request.getAttribute("friendCount");
    String relationship = (String) request.getAttribute("relationship");
    Integer friendshipId = (Integer) request.getAttribute("friendshipId");
    List<Post> recentPosts = (List<Post>) request.getAttribute("recentPosts");
    String ctxPath = request.getContextPath();

    if (currentUser == null) { response.sendRedirect(ctxPath + "/blog/login"); return; }
    if (profileUser == null) { response.sendRedirect(ctxPath + "/blog"); return; }
    if (postCount == null) postCount = 0;
    if (commentCount == null) commentCount = 0;
    if (friendCount == null) friendCount = 0;
    if (relationship == null) relationship = "none";
    if (friendshipId == null) friendshipId = 0;

    String avatarSrc = profileUser.getAvatar();
    if (avatarSrc == null || avatarSrc.isEmpty()) {
        avatarSrc = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'%3E%3Ccircle cx='50' cy='50' r='50' fill='%234a0000'/%3E%3Ctext x='50' y='65' text-anchor='middle' font-size='40'%3E👤%3C/text%3E%3C/svg%3E";
    } else if (!avatarSrc.startsWith("data:")) {
        avatarSrc = ctxPath + "/" + avatarSrc;
    }

    boolean isOwnProfile = "self".equals(relationship);
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= HtmlUtil.escape(profileUser.getNickname()) %> 的主页 — 红魔馆</title>
    <link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Ctext y='50' font-size='50'%3E🏰%3C/text%3E%3C/svg%3E">
    <link rel="stylesheet" href="<%=ctxPath%>/css/scarlet.css">
    <style>
        /* ===== B 站风格住人主页 ===== */
        .user-banner {
            background: linear-gradient(180deg, #1a0505 0%, #0d0202 50%, transparent 100%);
            border: 1px solid #3a1010;
            border-radius: 12px;
            padding: 50px 30px 30px;
            text-align: center;
            margin-bottom: 20px;
            box-shadow: 0 4px 30px rgba(139,0,0,0.25);
        }
        .user-avatar-wrap { display: inline-block; position: relative; }
        .user-avatar-lg {
            width: 160px; height: 160px; border-radius: 50%; object-fit: cover;
            border: 3px solid var(--gold, #d4af37);
            box-shadow: 0 0 30px rgba(212,175,55,0.3), 0 0 60px rgba(139,0,0,0.2);
            transition: transform 0.3s ease;
        }
        .user-avatar-lg:hover { transform: scale(1.05); }
        .user-avatar-lg.clickable { cursor: pointer; }
        .avatar-edit-badge {
            position: absolute; bottom: 10px; right: 10px;
            width: 32px; height: 32px; background: var(--scarlet, #8b0000);
            border: 2px solid var(--gold); border-radius: 50%;
            display: flex; align-items: center; justify-content: center;
            cursor: pointer; font-size: 0.9rem; color: var(--gold);
            box-shadow: 0 0 10px rgba(0,0,0,0.5); transition: all 0.3s;
        }
        .avatar-edit-badge:hover { background: #a01010; transform: scale(1.1); }
        .user-role-badge {
            display: inline-block; background: linear-gradient(135deg, #8b0000, #4a0000);
            color: var(--gold); font-size: 0.8rem; padding: 3px 14px;
            border-radius: 12px; border: 1px solid var(--gold); letter-spacing: 2px; margin: 8px 0;
        }
        .user-nickname-lg {
            font-size: 1.8rem; color: var(--gold); letter-spacing: 3px;
            margin: 12px 0 4px; text-shadow: 0 0 20px rgba(212,175,55,0.3);
        }
        .user-username { font-size: 0.85rem; color: var(--text-muted, #8a7a7a); }
        .user-join-date { font-size: 0.8rem; color: #6a5050; margin-top: 6px; }
        .user-stats { display: flex; justify-content: center; gap: 40px; margin: 24px 0 0; flex-wrap: wrap; }
        .user-stat-item { text-align: center; min-width: 70px; }
        .user-stat-num { font-size: 1.6rem; font-weight: bold; color: var(--scarlet-light, #cc3333); line-height: 1; }
        .user-stat-label { font-size: 0.75rem; color: var(--text-muted); margin-top: 4px; }

        /* 操作按钮 */
        .user-actions { display: flex; justify-content: center; gap: 12px; margin: 20px 0 0; flex-wrap: wrap; }
        .btn-friend { padding: 8px 24px; border-radius: 20px; font-size: 0.9rem; cursor: pointer; letter-spacing: 1px; transition: all 0.3s ease; font-family: inherit; border: none; }
        .btn-friend-add { background: linear-gradient(135deg, var(--scarlet), #4a0000); color: var(--gold); border: 1px solid var(--gold); }
        .btn-friend-add:hover { background: linear-gradient(135deg, #a01010, #6a0000); box-shadow: 0 0 15px rgba(212,175,55,0.3); }
        .btn-friend-pending { background: #2a1a1a; color: #8a7a7a; border: 1px solid #4a3030; cursor: not-allowed; }
        .btn-friend-accept { background: linear-gradient(135deg, #1a4a1a, #0a2a0a); color: #7fbf7f; border: 1px solid #7fbf7f; }
        .btn-friend-accept:hover { background: linear-gradient(135deg, #2a5a2a, #1a3a1a); }
        .btn-friend-decline { background: linear-gradient(135deg, #3a1010, #1a0505); color: #cc6666; border: 1px solid #cc6666; }
        .btn-friend-decline:hover { background: linear-gradient(135deg, #4a1515, #2a0505); }
        .btn-friend-remove { background: linear-gradient(135deg, var(--scarlet), #4a0000); color: #e0a0a0; border: 1px solid #e0a0a0; }
        .btn-friend-remove:hover { background: linear-gradient(135deg, #a01010, #6a0000); }
        .btn-go-chat { background: linear-gradient(135deg, #2a1a4a, #150a2a); color: #b090d0; border: 1px solid #b090d0; }
        .btn-go-chat:hover { background: linear-gradient(135deg, #3a2a5a, #251a3a); }

        /* 编辑区（仅自己可见） */
        .user-edit-section { max-width: 700px; margin: 0 auto 20px; }
        .profile-tabs { display: flex; gap: 0; border-bottom: 1px solid var(--border-dark, #3a1010); margin-bottom: 20px; }
        .profile-tab {
            flex: 1; text-align: center; padding: 12px; cursor: pointer;
            color: var(--text-muted); border-bottom: 2px solid transparent;
            letter-spacing: 1px; font-size: 0.85rem; transition: all 0.3s;
        }
        .profile-tab:hover { color: var(--text-light); }
        .profile-tab.active { color: var(--gold); border-bottom-color: var(--gold); }
        .profile-panel { display: none; }
        .profile-panel.active { display: block; }
        .profile-panel .form-group { margin-bottom: 20px; }
        .profile-panel label { display: block; color: var(--gold); font-size: 0.85rem; letter-spacing: 2px; margin-bottom: 8px; }
        .profile-panel input {
            width: 100%; background: var(--bg-dark, #0d0505); border: 1px solid var(--border-dark, #3a1010);
            color: var(--text-light); padding: 12px 16px; font-size: 0.95rem; border-radius: 4px; transition: all 0.3s;
        }
        .profile-panel input:focus { outline: none; border-color: var(--gold-dark, #b8960e); box-shadow: 0 0 12px rgba(212,175,55,0.15); }
        .profile-panel input[readonly] { opacity: 0.6; cursor: not-allowed; }

        /* 文章列表 */
        .user-posts-section { margin-top: 24px; }
        .user-posts-header { font-size: 1.1rem; color: var(--gold); letter-spacing: 2px; padding-bottom: 12px; border-bottom: 1px solid #3a1010; margin-bottom: 16px; }
        .user-post-card { background: linear-gradient(180deg, #1a0d0d, #0f0808); border: 1px solid #2a1010; border-radius: 8px; padding: 16px 20px; margin-bottom: 12px; transition: border-color 0.3s; }
        .user-post-card:hover { border-color: var(--scarlet); }
        .user-post-title { font-size: 1.05rem; margin-bottom: 6px; }
        .user-post-title a { color: var(--gold); text-decoration: none; }
        .user-post-title a:hover { text-decoration: underline; }
        .user-post-excerpt { font-size: 0.85rem; color: var(--text-muted); line-height: 1.6; }
        .user-post-meta { font-size: 0.75rem; color: #6a5050; margin-top: 8px; }
        .user-post-tag { display: inline-block; background: #1a0a0a; color: var(--scarlet-light); font-size: 0.7rem; padding: 2px 8px; border-radius: 8px; margin-right: 4px; border: 1px solid #3a1010; }
        .user-no-posts { text-align: center; color: var(--text-muted); padding: 30px; }
        .hidden-file-input { display: none; }

        /* ===== 头像裁剪模态框 ===== */
        .crop-modal-dialog { max-width: 520px; }
        .crop-modal-body { padding: 20px 25px; }
        .crop-workspace { display: flex; gap: 20px; align-items: flex-start; justify-content: center; flex-wrap: wrap; margin-bottom: 20px; }
        .crop-area-container { position: relative; width: 280px; height: 280px; overflow: hidden; background: var(--bg-dark); border: 1px solid var(--border-dark); border-radius: 4px; cursor: grab; user-select: none; flex-shrink: 0; }
        .crop-area-container:active { cursor: grabbing; }
        .crop-mask { position: absolute; inset: 0; pointer-events: none; z-index: 2; background: radial-gradient(circle 110px at center, transparent 110px, rgba(0,0,0,0.75) 111px); }
        .crop-circle { position: absolute; top: 50%; left: 50%; transform: translate(-50%,-50%); width: 220px; height: 220px; border-radius: 50%; border: 2px solid var(--gold); box-shadow: 0 0 12px rgba(212,175,55,0.25), inset 0 0 12px rgba(212,175,55,0.1); pointer-events: none; z-index: 3; }
        .crop-image { position: absolute; z-index: 1; }
        .crop-preview-section { display: flex; flex-direction: column; align-items: center; gap: 8px; flex-shrink: 0; }
        .crop-preview-label { color: var(--text-muted); font-size: 0.75rem; }
        .crop-preview-circle { width: 80px; height: 80px; border-radius: 50%; overflow: hidden; border: 2px solid var(--gold); box-shadow: 0 0 15px rgba(212,175,55,0.3); background: var(--scarlet-darkest); }
        .crop-preview-circle canvas { width: 100%; height: 100%; display: block; }
        .crop-controls { display: flex; align-items: center; justify-content: center; gap: 12px; margin-bottom: 20px; }
        .crop-zoom-icon { color: var(--text-muted); font-size: 0.9rem; }
        .crop-zoom-slider { flex: 1; max-width: 250px; -webkit-appearance: none; appearance: none; height: 4px; border-radius: 2px; background: var(--border-dark); outline: none; cursor: pointer; }
        .crop-zoom-slider::-webkit-slider-thumb { -webkit-appearance: none; width: 18px; height: 18px; border-radius: 50%; background: var(--scarlet); border: 2px solid var(--gold-dark); cursor: pointer; }
        .crop-actions { justify-content: center; gap: 16px; }

        @media (max-width: 600px) {
            .user-avatar-lg { width: 120px; height: 120px; }
            .user-nickname-lg { font-size: 1.3rem; }
            .user-stats { gap: 20px; }
            .user-stat-num { font-size: 1.3rem; }
            .crop-area-container { width: 240px; height: 240px; }
            .crop-mask { background: radial-gradient(circle 95px at center, transparent 95px, rgba(0,0,0,0.75) 96px); }
            .crop-circle { width: 190px; height: 190px; }
        }
    </style>
</head>
<body>
    <header class="scarlet-header">
        <div class="header-inner">
            <div class="logo-area">
                <div class="logo-icon">🏰</div>
                <div class="logo-text"><h1>红 魔 馆</h1><span class="subtitle">Scarlet Devil Mansion</span></div>
            </div>
            <nav class="nav-links">
                <a href="<%=ctxPath%>/blog" title="大厅">🏠 大厅</a>
                <% if (currentUser.isAdmin()) { %><a href="<%=ctxPath%>/blog/admin">⚙️ 管理室</a><% } %>
                <a href="<%=ctxPath%>/blog/chat" id="navChatLink">🍵 茶话会<span id="navChatBadge" class="nav-badge" style="display:none;">0</span></a>
                <% if (isOwnProfile) { %>
                <a href="<%=ctxPath%>/blog/user?id=<%=currentUser.getId()%>" class="active">🏷️ 我的主页</a>
                <% } else { %>
                <a href="<%=ctxPath%>/blog/user?id=<%=currentUser.getId()%>">🏷️ 我的主页</a>
                <% } %>
                <a href="<%=ctxPath%>/api/auth/logout" style="color:var(--scarlet-light)">🚪 离馆</a>
            </nav>
        </div>
    </header>

    <div class="main-container">
        <div class="content-area">
            <%-- ===== Banner ===== --%>
            <div class="user-banner">
                <div class="user-avatar-wrap">
                    <img class="user-avatar-lg<%= isOwnProfile ? " clickable" : "" %>"
                         id="avatarPreview" src="<%= avatarSrc %>"
                         alt="<%= HtmlUtil.escape(profileUser.getNickname()) %>"
                         <%= isOwnProfile ? "onclick=\"document.getElementById('avatarFileInput').click()\" title=\"点击更换头像\"" : "" %>>
                    <% if (isOwnProfile) { %>
                    <div class="avatar-edit-badge" onclick="document.getElementById('avatarFileInput').click()" title="更换头像">📷</div>
                    <% } %>
                </div>
                <% if (isOwnProfile) { %>
                <input type="file" class="hidden-file-input" id="avatarFileInput" accept="image/jpeg,image/png,image/gif,image/webp" onchange="onAvatarFileSelected(event)">
                <% } %>
                <div class="user-nickname-lg"><%= HtmlUtil.escape(profileUser.getNickname()) %></div>
                <div class="user-username">@<%= HtmlUtil.escape(profileUser.getUsername()) %></div>
                <div class="user-role-badge"><%= HtmlUtil.escape(profileUser.getRole()) %></div>
                <div class="user-join-date">🕐 入馆于 <%= profileUser.getCreatedAt() != null ? new SimpleDateFormat("yyyy年MM月dd日").format(profileUser.getCreatedAt()) : "未知" %></div>

                <div class="user-stats">
                    <div class="user-stat-item"><div class="user-stat-num"><%= postCount %></div><div class="user-stat-label">📝 文章</div></div>
                    <div class="user-stat-item"><div class="user-stat-num"><%= friendCount %></div><div class="user-stat-label">👥 友人</div></div>
                    <div class="user-stat-item"><div class="user-stat-num"><%= commentCount %></div><div class="user-stat-label">💬 评论</div></div>
                </div>

                <% if (!isOwnProfile) { %>
                <div class="user-actions" id="userActions">
                    <% if ("none".equals(relationship)) { %>
                        <button class="btn-friend btn-friend-add" onclick="sendFriendRequest()">✉️ 发送邀请函</button>
                    <% } else if ("pending_sent".equals(relationship)) { %>
                        <button class="btn-friend btn-friend-pending" disabled>📨 邀请函已发送</button>
                    <% } else if ("pending_received".equals(relationship)) { %>
                        <button class="btn-friend btn-friend-accept" onclick="acceptRequest()">✅ 接受邀请</button>
                        <button class="btn-friend btn-friend-decline" onclick="rejectRequest()">❌ 婉拒</button>
                    <% } else if ("friend".equals(relationship)) { %>
                        <button class="btn-friend btn-go-chat" onclick="enterChat()">🍵 进入茶室</button>
                        <button class="btn-friend btn-friend-remove" onclick="removeFriend()">💔 移除友人</button>
                    <% } %>
                </div>
                <% } %>
            </div>

            <%-- ===== 自己的编辑面板 ===== --%>
            <% if (isOwnProfile) { %>
            <div class="user-edit-section">
                <div class="profile-tabs">
                    <div class="profile-tab active" onclick="switchTab('info')">📋 个人资料</div>
                    <div class="profile-tab" onclick="switchTab('edit')">✏️ 编辑称呼</div>
                    <div class="profile-tab" onclick="switchTab('password')">🔐 修改密语</div>
                </div>

                <div class="profile-panel active" id="panel-info">
                    <div style="background: linear-gradient(180deg, #1a0d0d, #0f0808); border: 1px solid #2a1010; border-radius: 8px; padding: 20px;">
                        <div style="display:flex;justify-content:space-between;align-items:center;padding:14px 0;border-bottom:1px dotted rgba(139,0,0,0.2);">
                            <span style="color:var(--text-muted);">📛 名札</span>
                            <span style="color:var(--text-light);"><%= HtmlUtil.escape(profileUser.getUsername()) %></span>
                        </div>
                        <div style="display:flex;justify-content:space-between;align-items:center;padding:14px 0;border-bottom:1px dotted rgba(139,0,0,0.2);">
                            <span style="color:var(--text-muted);">🎭 称呼</span>
                            <span style="color:var(--text-light);"><%= HtmlUtil.escape(profileUser.getNickname()) %></span>
                        </div>
                        <div style="display:flex;justify-content:space-between;align-items:center;padding:14px 0;border-bottom:1px dotted rgba(139,0,0,0.2);">
                            <span style="color:var(--text-muted);">⚜️ 身份</span>
                            <span style="color:var(--text-light);"><%= HtmlUtil.escape(profileUser.getRole()) %></span>
                        </div>
                        <div style="display:flex;justify-content:space-between;align-items:center;padding:14px 0;">
                            <span style="color:var(--text-muted);">📅 入馆日期</span>
                            <span style="color:var(--text-light);"><%= profileUser.getCreatedAt() != null ? new SimpleDateFormat("yyyy年MM月dd日").format(profileUser.getCreatedAt()) : "未知" %></span>
                        </div>
                    </div>
                </div>

                <div class="profile-panel" id="panel-edit">
                    <form onsubmit="saveProfile(event)" style="background: linear-gradient(180deg, #1a0d0d, #0f0808); border: 1px solid #2a1010; border-radius: 8px; padding: 20px;">
                        <div class="form-group">
                            <label>📛 名札（不可修改）</label>
                            <input type="text" value="<%= HtmlUtil.escape(profileUser.getUsername()) %>" readonly>
                        </div>
                        <div class="form-group">
                            <label>🎭 称呼</label>
                            <input type="text" id="editNickname" value="<%= HtmlUtil.escape(profileUser.getNickname()) %>" maxlength="50" required>
                        </div>
                        <div class="form-actions" style="text-align:right;">
                            <button type="submit" class="btn-scarlet">💾 保存称呼</button>
                        </div>
                    </form>
                </div>

                <div class="profile-panel" id="panel-password">
                    <form onsubmit="changePassword(event)" style="background: linear-gradient(180deg, #1a0d0d, #0f0808); border: 1px solid #2a1010; border-radius: 8px; padding: 20px;">
                        <div class="form-group">
                            <label>🔐 当前封印密语</label>
                            <input type="password" id="oldPassword" placeholder="输入当前密码" required>
                        </div>
                        <div class="form-group">
                            <label>🔑 新的封印密语</label>
                            <input type="password" id="newPassword" placeholder="至少4位" minlength="4" required>
                        </div>
                        <div class="form-group">
                            <label>🔑 确认封印密语</label>
                            <input type="password" id="confirmPassword" placeholder="再次输入新密码" minlength="4" required>
                        </div>
                        <div class="form-actions" style="text-align:right;">
                            <button type="submit" class="btn-scarlet">🔐 更新密语</button>
                        </div>
                    </form>
                </div>
            </div>
            <% } %>

            <%-- ===== 最近文章 ===== --%>
            <div class="user-posts-section">
                <div class="user-posts-header"><%= isOwnProfile ? "📝 我的文章" : "📝 最近文章" %></div>
                <% if (recentPosts != null && !recentPosts.isEmpty()) {
                    for (Post p : recentPosts) {
                        String excerpt = p.getExcerpt();
                        if (excerpt == null || excerpt.isEmpty()) {
                            String content = p.getContent();
                            excerpt = content != null ? content.replaceAll("<[^>]*>", "") : "";
                            if (excerpt.length() > 150) excerpt = excerpt.substring(0, 150) + "...";
                        }
                %>
                <div class="user-post-card">
                    <div class="user-post-title"><a href="<%=ctxPath%>/blog/post?id=<%=p.getId()%>"><%= HtmlUtil.escape(p.getTitle()) %></a></div>
                    <div class="user-post-excerpt"><%= HtmlUtil.escape(excerpt) %></div>
                    <div class="user-post-meta">
                        <span>🕐 <%= p.getCreatedAt() != null ? new SimpleDateFormat("yyyy-MM-dd").format(p.getCreatedAt()) : "" %></span>
                        <span style="margin-left:10px;">👁️ <%= p.getViewCount() %></span>
                        <% if (p.getCategoryName() != null && !p.getCategoryName().isEmpty()) { %>
                        <span style="margin-left:10px;"><%= HtmlUtil.escape(p.getCategoryIcon() != null ? p.getCategoryIcon() : "📜") %> <%= HtmlUtil.escape(p.getCategoryName()) %></span>
                        <% } %>
                    </div>
                    <% if (p.getTags() != null && !p.getTags().isEmpty()) {
                        for (String tag : p.getTags().split(",")) { %>
                        <span class="user-post-tag"><%= HtmlUtil.escape(tag.trim()) %></span>
                    <%  }
                       } %>
                </div>
                <%     }
                   } else { %>
                <div class="user-no-posts"><div style="font-size:2rem;">📜</div><p>暂无文章</p></div>
                <% } %>
            </div>
        </div>
    </div>

    <footer class="scarlet-footer">
        <div class="footer-ornament">◆ ◇ ◆</div>
        <p>🏰 红魔馆博客 — Scarlet Devil Mansion Blog</p>
        <p>© 2024 红魔馆 | Powered by Java Servlet &amp; MySQL</p>
    </footer>

    <div id="toastContainer" style="position:fixed;top:80px;right:20px;z-index:9999;display:flex;flex-direction:column;gap:8px;"></div>

    <%-- ===== 头像裁剪模态框（仅自己） ===== --%>
    <% if (isOwnProfile) { %>
    <div class="modal-overlay" id="cropModal">
        <div class="modal-dialog crop-modal-dialog">
            <div class="modal-header">
                <h3>🎭 裁剪头像</h3>
                <button class="modal-close" onclick="closeCropModal()">×</button>
            </div>
            <div class="modal-body crop-modal-body">
                <div class="crop-workspace">
                    <div class="crop-area-container" id="cropAreaContainer">
                        <div class="crop-mask"></div>
                        <div class="crop-circle"></div>
                        <img class="crop-image" id="cropImage" alt="裁剪预览" draggable="false">
                    </div>
                    <div class="crop-preview-section">
                        <p class="crop-preview-label">预览</p>
                        <div class="crop-preview-circle">
                            <canvas id="cropPreviewCanvas" width="80" height="80"></canvas>
                        </div>
                    </div>
                </div>
                <div class="crop-controls">
                    <span class="crop-zoom-icon">🔍−</span>
                    <input type="range" class="crop-zoom-slider" id="cropZoomSlider" min="50" max="300" value="100" step="1">
                    <span class="crop-zoom-icon">🔍+</span>
                </div>
                <div class="form-actions crop-actions">
                    <button type="button" class="btn-scarlet-outline" onclick="closeCropModal()">取消</button>
                    <button type="button" class="btn-scarlet" id="btnCropConfirm" onclick="confirmCrop()">确认</button>
                </div>
            </div>
        </div>
    </div>
    <% } %>

    <script>
        var CTX_PATH = '<%=ctxPath%>';
    </script>

    <%-- 自己的编辑 JS --%>
    <% if (isOwnProfile) { %>
    <script src="<%=ctxPath%>/js/api.js?v=20260616"></script>
    <script>
        function switchTab(tab) {
            document.querySelectorAll('.profile-tab').forEach(function(t) {
                t.classList.toggle('active',
                    (tab === 'info' && t.textContent.includes('个人资料')) ||
                    (tab === 'edit' && t.textContent.includes('编辑称呼')) ||
                    (tab === 'password' && t.textContent.includes('修改密语'))
                );
            });
            document.querySelectorAll('.profile-panel').forEach(function(p) { p.classList.remove('active'); });
            var el = document.getElementById('panel-' + tab);
            if (el) el.classList.add('active');
        }

        // === 头像裁剪 ===
        var cropState = { image: null, scale: 1.0, offsetX: 0, offsetY: 0, dragging: false, dragStartX: 0, dragStartY: 0, dragStartOffsetX: 0, dragStartOffsetY: 0 };
        var CROP_SIZE = 280, CIRCLE_RADIUS = 110, OUTPUT_SIZE = 400;

        function onAvatarFileSelected(e) {
            var f = e.target.files[0];
            if (!f) return;
            if (!/^image\/(jpeg|png|gif|webp)$/.test(f.type)) { showToast('仅支持 JPG/PNG/GIF/WebP', 'error'); e.target.value = ''; return; }
            if (f.size > 5*1024*1024) { showToast('文件不能超过 5MB', 'error'); e.target.value = ''; return; }
            var r = new FileReader();
            r.onload = function(ev) { var img = new Image(); img.onload = function() { openCropModal(img); }; img.src = ev.target.result; };
            r.readAsDataURL(f);
        }
        function openCropModal(img) {
            if (window.innerWidth <= 500) { CROP_SIZE = 240; CIRCLE_RADIUS = 95; } else { CROP_SIZE = 280; CIRCLE_RADIUS = 110; }
            document.getElementById('cropAreaContainer').style.width = CROP_SIZE + 'px';
            document.getElementById('cropAreaContainer').style.height = CROP_SIZE + 'px';
            cropState.image = img; cropState.scale = 1.0;
            var minDim = Math.min(img.naturalWidth, img.naturalHeight);
            var s = (2*CIRCLE_RADIUS)/minDim;
            cropState.scale = s < 0.4 ? 0.5 : s;
            document.getElementById('cropZoomSlider').value = Math.round(cropState.scale*100);
            var sw = img.naturalWidth*cropState.scale, sh = img.naturalHeight*cropState.scale;
            cropState.offsetX = (CROP_SIZE-sw)/2; cropState.offsetY = (CROP_SIZE-sh)/2;
            applyCropTransform(); document.getElementById('cropModal').classList.add('active'); renderCropPreview();
        }
        function closeCropModal() { document.getElementById('cropModal').classList.remove('active'); document.getElementById('avatarFileInput').value = ''; cropState.image = null; }
        function applyCropTransform() {
            var img = document.getElementById('cropImage'); img.src = cropState.image.src;
            var sw = cropState.image.naturalWidth*cropState.scale, sh = cropState.image.naturalHeight*cropState.scale;
            img.style.left = cropState.offsetX+'px'; img.style.top = cropState.offsetY+'px';
            img.style.width = sw+'px'; img.style.height = sh+'px';
        }
        function clampImagePosition() {
            var sw = cropState.image.naturalWidth*cropState.scale, sh = cropState.image.naturalHeight*cropState.scale;
            var cx = CROP_SIZE/2, cy = CROP_SIZE/2;
            if (sw < 2*CIRCLE_RADIUS) cropState.offsetX = cx-sw/2;
            else cropState.offsetX = Math.max(cx-sw+CIRCLE_RADIUS, Math.min(cx-CIRCLE_RADIUS, cropState.offsetX));
            if (sh < 2*CIRCLE_RADIUS) cropState.offsetY = cy-sh/2;
            else cropState.offsetY = Math.max(cy-sh+CIRCLE_RADIUS, Math.min(cy-CIRCLE_RADIUS, cropState.offsetY));
        }
        function zoomAtCenter(newScale) {
            var cx = CROP_SIZE/2, cy = CROP_SIZE/2;
            var natX = (cx-cropState.offsetX)/cropState.scale, natY = (cy-cropState.offsetY)/cropState.scale;
            cropState.scale = newScale;
            cropState.offsetX = cx-natX*newScale; cropState.offsetY = cy-natY*newScale;
            clampImagePosition(); applyCropTransform(); renderCropPreview();
        }
        function renderCropPreview() {
            if (!cropState.image) return;
            var c = document.getElementById('cropPreviewCanvas'), ctx = c.getContext('2d');
            ctx.clearRect(0,0,80,80);
            var cx = CROP_SIZE/2, cy = CROP_SIZE/2;
            var sx = (cx-CIRCLE_RADIUS-cropState.offsetX)/cropState.scale, sy = (cy-CIRCLE_RADIUS-cropState.offsetY)/cropState.scale;
            var sw = (2*CIRCLE_RADIUS)/cropState.scale, sh = (2*CIRCLE_RADIUS)/cropState.scale;
            var csx = Math.max(0,sx), csy = Math.max(0,sy);
            var csw = Math.min(sw, cropState.image.naturalWidth-csx), csh = Math.min(sh, cropState.image.naturalHeight-csy);
            if (csw<=0||csh<=0) return;
            ctx.save(); ctx.beginPath(); ctx.arc(40,40,40,0,Math.PI*2); ctx.clip();
            ctx.drawImage(cropState.image, csx, csy, csw, csh, (csx-sx)/sw*80, (csy-sy)/sh*80, csw/sw*80, csh/sh*80);
            ctx.restore();
        }
        function confirmCrop() {
            if (!cropState.image) return;
            var btn = document.getElementById('btnCropConfirm'); btn.classList.add('loading'); btn.textContent = '处理中...';
            var c = document.createElement('canvas'); c.width=OUTPUT_SIZE; c.height=OUTPUT_SIZE;
            var ctx = c.getContext('2d');
            var cx=CROP_SIZE/2, cy=CROP_SIZE/2, s=cropState.scale;
            var sx=(cx-CIRCLE_RADIUS-cropState.offsetX)/s, sy=(cy-CIRCLE_RADIUS-cropState.offsetY)/s, sw=(2*CIRCLE_RADIUS)/s, sh=(2*CIRCLE_RADIUS)/s;
            var csx=Math.max(0,sx), csy=Math.max(0,sy), csw=Math.min(sw,cropState.image.naturalWidth-csx), csh=Math.min(sh,cropState.image.naturalHeight-csy);
            ctx.save(); ctx.beginPath(); ctx.arc(OUTPUT_SIZE/2,OUTPUT_SIZE/2,OUTPUT_SIZE/2,0,Math.PI*2); ctx.clip();
            ctx.drawImage(cropState.image, csx, csy, csw, csh, (csx-sx)/sw*OUTPUT_SIZE, (csy-sy)/sh*OUTPUT_SIZE, csw/sw*OUTPUT_SIZE, csh/sh*OUTPUT_SIZE);
            ctx.restore();
            var id = ctx.getImageData(0,0,OUTPUT_SIZE,OUTPUT_SIZE), p = id.data;
            for (var i=0;i<p.length;i+=4) { if(p[i+3]===0){p[i]=26;p[i+1]=0;p[i+2]=0;p[i+3]=255;} }
            ctx.putImageData(id,0,0);
            document.getElementById('avatarPreview').src = c.toDataURL('image/png');
            c.toBlob(function(b) {
                if(!b){showToast('图片处理失败','error');btn.classList.remove('loading');btn.textContent='确认';return;}
                var fd = new FormData(); fd.append('avatar',b,'avatar.png');
                var xhr = new XMLHttpRequest(); xhr.open('POST',CTX_PATH+'/api/auth/profile',true);
                xhr.onload=function(){try{var r=JSON.parse(xhr.responseText);if(r.success){showToast('头像已更新！🎭','success');setTimeout(function(){location.reload()},1000);}else{showToast(r.error||'上传失败','error');}}catch(ex){showToast('上传失败','error');}};
                xhr.send(fd); closeCropModal(); btn.classList.remove('loading'); btn.textContent='确认';
            },'image/png',0.92);
        }
        // 拖拽和缩放事件
        document.addEventListener('DOMContentLoaded',function(){
            var con=document.getElementById('cropAreaContainer'), sl=document.getElementById('cropZoomSlider');
            con.addEventListener('mousedown',function(e){if(!cropState.image)return;e.preventDefault();cropState.dragging=true;cropState.dragStartX=e.clientX;cropState.dragStartY=e.clientY;cropState.dragStartOffsetX=cropState.offsetX;cropState.dragStartOffsetY=cropState.offsetY;});
            window.addEventListener('mousemove',function(e){if(!cropState.dragging)return;var dx=e.clientX-cropState.dragStartX,dy=e.clientY-cropState.dragStartY;cropState.offsetX=cropState.dragStartOffsetX+dx;cropState.offsetY=cropState.dragStartOffsetY+dy;clampImagePosition();applyCropTransform();renderCropPreview();});
            window.addEventListener('mouseup',function(){cropState.dragging=false;});
            con.addEventListener('touchstart',function(e){if(!cropState.image||e.touches.length!==1)return;cropState.dragging=true;cropState.dragStartX=e.touches[0].clientX;cropState.dragStartY=e.touches[0].clientY;cropState.dragStartOffsetX=cropState.offsetX;cropState.dragStartOffsetY=cropState.offsetY;});
            window.addEventListener('touchmove',function(e){if(!cropState.dragging||e.touches.length!==1)return;var dx=e.touches[0].clientX-cropState.dragStartX,dy=e.touches[0].clientY-cropState.dragStartY;cropState.offsetX=cropState.dragStartOffsetX+dx;cropState.offsetY=cropState.dragStartOffsetY+dy;clampImagePosition();applyCropTransform();renderCropPreview();});
            window.addEventListener('touchend',function(){cropState.dragging=false;});
            sl.addEventListener('input',function(){if(!cropState.image)return;zoomAtCenter(parseInt(this.value)/100);});
        });

        function saveProfile(e) {
            e.preventDefault();
            var nn = document.getElementById('editNickname').value.trim();
            if(!nn){showToast('称呼不能为空','error');return;}
            var fd = new FormData(); fd.append('nickname',nn);
            var xhr = new XMLHttpRequest(); xhr.open('POST',CTX_PATH+'/api/auth/profile',true);
            xhr.onload=function(){try{var r=JSON.parse(xhr.responseText);if(r.success){showToast('称呼已更新！✨','success');setTimeout(function(){location.reload()},1000);}else{showToast(r.error||'更新失败','error');}}catch(ex){showToast('更新失败','error');}};
            xhr.send(fd);
        }

        function changePassword(e) {
            e.preventDefault();
            var op=document.getElementById('oldPassword').value, np=document.getElementById('newPassword').value, cp=document.getElementById('confirmPassword').value;
            if(np!==cp){showToast('两次输入的密语不一致！','error');return;}
            if(np.length<4){showToast('密语至少需要4个字符！','error');return;}
            var body='old_password='+encodeURIComponent(op)+'&new_password='+encodeURIComponent(np);
            var xhr=new XMLHttpRequest();xhr.open('POST',CTX_PATH+'/api/auth/password',true);
            xhr.setRequestHeader('Content-Type','application/x-www-form-urlencoded');
            xhr.onload=function(){try{var r=JSON.parse(xhr.responseText);if(r.success){showToast('密语已更新！🔐','success');document.getElementById('oldPassword').value='';document.getElementById('newPassword').value='';document.getElementById('confirmPassword').value='';}else{showToast(r.error||'修改失败','error');}}catch(ex){showToast('修改失败','error');}};
            xhr.send(body);
        }
    </script>
    <% } %>

    <%-- 他人的好友按钮 JS --%>
    <% if (!isOwnProfile) { %>
    <script src="<%=ctxPath%>/js/api.js?v=20260616"></script>
    <script>
        var TARGET_USERNAME = '<%= HtmlUtil.escape(profileUser.getUsername()) %>';
        var TARGET_USER_ID = <%= profileUser.getId() %>;
        var FRIENDSHIP_ID = <%= friendshipId %>;

        function sendFriendRequest() {
            var btn = document.querySelector('#userActions .btn-friend-add'); if(!btn)return;
            btn.disabled=true;btn.textContent='⏳ 发送中...';
            fetch(CTX_PATH+'/api/friends',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'username='+encodeURIComponent(TARGET_USERNAME)})
            .then(function(r){return r.json()}).then(function(d){if(d.success){FRIENDSHIP_ID=d.data&&d.data.id?d.data.id:0;document.getElementById('userActions').innerHTML='<button class="btn-friend btn-friend-pending" disabled>📨 邀请函已发送</button>';showToast('邀请函已送达！📨');}else{showToast(d.error||'发送失败','error');btn.disabled=false;btn.textContent='✉️ 发送邀请函';}})
            .catch(function(){showToast('红魔馆暂时无法连接','error');btn.disabled=false;btn.textContent='✉️ 发送邀请函';});
        }
        function acceptRequest(){if(FRIENDSHIP_ID<=0)return;var btns=document.querySelectorAll('#userActions .btn-friend');btns.forEach(function(b){b.disabled=true;});fetch(CTX_PATH+'/api/friends/'+FRIENDSHIP_ID,{method:'PUT',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'action=accept'}).then(function(r){return r.json()}).then(function(d){if(d.success){document.getElementById('userActions').innerHTML='<button class="btn-friend btn-go-chat" onclick="enterChat()">🍵 进入茶室</button><button class="btn-friend btn-friend-remove" onclick="removeFriend()">💔 移除友人</button>';showToast('你们现在是友人啦！🎉');}else{showToast(d.error||'操作失败','error');btns.forEach(function(b){b.disabled=false;});}}).catch(function(){showToast('红魔馆暂时无法连接','error');btns.forEach(function(b){b.disabled=false;});});}
        function rejectRequest(){if(FRIENDSHIP_ID<=0)return;var btns=document.querySelectorAll('#userActions .btn-friend');btns.forEach(function(b){b.disabled=true;});fetch(CTX_PATH+'/api/friends/'+FRIENDSHIP_ID,{method:'PUT',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'action=reject'}).then(function(r){return r.json()}).then(function(d){if(d.success){document.getElementById('userActions').innerHTML='<button class="btn-friend btn-friend-add" onclick="sendFriendRequest()">✉️ 发送邀请函</button>';showToast('已婉拒邀请');}else{showToast(d.error||'操作失败','error');btns.forEach(function(b){b.disabled=false;});}}).catch(function(){showToast('红魔馆暂时无法连接','error');btns.forEach(function(b){b.disabled=false;});});}
        function removeFriend(){if(FRIENDSHIP_ID<=0)return;if(!confirm('确定要移除这位友人吗？'))return;var btns=document.querySelectorAll('#userActions .btn-friend');btns.forEach(function(b){b.disabled=true;});fetch(CTX_PATH+'/api/friends/'+FRIENDSHIP_ID,{method:'DELETE'}).then(function(r){return r.json()}).then(function(d){if(d.success){document.getElementById('userActions').innerHTML='<button class="btn-friend btn-friend-add" onclick="sendFriendRequest()">✉️ 发送邀请函</button>';showToast('友人已移除');}else{showToast(d.error||'操作失败','error');btns.forEach(function(b){b.disabled=false;});}}).catch(function(){showToast('红魔馆暂时无法连接','error');btns.forEach(function(b){b.disabled=false;});});}
        function enterChat(){window.location.href=CTX_PATH+'/blog/chat';}
    </script>
    <% } %>

    <script>
        function showToast(msg,type){
            var c=document.getElementById('toastContainer');if(!c)return;
            var t=document.createElement('div');t.className='toast '+(type||'success');t.textContent=msg;c.appendChild(t);
            setTimeout(function(){t.style.opacity='0';t.style.transition='all 0.4s';setTimeout(function(){t.remove();},400);},3500);
        }
    </script>

    <%-- 全局茶话会通知轮询 --%>
    <script>
    (function(){var lic=0;function pf(){fetch('<%=ctxPath%>/api/friends').then(function(r){return r.json()}).then(function(d){if(!d.success)return;var c=(d.received&&d.received.length)||0;var b=document.getElementById('navChatBadge');if(b){if(c>0){b.textContent=c;b.style.display='inline-block';}else{b.style.display='none';}}if(c>lic&&lic>0){var t=document.createElement('div');t.className='toast success';t.textContent='📨 收到新邀请函！';t.style.cssText='position:fixed;top:80px;right:20px;z-index:9999;';document.body.appendChild(t);setTimeout(function(){t.style.opacity='0';t.style.transition='all 0.5s';setTimeout(function(){t.remove();},500);},4000);}lic=c;}).catch(function(){});}pf();setInterval(pf,30000);})();
    </script>
</body>
</html>
