<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.scarletblog.model.User" %>
<%
    String ctxPath = request.getContextPath();
    User currentUser = (User) request.getAttribute("currentUser");
    if (currentUser != null) {
        response.sendRedirect(ctxPath + "/blog");
        return;
    }
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🔑 找回封印密语 - 红魔馆</title>
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
        .auth-form input:disabled {
            opacity: 0.5;
            cursor: not-allowed;
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
        .success-msg {
            background: rgba(34, 139, 34, 0.15);
            border: 1px solid #228b22;
            border-radius: 4px;
            padding: 12px 15px;
            color: #90ee90;
            text-align: center;
            margin-bottom: 20px;
            display: none;
        }
        .success-msg.show { display: block; }

        /* 验证方式 Tab 切换 */
        .method-tabs {
            display: flex;
            gap: 0;
            margin-bottom: 25px;
            border-radius: 6px;
            overflow: hidden;
        }
        .method-tab {
            flex: 1;
            padding: 10px 16px;
            background: var(--bg-dark);
            border: 1px solid var(--border-dark);
            color: var(--text-muted);
            cursor: pointer;
            text-align: center;
            font-size: 0.9rem;
            transition: all 0.3s;
            font-family: var(--font-jp);
        }
        .method-tab:first-child { border-radius: 6px 0 0 6px; }
        .method-tab:last-child { border-radius: 0 6px 6px 0; }
        .method-tab.active {
            background: rgba(139, 0, 0, 0.3);
            border-color: var(--gold-dark);
            color: var(--gold);
        }
        .method-tab:hover:not(.active) {
            color: var(--scarlet-light);
            border-color: var(--scarlet-dark);
        }

        /* 步骤指示器 */
        .step-indicator {
            display: flex;
            justify-content: center;
            gap: 30px;
            margin-bottom: 30px;
        }
        .step-dot {
            width: 36px;
            height: 36px;
            border-radius: 50%;
            background: var(--bg-dark);
            border: 2px solid var(--border-dark);
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--text-muted);
            font-weight: bold;
            font-size: 0.9rem;
            transition: all 0.4s;
            position: relative;
        }
        .step-dot.active {
            border-color: var(--gold);
            color: var(--gold);
            box-shadow: 0 0 12px rgba(212, 175, 55, 0.3);
        }
        .step-dot.done {
            background: var(--gold-dark);
            border-color: var(--gold);
            color: #1a0000;
        }
        .step-line {
            width: 40px;
            height: 2px;
            background: var(--border-dark);
            align-self: center;
            transition: background 0.4s;
        }
        .step-line.done {
            background: var(--gold-dark);
        }

        /* 步骤面板 */
        .step-panel { display: none; }
        .step-panel.active { display: block; }

        /* 提示信息 */
        .hint-text {
            color: var(--text-muted);
            font-size: 0.8rem;
            margin-top: 6px;
            font-style: italic;
        }
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
                <a href="<%=ctxPath%>/blog/login">⚜️ 入馆</a>
            </nav>
        </div>
    </header>

    <div class="auth-container">
        <div class="auth-card">
            <div class="gate-icon">🔑</div>
            <h2>找回封印密语</h2>
            <span class="subtitle">~ 重新封印你的名札 ~</span>

            <!-- 验证方式切换 -->
            <div class="method-tabs">
                <div class="method-tab active" id="tabNickname" onclick="switchMethod('nickname')">🔐 昵称验证</div>
                <div class="method-tab" id="tabEmail" onclick="switchMethod('email')">📧 邮箱验证</div>
            </div>

            <!-- 步骤指示器 -->
            <div class="step-indicator">
                <div class="step-dot active" id="stepDot1">1</div>
                <div class="step-line" id="stepLine1"></div>
                <div class="step-dot" id="stepDot2">2</div>
            </div>

            <div class="error-msg" id="errorMsg"></div>
            <div class="success-msg" id="successMsg"></div>

            <!-- ========== 步骤1：验证用户名 ========== -->
            <div class="step-panel active" id="step1Panel">
                <form class="auth-form" id="step1Form" onsubmit="doStep1(event)">
                    <div class="form-group">
                        <label>📛 你的名札（用户名）</label>
                        <input type="text" id="username" placeholder="输入你登记时的名札" maxlength="50" required autofocus>
                    </div>
                    <div class="form-group">
                        <label>🧩 验证码</label>
                        <div style="display:flex;align-items:center;gap:10px;">
                            <span id="captchaQuestion1" style="background:var(--bg-dark);padding:12px 18px;border:1px solid var(--border-dark);border-radius:4px;color:var(--gold);font-family:var(--font-title);font-size:1.1rem;letter-spacing:1px;min-width:120px;text-align:center;">加载中...</span>
                            <button type="button" onclick="refreshCaptcha('captchaQuestion1')" style="background:none;border:1px solid var(--border-dark);color:var(--text-muted);cursor:pointer;padding:8px 12px;border-radius:4px;font-size:0.8rem;transition:all 0.3s;">🔄 刷新</button>
                        </div>
                        <input type="text" id="captcha1" placeholder="请输入答案" maxlength="10" required style="margin-top:8px;width:100%;background:var(--bg-dark);border:1px solid var(--border-dark);color:var(--text-light);padding:10px 15px;font-family:var(--font-jp);font-size:0.9rem;border-radius:4px;">
                    </div>
                    <button type="submit" class="btn-scarlet" id="step1Btn">🔍 验证身份</button>
                </form>
            </div>

            <!-- ========== 步骤2：验证昵称 + 设置新密码 ========== -->
            <div class="step-panel" id="step2Panel">
                <form class="auth-form" id="step2Form" onsubmit="doStep2(event)">
                    <div class="form-group">
                        <label>📛 名札</label>
                        <input type="text" id="usernameDisplay" disabled>
                    </div>
                    <div class="form-group">
                        <label>💬 你的称呼（昵称验证）</label>
                        <input type="text" id="nickname" placeholder="输入你登记时使用的称呼" maxlength="50" required autofocus>
                        <p class="hint-text">请输入你注册时填写的称呼，这是身份验证的关键一步。</p>
                    </div>
                    <div class="form-group">
                        <label>🔐 新的封印密语（新密码）</label>
                        <input type="password" id="newPassword" placeholder="输入新的封印密语（至少4个字符）" maxlength="100" required>
                    </div>
                    <div class="form-group">
                        <label>🧩 验证码</label>
                        <div style="display:flex;align-items:center;gap:10px;">
                            <span id="captchaQuestion2" style="background:var(--bg-dark);padding:12px 18px;border:1px solid var(--border-dark);border-radius:4px;color:var(--gold);font-family:var(--font-title);font-size:1.1rem;letter-spacing:1px;min-width:120px;text-align:center;">加载中...</span>
                            <button type="button" onclick="refreshCaptcha('captchaQuestion2')" style="background:none;border:1px solid var(--border-dark);color:var(--text-muted);cursor:pointer;padding:8px 12px;border-radius:4px;font-size:0.8rem;transition:all 0.3s;">🔄 刷新</button>
                        </div>
                        <input type="text" id="captcha2" placeholder="请输入答案" maxlength="10" required style="margin-top:8px;width:100%;background:var(--bg-dark);border:1px solid var(--border-dark);color:var(--text-light);padding:10px 15px;font-family:var(--font-jp);font-size:0.9rem;border-radius:4px;">
                    </div>
                    <button type="submit" class="btn-scarlet" id="step2Btn">🔐 重置封印密语</button>
                </form>
            </div>

            <!-- ========== 邮箱验证方式 ========== -->
            <div class="step-panel" id="emailPanel">
                <form class="auth-form" id="emailForm" onsubmit="doEmailReset(event)">
                    <div class="form-group">
                        <label>📧 绑定的QQ邮箱</label>
                        <input type="email" id="resetEmail" placeholder="输入你绑定的QQ邮箱" maxlength="100" required autofocus>
                    </div>
                    <div class="form-group">
                        <label>🧩 验证码</label>
                        <div style="display:flex;align-items:center;gap:10px;">
                            <span id="captchaQuestion3" style="background:var(--bg-dark);padding:12px 18px;border:1px solid var(--border-dark);border-radius:4px;color:var(--gold);font-family:var(--font-title);font-size:1.1rem;letter-spacing:1px;min-width:120px;text-align:center;">加载中...</span>
                            <button type="button" onclick="refreshCaptcha('captchaQuestion3')" style="background:none;border:1px solid var(--border-dark);color:var(--text-muted);cursor:pointer;padding:8px 12px;border-radius:4px;font-size:0.8rem;transition:all 0.3s;">🔄 刷新</button>
                        </div>
                        <input type="text" id="captcha3" placeholder="请输入答案" maxlength="10" required style="margin-top:8px;width:100%;background:var(--bg-dark);border:1px solid var(--border-dark);color:var(--text-light);padding:10px 15px;font-family:var(--font-jp);font-size:0.9rem;border-radius:4px;">
                    </div>
                    <button type="submit" class="btn-scarlet" id="emailBtn">📧 发送重置邮件</button>
                    <p style="text-align:center;color:var(--text-muted);font-size:0.8rem;margin-top:15px;">
                        我们将向你的QQ邮箱发送一封包含重置链接的邮件。<br>链接有效期为 30 分钟。
                    </p>
                </form>
            </div>

            <!-- ========== 邮箱 token 重置密码 ========== -->
            <div class="step-panel" id="tokenPanel">
                <form class="auth-form" id="tokenForm" onsubmit="doTokenReset(event)">
                    <div class="form-group">
                        <label>📧 邮箱</label>
                        <input type="text" id="tokenEmailDisplay" disabled>
                    </div>
                    <div class="form-group">
                        <label>🔐 新的封印密语（新密码）</label>
                        <input type="password" id="tokenNewPassword" placeholder="输入新的封印密语（至少4个字符）" maxlength="100" required autofocus>
                    </div>
                    <div class="form-group">
                        <label>🧩 验证码</label>
                        <div style="display:flex;align-items:center;gap:10px;">
                            <span id="captchaQuestion4" style="background:var(--bg-dark);padding:12px 18px;border:1px solid var(--border-dark);border-radius:4px;color:var(--gold);font-family:var(--font-title);font-size:1.1rem;letter-spacing:1px;min-width:120px;text-align:center;">加载中...</span>
                            <button type="button" onclick="refreshCaptcha('captchaQuestion4')" style="background:none;border:1px solid var(--border-dark);color:var(--text-muted);cursor:pointer;padding:8px 12px;border-radius:4px;font-size:0.8rem;transition:all 0.3s;">🔄 刷新</button>
                        </div>
                        <input type="text" id="captcha4" placeholder="请输入答案" maxlength="10" required style="margin-top:8px;width:100%;background:var(--bg-dark);border:1px solid var(--border-dark);color:var(--text-light);padding:10px 15px;font-family:var(--font-jp);font-size:0.9rem;border-radius:4px;">
                    </div>
                    <button type="submit" class="btn-scarlet" id="tokenBtn">🔐 重置封印密语</button>
                </form>
            </div>

            <div class="auth-footer">
                <p>想起密码了？ <a href="<%=ctxPath%>/blog/login">⚜️ 返回入馆 →</a></p>
            </div>
        </div>
    </div>

    <footer class="scarlet-footer">
        <div class="footer-ornament">◆ ◇ ◆</div>
        <p>🏰 红魔馆博客 — Scarlet Devil Mansion Blog</p>
    </footer>

    <script>
        var CTX_PATH = '<%=ctxPath%>';
        var verifiedUsername = '';
        var currentMethod = 'nickname';

        function refreshCaptcha(elId) {
            fetch(CTX_PATH + '/api/auth/captcha')
                .then(function(r) { return r.json(); })
                .then(function(d) {
                    if (d.success) document.getElementById(elId).textContent = d.question;
                });
            var inputMap = { 'captchaQuestion1':'captcha1', 'captchaQuestion2':'captcha2', 'captchaQuestion3':'captcha3', 'captchaQuestion4':'captcha4' };
            var inputId = inputMap[elId];
            if (inputId) document.getElementById(inputId).value = '';
        }

        function showError(msg) {
            var box = document.getElementById('errorMsg');
            box.textContent = msg; box.classList.add('show');
            document.getElementById('successMsg').classList.remove('show');
        }

        function showSuccess(msg) {
            var box = document.getElementById('successMsg');
            box.textContent = msg; box.classList.add('show');
            document.getElementById('errorMsg').classList.remove('show');
        }

        function hideMessages() {
            document.getElementById('errorMsg').classList.remove('show');
            document.getElementById('successMsg').classList.remove('show');
        }

        // ========== 验证方式切换 ==========
        function switchMethod(method) {
            currentMethod = method;
            hideMessages();
            document.getElementById('tabNickname').classList.toggle('active', method === 'nickname');
            document.getElementById('tabEmail').classList.toggle('active', method === 'email');

            // 隐藏所有面板
            document.getElementById('step1Panel').classList.remove('active');
            document.getElementById('step2Panel').classList.remove('active');
            document.getElementById('emailPanel').classList.remove('active');
            document.getElementById('tokenPanel').classList.remove('active');
            document.getElementById('stepDot1').className = 'step-dot active';
            document.getElementById('stepDot2').className = 'step-dot';
            document.getElementById('stepLine1').className = 'step-line';

            if (method === 'nickname') {
                document.getElementById('step1Panel').classList.add('active');
                document.getElementById('stepDot1').style.display = '';
                document.getElementById('stepDot2').style.display = '';
                document.getElementById('stepLine1').style.display = '';
                refreshCaptcha('captchaQuestion1');
            } else {
                document.getElementById('emailPanel').classList.add('active');
                document.getElementById('stepDot1').style.display = 'none';
                document.getElementById('stepDot2').style.display = 'none';
                document.getElementById('stepLine1').style.display = 'none';
                refreshCaptcha('captchaQuestion3');
            }
        }

        // ========== 昵称验证 Step 1 ==========
        async function doStep1(e) {
            e.preventDefault(); hideMessages();
            var username = document.getElementById('username').value.trim();
            var captcha = document.getElementById('captcha1').value.trim();
            var btn = document.getElementById('step1Btn');
            if (!username) { showError('请输入你的名札。'); return; }
            if (!captcha) { showError('请输入验证码。'); return; }
            btn.disabled = true; btn.textContent = '⏳ 验证中...';
            try {
                var fd = 'username=' + encodeURIComponent(username) + '&captcha=' + encodeURIComponent(captcha);
                var resp = await fetch(CTX_PATH + '/api/auth/forgot-password', { method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:fd });
                var data = await resp.json();
                if (data.success) {
                    verifiedUsername = username;
                    document.getElementById('usernameDisplay').value = username;
                    goToStep(2);
                    refreshCaptcha('captchaQuestion2');
                } else { refreshCaptcha('captchaQuestion1'); showError(data.error||'验证失败。'); btn.disabled=false; btn.textContent='🔍 验证身份'; }
            } catch(err) { showError('红魔馆大门暂时无法连接。'); btn.disabled=false; btn.textContent='🔍 验证身份'; }
        }

        // ========== 昵称验证 Step 2 ==========
        async function doStep2(e) {
            e.preventDefault(); hideMessages();
            var nickname = document.getElementById('nickname').value.trim();
            var newPassword = document.getElementById('newPassword').value;
            var captcha = document.getElementById('captcha2').value.trim();
            var btn = document.getElementById('step2Btn');
            if (!nickname) { showError('请输入你的称呼。'); return; }
            if (!newPassword||newPassword.length<4) { showError('新密码至少需要4个字符。'); return; }
            if (!captcha) { showError('请输入验证码。'); return; }
            btn.disabled=true; btn.textContent='⏳ 重置中...';
            try {
                var fd = 'username='+encodeURIComponent(verifiedUsername)+'&nickname='+encodeURIComponent(nickname)+'&new_password='+encodeURIComponent(newPassword)+'&captcha='+encodeURIComponent(captcha);
                var resp = await fetch(CTX_PATH+'/api/auth/reset-password',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:fd});
                var data = await resp.json();
                if(data.success){showSuccess(data.message||'已重置！');document.getElementById('step2Form').style.display='none';setTimeout(function(){window.location.href=CTX_PATH+'/blog/login';},3000);}
                else{refreshCaptcha('captchaQuestion2');showError(data.error||'重置失败。');btn.disabled=false;btn.textContent='🔐 重置封印密语';}
            }catch(err){showError('红魔馆大门暂时无法连接。');btn.disabled=false;btn.textContent='🔐 重置封印密语';}
        }

        // ========== 邮箱验证：发送重置邮件 ==========
        async function doEmailReset(e) {
            e.preventDefault(); hideMessages();
            var email = document.getElementById('resetEmail').value.trim();
            var captcha = document.getElementById('captcha3').value.trim();
            var btn = document.getElementById('emailBtn');
            if (!email) { showError('请输入你的QQ邮箱。'); return; }
            if (!captcha) { showError('请输入验证码。'); return; }
            btn.disabled=true; btn.textContent='⏳ 发送中...';
            try {
                var fd = 'email='+encodeURIComponent(email)+'&captcha='+encodeURIComponent(captcha);
                var resp = await fetch(CTX_PATH+'/api/auth/forgot-password',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:fd});
                var data = await resp.json();
                if(data.success){showSuccess(data.message||'邮件已发送！');document.getElementById('emailForm').style.display='none';}
                else{refreshCaptcha('captchaQuestion3');showError(data.error||'发送失败。');btn.disabled=false;btn.textContent='📧 发送重置邮件';}
            }catch(err){showError('红魔馆大门暂时无法连接。');btn.disabled=false;btn.textContent='📧 发送重置邮件';}
        }

        // ========== Token 重置密码 ==========
        async function doTokenReset(e) {
            e.preventDefault(); hideMessages();
            var urlParams = new URLSearchParams(window.location.search);
            var token = urlParams.get('token') || '';
            var newPassword = document.getElementById('tokenNewPassword').value;
            var captcha = document.getElementById('captcha4').value.trim();
            var btn = document.getElementById('tokenBtn');
            if (!token) { showError('缺少重置令牌，请使用邮件中的完整链接。'); return; }
            if (!newPassword||newPassword.length<4) { showError('新密码至少需要4个字符。'); return; }
            if (!captcha) { showError('请输入验证码。'); return; }
            btn.disabled=true; btn.textContent='⏳ 重置中...';
            try {
                var fd = 'token='+encodeURIComponent(token)+'&new_password='+encodeURIComponent(newPassword)+'&captcha='+encodeURIComponent(captcha);
                var resp = await fetch(CTX_PATH+'/api/auth/reset-by-token',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:fd});
                var data = await resp.json();
                if(data.success){showSuccess(data.message||'已重置！');document.getElementById('tokenForm').style.display='none';setTimeout(function(){window.location.href=CTX_PATH+'/blog/login';},3000);}
                else{refreshCaptcha('captchaQuestion4');showError(data.error||'重置失败。');btn.disabled=false;btn.textContent='🔐 重置封印密语';}
            }catch(err){showError('红魔馆大门暂时无法连接。');btn.disabled=false;btn.textContent='🔐 重置封印密语';}
        }

        // ========== 昵称验证步骤切换 ==========
        function goToStep(step) {
            hideMessages();
            var dot1=document.getElementById('stepDot1'),dot2=document.getElementById('stepDot2'),line1=document.getElementById('stepLine1');
            var panel1=document.getElementById('step1Panel'),panel2=document.getElementById('step2Panel');
            if(step===2){dot1.classList.remove('active');dot1.classList.add('done');dot2.classList.add('active');line1.classList.add('done');panel1.classList.remove('active');panel2.classList.add('active');document.getElementById('nickname').focus();}
        }

        // ========== 页面初始化 ==========
        (function init() {
            refreshCaptcha('captchaQuestion1');
            refreshCaptcha('captchaQuestion2');
            refreshCaptcha('captchaQuestion3');
            refreshCaptcha('captchaQuestion4');
            // 检查 URL 是否带有 token（邮箱重置链接）
            var urlParams = new URLSearchParams(window.location.search);
            var token = urlParams.get('token');
            if (token) {
                // 自动切换到邮箱 Token 重置面板
                currentMethod = 'email';
                document.getElementById('tabNickname').classList.remove('active');
                document.getElementById('tabEmail').classList.add('active');
                document.getElementById('stepDot1').style.display = 'none';
                document.getElementById('stepDot2').style.display = 'none';
                document.getElementById('stepLine1').style.display = 'none';
                document.getElementById('tokenPanel').classList.add('active');
            }
        })();
    </script>
</body>
</html>
