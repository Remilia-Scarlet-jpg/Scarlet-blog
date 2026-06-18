<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String ctxPath = request.getContextPath();
    String result = (String) request.getAttribute("verifyResult");
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>📧 邮箱验证 - 红魔馆</title>
    <link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Ctext y='50' font-size='50'%3E🏰%3C/text%3E%3C/svg%3E">
    <link rel="stylesheet" href="<%=ctxPath%>/css/scarlet.css">
    <style>
        .result-container {
            display: flex; justify-content: center; align-items: center; min-height: 60vh; padding: 40px 20px;
        }
        .result-card {
            background: linear-gradient(135deg, #1a0a0a 0%, #0d0505 100%);
            border: 1px solid var(--border-dark); border-radius: 8px; padding: 50px 40px;
            width: 100%; max-width: 480px; text-align: center;
            box-shadow: 0 0 40px rgba(139,0,0,0.3);
        }
        .result-icon { font-size: 4rem; margin-bottom: 20px; }
        .result-title { color: var(--gold); font-size: 1.4rem; letter-spacing: 2px; margin-bottom: 10px; }
        .result-msg { color: var(--text-muted); margin-bottom: 30px; line-height: 1.8; }
        .result-card .btn-scarlet { display: inline-block; padding: 12px 40px; }
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
                <a href="<%=ctxPath%>/blog">🏠 大厅</a>
            </nav>
        </div>
    </header>

    <div class="result-container">
        <div class="result-card">
            <% if ("success".equals(result)) { %>
                <div class="result-icon">✅</div>
                <div class="result-title">邮箱验证成功！</div>
                <div class="result-msg">你的邮箱已通过验证。<br>现在可以通过邮箱找回封印密语了。</div>
                <a href="<%=ctxPath%>/blog/user" class="btn-scarlet">📋 前往个人主页</a>
            <% } else if ("fail".equals(result)) { %>
                <div class="result-icon">❌</div>
                <div class="result-title">验证链接无效</div>
                <div class="result-msg">此验证链接已过期或无效。<br>请在个人主页重新绑定邮箱获取新的验证链接。</div>
                <a href="<%=ctxPath%>/blog/user" class="btn-scarlet">📋 前往个人主页</a>
            <% } else { %>
                <div class="result-icon">📧</div>
                <div class="result-title">缺少验证信息</div>
                <div class="result-msg">请点击邮件中的完整验证链接。</div>
                <a href="<%=ctxPath%>/blog" class="btn-scarlet">🏠 返回大厅</a>
            <% } %>
        </div>
    </div>

    <footer class="scarlet-footer">
        <div class="footer-ornament">◆ ◇ ◆</div>
        <p>🏰 红魔馆博客 — Scarlet Devil Mansion Blog</p>
    </footer>
</body>
</html>
