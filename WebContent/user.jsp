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

    String backgroundSrc = profileUser.getBackground();
    boolean hasBg = backgroundSrc != null && !backgroundSrc.isEmpty();
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
        /* ── 头图区：全宽 Banner ── */
        .user-profile-header {
            margin-bottom: 0;
            overflow: visible;
        }
        .user-cover {
            position: relative;
            width: 100%;
            height: 300px;
            background: linear-gradient(180deg, #2a0a0a 0%, #1a0505 70%, #0d0202 100%);
            background-size: cover;
            background-position: center;
            border-radius: 0 0 8px 8px;
        }
        .user-cover .banner-edit-badge {
            position: absolute; top: 12px; right: 12px;
            width: 32px; height: 32px; background: rgba(0,0,0,0.5);
            border: 1px solid rgba(255,255,255,0.3); border-radius: 50%;
            display: flex; align-items: center; justify-content: center;
            cursor: pointer; font-size: 0.85rem; color: #fff;
            transition: all 0.3s; z-index: 5;
        }
        .user-cover .banner-edit-badge:hover { background: rgba(0,0,0,0.7); transform: scale(1.1); }
        .user-cover.clickable { cursor: pointer; }

        /* ── 信息栏：头像左下角 + 昵称右侧 ── */
        .user-info-bar {
            display: flex;
            align-items: flex-end;
            padding: 0 30px 16px;
            margin-top: -64px;
            position: relative;
            z-index: 2;
        }
        .user-avatar-wrap {
            position: relative; flex-shrink: 0; margin-right: 24px;
        }
        .user-avatar-lg {
            width: 160px; height: 160px; border-radius: 50%; object-fit: cover;
            border: 4px solid var(--bg-darkest);
            box-shadow: 0 0 30px rgba(0,0,0,0.6);
            transition: transform 0.3s ease;
        }
        .user-avatar-lg:hover { transform: scale(1.05); }
        .user-avatar-lg.clickable { cursor: pointer; }
        .avatar-edit-badge {
            position: absolute; bottom: 8px; right: 8px;
            width: 32px; height: 32px; background: var(--scarlet, #8b0000);
            border: 2px solid var(--gold); border-radius: 50%;
            display: flex; align-items: center; justify-content: center;
            cursor: pointer; font-size: 0.9rem; color: var(--gold);
            box-shadow: 0 0 10px rgba(0,0,0,0.5); transition: all 0.3s;
        }
        .avatar-edit-badge:hover { background: #a01010; transform: scale(1.1); }
        .user-info-text {
            flex: 1; padding-bottom: 8px; min-width: 0;
        }
        .user-nickname-lg {
            font-size: 1.6rem; color: #fff; letter-spacing: 2px;
            margin: 0 0 4px; text-shadow: 0 0 20px rgba(0,0,0,0.5);
        }
        .user-info-sub {
            display: flex; align-items: center; gap: 10px; flex-wrap: wrap;
            font-size: 0.8rem; color: #999;
        }
        .user-username { color: #aaa; }
        .user-role-badge {
            display: inline-block; background: rgba(139,0,0,0.6);
            color: var(--gold); font-size: 0.7rem; padding: 2px 10px;
            border-radius: 10px; border: 1px solid rgba(212,175,55,0.4);
        }
        .user-join-date { color: #777; font-size: 0.75rem; }

        /* ── 右侧操作区 ── */
        .user-header-actions {
            flex-shrink: 0; text-align: right; padding-bottom: 8px;
        }
        .user-header-stats {
            display: flex; gap: 16px; justify-content: flex-end;
            margin-bottom: 10px; font-size: 0.8rem; color: #999;
        }
        .user-header-stats span { white-space: nowrap; }
        .user-header-stats strong { color: #ddd; }
        .user-actions { display: flex; gap: 8px; justify-content: flex-end; flex-wrap: wrap; }
        .btn-friend { padding: 7px 20px; border-radius: 6px; font-size: 0.85rem; cursor: pointer; letter-spacing: 1px; transition: all 0.3s ease; font-family: inherit; border: none; white-space: nowrap; }
        .btn-friend-add { background: var(--scarlet); color: #fff; }
        .btn-friend-add:hover { background: #a01010; }
        .btn-friend-pending { background: #333; color: #888; cursor: not-allowed; }
        .btn-friend-accept { background: #2a5a2a; color: #8fbc8f; border: 1px solid #5a8a5a; }
        .btn-friend-accept:hover { background: #3a6a3a; }
        .btn-friend-decline { background: #3a1010; color: #cc6666; border: 1px solid #6a3030; }
        .btn-friend-decline:hover { background: #4a1515; }
        .btn-friend-remove { background: #4a2020; color: #cc8888; border: 1px solid #6a3030; }
        .btn-friend-remove:hover { background: #5a2828; }
        .btn-go-chat { background: #2a1a4a; color: #b090d0; border: 1px solid #5a3a7a; }
        .btn-go-chat:hover { background: #3a2a5a; }

        /* ── 标签栏 ── */
        .user-tab-bar {
            display: flex; padding: 0 30px;
            border-bottom: 1px solid var(--border-dark, #3a1010);
            background: var(--bg-darkest);
        }
        .user-tab {
            padding: 12px 24px; cursor: pointer; font-size: 0.9rem;
            color: #999; border-bottom: 2px solid transparent;
            margin-bottom: -1px; transition: all 0.2s; letter-spacing: 1px;
        }
        .user-tab:hover { color: #ddd; }
        .user-tab.active { color: var(--gold); border-bottom-color: var(--gold); }

        /* ===== 双栏主布局 ===== */
        .user-main-layout { display: flex; gap: 24px; padding: 20px 0; }
        .user-content { flex: 1; min-width: 0; }
        .user-content-tabs { display: flex; gap: 0; margin-bottom: 16px; }
        .user-content-tab {
            padding: 8px 20px; cursor: pointer; font-size: 0.85rem;
            color: var(--text-muted); border-bottom: 2px solid transparent;
            transition: all 0.2s; letter-spacing: 1px;
        }
        .user-content-tab:hover { color: #ddd; }
        .user-content-tab.active { color: var(--gold); border-bottom-color: var(--scarlet); }
        .user-content-panel { display: none; }
        .user-content-panel.active { display: block; }

        /* 侧边栏 */
        .user-sidebar { width: 320px; flex-shrink: 0; }
        .sidebar-card {
            background: linear-gradient(180deg, #1a0d0d, #0f0808);
            border: 1px solid #2a1010; border-radius: 8px;
            padding: 20px; margin-bottom: 16px;
        }
        .sidebar-card-title {
            font-size: 0.9rem; color: var(--gold); letter-spacing: 2px;
            margin-bottom: 14px; padding-bottom: 10px;
            border-bottom: 1px solid rgba(139,0,0,0.3);
        }
        .sidebar-row { display: flex; justify-content: space-between; padding: 8px 0; color: var(--text-light); font-size: 0.85rem; }
        .sidebar-row-label { color: var(--text-muted); }
        .sidebar-action-btn {
            display: block; width: 100%; padding: 10px; text-align: center;
            background: var(--scarlet); color: #fff; border: none; border-radius: 6px;
            font-size: 0.9rem; cursor: pointer; letter-spacing: 1px; transition: all 0.3s;
        }
        .sidebar-action-btn:hover { background: #a01010; }

        /* 编辑区（融入侧边栏） */
        .profile-panel { display: none; }
        .profile-panel.active { display: block; }
        .profile-panel .form-group { margin-bottom: 16px; }
        .profile-panel label { display: block; color: var(--gold); font-size: 0.8rem; letter-spacing: 1px; margin-bottom: 6px; }
        .profile-panel input {
            width: 100%; background: var(--bg-dark, #0d0505); border: 1px solid var(--border-dark, #3a1010);
            color: var(--text-light); padding: 10px 14px; font-size: 0.9rem; border-radius: 4px; transition: all 0.3s;
            box-sizing: border-box;
        }
        .profile-panel input:focus { outline: none; border-color: var(--gold-dark, #b8960e); box-shadow: 0 0 12px rgba(212,175,55,0.15); }
        .profile-panel input[readonly] { opacity: 0.6; cursor: not-allowed; }

        /* 文章卡片 */
        .user-post-card { background: linear-gradient(180deg, #1a0d0d, #0f0808); border: 1px solid #2a1010; border-radius: 8px; padding: 16px 20px; margin-bottom: 12px; transition: border-color 0.3s; }
        .user-post-card:hover { border-color: var(--scarlet); }
        .user-post-title { font-size: 1.05rem; margin-bottom: 6px; }
        .user-post-title a { color: var(--gold); text-decoration: none; }
        .user-post-title a:hover { text-decoration: underline; }
        .user-post-excerpt { font-size: 0.85rem; color: var(--text-muted); line-height: 1.6; }
        .user-post-meta { font-size: 0.75rem; color: #6a5050; margin-top: 8px; }
        .user-post-tag { display: inline-block; background: #1a0a0a; color: var(--scarlet-light); font-size: 0.7rem; padding: 2px 8px; border-radius: 8px; margin-right: 4px; border: 1px solid #3a1010; }
        .user-no-posts { text-align: center; color: var(--text-muted); padding: 30px; }

        @media (max-width: 768px) {
            .user-main-layout { flex-direction: column; }
            .user-sidebar { width: 100%; }
        }
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
            .user-cover { height: 180px; }
            .user-info-bar { flex-direction: column; align-items: flex-start; padding: 0 16px 12px; margin-top: -48px; }
            .user-avatar-lg { width: 96px; height: 96px; }
            .user-avatar-wrap { margin-right: 0; margin-bottom: 8px; }
            .user-nickname-lg { font-size: 1.2rem; }
            .user-info-text { padding-bottom: 4px; }
            .user-header-actions { text-align: left; padding-bottom: 0; }
            .user-header-stats { justify-content: flex-start; gap: 12px; font-size: 0.75rem; margin-bottom: 6px; }
            .user-tab-bar { padding: 0 12px; }
            .user-tab { padding: 10px 14px; font-size: 0.8rem; }
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
            <%-- ===== Banner：全宽封面 + 头像左下角 + 信息右侧 ===== --%>
            <div class="user-profile-header">
                <div class="user-cover<%= isOwnProfile ? " clickable" : "" %>" id="userCover"
                     style="<%= hasBg ? "background-image: url(" + backgroundSrc + ");" : "" %>"
                     <%= isOwnProfile ? "onclick=\"document.getElementById('bgFileInput').click()\" title=\"点击更换背景图\"" : "" %>>
                    <% if (isOwnProfile) { %>
                    <div class="banner-edit-badge" onclick="event.stopPropagation();document.getElementById('bgFileInput').click()" title="更换背景图">🖼️</div>
                    <input type="file" class="hidden-file-input" id="bgFileInput" accept="image/jpeg,image/png,image/gif,image/webp" onchange="onBgFileSelected(event)">
                    <% } %>
                </div>

                <div class="user-info-bar">
                    <%-- 头像 → 左下角重叠 cover --%>
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

                    <%-- 昵称 + 副信息 --%>
                    <div class="user-info-text">
                        <div class="user-nickname-lg"><%= HtmlUtil.escape(profileUser.getNickname()) %></div>
                        <div class="user-info-sub">
                            <span class="user-username">@<%= HtmlUtil.escape(profileUser.getUsername()) %></span>
                            <span class="user-role-badge"><%= HtmlUtil.escape(profileUser.getRole()) %></span>
                            <span class="user-join-date">🕐 <%= profileUser.getCreatedAt() != null ? new SimpleDateFormat("yyyy年MM月dd日").format(profileUser.getCreatedAt()) : "未知" %></span>
                        </div>
                    </div>

                    <%-- 右侧：统计 + 操作按钮 --%>
                    <div class="user-header-actions">
                        <div class="user-header-stats">
                            <span><strong><%= postCount %></strong> 文章</span>
                            <span><strong><%= friendCount %></strong> 友人</span>
                            <span><strong><%= commentCount %></strong> 评论</span>
                        </div>
                        <% if (!isOwnProfile) { %>
                        <div class="user-actions" id="userActions">
                            <% if ("none".equals(relationship)) { %>
                                <button class="btn-friend btn-friend-add" onclick="sendFriendRequest()">✉️ 发送邀请函</button>
                            <% } else if ("pending_sent".equals(relationship)) { %>
                                <button class="btn-friend btn-friend-pending" disabled>📨 邀请函已发送</button>
                            <% } else if ("pending_received".equals(relationship)) { %>
                                <button class="btn-friend btn-friend-accept" onclick="acceptRequest()">✅ 接受</button>
                                <button class="btn-friend btn-friend-decline" onclick="rejectRequest()">❌ 婉拒</button>
                            <% } else if ("friend".equals(relationship)) { %>
                                <button class="btn-friend btn-go-chat" onclick="enterChat()">🍵 进入茶室</button>
                                <button class="btn-friend btn-friend-remove" onclick="removeFriend()">💔 移除</button>
                            <% } %>
                        </div>
                        <% } else { %>
                        <div class="user-actions">
                            <a href="<%=ctxPath%>/blog/admin" class="btn-friend btn-go-chat" style="text-decoration:none;display:inline-block;">⚙️ 管理室</a>
                        </div>
                        <% } %>
                    </div>
                </div>

                <%-- 标签栏 --%>
                <div class="user-tab-bar">
                    <div class="user-tab active" onclick="switchContentTab('posts')">📝 文章</div>
                    <div class="user-tab" onclick="switchContentTab('about')">📋 关于</div>
                </div>
            </div>

            <%-- ===== 双栏主体 ===== --%>
            <div class="user-main-layout">
                <%-- 左栏：内容区 --%>
                <div class="user-content">
                    <div class="user-content-tabs">
                        <div class="user-content-tab active" onclick="switchContentTab('posts')">📝 文章</div>
                        <div class="user-content-tab" onclick="switchContentTab('about')">📋 关于</div>
                    </div>

                    <%-- 文章面板 --%>
                    <div class="user-content-panel active" id="content-posts">
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

                    <%-- 关于面板 --%>
                    <div class="user-content-panel" id="content-about">
                        <div class="sidebar-card">
                            <div class="sidebar-card-title">📋 个人资料</div>
                            <div class="sidebar-row"><span class="sidebar-row-label">📛 名札</span><span><%= HtmlUtil.escape(profileUser.getUsername()) %></span></div>
                            <div class="sidebar-row"><span class="sidebar-row-label">🎭 称呼</span><span><%= HtmlUtil.escape(profileUser.getNickname()) %></span></div>
                            <div class="sidebar-row"><span class="sidebar-row-label">⚜️ 身份</span><span><%= HtmlUtil.escape(profileUser.getRole()) %></span></div>
                            <div class="sidebar-row"><span class="sidebar-row-label">📅 入馆</span><span><%= profileUser.getCreatedAt() != null ? new SimpleDateFormat("yyyy年MM月dd日").format(profileUser.getCreatedAt()) : "未知" %></span></div>
                            <% if (profileUser.getEmail() != null) { %>
                            <div class="sidebar-row"><span class="sidebar-row-label">📧 邮箱</span><span><%= HtmlUtil.escape(profileUser.getEmail()) %> <%= profileUser.isEmailVerified() ? "✅" : "⚠ 未验证" %></span></div>
                            <% } %>
                        </div>
                    </div>
                </div>

                <%-- 右栏：侧边栏 --%>
                <div class="user-sidebar">
                    <%-- 统计卡片 --%>
                    <div class="sidebar-card">
                        <div class="sidebar-card-title">📊 数据统计</div>
                        <div class="sidebar-row"><span class="sidebar-row-label">📝 文章</span><span><strong><%= postCount %></strong></span></div>
                        <div class="sidebar-row"><span class="sidebar-row-label">👥 友人</span><span><strong><%= friendCount %></strong></span></div>
                        <div class="sidebar-row"><span class="sidebar-row-label">💬 评论</span><span><strong><%= commentCount %></strong></span></div>
                    </div>

                    <%-- 自己可见：编辑面板 --%>
                    <% if (isOwnProfile) { %>
                    <div class="sidebar-card">
                        <div class="sidebar-card-title">✏️ 编辑资料</div>
                        <div class="profile-panel active" id="panel-edit">
                            <form onsubmit="saveProfile(event)">
                                <div class="form-group">
                                    <label>🎭 称呼</label>
                                    <input type="text" id="editNickname" value="<%= HtmlUtil.escape(profileUser.getNickname()) %>" maxlength="50" required>
                                </div>
                                <div style="text-align:right;">
                                    <button type="submit" class="sidebar-action-btn">💾 保存</button>
                                </div>
                            </form>
                        </div>
                        <div class="profile-panel" id="panel-password">
                            <form onsubmit="changePassword(event)">
                                <div class="form-group">
                                    <label>🔐 当前密语</label>
                                    <input type="password" id="oldPassword" placeholder="输入当前密码" required>
                                </div>
                                <div class="form-group">
                                    <label>🔑 新密语</label>
                                    <input type="password" id="newPassword" placeholder="至少4位" minlength="4" required>
                                </div>
                                <div class="form-group">
                                    <label>🔑 确认密语</label>
                                    <input type="password" id="confirmPassword" placeholder="再次输入新密码" minlength="4" required>
                                </div>
                                <div style="text-align:right;">
                                    <button type="submit" class="sidebar-action-btn">🔐 更新密语</button>
                                </div>
                            </form>
                        </div>
                        <div style="display:flex;gap:8px;margin-top:8px;">
                            <button class="sidebar-action-btn" style="flex:1;background:transparent;border:1px solid var(--border-dark);color:var(--text-muted);" onclick="switchEditTab('edit')">✏️ 称呼</button>
                            <button class="sidebar-action-btn" style="flex:1;background:transparent;border:1px solid var(--border-dark);color:var(--text-muted);" onclick="switchEditTab('password')">🔐 密语</button>
                        </div>
                    </div>
                    <% } %>

                    <%-- 自己可见：邮箱绑定 --%>
                    <% if (isOwnProfile) { %>
                    <div class="sidebar-card" style="margin-top:12px;">
                        <div class="sidebar-card-title">📧 邮箱绑定</div>
                        <% if (profileUser.getEmail() == null) { %>
                            <p style="color:var(--text-muted);font-size:0.8rem;margin-bottom:10px;">绑定QQ邮箱后可通过邮箱找回密码。</p>
                            <input type="email" id="bindEmailInput" placeholder="your-email@qq.com" style="width:100%;background:var(--bg-dark);border:1px solid var(--border-dark);color:var(--text-light);padding:8px 10px;font-size:0.85rem;border-radius:4px;margin-bottom:8px;">
                            <button class="sidebar-action-btn" onclick="bindEmail()" style="width:100%;background:rgba(139,0,0,0.4);border:1px solid var(--scarlet);color:var(--scarlet-light);">📧 发送验证邮件</button>
                        <% } else if (!profileUser.isEmailVerified()) { %>
                            <p style="color:var(--gold);font-size:0.8rem;margin-bottom:6px;">📧 <%= profileUser.getEmail() %></p>
                            <p style="color:var(--scarlet-light);font-size:0.75rem;margin-bottom:10px;">⚠ 尚未验证，请检查邮箱中的验证链接。</p>
                            <div style="display:flex;gap:6px;">
                                <button class="sidebar-action-btn" onclick="bindEmail()" style="flex:1;background:rgba(139,0,0,0.4);border:1px solid var(--scarlet);color:var(--scarlet-light);">🔄 重发验证</button>
                                <button class="sidebar-action-btn" onclick="unbindEmail()" style="flex:1;background:transparent;border:1px solid var(--scarlet-darkest);color:var(--scarlet-light);">❌ 解绑</button>
                            </div>
                        <% } else { %>
                            <p style="color:var(--gold);font-size:0.85rem;margin-bottom:4px;">📧 <%= profileUser.getEmail() %></p>
                            <p style="color:#2ecc71;font-size:0.75rem;margin-bottom:10px;">✅ 已验证 · 可通过邮箱找回密码</p>
                            <div style="display:flex;gap:6px;">
                                <button class="sidebar-action-btn" onclick="changeEmail()" style="flex:1;background:transparent;border:1px solid var(--border-dark);color:var(--text-muted);">🔄 更换</button>
                                <button class="sidebar-action-btn" onclick="unbindEmail()" style="flex:1;background:transparent;border:1px solid var(--scarlet-darkest);color:var(--scarlet-light);">❌ 解绑</button>
                            </div>
                            <div id="changeEmailBox" style="display:none;margin-top:8px;">
                                <input type="email" id="bindEmailInput2" placeholder="输入新邮箱" style="width:100%;background:var(--bg-dark);border:1px solid var(--border-dark);color:var(--text-light);padding:8px 10px;font-size:0.85rem;border-radius:4px;margin-bottom:8px;">
                                <button class="sidebar-action-btn" onclick="bindEmail()" style="width:100%;background:rgba(139,0,0,0.4);border:1px solid var(--scarlet);color:var(--scarlet-light);">📧 发送新验证邮件</button>
                            </div>
                        <% } %>
                    </div>
                    <% } %>

                    <%-- 访客可见：快捷操作 --%>
                    <% if (!isOwnProfile) { %>
                    <div class="sidebar-card">
                        <div class="sidebar-card-title">🔗 快捷操作</div>
                        <a href="<%=ctxPath%>/blog" class="sidebar-action-btn" style="text-decoration:none;display:block;background:transparent;border:1px solid var(--gold);color:var(--gold);">🏠 返回大厅</a>
                    </div>
                    <% } %>
                </div>
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

    <%-- ===== 背景图裁剪模态框 ===== --%>
    <% if (isOwnProfile) { %>
    <div class="modal-overlay" id="bgCropModal" onclick="if(event.target===this)closeBgCropModal()">
        <div class="modal-dialog bg-crop-modal-dialog">
            <div class="modal-header">
                <h3>🖼️ 裁剪背景图</h3>
                <button class="modal-close" onclick="closeBgCropModal()">✕</button>
            </div>
            <div class="modal-body bg-crop-modal-body">
                <div class="bg-crop-workspace">
                    <div class="bg-crop-area-container" id="bgCropAreaContainer">
                        <div class="bg-crop-rect"></div>
                        <img class="bg-crop-image" id="bgCropImage" alt="背景裁剪预览" draggable="false">
                    </div>
                    <div class="bg-crop-preview-section">
                        <p class="crop-preview-label">预览</p>
                        <div class="bg-crop-preview-rect">
                            <canvas id="bgCropPreviewCanvas" width="240" height="80"></canvas>
                        </div>
                    </div>
                </div>
                <div class="crop-controls">
                    <span class="crop-zoom-icon">🔍−</span>
                    <input type="range" class="crop-zoom-slider" id="bgZoomSlider" min="50" max="300" value="100" step="1">
                    <span class="crop-zoom-icon">🔍+</span>
                </div>
                <div class="form-actions crop-actions">
                    <button type="button" class="btn-scarlet-outline" onclick="closeBgCropModal()">取消</button>
                    <button type="button" class="btn-scarlet" id="btnBgCropConfirm" onclick="confirmBgCrop()">确认</button>
                </div>
            </div>
        </div>
    </div>
    <% } %>

    <script>
        var CTX_PATH = '<%=ctxPath%>';
    </script>

    <%-- 公共 JS：tab 切换（自己和别人页面都需要） --%>
    <script>
        function switchContentTab(tab) {
            document.querySelectorAll('.user-content-tab').forEach(function(t) { t.classList.remove('active'); });
            document.querySelectorAll('.user-content-panel').forEach(function(p) { p.classList.remove('active'); });
            document.querySelectorAll('.user-tab').forEach(function(t) { t.classList.remove('active'); });
            if (tab === 'posts') {
                document.querySelectorAll('.user-content-tab')[0].classList.add('active');
                document.getElementById('content-posts').classList.add('active');
                document.querySelectorAll('.user-tab')[0].classList.add('active');
            } else if (tab === 'about') {
                document.querySelectorAll('.user-content-tab')[1].classList.add('active');
                document.getElementById('content-about').classList.add('active');
                document.querySelectorAll('.user-tab')[1].classList.add('active');
            }
        }
    </script>
    <% if (isOwnProfile) { %>
    <script src="<%=ctxPath%>/js/api.js?v=20260616"></script>
    <script>
        function switchEditTab(tab) {
            document.querySelectorAll('.profile-panel').forEach(function(p) { p.classList.remove('active'); });
            document.getElementById('panel-' + tab).classList.add('active');
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

        // === 背景图裁剪 ===
        var bgCropState = { image: null, scale: 1.0, offsetX: 0, offsetY: 0, dragging: false, dragStartX: 0, dragStartY: 0, dragStartOffsetX: 0, dragStartOffsetY: 0 };
        var BG_CROP_W = 750, BG_CROP_H = 250, BG_RECT_W = 720, BG_RECT_H = 240, BG_OUTPUT_W = 1200, BG_OUTPUT_H = 400;

        function onBgFileSelected(e) {
            var f = e.target.files[0];
            if (!f) return;
            if (!/^image\/(jpeg|png|gif|webp)$/.test(f.type)) { showToast('仅支持 JPG/PNG/GIF/WebP', 'error'); e.target.value = ''; return; }
            if (f.size > 5*1024*1024) { showToast('文件不能超过 5MB', 'error'); e.target.value = ''; return; }
            var r = new FileReader();
            r.onload = function(ev) { var img = new Image(); img.onload = function() { openBgCropModal(img); }; img.src = ev.target.result; };
            r.readAsDataURL(f);
        }

        function openBgCropModal(img) {
            if (window.innerWidth <= 600) { BG_CROP_W = 300; BG_CROP_H = 100; BG_RECT_W = 285; BG_RECT_H = 95; }
            else { BG_CROP_W = 750; BG_CROP_H = 250; BG_RECT_W = 720; BG_RECT_H = 240; }
            var con = document.getElementById('bgCropAreaContainer');
            con.style.width = BG_CROP_W + 'px'; con.style.height = BG_CROP_H + 'px';
            var rect = con.querySelector('.bg-crop-rect');
            rect.style.width = BG_RECT_W + 'px'; rect.style.height = BG_RECT_H + 'px';
            bgCropState.image = img; bgCropState.scale = 1.0;
            var sW = BG_RECT_W / img.naturalWidth, sH = BG_RECT_H / img.naturalHeight;
            bgCropState.scale = Math.max(sW, sH);
            if (bgCropState.scale < 0.4) bgCropState.scale = 0.5;
            document.getElementById('bgZoomSlider').value = Math.round(bgCropState.scale * 100);
            var sw = img.naturalWidth * bgCropState.scale, sh = img.naturalHeight * bgCropState.scale;
            bgCropState.offsetX = (BG_CROP_W - sw) / 2;
            bgCropState.offsetY = (BG_CROP_H - sh) / 2;
            applyBgTransform();
            document.getElementById('bgCropModal').classList.add('active');
            renderBgPreview();
        }

        function closeBgCropModal() {
            document.getElementById('bgCropModal').classList.remove('active');
            document.getElementById('bgFileInput').value = '';
            bgCropState.image = null;
        }

        function applyBgTransform() {
            var el = document.getElementById('bgCropImage');
            el.src = bgCropState.image.src;
            var sw = bgCropState.image.naturalWidth * bgCropState.scale;
            var sh = bgCropState.image.naturalHeight * bgCropState.scale;
            el.style.left = bgCropState.offsetX + 'px';
            el.style.top = bgCropState.offsetY + 'px';
            el.style.width = sw + 'px';
            el.style.height = sh + 'px';
        }

        function clampBgPosition() {
            var sw = bgCropState.image.naturalWidth * bgCropState.scale;
            var sh = bgCropState.image.naturalHeight * bgCropState.scale;
            var cx = BG_CROP_W / 2, cy = BG_CROP_H / 2;
            if (sw < BG_RECT_W) bgCropState.offsetX = cx - sw / 2;
            else bgCropState.offsetX = Math.max(cx - sw + BG_RECT_W / 2, Math.min(cx - BG_RECT_W / 2, bgCropState.offsetX));
            if (sh < BG_RECT_H) bgCropState.offsetY = cy - sh / 2;
            else bgCropState.offsetY = Math.max(cy - sh + BG_RECT_H / 2, Math.min(cy - BG_RECT_H / 2, bgCropState.offsetY));
        }

        function bgZoomAtCenter(newScale) {
            var cx = BG_CROP_W / 2, cy = BG_CROP_H / 2;
            var natX = (cx - bgCropState.offsetX) / bgCropState.scale;
            var natY = (cy - bgCropState.offsetY) / bgCropState.scale;
            bgCropState.scale = newScale;
            bgCropState.offsetX = cx - natX * newScale;
            bgCropState.offsetY = cy - natY * newScale;
            clampBgPosition(); applyBgTransform(); renderBgPreview();
        }

        function renderBgPreview() {
            if (!bgCropState.image) return;
            var c = document.getElementById('bgCropPreviewCanvas'), ctx = c.getContext('2d');
            var pw = 240, ph = 80;
            ctx.clearRect(0, 0, pw, ph);
            var cx = BG_CROP_W / 2, cy = BG_CROP_H / 2;
            var sx = (cx - BG_RECT_W / 2 - bgCropState.offsetX) / bgCropState.scale;
            var sy = (cy - BG_RECT_H / 2 - bgCropState.offsetY) / bgCropState.scale;
            var sw = BG_RECT_W / bgCropState.scale, sh = BG_RECT_H / bgCropState.scale;
            var csx = Math.max(0, sx), csy = Math.max(0, sy);
            var csw = Math.min(sw, bgCropState.image.naturalWidth - csx);
            var csh = Math.min(sh, bgCropState.image.naturalHeight - csy);
            if (csw <= 0 || csh <= 0) { ctx.fillStyle = '#1a0000'; ctx.fillRect(0, 0, pw, ph); return; }
            ctx.drawImage(bgCropState.image, csx, csy, csw, csh,
                (csx - sx) / sw * pw, (csy - sy) / sh * ph,
                csw / sw * pw, csh / sh * ph);
        }

        function confirmBgCrop() {
            if (!bgCropState.image) return;
            var btn = document.getElementById('btnBgCropConfirm');
            btn.classList.add('loading'); btn.textContent = '处理中...';
            var c = document.createElement('canvas');
            c.width = BG_OUTPUT_W; c.height = BG_OUTPUT_H;
            var ctx = c.getContext('2d');
            var cx = BG_CROP_W / 2, cy = BG_CROP_H / 2, s = bgCropState.scale;
            var sx = (cx - BG_RECT_W / 2 - bgCropState.offsetX) / s;
            var sy = (cy - BG_RECT_H / 2 - bgCropState.offsetY) / s;
            var sw = BG_RECT_W / s, sh = BG_RECT_H / s;
            var csx = Math.max(0, sx), csy = Math.max(0, sy);
            var csw = Math.min(sw, bgCropState.image.naturalWidth - csx);
            var csh = Math.min(sh, bgCropState.image.naturalHeight - csy);
            ctx.fillStyle = '#1a0000'; ctx.fillRect(0, 0, BG_OUTPUT_W, BG_OUTPUT_H);
            ctx.drawImage(bgCropState.image, csx, csy, csw, csh,
                (csx - sx) / sw * BG_OUTPUT_W, (csy - sy) / sh * BG_OUTPUT_H,
                csw / sw * BG_OUTPUT_W, csh / sh * BG_OUTPUT_H);
            var cover = document.getElementById('userCover');
            if (cover) {
                cover.style.backgroundImage = 'url(' + c.toDataURL('image/jpeg', 0.9) + ')';
                cover.style.backgroundSize = 'cover';
                cover.style.backgroundPosition = 'center';
            }
            c.toBlob(function(b) {
                if (!b) { showToast('图片处理失败', 'error'); btn.classList.remove('loading'); btn.textContent = '确认'; return; }
                var fd = new FormData(); fd.append('background', b, 'background.jpg');
                var xhr = new XMLHttpRequest();
                xhr.open('POST', CTX_PATH + '/api/auth/profile', true);
                xhr.onload = function() {
                    try {
                        var r = JSON.parse(xhr.responseText);
                        if (r.success) { showToast('背景图已更新！🖼️', 'success'); setTimeout(function() { location.reload(); }, 1000); }
                        else { showToast(r.error || '上传失败', 'error'); }
                    } catch(ex) { showToast('上传失败', 'error'); }
                };
                xhr.send(fd); closeBgCropModal(); btn.classList.remove('loading'); btn.textContent = '确认';
            }, 'image/jpeg', 0.9);
        }

        // 背景裁剪拖拽/缩放事件
        (function() {
            var bgCon = document.getElementById('bgCropAreaContainer');
            var bgSl = document.getElementById('bgZoomSlider');
            bgCon.addEventListener('mousedown', function(e) {
                if (!bgCropState.image) return; e.preventDefault();
                bgCropState.dragging = true; bgCropState.dragStartX = e.clientX; bgCropState.dragStartY = e.clientY;
                bgCropState.dragStartOffsetX = bgCropState.offsetX; bgCropState.dragStartOffsetY = bgCropState.offsetY;
            });
            window.addEventListener('mousemove', function(e) {
                if (!bgCropState.dragging) return;
                bgCropState.offsetX = bgCropState.dragStartOffsetX + (e.clientX - bgCropState.dragStartX);
                bgCropState.offsetY = bgCropState.dragStartOffsetY + (e.clientY - bgCropState.dragStartY);
                clampBgPosition(); applyBgTransform(); renderBgPreview();
            });
            window.addEventListener('mouseup', function() { bgCropState.dragging = false; });
            bgCon.addEventListener('touchstart', function(e) {
                if (!bgCropState.image || e.touches.length !== 1) return;
                bgCropState.dragging = true; bgCropState.dragStartX = e.touches[0].clientX; bgCropState.dragStartY = e.touches[0].clientY;
                bgCropState.dragStartOffsetX = bgCropState.offsetX; bgCropState.dragStartOffsetY = bgCropState.offsetY;
            });
            window.addEventListener('touchmove', function(e) {
                if (!bgCropState.dragging || e.touches.length !== 1) return;
                bgCropState.offsetX = bgCropState.dragStartOffsetX + (e.touches[0].clientX - bgCropState.dragStartX);
                bgCropState.offsetY = bgCropState.dragStartOffsetY + (e.touches[0].clientY - bgCropState.dragStartY);
                clampBgPosition(); applyBgTransform(); renderBgPreview();
            });
            window.addEventListener('touchend', function() { bgCropState.dragging = false; });
            bgSl.addEventListener('input', function() {
                if (!bgCropState.image) return;
                bgZoomAtCenter(parseInt(this.value) / 100);
            });
        })();
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

    <%-- 邮箱绑定 --%>
    <script>
    function bindEmail() {
        var email = '';
        var el1 = document.getElementById('bindEmailInput');
        var el2 = document.getElementById('bindEmailInput2');
        if (el2 && el2.value.trim()) {
            email = el2.value.trim();
        } else if (el1 && el1.value.trim()) {
            email = el1.value.trim();
        } else {
            // 已绑定未验证状态：没有输入框，直接用已绑定的邮箱重新发送
            email = '<%= profileUser.getEmail() != null ? profileUser.getEmail() : "" %>';
        }
        if (!email) { alert('请输入邮箱地址。'); return; }
        fetch('<%=ctxPath%>/api/auth/bind-email', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: 'email=' + encodeURIComponent(email)
        }).then(function(r) { return r.json(); }).then(function(d) {
            if (d.success) { alert(d.message); location.reload(); }
            else { alert(d.error); }
        });
    }
    function unbindEmail() {
        if (!confirm('确定要解绑邮箱吗？解绑后将无法通过邮箱找回密码。')) return;
        fetch('<%=ctxPath%>/api/auth/unbind-email', { method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'} })
            .then(function(r){return r.json()})
            .then(function(d){ if(d.success) location.reload(); else alert(d.error); });
    }
    function changeEmail() {
        var box = document.getElementById('changeEmailBox');
        box.style.display = box.style.display === 'none' ? 'block' : 'none';
    }
    </script>

    <%-- 全局茶话会通知轮询 --%>
    <script>
    (function(){var lic=0;function pf(){fetch('<%=ctxPath%>/api/friends').then(function(r){return r.json()}).then(function(d){if(!d.success)return;var c=(d.received&&d.received.length)||0;var b=document.getElementById('navChatBadge');if(b){if(c>0){b.textContent=c;b.style.display='inline-block';}else{b.style.display='none';}}if(c>lic&&lic>0){var t=document.createElement('div');t.className='toast success';t.textContent='📨 收到新邀请函！';t.style.cssText='position:fixed;top:80px;right:20px;z-index:9999;';document.body.appendChild(t);setTimeout(function(){t.style.opacity='0';t.style.transition='all 0.5s';setTimeout(function(){t.remove();},500);},4000);}lic=c;}).catch(function(){});}pf();setInterval(pf,30000);})();
    </script>
</body>
</html>
