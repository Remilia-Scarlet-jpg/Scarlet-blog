<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.scarletblog.model.User" %>
<%
    String ctxPath = request.getContextPath();
    User currentUser = (User) request.getAttribute("currentUser");
    if (currentUser == null) {
        response.sendRedirect(ctxPath + "/blog/login");
        return;
    }
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🍵 茶话会 - 红魔馆</title>
    <link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Ctext y='50' font-size='50'%3E🍵%3C/text%3E%3C/svg%3E">
    <link rel="stylesheet" href="<%=ctxPath%>/css/scarlet.css">
</head>
<body>
    <header class="scarlet-header">
        <div class="header-inner">
            <div class="logo-area">
                <div class="logo-icon">🍵</div>
                <div class="logo-text">
                    <h1>茶 话 会</h1>
                    <span class="subtitle">~ Tea Party ~</span>
                </div>
            </div>
            <nav class="nav-links">
                <a href="<%=ctxPath%>/blog">🏠 大厅</a>
                <% if (currentUser.isAdmin()) { %><a href="<%=ctxPath%>/blog/admin">⚙️ 管理室</a><% } %>
                <a href="<%=ctxPath%>/blog/chat" class="active">🍵 茶话会</a>
            </nav>
        </div>
    </header>

    <div class="toast-container" id="toastContainer"></div>

    <div class="main-container full-width" style="max-width:1000px;margin:30px auto;padding:0 20px;">
        <div class="chat-layout">
            <!-- 侧栏 -->
            <aside class="chat-sidebar">
                <!-- 友人列表 -->
                <div class="scarlet-card" style="margin-bottom:20px;">
                    <div class="scarlet-card-header">👥 友人</div>
                    <div class="scarlet-card-body" id="friendsList">
                        <div class="empty-state-sm">加载中...</div>
                    </div>
                </div>

                <!-- 邀请函 -->
                <div class="scarlet-card" style="margin-bottom:20px;">
                    <div class="scarlet-card-header">✉️ 邀请函</div>
                    <div class="scarlet-card-body">
                        <div id="receivedRequests"><div class="empty-state-sm">暂无收到的邀请</div></div>
                        <div id="sentRequests" style="margin-top:10px;"><div class="empty-state-sm" style="font-size:0.75rem;color:#6a5050;">暂无发出的邀请</div></div>
                    </div>
                </div>

                <!-- 添加友人 -->
                <div class="scarlet-card">
                    <div class="scarlet-card-header">➕ 添加友人</div>
                    <div class="scarlet-card-body">
                        <div class="friend-request-form">
                            <input type="text" id="addFriendInput" placeholder="输入对方的名札（用户名）" maxlength="50">
                            <button class="btn-scarlet" onclick="sendFriendRequest()" style="padding:8px 14px;">📨 发送</button>
                        </div>
                    </div>
                </div>
            </aside>

            <!-- 主区域 -->
            <main class="content-area">
                <h2 style="color:var(--gold);font-family:var(--font-en);letter-spacing:3px;margin-bottom:20px;">🍵 茶话会</h2>

                <!-- 公共茶室 -->
                <div class="section-title">🏰 公共茶室</div>
                <div class="room-list" id="publicRooms">
                    <div class="empty-state-sm">加载中...</div>
                </div>
                <% if (currentUser.isAdmin()) { %>
                <div style="margin-top:15px;">
                    <button class="btn-scarlet-outline" onclick="showCreatePublicRoom()" style="font-size:0.85rem;">➕ 新建公共茶室</button>
                    <div id="createRoomForm" style="display:none;margin-top:10px;display:flex;gap:8px;">
                        <input type="text" id="newRoomName" placeholder="茶室名称" maxlength="100" style="flex:1;background:var(--bg-dark);border:1px solid var(--border-dark);color:var(--text-light);padding:8px 12px;border-radius:3px;">
                        <button class="btn-scarlet" onclick="createPublicRoom()" style="padding:8px 16px;">创建</button>
                    </div>
                </div>
                <% } %>

                <!-- 私人茶室 -->
                <div class="section-title" style="margin-top:30px;">💬 私人茶室</div>
                <div class="room-list" id="privateRooms">
                    <div class="empty-state-sm">添加友人后，私人茶室将自动创建~</div>
                </div>
            </main>
        </div>
    </div>

    <footer class="scarlet-footer">
        <div class="footer-ornament">◆ ◇ ◆</div>
        <p>🏰 红魔馆博客 — Scarlet Devil Mansion Blog</p>
    </footer>

    <script>
        var API_BASE = '<%=ctxPath%>/api';
        var ctxPath = '<%=ctxPath%>';
        var currentUserId = <%= currentUser.getId() %>;
        var lastReceivedCount = 0;
        var isFirstLoad = true;

        // 页面加载
        loadAll();

        // 实时轮询（每 4 秒检查新邀请函和茶室消息）
        var pollFriendsTimer = setInterval(loadFriends, 4000);
        var pollRoomsTimer = setInterval(loadRooms, 4000);

        // 离开页面时停止轮询
        window.addEventListener('beforeunload', function() {
            clearInterval(pollFriendsTimer);
            clearInterval(pollRoomsTimer);
        });

        function loadAll() {
            loadFriends();
            loadRooms();
        }

        // ===== 友人 =====
        function loadFriends() {
            fetch(API_BASE + '/friends')
                .then(r => r.json())
                .then(d => {
                    if (!d.success) return;
                    renderFriends(d.friends);
                    renderReceived(d.received);
                    renderSent(d.sent);
                })
                .catch(e => console.error(e));
        }

        function renderFriends(friends) {
            var el = document.getElementById('friendsList');
            if (!friends || friends.length === 0) {
                el.innerHTML = '<div class="empty-state-sm">暂无友人，去添加一位吧~</div>';
                return;
            }
            var html = '';
            friends.forEach(function(f) {
                var avatar = f.avatar ? (f.avatar.startsWith('data:') ? f.avatar : ctxPath + '/' + f.avatar) : 'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 24 24%22%3E%3Ccircle cx=%2212%22 cy=%2212%22 r=%2212%22 fill=%22%234a0000%22/%3E%3C/svg%3E';
                html += '<div class="friend-item">' +
                    '<img class="friend-avatar" src="' + avatar + '" onerror="this.src=\'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 24 24%22%3E%3Ccircle cx=%2212%22 cy=%2212%22 r=%2212%22 fill=%22%234a0000%22/%3E%3C/svg%3E\'">' +
                    '<span class="friend-name">' + escHtml(f.nickname || f.username) + '</span>' +
                    '<div class="friend-actions">' +
                    '<button onclick="enterPrivateRoom(' + f.friend_id + ',' + f.user_id + ')" title="进入茶室">🍵</button>' +
                    '<button onclick="removeFriend(' + f.id + ')" title="移除友人">✕</button>' +
                    '</div></div>';
            });
            el.innerHTML = html;
        }

        function renderReceived(list) {
            var el = document.getElementById('receivedRequests');
            var count = list ? list.length : 0;

            // 检测新邀请函并弹通知
            if (!isFirstLoad && count > lastReceivedCount) {
                var newCount = count - lastReceivedCount;
                showToast('📨 收到 ' + newCount + ' 封新邀请函！', 'success');
            }
            lastReceivedCount = count;
            if (isFirstLoad) isFirstLoad = false;

            if (!list || list.length === 0) {
                el.innerHTML = '<div class="empty-state-sm">暂无收到的邀请</div>';
                updateInviteBadge(0);
                return;
            }
            updateInviteBadge(list.length);
            var html = '';
            list.forEach(function(f) {
                html += '<div class="friend-item">' +
                    '<span class="friend-name">' + escHtml(f.nickname || f.username) + '</span>' +
                    '<div class="friend-actions">' +
                    '<button class="btn-accept" onclick="acceptRequest(' + f.id + ')">接受</button>' +
                    '<button class="btn-reject" onclick="rejectRequest(' + f.id + ')">婉拒</button>' +
                    '</div></div>';
            });
            el.innerHTML = html;
        }

        // 更新邀请函徽标
        function updateInviteBadge(count) {
            var badge = document.getElementById('inviteBadge');
            var header = document.querySelector('.scarlet-card-header');
            if (count > 0) {
                if (!badge) {
                    // 在邀请函卡片标题处添加徽标
                    var inviteCard = document.getElementById('receivedRequests').closest('.scarlet-card');
                    if (inviteCard) {
                        var hdr = inviteCard.querySelector('.scarlet-card-header');
                        if (hdr) {
                            badge = document.createElement('span');
                            badge.id = 'inviteBadge';
                            badge.className = 'nav-badge';
                            hdr.appendChild(badge);
                        }
                    }
                }
                if (badge) {
                    badge.textContent = count;
                    badge.style.display = 'inline-block';
                }
            } else {
                if (badge) badge.style.display = 'none';
            }
        }

        function renderSent(list) {
            var el = document.getElementById('sentRequests');
            if (!list || list.length === 0) {
                el.innerHTML = '<div class="empty-state-sm" style="font-size:0.75rem;color:#6a5050;">暂无发出的邀请</div>';
                return;
            }
            var html = '';
            list.forEach(function(f) {
                html += '<div class="friend-item">' +
                    '<span class="friend-name">' + escHtml(f.nickname || f.username) + '</span>' +
                    '<span style="font-size:0.7rem;color:var(--text-muted);">等待回复...</span>' +
                    '</div>';
            });
            el.innerHTML = html;
        }

        function sendFriendRequest() {
            var input = document.getElementById('addFriendInput');
            var username = input.value.trim();
            if (!username) { showToast('请输入对方名札。', 'error'); return; }
            fetch(API_BASE + '/friends', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: 'username=' + encodeURIComponent(username)
            })
            .then(r => r.json())
            .then(d => {
                if (d.success) { showToast(d.message, 'success'); input.value = ''; loadFriends(); }
                else { showToast(d.error, 'error'); }
            });
        }

        function acceptRequest(id) {
            fetch(API_BASE + '/friends/' + id, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: 'action=accept'
            })
            .then(r => r.json())
            .then(d => {
                if (d.success) { showToast(d.message, 'success'); loadAll(); }
                else { showToast(d.error, 'error'); }
            });
        }

        function rejectRequest(id) {
            fetch(API_BASE + '/friends/' + id, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: 'action=reject'
            })
            .then(r => r.json())
            .then(d => {
                if (d.success) { showToast(d.message, 'success'); loadFriends(); }
                else { showToast(d.error, 'error'); }
            });
        }

        function removeFriend(id) {
            if (!confirm('确定要移除此友人吗？')) return;
            fetch(API_BASE + '/friends/' + id, { method: 'DELETE' })
                .then(r => r.json())
                .then(d => {
                    if (d.success) { showToast(d.message, 'success'); loadAll(); }
                    else { showToast(d.error, 'error'); }
                });
        }

        // ===== 茶室 =====
        function loadRooms() {
            fetch(API_BASE + '/chat/rooms')
                .then(r => r.json())
                .then(d => {
                    if (!d.success) return;
                    var pub = d.data.filter(function(r) { return r.type === 'public'; });
                    var priv = d.data.filter(function(r) { return r.type === 'private'; });
                    renderRoomList('publicRooms', pub, '暂无公共茶室');
                    renderRoomList('privateRooms', priv, '添加友人后，私人茶室将自动创建~');
                });
        }

        function renderRoomList(id, rooms, emptyMsg) {
            var el = document.getElementById(id);
            if (!rooms || rooms.length === 0) {
                el.innerHTML = '<div class="empty-state-sm">' + emptyMsg + '</div>';
                return;
            }
            var html = '';
            rooms.forEach(function(r) {
                var lastMsg = r.last_message ? escHtml(r.last_message.substring(0, 50)) : '暂无消息';
                html += '<div class="room-card" onclick="enterRoom(' + r.id + ')">' +
                    '<div class="room-card-icon">' + (r.type === 'public' ? '🏰' : '💬') + '</div>' +
                    '<div class="room-card-info">' +
                    '<div class="room-card-name">' + escHtml(r.name) + '</div>' +
                    '<div class="room-card-preview">' + lastMsg + '</div>' +
                    '</div>' +
                    '<div class="room-card-meta">👥 ' + (r.member_count || 0) + '</div>' +
                    '</div>';
            });
            el.innerHTML = html;
        }

        function enterRoom(roomId) {
            window.location.href = ctxPath + '/blog/chat/room?id=' + roomId;
        }

        function enterPrivateRoom(friendId, userId) {
            // 自动使用对应的私人茶室
            enterPrivateRoomByUsers(friendId, userId);
        }

        function enterPrivateRoomByUsers(uid1, uid2) {
            // 遍历私人茶室列表找到匹配的
            fetch(API_BASE + '/chat/rooms')
                .then(r => r.json())
                .then(d => {
                    if (!d.success) return;
                    var priv = d.data.filter(function(r) { return r.type === 'private'; });
                    for (var i = 0; i < priv.length; i++) {
                        var name = priv[i].name;
                        // 私人茶室名格式: "nickname1 & nickname2 的茶室"
                        if (priv[i].member_count === 2) {
                            enterRoom(priv[i].id);
                            return;
                        }
                    }
                    showToast('私人茶室尚未创建，请先确认友人关系。', 'error');
                });
        }

        function showCreatePublicRoom() {
            var form = document.getElementById('createRoomForm');
            form.style.display = (form.style.display === 'none' || !form.style.display) ? 'flex' : 'none';
        }

        function createPublicRoom() {
            var name = document.getElementById('newRoomName').value.trim();
            if (!name) { showToast('请输入茶室名称。', 'error'); return; }
            fetch(API_BASE + '/chat/rooms', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: 'name=' + encodeURIComponent(name)
            })
            .then(r => r.json())
            .then(d => {
                if (d.success) { showToast(d.message, 'success'); document.getElementById('newRoomName').value = ''; loadRooms(); }
                else { showToast(d.error, 'error'); }
            });
        }

        // ===== 工具 =====
        function showToast(message, type) {
            var container = document.getElementById('toastContainer');
            var toast = document.createElement('div');
            toast.className = 'toast ' + (type || 'success');
            toast.textContent = message;
            container.appendChild(toast);
            setTimeout(function() {
                toast.style.opacity = '0';
                toast.style.transition = 'all 0.4s';
                setTimeout(function() { toast.remove(); }, 400);
            }, 3000);
        }

        function escHtml(s) {
            if (!s) return '';
            return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
        }
    </script>
</body>
</html>
