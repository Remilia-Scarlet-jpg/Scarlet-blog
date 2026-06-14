<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.scarletblog.model.User" %>
<%
    String ctxPath = request.getContextPath();
    User currentUser = (User) request.getAttribute("currentUser");
    if (currentUser == null) {
        response.sendRedirect(ctxPath + "/blog/login");
        return;
    }
    String roomIdStr = request.getParameter("id");
    if (roomIdStr == null || roomIdStr.isEmpty()) {
        response.sendRedirect(ctxPath + "/blog/chat");
        return;
    }
    int roomId = Integer.parseInt(roomIdStr);
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🍵 茶室 - 红魔馆</title>
    <link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Ctext y='50' font-size='50'%3E🍵%3C/text%3E%3C/svg%3E">
    <link rel="stylesheet" href="<%=ctxPath%>/css/scarlet.css">
</head>
<body>
    <header class="scarlet-header">
        <div class="header-inner">
            <div class="logo-area">
                <div class="logo-icon">🍵</div>
                <div class="logo-text">
                    <h1 id="roomTitle">茶 室</h1>
                    <span class="subtitle">~ Tea Room ~</span>
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

    <div class="main-container full-width" style="max-width:800px;margin:30px auto;padding:0 20px;">
        <!-- 茶室头部 -->
        <div class="room-header">
            <div class="room-header-icon" id="roomIcon">🍵</div>
            <div class="room-header-info">
                <h2 id="roomName">加载中...</h2>
                <span id="roomMeta"></span>
            </div>
        </div>

        <!-- 消息列表 -->
        <div class="message-list" id="messageList">
            <div class="empty-state-sm">正在加载消息...</div>
        </div>

        <!-- 输入区 -->
        <div class="chat-input-area">
            <textarea id="messageInput" placeholder="输入消息...（Enter 发送，Shift+Enter 换行）" rows="2"></textarea>
            <button class="btn-scarlet" onclick="sendMessage()" id="sendBtn">📨 发送</button>
        </div>
    </div>

    <footer class="scarlet-footer">
        <div class="footer-ornament">◆ ◇ ◆</div>
        <p>🏰 红魔馆博客 — Scarlet Devil Mansion Blog</p>
    </footer>

    <script>
        var API_BASE = '<%=ctxPath%>/api';
        var ctxPath = '<%=ctxPath%>';
        var roomId = <%= roomId %>;
        var currentUserId = <%= currentUser.getId() %>;
        var lastMsgId = 0;
        var polling = null;
        var fetchFailCount = 0;

        // 检测移动端
        var isMobile = /Android|iPhone|iPad|iPod|webOS/i.test(navigator.userAgent)
                    || (navigator.maxTouchPoints > 1 && window.innerWidth < 900);
        var POLL_INTERVAL = isMobile ? 5000 : 3000;  // 移动端 5秒，桌面 3秒
        var INITIAL_MSG_LIMIT = isMobile ? 20 : 50;   // 移动端首屏少加载

        // 加载茶室信息（带重试）
        function fetchWithRetry(url, retries, delayMs) {
            retries = retries || 2;
            delayMs = delayMs || 1000;
            return fetch(url).then(function(r) {
                if (!r.ok) throw new Error('HTTP ' + r.status);
                return r.json();
            }).catch(function(e) {
                if (retries > 0) {
                    console.log('[chat] Retrying fetch, attempts left: ' + retries);
                    return new Promise(function(resolve) {
                        setTimeout(function() {
                            resolve(fetchWithRetry(url, retries - 1, delayMs * 2));
                        }, delayMs);
                    });
                }
                throw e;
            });
        }

        fetchWithRetry(API_BASE + '/chat/rooms/' + roomId)
            .then(function(d) {
                if (d.success) {
                    document.getElementById('roomName').textContent = d.data.name;
                    document.getElementById('roomIcon').textContent = d.data.type === 'public' ? '🏰' : '💬';
                    document.getElementById('roomMeta').textContent = '👥 ' + d.data.member_count + ' 人';
                    document.title = '🍵 ' + d.data.name + ' - 红魔馆';
                } else {
                    showToast(d.error, 'error');
                    setTimeout(function() { window.location.href = ctxPath + '/blog/chat'; }, 2000);
                }
            }).catch(function() {
                document.getElementById('roomName').textContent = '加载失败';
                document.getElementById('roomMeta').textContent = '请检查网络连接后刷新';
            });

        // 加载消息
        loadMessages(true);

        function loadMessages(isInitial) {
            var url = API_BASE + '/chat/rooms/' + roomId + '/messages';
            if (lastMsgId > 0) url += '?since=' + lastMsgId;
            if (isInitial) {
                url += (lastMsgId > 0 ? '&' : '?') + 'limit=' + INITIAL_MSG_LIMIT;
            }

            fetchWithRetry(url, 2, 1500)
                .then(function(d) {
                    fetchFailCount = 0;  // 重置失败计数
                    if (d.success && d.data.length > 0) {
                        d.data.forEach(function(m) {
                            appendMessage(m);
                            if (m.id > lastMsgId) lastMsgId = m.id;
                        });
                        scrollToBottom();
                    }
                }).catch(function() {
                    fetchFailCount++;
                    // 连续失败 5 次（移动端 25 秒，桌面 15 秒）提示用户
                    if (fetchFailCount >= 5) {
                        showToast('⚠️ 连接不稳定，消息可能延迟', 'error');
                        fetchFailCount = 0;
                    }
                });
        }

        function appendMessage(m) {
            var container = document.getElementById('messageList');
            var empty = container.querySelector('.empty-state-sm');
            if (empty) empty.remove();

            var isSelf = m.sender_id === currentUserId;
            var avatar = m.sender_avatar ? (m.sender_avatar.startsWith('data:') ? m.sender_avatar : ctxPath + '/' + m.sender_avatar) : 'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 24 24%22%3E%3Ccircle cx=%2212%22 cy=%2212%22 r=%2212%22 fill=%22%234a0000%22/%3E%3C/svg%3E';
            var time = new Date(m.created_at).toLocaleTimeString('zh-CN', {hour:'2-digit',minute:'2-digit'});

            var div = document.createElement('div');
            div.className = 'message-item' + (isSelf ? ' message-self' : '');
            div.innerHTML =
                '<img class="message-avatar" src="' + avatar + '" onerror="this.src=\'data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 24 24%22%3E%3Ccircle cx=%2212%22 cy=%2212%22 r=%2212%22 fill=%22%234a0000%22/%3E%3C/svg%3E\'">' +
                '<div class="message-body">' +
                '<div class="message-header">' +
                '<span class="message-sender">' + escHtml(m.sender_nickname) + '</span>' +
                '<span class="message-time">' + time + '</span>' +
                '</div>' +
                '<div class="message-content">' + escHtml(m.content) + '</div>' +
                '</div>';
            container.appendChild(div);
        }

        function scrollToBottom() {
            var list = document.getElementById('messageList');
            var nearBottom = list.scrollHeight - list.scrollTop - list.clientHeight < 100;
            if (nearBottom) {
                list.scrollTop = list.scrollHeight;
            }
        }

        function sendMessage() {
            var input = document.getElementById('messageInput');
            var content = input.value.trim();
            if (!content) return;
            var btn = document.getElementById('sendBtn');
            btn.disabled = true; btn.textContent = '⏳';

            fetch(API_BASE + '/chat/messages', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: 'room_id=' + roomId + '&content=' + encodeURIComponent(content)
            })
            .then(function(r) { return r.json(); })
            .then(function(d) {
                btn.disabled = false; btn.textContent = '📨 发送';
                if (d.success) {
                    input.value = '';
                    input.focus();
                    loadMessages();
                } else {
                    showToast(d.error, 'error');
                }
            }).catch(function() {
                btn.disabled = false; btn.textContent = '📨 发送';
                showToast('发送失败，请重试', 'error');
            });
        }

        // Enter 发送，Shift+Enter 换行
        document.getElementById('messageInput').addEventListener('keydown', function(e) {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                sendMessage();
            }
        });

        // 自适应轮询间隔
        polling = setInterval(loadMessages, POLL_INTERVAL);

        // 页面离开时停止轮询
        window.addEventListener('beforeunload', function() { clearInterval(polling); });

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
