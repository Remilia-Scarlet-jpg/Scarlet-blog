<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.scarletblog.model.User" %>
<%@ page import="com.scarletblog.util.HtmlUtil" %>
<%
    User currentUser = (User) request.getAttribute("currentUser");
    String ctxPath = request.getContextPath();
    if (currentUser == null) {
        response.sendRedirect(ctxPath + "/blog/login");
        return;
    }
    String avatarPath = currentUser.getAvatar();
    if (avatarPath == null || avatarPath.isEmpty()) {
        avatarPath = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'%3E%3Ccircle cx='50' cy='50' r='50' fill='%234a0000'/%3E%3Ctext x='50' y='65' text-anchor='middle' font-size='40'%3E%F0%9F%91%A4%3C/text%3E%3C/svg%3E";
    } else if (!avatarPath.startsWith("data:")) {
        avatarPath = ctxPath + "/" + avatarPath;
    }
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>访客档案 - 红魔馆博客</title>
    <link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Ctext y='50' font-size='50'%3E%F0%9F%91%A4%3C/text%3E%3C/svg%3E">
    <link rel="stylesheet" href="<%=ctxPath%>/css/scarlet.css">
    <style>
        .profile-container {
            max-width: 700px;
            margin: 0 auto;
        }
        .profile-card {
            background: linear-gradient(135deg, #1a0a0a 0%, #0d0505 100%);
            border: 1px solid var(--border-dark);
            border-radius: 8px;
            padding: 40px;
            box-shadow: 0 4px 30px rgba(0,0,0,0.5);
            position: relative;
            overflow: hidden;
        }
        .profile-card::before {
            content: '';
            position: absolute;
            top: 0; left: 0; right: 0;
            height: 4px;
            background: linear-gradient(90deg, var(--scarlet-darkest), var(--scarlet), var(--gold), var(--scarlet), var(--scarlet-darkest));
        }
        .profile-header {
            text-align: center;
            margin-bottom: 35px;
        }
        .avatar-section {
            position: relative;
            display: inline-block;
            margin-bottom: 15px;
        }
        .avatar-preview {
            width: 120px;
            height: 120px;
            border-radius: 50%;
            object-fit: cover;
            border: 3px solid var(--gold);
            box-shadow: 0 0 25px rgba(212, 175, 55, 0.3), 0 0 10px rgba(139,0,0,0.4);
            background: var(--scarlet-darkest);
            transition: all 0.3s;
        }
        .avatar-preview:hover {
            box-shadow: 0 0 35px rgba(212, 175, 55, 0.5), 0 0 20px rgba(220,20,60,0.5);
        }
        .avatar-edit-overlay {
            position: absolute;
            bottom: 5px;
            right: 5px;
            width: 32px;
            height: 32px;
            background: var(--scarlet);
            border: 2px solid var(--gold);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            font-size: 0.9rem;
            color: var(--gold-bright);
            transition: all 0.3s;
            box-shadow: 0 0 10px rgba(0,0,0,0.5);
        }
        .avatar-edit-overlay:hover {
            background: var(--scarlet-fire);
            transform: scale(1.1);
        }
        .profile-name {
            font-family: var(--font-title);
            font-size: 1.6rem;
            color: var(--gold);
            letter-spacing: 3px;
            margin-bottom: 5px;
        }
        .profile-role {
            display: inline-block;
            background: rgba(139,0,0,0.4);
            color: var(--scarlet-light);
            padding: 4px 16px;
            border-radius: 20px;
            font-size: 0.85rem;
            border: 1px solid var(--scarlet);
        }
        .profile-tabs {
            display: flex;
            gap: 0;
            border-bottom: 1px solid var(--border-dark);
            margin-bottom: 25px;
        }
        .profile-tab {
            flex: 1;
            text-align: center;
            padding: 12px;
            cursor: pointer;
            color: var(--text-muted);
            border-bottom: 2px solid transparent;
            font-family: var(--font-en);
            letter-spacing: 1px;
            font-size: 0.85rem;
            transition: all 0.3s;
        }
        .profile-tab:hover { color: var(--text-light); }
        .profile-tab.active {
            color: var(--gold);
            border-bottom-color: var(--gold);
        }
        .profile-panel { display: none; }
        .profile-panel.active { display: block; }
        .profile-panel .form-group {
            margin-bottom: 20px;
        }
        .profile-panel label {
            display: block;
            color: var(--gold);
            font-family: var(--font-en);
            font-size: 0.85rem;
            letter-spacing: 2px;
            margin-bottom: 8px;
        }
        .profile-panel input {
            width: 100%;
            background: var(--bg-dark);
            border: 1px solid var(--border-dark);
            color: var(--text-light);
            padding: 12px 16px;
            font-family: var(--font-jp);
            font-size: 0.95rem;
            border-radius: 4px;
            transition: all 0.3s;
        }
        .profile-panel input:focus {
            outline: none;
            border-color: var(--gold-dark);
            box-shadow: 0 0 12px rgba(212, 175, 55, 0.15);
        }
        .profile-panel input[readonly] {
            opacity: 0.6;
            cursor: not-allowed;
        }
        .profile-info-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 14px 0;
            border-bottom: 1px dotted rgba(139,0,0,0.2);
        }
        .profile-info-label {
            color: var(--text-muted);
            font-size: 0.85rem;
        }
        .profile-info-value {
            color: var(--text-light);
            font-weight: 500;
        }
        .profile-stats {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 12px;
            margin-top: 25px;
        }
        .profile-stat {
            text-align: center;
            background: rgba(139,0,0,0.1);
            border-radius: 6px;
            padding: 15px 10px;
            border: 1px solid rgba(139,0,0,0.15);
        }
        .profile-stat-value {
            font-family: var(--font-title);
            font-size: 1.5rem;
            color: var(--gold);
        }
        .profile-stat-label {
            font-size: 0.75rem;
            color: var(--text-muted);
            margin-top: 4px;
        }
        .hidden-file-input { display: none; }
        .btn-avatar-upload {
            display: block;
            margin: 8px auto 0;
            background: none;
            border: 1px solid var(--border-dark);
            color: var(--text-muted);
            padding: 5px 14px;
            cursor: pointer;
            font-size: 0.8rem;
            border-radius: 3px;
            transition: all 0.3s;
        }
        .btn-avatar-upload:hover {
            color: var(--gold);
            border-color: var(--gold-dark);
        }

        /* === 头像裁剪模态框样式 === */
        .crop-modal-dialog {
            max-width: 520px;
        }
        .crop-modal-body {
            padding: 20px 25px;
        }
        .crop-workspace {
            display: flex;
            gap: 20px;
            align-items: flex-start;
            justify-content: center;
            flex-wrap: wrap;
            margin-bottom: 20px;
        }
        .crop-area-container {
            position: relative;
            width: 280px;
            height: 280px;
            overflow: hidden;
            background: var(--bg-dark);
            border: 1px solid var(--border-dark);
            border-radius: 4px;
            cursor: grab;
            user-select: none;
            -webkit-user-select: none;
            flex-shrink: 0;
        }
        .crop-area-container:active {
            cursor: grabbing;
        }
        .crop-mask {
            position: absolute;
            inset: 0;
            pointer-events: none;
            z-index: 2;
            background: radial-gradient(
                circle 110px at center,
                transparent 110px,
                rgba(0, 0, 0, 0.75) 111px
            );
        }
        .crop-circle {
            position: absolute;
            top: 50%; left: 50%;
            transform: translate(-50%, -50%);
            width: 220px;
            height: 220px;
            border-radius: 50%;
            border: 2px solid var(--gold);
            box-shadow: 0 0 12px rgba(212, 175, 55, 0.25),
                        inset 0 0 12px rgba(212, 175, 55, 0.1);
            pointer-events: none;
            z-index: 3;
        }
        .crop-image {
            position: absolute;
            z-index: 1;
        }
        .crop-preview-section {
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 8px;
            flex-shrink: 0;
        }
        .crop-preview-label {
            color: var(--text-muted);
            font-size: 0.75rem;
            font-family: var(--font-en);
            letter-spacing: 1px;
            margin: 0;
        }
        .crop-preview-circle {
            width: 80px;
            height: 80px;
            border-radius: 50%;
            overflow: hidden;
            border: 2px solid var(--gold);
            box-shadow: 0 0 15px rgba(212, 175, 55, 0.3);
            background: var(--scarlet-darkest);
        }
        .crop-preview-circle canvas {
            width: 100%;
            height: 100%;
            display: block;
        }
        .crop-controls {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 12px;
            margin-bottom: 20px;
        }
        .crop-zoom-icon {
            color: var(--text-muted);
            font-size: 0.9rem;
            flex-shrink: 0;
        }
        .crop-zoom-slider {
            flex: 1;
            max-width: 250px;
            -webkit-appearance: none;
            appearance: none;
            height: 4px;
            border-radius: 2px;
            background: var(--border-dark);
            outline: none;
            cursor: pointer;
        }
        .crop-zoom-slider::-webkit-slider-thumb {
            -webkit-appearance: none;
            appearance: none;
            width: 18px;
            height: 18px;
            border-radius: 50%;
            background: var(--scarlet);
            border: 2px solid var(--gold-dark);
            cursor: pointer;
            box-shadow: 0 0 6px rgba(220, 20, 60, 0.4);
            transition: all 0.2s;
        }
        .crop-zoom-slider::-webkit-slider-thumb:hover {
            background: var(--scarlet-fire);
            box-shadow: 0 0 12px rgba(220, 20, 60, 0.6);
        }
        .crop-zoom-slider::-moz-range-thumb {
            width: 18px;
            height: 18px;
            border-radius: 50%;
            background: var(--scarlet);
            border: 2px solid var(--gold-dark);
            cursor: pointer;
            box-shadow: 0 0 6px rgba(220, 20, 60, 0.4);
        }
        .crop-actions {
            justify-content: center;
            gap: 16px;
        }
        #btnCropConfirm.loading {
            opacity: 0.7;
            pointer-events: none;
        }

        @media (max-width: 500px) {
            .crop-area-container {
                width: 240px;
                height: 240px;
            }
            .crop-mask {
                background: radial-gradient(
                    circle 95px at center,
                    transparent 95px,
                    rgba(0, 0, 0, 0.75) 96px
                );
            }
            .crop-circle {
                width: 190px;
                height: 190px;
            }
            .crop-workspace {
                gap: 12px;
            }
            .crop-modal-body {
                padding: 15px;
            }
        }
    </style>
