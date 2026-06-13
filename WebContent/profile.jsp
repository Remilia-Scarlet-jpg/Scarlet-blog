<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.scarletblog.model.User" %>
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
    } else {
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
                <a href="<%=ctxPath%>/blog/admin">⚙️ 管理室</a>
                <a href="<%=ctxPath%>/blog/profile" class="active">👤 档案</a>
                <a href="<%=ctxPath%>/api/auth/logout" title="离馆" style="color:var(--scarlet-light);border:1px solid var(--scarlet);">🚪 离馆</a>
            </nav>
        </div>
    </header>

    <div class="toast-container" id="toastContainer"></div>

    <div class="main-container full-width">
        <div class="profile-container">
            <div class="profile-card">
                <div class="profile-header">
                    <div class="avatar-section">
                        <img class="avatar-preview" id="avatarPreview" src="<%=avatarPath%>" alt="头像">
                        <div class="avatar-edit-overlay" onclick="document.getElementById('avatarFileInput').click()" title="更换头像">📷</div>
                    </div>
                    <button class="btn-avatar-upload" onclick="document.getElementById('avatarFileInput').click()">🖼️ 更换头像</button>
                    <input type="file" class="hidden-file-input" id="avatarFileInput" accept="image/jpeg,image/png,image/gif,image/webp" onchange="previewAndUpload(event)">
                    <div class="profile-name"><%= currentUser.getNickname() %></div>
                    <span class="profile-role"><%= currentUser.getRole() %></span>
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
                        <span class="profile-info-value"><%= currentUser.getUsername() %></span>
                    </div>
                    <div class="profile-info-item">
                        <span class="profile-info-label">🎭 称呼</span>
                        <span class="profile-info-value"><%= currentUser.getNickname() %></span>
                    </div>
                    <div class="profile-info-item">
                        <span class="profile-info-label">⚜️ 身份</span>
                        <span class="profile-info-value"><%= currentUser.getRole() %></span>
                    </div>
                    <div class="profile-info-item">
                        <span class="profile-info-label">📅 入馆日期</span>
                        <span class="profile-info-value"><%= currentUser.getCreatedAt() != null ? new java.text.SimpleDateFormat("yyyy年MM月dd日").format(currentUser.getCreatedAt()) : "未知" %></span>
                    </div>
                    <div class="profile-stats">
                        <div class="profile-stat">
                            <div class="profile-stat-value"><%= currentUser.getRole().equals("馆主") || currentUser.getRole().equals("女仆长") ? "👑" : "🏠" %></div>
                            <div class="profile-stat-label"><%= currentUser.getRole() %></div>
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
                            <input type="text" value="<%= currentUser.getUsername() %>" readonly>
                        </div>
                        <div class="form-group">
                            <label>🎭 称呼</label>
                            <input type="text" id="editNickname" value="<%= currentUser.getNickname() %>" placeholder="输入你的称呼" maxlength="50">
                        </div>
                        <div class="form-group">
                            <label>⚜️ 身份</label>
                            <input type="text" value="<%= currentUser.getRole() %>" readonly>
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

        function previewAndUpload(e) {
            var file = e.target.files[0];
            if (!file) return;
            // 本地预览
            var reader = new FileReader();
            reader.onload = function(ev) {
                document.getElementById('avatarPreview').src = ev.target.result;
            };
            reader.readAsDataURL(file);
            // 上传
            uploadAvatar(file);
        }

        function uploadAvatar(file) {
            var formData = new FormData();
            formData.append('avatar', file);

            var xhr = new XMLHttpRequest();
            xhr.open('POST', '<%=ctxPath%>/api/auth/profile', true);
            xhr.onload = function() {
                try {
                    var resp = JSON.parse(xhr.responseText);
                    if (resp.success) {
                        showToast('头像已更新！🎭', 'success');
                    } else {
                        showToast(resp.error || '上传失败', 'error');
                    }
                } catch(ex) {
                    showToast('上传失败', 'error');
                }
            };
            xhr.send(formData);
        }

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
</body>
</html>
