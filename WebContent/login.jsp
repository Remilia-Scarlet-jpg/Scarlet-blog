<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.scarletblog.model.User" %>
<%
    String ctxPath = request.getContextPath();
    User currentUser = (User) request.getAttribute("currentUser");
    if (currentUser != null) {
        response.sendRedirect(ctxPath + "/blog/admin");
        return;
    }
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🏰 入馆通行 - 红魔馆</title>
    <link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Ctext y='50' font-size='50'%3E🏰%3C/text%3E%3C/svg%3E">
    <link rel="stylesheet" href="<%=ctxPath%>/css/scarlet.css">
    <style>
        .auth-container {
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 70vh;
            padding: 40px 20px;
        }
        .auth-card {
            background: linear-gradient(135deg, #1a0a0a 0%, #0d0505 100%);
            border: 1px solid var(--border-dark);
            border-radius: 8px;
            padding: 50px 40px;
            width: 100%;
            max-width: 440px;
            box-shadow: 0 0 40px rgba(139, 0, 0, 0.3), 0 10px 30px rgba(0,0,0,0.6);
            position: relative;
        }
        .auth-card::before {
            content: '';
            position: absolute;
            top: 0; left: 0; right: 0;
            height: 4px;
            background: linear-gradient(90deg, var(--scarlet-darkest), var(--scarlet), var(--gold), var(--scarlet), var(--scarlet-darkest));
        }
        .auth-card h2 {
            font-family: var(--font-title);
            color: var(--gold);
            text-align: center;
            font-size: 1.6rem;
            margin-bottom: 5px;
            letter-spacing: 4px;
        }
        .auth-card .subtitle {
            text-align: center;
            color: var(--text-muted);
            font-family: var(--font-en);
            font-style: italic;
            font-size: 0.85rem;
            margin-bottom: 35px;
            display: block;
        }
        .auth-card .gate-icon {
            text-align: center;
            font-size: 3rem;
            margin-bottom: 15px;
            animation: logoPulse 3s ease-in-out infinite;
        }
        .auth-form .form-group {
            margin-bottom: 22px;
        }
        .auth-form label {
            display: block;
            color: var(--gold);
            font-family: var(--font-en);
            font-size: 0.85rem;
            letter-spacing: 2px;
            margin-bottom: 8px;
        }
        .auth-form input {
            width: 100%;
            background: var(--bg-dark);
            border: 1px solid var(--border-dark);
            color: var(--text-light);
            padding: 14px 16px;
            font-family: var(--font-jp);
            font-size: 1rem;
            border-radius: 4px;
            transition: all 0.3s;
        }
        .auth-form input:focus {
            outline: none;
            border-color: var(--gold-dark);
            box-shadow: 0 0 15px rgba(212, 175, 55, 0.2);
        }
        .auth-form .btn-scarlet {
            width: 100%;
            padding: 15px;
            font-size: 1.1rem;
            margin-top: 10px;
        }
        .auth-footer {
            text-align: center;
            margin-top: 25px;
            color: var(--text-muted);
            font-size: 0.9rem;
        }
        .auth-footer a {
            color: var(--scarlet-light);
            text-decoration: none;
            transition: color 0.3s;
        }
        .auth-footer a:hover {
            color: var(--gold-bright);
        }
        .error-msg {
            background: rgba(220, 20, 60, 0.15);
            border: 1px solid var(--scarlet);
            border-radius: 4px;
            padding: 12px 15px;
            color: var(--scarlet-light);
            text-align: center;
            margin-bottom: 20px;
            display: none;
        }
        .error-msg.show { display: block; }
    </style>
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
                <a href="<%=ctxPath%>/blog/register">📝 来馆登记</a>
            </nav>
        </div>
    </header>

    <div class="auth-container">
        <div class="auth-card">
            <div class="gate-icon">⚜️</div>
            <h2>入 馆 通 行</h2>
            <span class="subtitle">~ 出示你的名札 ~</span>

            <div class="error-msg" id="errorMsg"></div>

            <form class="auth-form" id="loginForm" onsubmit="doLogin(event)">
                <div class="form-group">
                    <label>📛 名札（用户名）</label>
                    <input type="text" name="username" id="username" placeholder="输入你的名札" maxlength="50" required autofocus>
                </div>
                <div class="form-group">
                    <label>🔐 封印密语（密码）</label>
                    <input type="password" name="password" id="password" placeholder="输入你的封印密语" maxlength="100" required>
                </div>
                <div class="form-group">
                    <label>🧩 验证码</label>
                    <div style="display:flex;align-items:center;gap:10px;">
                        <span id="captchaQuestion" style="background:var(--bg-dark);padding:12px 18px;border:1px solid var(--border-dark);border-radius:4px;color:var(--gold);font-family:var(--font-title);font-size:1.1rem;letter-spacing:1px;min-width:120px;text-align:center;">加载中...</span>
                        <button type="button" onclick="refreshCaptcha()" style="background:none;border:1px solid var(--border-dark);color:var(--text-muted);cursor:pointer;padding:8px 12px;border-radius:4px;font-size:0.8rem;transition:all 0.3s;">🔄 刷新</button>
                    </div>
                    <input type="text" id="captcha" placeholder="请输入答案" maxlength="5" required style="margin-top:8px;width:100%;background:var(--bg-dark);border:1px solid var(--border-dark);color:var(--text-light);padding:10px 15px;font-family:var(--font-jp);font-size:0.9rem;border-radius:4px;">
                </div>
                <button type="submit" class="btn-scarlet" id="loginSubmitBtn">⚜️ 入馆</button>
            </form>

            <div class="auth-footer">
                <p>尚未登记？ <a href="<%=ctxPath%>/blog/register">📝 来馆登记 →</a></p>
                <p><a href="<%=ctxPath%>/blog/forgot-password">🔑 忘记密码？</a></p>
            </div>
        </div>
    </div>

    <footer class="scarlet-footer">
        <div class="footer-ornament">◆ ◇ ◆</div>
        <p>🏰 红魔馆博客 — Scarlet Devil Mansion Blog</p>
    </footer>

    <script>
        function refreshCaptcha() {
            fetch('<%=ctxPath%>/api/auth/captcha')
                .then(r => r.json())
                .then(d => {
                    if (d.success) document.getElementById('captchaQuestion').textContent = d.question;
                });
            document.getElementById('captcha').value = '';
        }
        refreshCaptcha(); // 页面加载时获取

        async function doLogin(e) {
            e.preventDefault();
            var username = document.getElementById('username').value.trim();
            var password = document.getElementById('password').value;
            var captcha = document.getElementById('captcha').value.trim();
            var errorBox = document.getElementById('errorMsg');
            var btn = document.getElementById('loginSubmitBtn');

            if (!username || !password) {
                showError('请出示你的名札和封印密语。');
                return;
            }
            if (!captcha) {
                showError('请输入验证码。');
                return;
            }

            // 防止重复提交
            btn.disabled = true;
            btn.textContent = '⏳ 入馆中...';

            try {
                var formData = 'username=' + encodeURIComponent(username)
                    + '&password=' + encodeURIComponent(password)
                    + '&captcha=' + encodeURIComponent(captcha);
                var resp = await fetch('<%=ctxPath%>/api/auth/login', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                    body: formData
                });
                var data = await resp.json();
                if (data.success) {
                    // 登录成功，按角色跳转
                    var role = data.data && data.data.role;
                    if (role === '馆主' || role === '女仆长') {
                        window.location.href = '<%=ctxPath%>/blog/admin';
                    } else {
                        window.location.href = '<%=ctxPath%>/blog';
                    }
                } else {
                    refreshCaptcha();
                    showError(data.error || '入馆通行失败。');
                    btn.disabled = false;
                    btn.textContent = '⚜️ 入馆';
                }
            } catch (err) {
                showError('红魔馆大门暂时无法连接，请稍后再试。');
                btn.disabled = false;
                btn.textContent = '⚜️ 入馆';
            }
        }

        function showError(msg) {
            var box = document.getElementById('errorMsg');
            box.textContent = msg;
            box.classList.add('show');
            box.classList.remove('hide');
        }
    </script>
</body>
</html>