</head>
<body>
    <header class="scarlet-header">
        <div class="header-inner">
            <div class="logo-area">
                <div class="logo-icon">👤</div>
                <div class="logo-text">
                    <h1>访客档案</h1>
                    <span class="subtitle">~ 红魔馆住人名录 ~</span>
                </div>
            </div>
            <nav class="nav-links">
                <a href="<%=ctxPath%>/blog">🏠 大厅</a>
                <% if (currentUser != null && currentUser.isAdmin()) { %><a href="<%=ctxPath%>/blog/admin">⚙️ 管理室</a><% } %>
                <a href="<%=ctxPath%>/blog/chat" title="茶话会" id="navChatLink">🍵 茶话会<span id="navChatBadge" class="nav-badge" style="display:none;">0</span></a>
                <a href="<%=ctxPath%>/blog/profile" class="active">👤 档案</a>
                <a href="<%=ctxPath%>/blog/user?id=<%=currentUser.getId()%>" title="我的主页">🏷️ 我的主页</a>
                    <a href="<%=ctxPath%>/api/auth/logout" title="离馆" style="color:var(--scarlet-light);border:1px solid var(--scarlet);">🚪 离馆</a>
            </nav>
        </div>
    </header>

    <div class="toast-container" id="toastContainer"></div>

    <!-- 头像裁剪模态框 -->
    <div class="modal-overlay" id="cropModal">
        <div class="modal-dialog crop-modal-dialog">
            <div class="modal-header">
                <h3>🎭 裁剪头像</h3>
                <button class="modal-close" onclick="closeCropModal()" title="取消">×</button>
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

    <div class="main-container full-width">
        <div class="profile-container">
            <div class="profile-card">
                <div class="profile-header">
                    <div class="avatar-section">
                        <img class="avatar-preview" id="avatarPreview" src="<%=avatarPath%>" alt="头像">
                        <div class="avatar-edit-overlay" onclick="document.getElementById('avatarFileInput').click()" title="更换头像">📷</div>
                    </div>
                    <button class="btn-avatar-upload" onclick="document.getElementById('avatarFileInput').click()">🖼️ 更换头像</button>
                    <input type="file" class="hidden-file-input" id="avatarFileInput" accept="image/jpeg,image/png,image/gif,image/webp" onchange="onAvatarFileSelected(event)">
                    <div class="profile-name"><%= HtmlUtil.escape(currentUser.getNickname()) %></div>
                    <span class="profile-role"><%= HtmlUtil.escape(currentUser.getRole()) %></span>
                </div>

                <div class="profile-tabs">
                    <div class="profile-tab active" onclick="switchTab('info')">📋 基本信息</div>
                    <div class="profile-tab" onclick="switchTab('edit')">✏️ 编辑资料</div>
                    <div class="profile-tab" onclick="switchTab('password')">🔐 修改密语</div>
                </div>

                <!-- 基本信息面板 -->
                <div class="profile-panel active" id="panel-info">
                    <div class="profile-info-item">
                        <span class="profile-info-label">📛 名札</span>
                        <span class="profile-info-value"><%= HtmlUtil.escape(currentUser.getUsername()) %></span>
                    </div>
                    <div class="profile-info-item">
                        <span class="profile-info-label">🎭 称呼</span>
                        <span class="profile-info-value"><%= HtmlUtil.escape(currentUser.getNickname()) %></span>
                    </div>
                    <div class="profile-info-item">
                        <span class="profile-info-label">⚜️ 身份</span>
                        <span class="profile-info-value"><%= HtmlUtil.escape(currentUser.getRole()) %></span>
                    </div>
                    <div class="profile-info-item">
                        <span class="profile-info-label">📅 入馆日期</span>
                        <span class="profile-info-value"><%= currentUser.getCreatedAt() != null ? new java.text.SimpleDateFormat("yyyy年MM月dd日").format(currentUser.getCreatedAt()) : "未知" %></span>
                    </div>
                    <div class="profile-stats">
                        <div class="profile-stat">
                            <div class="profile-stat-value"><%= currentUser.getRole().equals("馆主") || currentUser.getRole().equals("女仆长") ? "👑" : "🏠" %></div>
                            <div class="profile-stat-label"><%= HtmlUtil.escape(currentUser.getRole()) %></div>
                        </div>
                        <div class="profile-stat">
                            <div class="profile-stat-value">📅</div>
                            <div class="profile-stat-label">活跃住人</div>
                        </div>
                        <div class="profile-stat">
                            <div class="profile-stat-value">💬</div>
                            <div class="profile-stat-label">留言者</div>
                        </div>
                    </div>
                </div>

                <!-- 编辑资料面板 -->
                <div class="profile-panel" id="panel-edit">
                    <form onsubmit="saveProfile(event)">
                        <div class="form-group">
                            <label>📛 名札（不可修改）</label>
                            <input type="text" value="<%= HtmlUtil.escape(currentUser.getUsername()) %>" readonly>
                        </div>
                        <div class="form-group">
                            <label>🎭 称呼</label>
                            <input type="text" id="editNickname" value="<%= HtmlUtil.escape(currentUser.getNickname()) %>" placeholder="输入你的称呼" maxlength="50">
                        </div>
                        <div class="form-group">
                            <label>⚜️ 身份</label>
                            <input type="text" value="<%= HtmlUtil.escape(currentUser.getRole()) %>" readonly>
                        </div>
                        <div class="form-actions">
                            <button type="submit" class="btn-scarlet" id="btnSaveProfile">💾 保存资料</button>
                        </div>
                    </form>
                </div>

                <!-- 修改密码面板 -->
                <div class="profile-panel" id="panel-password">
                    <form onsubmit="changePassword(event)">
                        <div class="form-group">
                            <label>🔐 当前封印密语</label>
                            <input type="password" id="oldPassword" placeholder="输入当前密码" maxlength="100" required>
                        </div>
                        <div class="form-group">
                            <label>🔑 新的封印密语</label>
                            <input type="password" id="newPassword" placeholder="输入新密码（至少4位）" maxlength="100" minlength="4" required>
                        </div>
                        <div class="form-group">
                            <label>🔑 确认封印密语</label>
                            <input type="password" id="confirmPassword" placeholder="再次输入新密码" maxlength="100" minlength="4" required>
                        </div>
                        <div class="form-actions">
                            <button type="submit" class="btn-scarlet">🔐 更新密语</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <footer class="scarlet-footer">
        <div class="footer-ornament">◆ ◇ ◆</div>
        <p>🏰 红魔馆博客 — 访客档案</p>
        <p>© 2024 红魔馆 | Powered by Java Servlet &amp; MySQL</p>
    </footer>

    <script>
        function switchTab(tab) {
            document.querySelectorAll('.profile-tab').forEach(function(t, i) {
                t.classList.toggle('active', t.textContent.includes(
                    tab === 'info' ? '基本信息' : tab === 'edit' ? '编辑资料' : '修改密语'
                ));
            });
            document.querySelectorAll('.profile-panel').forEach(function(p) {
                p.classList.remove('active');
            });
            var target = document.getElementById('panel-' + tab);
            if (target) target.classList.add('active');
        }


        // === 头像裁剪状态 ===
        var cropState = {
            image: null,
            scale: 1.0,
            offsetX: 0,
            offsetY: 0,
            dragging: false,
            dragStartX: 0,
            dragStartY: 0,
            dragStartOffsetX: 0,
            dragStartOffsetY: 0
        };
        var CROP_SIZE = 280;
        var CIRCLE_RADIUS = 110;
        var OUTPUT_SIZE = 400;

        function onAvatarFileSelected(e) {
            var file = e.target.files[0];
            if (!file) return;
            if (!/^image\/(jpeg|png|gif|webp)$/.test(file.type)) {
                showToast('仅支持 JPG / PNG / GIF / WebP 格式', 'error');
                e.target.value = '';
                return;
            }
            if (file.size > 5 * 1024 * 1024) {
                showToast('文件大小不能超过 5MB', 'error');
                e.target.value = '';
                return;
            }
            var reader = new FileReader();
            reader.onload = function(ev) {
                var img = new Image();
                img.onload = function() { openCropModal(img); };
                img.src = ev.target.result;
            };
            reader.readAsDataURL(file);
        }

        function openCropModal(img) {
            if (window.innerWidth <= 500) {
                CROP_SIZE = 240; CIRCLE_RADIUS = 95;
            } else {
                CROP_SIZE = 280; CIRCLE_RADIUS = 110;
            }
            var container = document.getElementById('cropAreaContainer');
            container.style.width  = CROP_SIZE + 'px';
            container.style.height = CROP_SIZE + 'px';

            cropState.image  = img;
            cropState.scale  = 1.0;
            cropState.offsetX = 0;
            cropState.offsetY = 0;

            var minDim = Math.min(img.naturalWidth, img.naturalHeight);
            var initScale = (2 * CIRCLE_RADIUS) / minDim;
            if (initScale > 1.0) {
                cropState.scale = initScale;
            } else if (initScale < 0.4) {
                cropState.scale = 0.5;
            } else {
                cropState.scale = initScale;
            }
            document.getElementById('cropZoomSlider').value = Math.round(cropState.scale * 100);

            var scaledW = img.naturalWidth  * cropState.scale;
            var scaledH = img.naturalHeight * cropState.scale;
            cropState.offsetX = (CROP_SIZE - scaledW) / 2;
            cropState.offsetY = (CROP_SIZE - scaledH) / 2;

            applyCropTransform();
            document.getElementById('cropModal').classList.add('active');
            renderCropPreview();
        }

        function closeCropModal() {
            document.getElementById('cropModal').classList.remove('active');
            document.getElementById('avatarFileInput').value = '';
            cropState.image = null;
        }

        function applyCropTransform() {
            var img = document.getElementById('cropImage');
            img.src = cropState.image.src;
            var scaledW = cropState.image.naturalWidth  * cropState.scale;
            var scaledH = cropState.image.naturalHeight * cropState.scale;
            img.style.left   = cropState.offsetX + 'px';
            img.style.top    = cropState.offsetY + 'px';
            img.style.width  = scaledW + 'px';
            img.style.height = scaledH + 'px';
        }

        function clampImagePosition() {
            var img = cropState.image;
            var scaledW = img.naturalWidth  * cropState.scale;
            var scaledH = img.naturalHeight * cropState.scale;
            var cx = CROP_SIZE / 2;
            var cy = CROP_SIZE / 2;
            if (scaledW < 2 * CIRCLE_RADIUS) {
                cropState.offsetX = cx - scaledW / 2;
            } else {
                var minX = cx - scaledW + CIRCLE_RADIUS;
                var maxX = cx - CIRCLE_RADIUS;
                cropState.offsetX = Math.max(minX, Math.min(maxX, cropState.offsetX));
            }
            if (scaledH < 2 * CIRCLE_RADIUS) {
                cropState.offsetY = cy - scaledH / 2;
            } else {
                var minY = cy - scaledH + CIRCLE_RADIUS;
                var maxY = cy - CIRCLE_RADIUS;
                cropState.offsetY = Math.max(minY, Math.min(maxY, cropState.offsetY));
            }
        }

        function zoomAtCenter(newScale) {
            var img = cropState.image;
            var cx = CROP_SIZE / 2;
            var cy = CROP_SIZE / 2;
            var oldScale = cropState.scale;
            var natX = (cx - cropState.offsetX) / oldScale;
            var natY = (cy - cropState.offsetY) / oldScale;
            cropState.scale = newScale;
            cropState.offsetX = cx - natX * newScale;
            cropState.offsetY = cy - natY * newScale;
            clampImagePosition();
            applyCropTransform();
            renderCropPreview();
        }

        function renderCropPreview() {
            if (!cropState.image) return;
            var canvas = document.getElementById('cropPreviewCanvas');
            var ctx = canvas.getContext('2d');
            var img = cropState.image;
            ctx.clearRect(0, 0, 80, 80);

            var cx = CROP_SIZE / 2;
            var cy = CROP_SIZE / 2;
            var srcX = (cx - CIRCLE_RADIUS - cropState.offsetX) / cropState.scale;
            var srcY = (cy - CIRCLE_RADIUS - cropState.offsetY) / cropState.scale;
            var srcW = (2 * CIRCLE_RADIUS) / cropState.scale;
            var srcH = (2 * CIRCLE_RADIUS) / cropState.scale;

            var clampSrcX = Math.max(0, srcX);
            var clampSrcY = Math.max(0, srcY);
            var clampSrcW = Math.min(srcW, img.naturalWidth  - clampSrcX);
            var clampSrcH = Math.min(srcH, img.naturalHeight - clampSrcY);
            if (clampSrcW <= 0 || clampSrcH <= 0) return;

            var dstX = (clampSrcX - srcX) / srcW * 80;
            var dstY = (clampSrcY - srcY) / srcH * 80;
            var dstW = clampSrcW / srcW * 80;
            var dstH = clampSrcH / srcH * 80;

            ctx.save();
            ctx.beginPath();
            ctx.arc(40, 40, 40, 0, Math.PI * 2);
            ctx.clip();
            ctx.drawImage(img, clampSrcX, clampSrcY, clampSrcW, clampSrcH, dstX, dstY, dstW, dstH);
            ctx.restore();
        }

        function confirmCrop() {
            if (!cropState.image) return;
            var btn = document.getElementById('btnCropConfirm');
            btn.classList.add('loading');
            btn.textContent = '处理中...';

            var canvas = document.createElement('canvas');
            canvas.width  = OUTPUT_SIZE;
            canvas.height = OUTPUT_SIZE;
            var ctx = canvas.getContext('2d');
            var img = cropState.image;

            var cx = CROP_SIZE / 2;
            var cy = CROP_SIZE / 2;
            var scale = cropState.scale;
            var srcX = (cx - CIRCLE_RADIUS - cropState.offsetX) / scale;
            var srcY = (cy - CIRCLE_RADIUS - cropState.offsetY) / scale;
            var srcW = (2 * CIRCLE_RADIUS) / scale;
            var srcH = (2 * CIRCLE_RADIUS) / scale;

            var clampSrcX = Math.max(0, srcX);
            var clampSrcY = Math.max(0, srcY);
            var clampSrcW = Math.min(srcW, img.naturalWidth  - clampSrcX);
            var clampSrcH = Math.min(srcH, img.naturalHeight - clampSrcY);
            if (clampSrcW <= 0 || clampSrcH <= 0) {
                showToast('裁剪区域无效', 'error');
                btn.classList.remove('loading');
                btn.textContent = '确认';
                return;
            }

            var dstX = (clampSrcX - srcX) / srcW * OUTPUT_SIZE;
            var dstY = (clampSrcY - srcY) / srcH * OUTPUT_SIZE;
            var dstW = clampSrcW / srcW * OUTPUT_SIZE;
            var dstH = clampSrcH / srcH * OUTPUT_SIZE;

            ctx.save();
            ctx.beginPath();
            ctx.arc(OUTPUT_SIZE / 2, OUTPUT_SIZE / 2, OUTPUT_SIZE / 2, 0, Math.PI * 2);
            ctx.clip();
            ctx.drawImage(img, clampSrcX, clampSrcY, clampSrcW, clampSrcH, dstX, dstY, dstW, dstH);
            ctx.restore();

            fillTransparentCorners(canvas);

            var avatarPreview = document.getElementById('avatarPreview');
            avatarPreview.src = canvas.toDataURL('image/png');

            canvas.toBlob(function(blob) {
                if (!blob) {
                    showToast('图片处理失败', 'error');
                    btn.classList.remove('loading');
                    btn.textContent = '确认';
                    return;
                }
                uploadCroppedAvatar(blob);
                closeCropModal();
                btn.classList.remove('loading');
                btn.textContent = '确认';
            }, 'image/png', 0.92);
        }

        function fillTransparentCorners(canvas) {
            var ctx = canvas.getContext('2d');
            var imageData = ctx.getImageData(0, 0, OUTPUT_SIZE, OUTPUT_SIZE);
            var pixels = imageData.data;
            for (var i = 0; i < pixels.length; i += 4) {
                if (pixels[i + 3] === 0) {
                    pixels[i]     = 26;
                    pixels[i + 1] = 0;
                    pixels[i + 2] = 0;
                    pixels[i + 3] = 255;
                }
            }
            ctx.putImageData(imageData, 0, 0);
        }

        function uploadCroppedAvatar(blob) {
            var formData = new FormData();
            formData.append('avatar', blob, 'avatar_cropped.png');

            var xhr = new XMLHttpRequest();
            xhr.open('POST', '<%=ctxPath%>/api/auth/profile', true);
            xhr.onload = function() {
                try {
                    var resp = JSON.parse(xhr.responseText);
                    if (resp.success) {
                        showToast('头像已更新！🎭', 'success');
                        setTimeout(function() { location.reload(); }, 1000);
                    } else {
                        showToast(resp.error || '上传失败', 'error');
                    }
                } catch(ex) {
                    showToast('上传失败', 'error');
                }
            };
            xhr.onerror = function() {
                showToast('网络错误，上传失败', 'error');
            };
            xhr.send(formData);
        }

        // === 拖拽 & 缩放事件 ===
        document.addEventListener('DOMContentLoaded', function() {
            var container = document.getElementById('cropAreaContainer');
            var slider   = document.getElementById('cropZoomSlider');

            container.addEventListener('mousedown', function(e) {
                if (!cropState.image) return;
                e.preventDefault();
                cropState.dragging = true;
                cropState.dragStartX = e.clientX;
                cropState.dragStartY = e.clientY;
                cropState.dragStartOffsetX = cropState.offsetX;
                cropState.dragStartOffsetY = cropState.offsetY;
            });
            window.addEventListener('mousemove', function(e) {
                if (!cropState.dragging) return;
                var dx = e.clientX - cropState.dragStartX;
                var dy = e.clientY - cropState.dragStartY;
                cropState.offsetX = cropState.dragStartOffsetX + dx;
                cropState.offsetY = cropState.dragStartOffsetY + dy;
                clampImagePosition();
                applyCropTransform();
                renderCropPreview();
            });
            window.addEventListener('mouseup', function() {
                cropState.dragging = false;
            });

            container.addEventListener('touchstart', function(e) {
                if (!cropState.image || e.touches.length !== 1) return;
                e.preventDefault();
                cropState.dragging = true;
                cropState.dragStartX = e.touches[0].clientX;
                cropState.dragStartY = e.touches[0].clientY;
                cropState.dragStartOffsetX = cropState.offsetX;
                cropState.dragStartOffsetY = cropState.offsetY;
            });
            window.addEventListener('touchmove', function(e) {
                if (!cropState.dragging || e.touches.length !== 1) return;
                var dx = e.touches[0].clientX - cropState.dragStartX;
                var dy = e.touches[0].clientY - cropState.dragStartY;
                cropState.offsetX = cropState.dragStartOffsetX + dx;
                cropState.offsetY = cropState.dragStartOffsetY + dy;
                clampImagePosition();
                applyCropTransform();
                renderCropPreview();
            });
            window.addEventListener('touchend', function() {
                cropState.dragging = false;
            });

            slider.addEventListener('input', function() {
                if (!cropState.image) return;
                var newScale = parseInt(this.value) / 100;
                zoomAtCenter(newScale);
            });
        });


        function saveProfile(e) {
            e.preventDefault();
            var nickname = document.getElementById('editNickname').value.trim();
            if (!nickname) { showToast('称呼不能为空', 'error'); return; }

            var formData = new FormData();
            formData.append('nickname', nickname);

            var xhr = new XMLHttpRequest();
            xhr.open('POST', '<%=ctxPath%>/api/auth/profile', true);
            xhr.onload = function() {
                try {
                    var resp = JSON.parse(xhr.responseText);
                    if (resp.success) {
                        showToast('资料已更新！✨', 'success');
                        setTimeout(function() { location.reload(); }, 1000);
                    } else {
                        showToast(resp.error || '更新失败', 'error');
                    }
                } catch(ex) {
                    showToast('更新失败', 'error');
                }
            };
            xhr.send(formData);
        }

        function changePassword(e) {
            e.preventDefault();
            var oldPwd = document.getElementById('oldPassword').value;
            var newPwd = document.getElementById('newPassword').value;
            var confirmPwd = document.getElementById('confirmPassword').value;

            if (newPwd !== confirmPwd) {
                showToast('两次输入的封印密语不一致！', 'error');
                return;
            }
            if (newPwd.length < 4) {
                showToast('封印密语至少需要4个字符！', 'error');
                return;
            }

            var formData = 'old_password=' + encodeURIComponent(oldPwd)
                + '&new_password=' + encodeURIComponent(newPwd);

            var xhr = new XMLHttpRequest();
            xhr.open('POST', '<%=ctxPath%>/api/auth/password', true);
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            xhr.onload = function() {
                try {
                    var resp = JSON.parse(xhr.responseText);
                    if (resp.success) {
                        showToast('封印密语已更新！🔐', 'success');
                        document.getElementById('oldPassword').value = '';
                        document.getElementById('newPassword').value = '';
                        document.getElementById('confirmPassword').value = '';
                    } else {
                        showToast(resp.error || '修改失败', 'error');
                    }
                } catch(ex) {
                    showToast('修改失败', 'error');
                }
            };
            xhr.send(formData);
        }

        function showToast(msg, type) {
            var container = document.getElementById('toastContainer');
            var toast = document.createElement('div');
            toast.className = 'toast ' + (type || 'success');
            toast.textContent = msg;
            container.appendChild(toast);
            setTimeout(function() {
                toast.style.opacity = '0';
                toast.style.transition = 'all 0.4s';
                setTimeout(function() { toast.remove(); }, 400);
            }, 3000);
        }
    </script>
<% if (currentUser != null) { %>
<script>
(function(){fetch('<%=ctxPath%>/api/friends').then(function(r){return r.json()}).then(function(d){if(d.success){var c=(d.received&&d.received.length)||0;var b=document.getElementById('navChatBadge');if(b){if(c>0){b.textContent=c;b.style.display='inline-block'}else{b.style.display='none'}}}}).catch(function(){})})();
</script>
<% } %>
</body>
</html>
