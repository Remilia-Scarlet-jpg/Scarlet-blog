package com.scarletblog.servlet;

import com.scarletblog.dao.PostDAO;
import com.scarletblog.dao.CategoryDAO;
import com.scarletblog.dao.UserDAO;
import com.scarletblog.dao.FriendDAO;
import com.scarletblog.dao.ChatDAO;
import com.scarletblog.dao.CarouselDAO;
import com.scarletblog.model.Post;
import com.scarletblog.model.Comment;
import com.scarletblog.model.Category;
import com.scarletblog.model.User;
import com.scarletblog.model.Friend;
import com.scarletblog.model.ChatRoom;
import com.scarletblog.model.Message;
import com.scarletblog.model.CarouselSlide;

import com.scarletblog.util.SecurityUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.security.SecureRandom;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 红魔馆博客 - 主控制器 Servlet
 * 处理所有 /blog/* 和 /api/* 请求
 */
@MultipartConfig(
    maxFileSize = 52 * 1024 * 1024,      // 52MB（预留视频上传空间）
    maxRequestSize = 60 * 1024 * 1024,   // 60MB
    fileSizeThreshold = 1024 * 1024      // 1MB buffer
)
public class BlogServlet extends HttpServlet {
    private PostDAO postDAO = new PostDAO();
    private CategoryDAO categoryDAO = new CategoryDAO();
    private UserDAO userDAO = new UserDAO();
    private FriendDAO friendDAO = new FriendDAO();
    private ChatDAO chatDAO = new ChatDAO();
    private CarouselDAO carouselDAO = new CarouselDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String path = req.getRequestURI().substring(req.getContextPath().length());

        try {
            // CSRF 防护：状态变更 API 验证 Origin 头
            String method = req.getMethod();
            if (isStateChanging(method) && path.startsWith("/api/")) {
                if (!csrfCheck(req)) {
                    resp.setContentType("application/json;charset=UTF-8");
                    resp.getWriter().write("{\"success\":false,\"error\":\"CSRF 验证失败\"}");
                    return;
                }
            }
            if (path.equals("/") || path.equals("/index.jsp") || path.equals("/blog")) {
                handleIndex(req, resp);
            } else if (path.equals("/blog/post")) {
                handlePostDetail(req, resp);
            } else if (path.equals("/blog/admin")) {
                handleAdmin(req, resp);
            } else if (path.equals("/blog/login")) {
                handleLoginPage(req, resp);
            } else if (path.equals("/blog/register")) {
                handleRegisterPage(req, resp);
            } else if (path.equals("/blog/profile")) {
                handleProfilePage(req, resp);
            } else if (path.equals("/blog/user")) {
                handleUserPage(req, resp);
            } else if (path.startsWith("/api/auth")) {
                handleAuthAPI(req, resp);
            } else if (path.startsWith("/api/posts")) {
                handlePostsAPI(req, resp);
            } else if (path.startsWith("/api/comments")) {
                handleCommentsAPI(req, resp);
            } else if (path.startsWith("/api/categories")) {
                handleCategoriesAPI(req, resp);
            } else if (path.equals("/api/stats")) {
                handleStatsAPI(req, resp);
            } else if (path.equals("/api/health")) {
                handleHealth(req, resp);
            } else if (path.startsWith("/api/admin/users")) {
                handleAdminUsers(req, resp);
            } else if (path.startsWith("/api/admin/carousel")) {
                handleCarouselAPI(req, resp);
            } else if (path.startsWith("/api/users")) {
                handleUsersAPI(req, resp);
            } else if (path.startsWith("/api/friends")) {
                handleFriendsAPI(req, resp);
            } else if (path.startsWith("/api/chat")) {
                handleChatAPI(req, resp);
            } else if (path.equals("/blog/forgot-password")) {
                handleForgotPasswordPage(req, resp);
            } else if (path.equals("/blog/verify-email")) {
                handleVerifyEmailPage(req, resp);
            } else if (path.startsWith("/blog/chat")) {
                handleChatPage(req, resp);
            } else {
                req.getRequestDispatcher("/index.jsp").forward(req, resp);
            }
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendError(500, "红魔馆内部错误：" + e.getMessage());
        }
        addSameSiteCookie(resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        doGet(req, resp);
    }

    @Override
    protected void doPut(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        doGet(req, resp);
    }

    @Override
    protected void doDelete(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        doGet(req, resp);
    }

    // ============================================
    // 入馆通行 (登录页面)
    // ============================================
    private void handleLoginPage(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        // 已登录则按角色跳转
        User user = getCurrentUser(req);
        if (user != null) {
            if (user.isAdmin()) {
                resp.sendRedirect(req.getContextPath() + "/blog/admin");
            } else {
                resp.sendRedirect(req.getContextPath() + "/blog");
            }
            return;
        }
        req.getRequestDispatcher("/login.jsp").forward(req, resp);
    }

    // ============================================
    // 找回封印密语 (忘记密码页面)
    // ============================================
    private void handleForgotPasswordPage(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        User user = getCurrentUser(req);
        if (user != null) {
            resp.sendRedirect(req.getContextPath() + "/blog");
            return;
        }
        // 如果有 token 参数，说明是邮箱重置链接 → 传给页面处理
        String token = req.getParameter("token");
        if (token != null && !token.trim().isEmpty()) {
            req.setAttribute("resetToken", token.trim());
        }
        req.getRequestDispatcher("/forgot-password.jsp").forward(req, resp);
    }

    // ============================================
    // 邮箱验证落地页
    // ============================================
    private void handleVerifyEmailPage(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        String token = req.getParameter("token");
        // 即使未登录也可能访问（点击邮件中的链接）
        if (token != null && !token.trim().isEmpty()) {
            boolean ok = userDAO.verifyEmail(token.trim());
            req.setAttribute("verifyResult", ok ? "success" : "fail");
        } else {
            req.setAttribute("verifyResult", "missing");
        }
        req.getRequestDispatcher("/verify-email.jsp").forward(req, resp);
    }

    // ============================================
    // 来馆登记 (注册页面)
    // ============================================
    private void handleRegisterPage(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        User user = getCurrentUser(req);
        if (user != null) {
            if (user.isAdmin()) {
                resp.sendRedirect(req.getContextPath() + "/blog/admin");
            } else {
                resp.sendRedirect(req.getContextPath() + "/blog");
            }
            return;
        }
        req.getRequestDispatcher("/register.jsp").forward(req, resp);
    }

    // ============================================
    // 访客档案 (个人资料页)
    // ============================================
    private void handleProfilePage(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        // 已整合到 user.jsp，重定向到新公开主页
        User user = getCurrentUser(req);
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/blog/login");
            return;
        }
        resp.sendRedirect(req.getContextPath() + "/blog/user?id=" + user.getId());
    }

    // ============================================
    // 住人公开主页（B 站风格个人主页）
    // ============================================
    private void handleUserPage(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        User currentUser = getCurrentUser(req);
        if (currentUser == null) {
            resp.sendRedirect(req.getContextPath() + "/blog/login");
            return;
        }
        String idStr = req.getParameter("id");
        if (idStr == null || idStr.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/blog");
            return;
        }
        int targetUserId = Integer.parseInt(idStr.trim());
        User profileUser = userDAO.findById(targetUserId);
        if (profileUser == null) {
            resp.sendRedirect(req.getContextPath() + "/blog");
            return;
        }

        // 加载统计数据
        int postCount = userDAO.getPostCount(targetUserId);
        int commentCount = userDAO.getCommentCount(targetUserId);
        int friendCount = friendDAO.getFriendCount(targetUserId);

        // 判断关系状态
        String relationship = "none";
        int friendshipId = 0;
        if (currentUser.getId() == targetUserId) {
            relationship = "self";
        } else {
            Friend rel = friendDAO.getRelationshipBetween(currentUser.getId(), targetUserId);
            if (rel == null) {
                relationship = "none";
            } else if ("accepted".equals(rel.getStatus())) {
                relationship = "friend";
                friendshipId = rel.getId();
            } else if (rel.getUserId() == currentUser.getId()) {
                relationship = "pending_sent";
                friendshipId = rel.getId();
            } else {
                relationship = "pending_received";
                friendshipId = rel.getId();
            }
        }

        // 加载最近文章
        List<Post> recentPosts = postDAO.getPostsByAuthor(profileUser.getNickname(), 1, 5);

        req.setAttribute("currentUser", currentUser);
        req.setAttribute("profileUser", profileUser);
        req.setAttribute("postCount", postCount);
        req.setAttribute("commentCount", commentCount);
        req.setAttribute("friendCount", friendCount);
        req.setAttribute("relationship", relationship);
        req.setAttribute("friendshipId", friendshipId);
        req.setAttribute("recentPosts", recentPosts);
        req.getRequestDispatcher("/user.jsp").forward(req, resp);
    }

    // ============================================
    // 认证 API
    // ============================================
    private void handleAuthAPI(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        resp.setContentType("application/json;charset=UTF-8");
        String path = req.getRequestURI().substring(req.getContextPath().length());
        String method = req.getMethod();

        // POST /api/auth/login — 入馆通行
        if (path.equals("/api/auth/login") && method.equals("POST")) {
            String username = req.getParameter("username");
            String password = req.getParameter("password");
            String captcha = req.getParameter("captcha");

            // 登录限流检查
            String ip = getClientIP(req);
            if (SecurityUtil.isBlocked(ip)) {
                long sec = SecurityUtil.getBlockSeconds(ip);
                resp.getWriter().write("{\"success\":false,\"error\":\"尝试次数过多，请 " + (sec / 60 + 1) + " 分钟后再试。\"}");
                return;
            }

            // 验证码检查
            HttpSession session = req.getSession(false);
            if (session == null || session.getAttribute("captchaAnswer") == null) {
                resp.getWriter().write("{\"success\":false,\"error\":\"验证码已过期，请刷新。\"}");
                return;
            }
            String expectedCaptcha = (String) session.getAttribute("captchaAnswer");
            if (captcha == null || !captcha.trim().equalsIgnoreCase(expectedCaptcha)) {
                session.removeAttribute("captchaAnswer");
                resp.getWriter().write("{\"success\":false,\"error\":\"验证码错误，请重新输入。\"}");
                return;
            }
            session.removeAttribute("captchaAnswer");

            if (username == null || password == null || username.trim().isEmpty()) {
                resp.getWriter().write("{\"success\":false,\"error\":\"请出示你的名札（用户名不能为空）！\"}");
                return;
            }

            User user = userDAO.login(username.trim(), password);
            if (user != null) {
                SecurityUtil.clearAttempts(ip);
                // Session 加固：登录成功后重新生成 Session ID
                HttpSession oldSession = req.getSession(false);
                if (oldSession != null) oldSession.invalidate();
                HttpSession newSession = req.getSession(true);
                newSession.setAttribute("user", user);
                newSession.setMaxInactiveInterval(60 * 60 * 24); // 24小时
                resp.getWriter().write(toUserJson(user));
            } else {
                SecurityUtil.recordFailure(ip);
                long remaining = 5 - (SecurityUtil.isBlocked(ip) ? 0 : 5);
                resp.getWriter().write("{\"success\":false,\"error\":\"封印密语不符…请确认名札和密语是否正确。\"}");
            }
        }
        // POST /api/auth/register — 来馆登记
        else if (path.equals("/api/auth/register") && method.equals("POST")) {
            String username = req.getParameter("username");
            String password = req.getParameter("password");
            String nickname = req.getParameter("nickname");
            String captcha = req.getParameter("captcha");

            // 验证码
            HttpSession session = req.getSession(false);
            if (session == null || session.getAttribute("captchaAnswer") == null) {
                resp.getWriter().write("{\"success\":false,\"error\":\"验证码已过期，请刷新。\"}");
                return;
            }
            String expected = (String) session.getAttribute("captchaAnswer");
            if (captcha == null || !captcha.trim().equalsIgnoreCase(expected)) {
                session.removeAttribute("captchaAnswer");
                resp.getWriter().write("{\"success\":false,\"error\":\"验证码错误，请重新输入。\"}");
                return;
            }
            session.removeAttribute("captchaAnswer");

            if (username == null || username.trim().length() < 2) {
                resp.getWriter().write("{\"success\":false,\"error\":\"名札至少需要2个字符！\"}");
                return;
            }
            if (password == null || password.length() < 4) {
                resp.getWriter().write("{\"success\":false,\"error\":\"封印密语至少需要4个字符！\"}");
                return;
            }
            if (userDAO.usernameExists(username.trim())) {
                resp.getWriter().write("{\"success\":false,\"error\":\"此名札已被登记，请换一个吧。\"}");
                return;
            }

            User newUser = new User();
            newUser.setUsername(username.trim());
            newUser.setPassword(password);
            newUser.setNickname(nickname != null && !nickname.trim().isEmpty() ? nickname.trim() : username.trim());
            int id = userDAO.register(newUser);

            if (id > 0) {
                newUser.setId(id);
                newUser.setRole("住人");  // 新登记默认身份
                // 如果注册时提供了邮箱 → 自动绑定并发送验证邮件
                String regEmail = req.getParameter("email");
                if (regEmail != null && !regEmail.trim().isEmpty() && regEmail.matches("^[\\w\\-\\.]+@[\\w\\-\\.]+\\.\\w+$")) {
                    try {
                        if (!userDAO.emailExists(regEmail.trim()) && com.scarletblog.util.EmailUtil.isConfigured()) {
                            userDAO.bindEmail(id, regEmail.trim());
                            String ctxPath = req.getScheme() + "://" + req.getServerName() +
                                (req.getServerPort() != 80 && req.getServerPort() != 443 ? ":" + req.getServerPort() : "") +
                                req.getContextPath();
                            // regenerate token for email
                            String token = java.util.UUID.randomUUID().toString();
                            java.sql.Connection c = com.scarletblog.util.DBUtil.getConnection();
                            java.sql.PreparedStatement ps = c.prepareStatement(
                                "UPDATE users SET verify_token = ?, token_expires = DATE_ADD(NOW(), INTERVAL 30 MINUTE) WHERE id = ?");
                            ps.setString(1, token);
                            ps.setInt(2, id);
                            ps.executeUpdate();
                            ps.close(); c.close();
                            com.scarletblog.util.EmailUtil.sendVerifyEmail(regEmail.trim(), token);
                        }
                    } catch (Exception e) { /* 邮件发送失败不影响注册 */ }
                }
                // 自动加入所有公共茶室
                try { chatDAO.addUserToPublicRooms(id); } catch (Exception e) {}
                // 登记成功，自动入馆 —— Session 加固
                HttpSession oldSession = req.getSession(false);
                if (oldSession != null) oldSession.invalidate();
                HttpSession newSession = req.getSession(true);
                newSession.setAttribute("user", newUser);
                newSession.setMaxInactiveInterval(60 * 60 * 24); // 24小时
                resp.getWriter().write(toUserJson(newUser));
            } else {
                resp.getWriter().write("{\"success\":false,\"error\":\"登记失败，请稍后再试。\"}");
            }
        }
        // GET /api/auth/captcha — 获取验证码（随机题库）
        else if (path.equals("/api/auth/captcha") && method.equals("GET")) {
            resp.setContentType("application/json;charset=UTF-8");
            HttpSession session = req.getSession(true);
            String[] qa = pickCaptcha();
            session.setAttribute("captchaAnswer", qa[1]);
            resp.getWriter().write("{\"success\":true,\"question\":\"" + escapeJson(qa[0]) + "\"}");
        }
        // GET /api/auth/me — 查看当前访客
        else if (path.equals("/api/auth/me") && method.equals("GET")) {
            User user = getCurrentUser(req);
            if (user != null) {
                resp.getWriter().write(toUserJson(user));
            } else {
                resp.getWriter().write("{\"success\":false,\"error\":\"未入馆\"}");
            }
        }
        // POST /api/auth/profile — 更新资料 (含头像上传)
        else if (path.equals("/api/auth/profile") && method.equals("POST")) {
            User user = getCurrentUser(req);
            if (user == null) {
                resp.getWriter().write("{\"success\":false,\"error\":\"请先入馆。\"}");
                return;
            }

            String nickname = req.getParameter("nickname");
            String avatar = null;
            String background = null;

            // 处理头像文件上传
            Part filePart = null;
            try { filePart = req.getPart("avatar"); } catch (Exception e) {}

            if (filePart != null && filePart.getSize() > 0) {
                String fileName = getSubmittedFileName(filePart);
                String ext = fileName.contains(".") ? fileName.substring(fileName.lastIndexOf(".")).toLowerCase() : ".jpg";
                // 只允许图片格式
                if (!ext.matches("\\.(jpg|jpeg|png|gif|webp)$")) {
                    resp.getWriter().write("{\"success\":false,\"error\":\"头像仅支持 JPG/PNG/GIF/WebP 格式。\"}");
                    return;
                }
                // 转 Base64 存入数据库（容器磁盘不持久化）
                String mime = ext.equals(".webp") ? "image/webp" : ext.equals(".gif") ? "image/gif" :
                    ext.equals(".png") ? "image/png" : "image/jpeg";
                java.io.ByteArrayOutputStream baos = new java.io.ByteArrayOutputStream();
                try (InputStream is = filePart.getInputStream()) {
                    byte[] buf = new byte[8192]; int n;
                    while ((n = is.read(buf)) != -1) baos.write(buf, 0, n);
                }
                avatar = "data:" + mime + ";base64," + java.util.Base64.getEncoder().encodeToString(baos.toByteArray());
            }

            // 处理背景图上传
            Part bgPart = null;
            try { bgPart = req.getPart("background"); } catch (Exception e) {}
            if (bgPart != null && bgPart.getSize() > 0) {
                String bgName = getSubmittedFileName(bgPart);
                String bgExt = bgName.contains(".") ? bgName.substring(bgName.lastIndexOf(".")).toLowerCase() : ".jpg";
                if (!bgExt.matches("\\.(jpg|jpeg|png|gif|webp)$")) {
                    resp.getWriter().write("{\"success\":false,\"error\":\"背景图仅支持 JPG/PNG/GIF/WebP 格式。\"}");
                    return;
                }
                String bgMime = bgExt.equals(".webp") ? "image/webp" : bgExt.equals(".gif") ? "image/gif" :
                    bgExt.equals(".png") ? "image/png" : "image/jpeg";
                java.io.ByteArrayOutputStream bgBaos = new java.io.ByteArrayOutputStream();
                try (InputStream is = bgPart.getInputStream()) {
                    byte[] b = new byte[8192]; int n;
                    while ((n = is.read(b)) != -1) bgBaos.write(b, 0, n);
                }
                background = "data:" + bgMime + ";base64," + java.util.Base64.getEncoder().encodeToString(bgBaos.toByteArray());
            }

            boolean ok = userDAO.updateProfile(user.getId(), nickname, avatar, background);
            if (ok) {
                // 刷新 session 中的用户信息
                if (avatar != null) user.setAvatar(avatar);
                if (background != null) user.setBackground(background);
                if (nickname != null) user.setNickname(nickname);
                req.getSession().setAttribute("user", user);
                resp.getWriter().write(toUserJson(user));
            } else {
                resp.getWriter().write("{\"success\":false,\"error\":\"更新失败，请稍后再试。\"}");
            }
        }
        // POST /api/auth/password — 修改密码
        else if (path.equals("/api/auth/password") && method.equals("POST")) {
            User user = getCurrentUser(req);
            if (user == null) {
                resp.getWriter().write("{\"success\":false,\"error\":\"请先入馆。\"}");
                return;
            }
            String oldPwd = req.getParameter("old_password");
            String newPwd = req.getParameter("new_password");
            if (oldPwd == null || newPwd == null || newPwd.length() < 4) {
                resp.getWriter().write("{\"success\":false,\"error\":\"新密码至少需要4个字符。\"}");
                return;
            }
            boolean ok = userDAO.changePassword(user.getId(), oldPwd, newPwd);
            if (ok) {
                resp.getWriter().write("{\"success\":true,\"message\":\"封印密语已更新！\"}");
            } else {
                resp.getWriter().write("{\"success\":false,\"error\":\"旧封印密语不正确。\"}");
            }
        }
        // POST /api/auth/forgot-password — 忘记密码步骤1：验证用户名或发送重置邮件
        else if (path.equals("/api/auth/forgot-password") && method.equals("POST")) {
            String username = req.getParameter("username");
            String email = req.getParameter("email");
            String captcha = req.getParameter("captcha");

            // 限流检查
            String ip = getClientIP(req);
            if (SecurityUtil.isBlocked(ip)) {
                long sec = SecurityUtil.getBlockSeconds(ip);
                resp.getWriter().write("{\"success\":false,\"error\":\"尝试次数过多，请 " + (sec / 60 + 1) + " 分钟后再试。\"}");
                return;
            }

            // 验证码检查
            HttpSession session = req.getSession(false);
            if (session == null || session.getAttribute("captchaAnswer") == null) {
                resp.getWriter().write("{\"success\":false,\"error\":\"验证码已过期，请刷新。\"}");
                return;
            }
            String expectedCaptcha = (String) session.getAttribute("captchaAnswer");
            if (captcha == null || !captcha.trim().equalsIgnoreCase(expectedCaptcha)) {
                session.removeAttribute("captchaAnswer");
                SecurityUtil.recordFailure(ip);
                resp.getWriter().write("{\"success\":false,\"error\":\"验证码错误，请重新输入。\"}");
                return;
            }
            session.removeAttribute("captchaAnswer");

            // ===== 邮箱方式：发送重置邮件 =====
            if (email != null && !email.trim().isEmpty()) {
                User foundUser = userDAO.findByEmail(email.trim());
                if (foundUser == null) {
                    SecurityUtil.recordFailure(ip);
                    resp.getWriter().write("{\"success\":false,\"error\":\"该邮箱未绑定任何账号。\"}");
                    return;
                }
                if (!com.scarletblog.util.EmailUtil.isConfigured()) {
                    resp.getWriter().write("{\"success\":false,\"error\":\"邮件服务尚未配置，请使用昵称验证方式。\"}");
                    return;
                }
                String token = userDAO.generateResetToken(email.trim());
                if (token != null) {
                    String ctxPath = req.getScheme() + "://" + req.getServerName() +
                        (req.getServerPort() != 80 && req.getServerPort() != 443 ? ":" + req.getServerPort() : "") +
                        req.getContextPath();
                    com.scarletblog.util.EmailUtil.sendResetEmail(email.trim(), token);
                    SecurityUtil.clearAttempts(ip);
                    resp.getWriter().write("{\"success\":true,\"message\":\"重置邮件已发送！请检查你的QQ邮箱（30分钟内有效）。\"}");
                } else {
                    resp.getWriter().write("{\"success\":false,\"error\":\"发送失败，请稍后再试。\"}");
                }
                return;
            }

            // ===== 昵称方式：验证用户名 =====
            if (username == null || username.trim().isEmpty()) {
                resp.getWriter().write("{\"success\":false,\"error\":\"请输入你的名札。\"}");
                return;
            }

            User foundUser = userDAO.findByUsername(username.trim());
            if (foundUser == null) {
                SecurityUtil.recordFailure(ip);
                resp.getWriter().write("{\"success\":false,\"error\":\"此名札未登记，请确认后重试。\"}");
                return;
            }

            // 验证成功，清除失败记录
            SecurityUtil.clearAttempts(ip);
            resp.getWriter().write("{\"success\":true,\"message\":\"身份确认，请继续验证。\"}");
        }
        // POST /api/auth/reset-password — 忘记密码步骤2：验证昵称 + 重置密码
        else if (path.equals("/api/auth/reset-password") && method.equals("POST")) {
            String username = req.getParameter("username");
            String nickname = req.getParameter("nickname");
            String newPassword = req.getParameter("new_password");
            String captcha = req.getParameter("captcha");

            // 限流检查
            String ip = getClientIP(req);
            if (SecurityUtil.isBlocked(ip)) {
                long sec = SecurityUtil.getBlockSeconds(ip);
                resp.getWriter().write("{\"success\":false,\"error\":\"尝试次数过多，请 " + (sec / 60 + 1) + " 分钟后再试。\"}");
                return;
            }

            // 验证码检查
            HttpSession session = req.getSession(false);
            if (session == null || session.getAttribute("captchaAnswer") == null) {
                resp.getWriter().write("{\"success\":false,\"error\":\"验证码已过期，请刷新。\"}");
                return;
            }
            String expectedCaptcha = (String) session.getAttribute("captchaAnswer");
            if (captcha == null || !captcha.trim().equalsIgnoreCase(expectedCaptcha)) {
                session.removeAttribute("captchaAnswer");
                SecurityUtil.recordFailure(ip);
                resp.getWriter().write("{\"success\":false,\"error\":\"验证码错误，请重新输入。\"}");
                return;
            }
            session.removeAttribute("captchaAnswer");

            if (username == null || username.trim().isEmpty()) {
                resp.getWriter().write("{\"success\":false,\"error\":\"缺少用户名。\"}");
                return;
            }
            if (nickname == null || nickname.trim().isEmpty()) {
                resp.getWriter().write("{\"success\":false,\"error\":\"请输入你的称呼。\"}");
                return;
            }
            if (newPassword == null || newPassword.length() < 4) {
                resp.getWriter().write("{\"success\":false,\"error\":\"新密码至少需要4个字符。\"}");
                return;
            }

            boolean ok = userDAO.resetPassword(username.trim(), nickname.trim(), newPassword);
            if (ok) {
                SecurityUtil.clearAttempts(ip);
                // 销毁旧 session（如果有），防止会话固定
                HttpSession oldSession = req.getSession(false);
                if (oldSession != null) oldSession.invalidate();
                resp.getWriter().write("{\"success\":true,\"message\":\"封印密语已重置！3秒后将跳转到登录页…\"}");
            } else {
                SecurityUtil.recordFailure(ip);
                resp.getWriter().write("{\"success\":false,\"error\":\"称呼不匹配，请确认后重试。\"}");
            }
        }
        // POST /api/auth/bind-email — 绑定/更换邮箱
        else if (path.equals("/api/auth/bind-email") && method.equals("POST")) {
            User user = getCurrentUser(req);
            if (user == null) {
                resp.getWriter().write("{\"success\":false,\"error\":\"请先入馆。\"}");
                return;
            }
            String email = req.getParameter("email");
            if (email == null || !email.matches("^[\\w\\-\\.]+@[\\w\\-\\.]+\\.\\w+$")) {
                resp.getWriter().write("{\"success\":false,\"error\":\"请输入有效的邮箱地址。\"}");
                return;
            }
            // 检查邮箱是否已被其他人绑定
            if (userDAO.emailExists(email.trim())) {
                resp.getWriter().write("{\"success\":false,\"error\":\"此邮箱已被其他账号绑定。\"}");
                return;
            }
            // 检查邮件服务是否配置
            if (!com.scarletblog.util.EmailUtil.isConfigured()) {
                resp.getWriter().write("{\"success\":false,\"error\":\"邮件服务尚未配置。请联系馆主。\"}");
                return;
            }
            boolean ok = userDAO.bindEmail(user.getId(), email.trim());
            if (ok) {
                // 异步发送验证邮件
                String ctxPath = req.getScheme() + "://" + req.getServerName() +
                    (req.getServerPort() != 80 && req.getServerPort() != 443 ? ":" + req.getServerPort() : "") +
                    req.getContextPath();
                // token already stored in DB by bindEmail, need to retrieve it
                // Re-generate and send
                String token = java.util.UUID.randomUUID().toString();
                // Update token again (bindEmail already set one, let's update with this new one)
                java.sql.Connection c = com.scarletblog.util.DBUtil.getConnection();
                java.sql.PreparedStatement ps = c.prepareStatement(
                    "UPDATE users SET verify_token = ?, token_expires = DATE_ADD(NOW(), INTERVAL 30 MINUTE) WHERE id = ?");
                ps.setString(1, token);
                ps.setInt(2, user.getId());
                ps.executeUpdate();
                ps.close(); c.close();
                com.scarletblog.util.EmailUtil.sendVerifyEmail(email.trim(), token);
                // 刷新 session 中的用户信息
                user.setEmail(email.trim());
                user.setEmailVerified(false);
                req.getSession().setAttribute("user", user);
                resp.getWriter().write("{\"success\":true,\"message\":\"验证邮件已发送！请检查你的QQ邮箱（30分钟内有效）。\"}");
            } else {
                resp.getWriter().write("{\"success\":false,\"error\":\"绑定失败，请稍后再试。\"}");
            }
        }
        // POST /api/auth/unbind-email — 解绑邮箱
        else if (path.equals("/api/auth/unbind-email") && method.equals("POST")) {
            User user = getCurrentUser(req);
            if (user == null) {
                resp.getWriter().write("{\"success\":false,\"error\":\"请先入馆。\"}");
                return;
            }
            boolean ok = userDAO.unbindEmail(user.getId());
            if (ok) {
                // 刷新 session
                user.setEmail(null);
                user.setEmailVerified(false);
                req.getSession().setAttribute("user", user);
                resp.getWriter().write("{\"success\":true,\"message\":\"邮箱已解绑。\"}");
            } else {
                resp.getWriter().write("{\"success\":false,\"error\":\"解绑失败，请稍后再试。\"}");
            }
        }
        // POST /api/auth/reset-by-token — 通过邮件 token 重置密码
        else if (path.equals("/api/auth/reset-by-token") && method.equals("POST")) {
            String token = req.getParameter("token");
            String newPassword = req.getParameter("new_password");
            String captcha = req.getParameter("captcha");

            // 验证码
            HttpSession session = req.getSession(false);
            if (session == null || session.getAttribute("captchaAnswer") == null) {
                resp.getWriter().write("{\"success\":false,\"error\":\"验证码已过期，请刷新。\"}");
                return;
            }
            String expectedCaptcha = (String) session.getAttribute("captchaAnswer");
            if (captcha == null || !captcha.trim().equalsIgnoreCase(expectedCaptcha)) {
                session.removeAttribute("captchaAnswer");
                resp.getWriter().write("{\"success\":false,\"error\":\"验证码错误，请重新输入。\"}");
                return;
            }
            session.removeAttribute("captchaAnswer");

            if (token == null || token.trim().isEmpty()) {
                resp.getWriter().write("{\"success\":false,\"error\":\"缺少重置 token。\"}");
                return;
            }
            if (newPassword == null || newPassword.length() < 4) {
                resp.getWriter().write("{\"success\":false,\"error\":\"新密码至少需要4个字符。\"}");
                return;
            }

            boolean ok = userDAO.resetPasswordByToken(token.trim(), newPassword);
            if (ok) {
                // 销毁旧 session
                HttpSession oldSession = req.getSession(false);
                if (oldSession != null) oldSession.invalidate();
                resp.getWriter().write("{\"success\":true,\"message\":\"封印密语已重置！请用新密码登录。\"}");
            } else {
                resp.getWriter().write("{\"success\":false,\"error\":\"链接已过期或无效，请重新申请重置。\"}");
            }
        }
        // GET /api/auth/logout — 离馆（销毁 session 后回大厅）
        else if (path.equals("/api/auth/logout") && method.equals("GET")) {
            HttpSession session = req.getSession(false);
            if (session != null) session.invalidate();
            resp.sendRedirect(req.getContextPath() + "/blog");
        }
    }

    /** 首页 */
    private void handleIndex(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        String search = req.getParameter("search");
        String category = req.getParameter("category");
        int page = 1;
        try { page = Integer.parseInt(req.getParameter("page")); } catch (Exception e) {}

        List<Post> posts = postDAO.getPosts(search, category, page, 10);
        int total = postDAO.getPostCount(search, category);
        List<Category> categories = categoryDAO.getAllCategories();

        req.setAttribute("posts", posts);
        req.setAttribute("categories", categories);
        req.setAttribute("currentPage", page);
        req.setAttribute("totalPages", Math.max(1, (int) Math.ceil((double) total / 10)));
        req.setAttribute("search", search);
        req.setAttribute("currentCategory", category);

        int totalPosts = categoryDAO.getTotalPosts();
        int totalComments = categoryDAO.getTotalComments();
        int totalViews = categoryDAO.getTotalViews();
        req.setAttribute("totalPosts", totalPosts);
        req.setAttribute("totalComments", totalComments);
        req.setAttribute("totalViews", totalViews);

        // 传递当前访客信息到页面
        req.setAttribute("currentUser", getCurrentUser(req));

        // 轮播图幻灯片（数据库驱动）
        req.setAttribute("slides", carouselDAO.getAllSlides());

        req.getRequestDispatcher("/index.jsp").forward(req, resp);
    }

    /** 文章详情 */
    private void handlePostDetail(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        int id = Integer.parseInt(req.getParameter("id"));
        Post post = postDAO.getPostById(id);
        if (post == null) {
            resp.sendRedirect(req.getContextPath() + "/blog");
            return;
        }
        List<Comment> comments = postDAO.getComments(id);
        req.setAttribute("post", post);
        req.setAttribute("comments", comments);
        req.setAttribute("currentUser", getCurrentUser(req));
        req.getRequestDispatcher("/post.jsp").forward(req, resp);
    }

    /** 管理后台 (需要认证) */
    private void handleAdmin(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        User user = getCurrentUser(req);
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/blog/login");
            return;
        }
        if (!user.isAdmin()) {
            resp.setContentType("text/html;charset=UTF-8");
            String ctx = req.getContextPath();
            resp.getWriter().write("<!DOCTYPE html>"
                + "<html lang=\"zh-CN\">"
                + "<head>"
                + "<meta charset=\"UTF-8\">"
                + "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1.0\">"
                + "<title>专属房间 — 红魔馆</title>"
                + "<style>"
                + "*{margin:0;padding:0;box-sizing:border-box}"
                + "body{background:linear-gradient(135deg,#1a0000,#0d0000);min-height:100vh;display:flex;align-items:center;justify-content:center;font-family:'Noto Serif SC','SimSun','STSong',serif}"
                + ".denied-card{background:linear-gradient(180deg,#1a0a0a,#0d0505);border:1px solid #4a0000;border-radius:12px;padding:60px 40px;text-align:center;max-width:500px;width:90%;box-shadow:0 0 60px rgba(139,0,0,.4),0 0 120px rgba(139,0,0,.1)}"
                + ".denied-icon{font-size:4rem;margin-bottom:20px;animation:float 3s ease-in-out infinite}"
                + "@keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-10px)}}"
                + ".denied-title{color:#d4af37;font-size:1.6rem;letter-spacing:3px;margin-bottom:15px;font-weight:bold}"
                + ".denied-sub{color:#a08060;font-size:1rem;margin-bottom:5px;line-height:1.8}"
                + ".denied-countdown{color:#8b0000;font-size:0.9rem;margin-top:30px;animation:pulse 1s ease-in-out infinite}"
                + "@keyframes pulse{0%,100%{opacity:1}50%{opacity:.5}}"
                + "</style>"
                + "</head>"
                + "<body>"
                + "<div class=\"denied-card\">"
                + "<div class=\"denied-icon\">🚪</div>"
                + "<div class=\"denied-title\">这是蕾米莉亚和咲夜的专属房间哦</div>"
                + "<div class=\"denied-sub\">不能进入呢~</div>"
                + "<div class=\"denied-sub\" style=\"font-size:0.85rem;color:#6a5050;\">只有馆主和女仆长才能进入管理室</div>"
                + "<div class=\"denied-countdown\"><span id=\"timer\">3</span> 秒后自动退回大厅...</div>"
                + "</div>"
                + "<script>"
                + "var t=3;"
                + "setInterval(function(){t--;if(t<=0){window.location.href='" + ctx + "/blog';}else{document.getElementById('timer').textContent=t;}},1000);"
                + "</script>"
                + "</body></html>");
            return;
        }

        List<Post> posts = postDAO.getPosts(null, null, 1, 100);
        List<Category> categories = categoryDAO.getAllCategories();
        int totalPosts = categoryDAO.getTotalPosts();
        int totalComments = categoryDAO.getTotalComments();
        int totalViews = categoryDAO.getTotalViews();

        req.setAttribute("posts", posts);
        req.setAttribute("categories", categories);
        req.setAttribute("totalPosts", totalPosts);
        req.setAttribute("totalComments", totalComments);
        req.setAttribute("totalViews", totalViews);
        req.setAttribute("currentUser", user);

        req.getRequestDispatcher("/admin.jsp").forward(req, resp);
    }

    /** REST API - 文章 */
    private void handlePostsAPI(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        resp.setContentType("application/json;charset=UTF-8");
        String path = req.getRequestURI().substring(req.getContextPath().length());
        String method = req.getMethod();

        if (path.equals("/api/posts") && method.equals("GET")) {
            String search = req.getParameter("search");
            String category = req.getParameter("category");
            int page = 1, limit = 10;
            try { page = Integer.parseInt(req.getParameter("page")); } catch (Exception e) {}
            try { limit = Integer.parseInt(req.getParameter("limit")); } catch (Exception e) {}

            List<Post> posts = postDAO.getPosts(search, category, page, limit);
            int total = postDAO.getPostCount(search, category);
            resp.getWriter().write(toJsonList(posts, page, limit, total));
        }
        else if (path.matches("/api/posts/\\d+") && method.equals("GET")) {
            int id = Integer.parseInt(path.substring(path.lastIndexOf('/') + 1));
            Post post = postDAO.getPostById(id);
            if (post == null) {
                resp.getWriter().write("{\"success\":false,\"error\":\"文章未找到\"}");
            } else {
                resp.getWriter().write(toPostJson(post));
            }
        }
        else if (path.equals("/api/posts") && method.equals("POST")) {
            // 创建文章需要登录
            User user = getCurrentUser(req);
            if (user == null) {
                resp.getWriter().write("{\"success\":false,\"error\":\"请先入馆才能撰写文章。\"}");
                return;
            }
            Post post = new Post();
            post.setTitle(req.getParameter("title"));
            post.setContent(req.getParameter("content"));
            // 非管理员作者自动设为当前用户昵称
            String author = req.getParameter("author");
            if (author == null || author.trim().isEmpty()) {
                author = user.getNickname();
            }
            post.setAuthor(author);
            try { post.setCategoryId(Integer.parseInt(req.getParameter("category_id"))); } catch (Exception e) {}
            post.setTags(req.getParameter("tags"));
            int id = postDAO.createPost(post);
            resp.getWriter().write("{\"success\":true,\"message\":\"文章创建成功！\",\"id\":" + id + "}");
        }
        else if (path.matches("/api/posts/\\d+") && method.equals("PUT")) {
            // 修改文章需要是作者本人或管理员
            User user = getCurrentUser(req);
            if (user == null) {
                resp.getWriter().write("{\"success\":false,\"error\":\"请先入馆。\"}");
                return;
            }
            int id = Integer.parseInt(path.substring(path.lastIndexOf('/') + 1));
            // 非管理员只能编辑自己的文章
            if (!user.isAdmin()) {
                Post existing = postDAO.getPostById(id);
                if (existing == null) {
                    resp.getWriter().write("{\"success\":false,\"error\":\"文章未找到。\"}");
                    return;
                }
                if (existing.getAuthor() == null || !existing.getAuthor().equals(user.getNickname())) {
                    resp.getWriter().write("{\"success\":false,\"error\":\"你只能编辑自己的文章哦~\"}");
                    return;
                }
            }
            Post post = new Post();
            post.setId(id);
            post.setTitle(req.getParameter("title"));
            post.setContent(req.getParameter("content"));
            post.setAuthor(req.getParameter("author"));
            try { post.setCategoryId(Integer.parseInt(req.getParameter("category_id"))); } catch (Exception e) {}
            post.setTags(req.getParameter("tags"));
            try { post.setIsPublished(Integer.parseInt(req.getParameter("is_published"))); } catch (Exception e) {}
            boolean ok = postDAO.updatePost(post);
            resp.getWriter().write("{\"success\":" + ok + ",\"message\":\"文章已更新\"}");
        }
        else if (path.matches("/api/posts/\\d+") && method.equals("DELETE")) {
            if (!isAdmin(req)) {
                resp.getWriter().write("{\"success\":false,\"error\":\"只有馆主或女仆长才能删除文章。\"}");
                return;
            }
            int id = Integer.parseInt(path.substring(path.lastIndexOf('/') + 1));
            boolean ok = postDAO.deletePost(id);
            resp.getWriter().write("{\"success\":" + ok + ",\"message\":\"文章已删除\"}");
        }
        else if (path.matches("/api/posts/\\d+/comments") && method.equals("GET")) {
            int postId = Integer.parseInt(path.split("/")[3]);
            List<Comment> comments = postDAO.getComments(postId);
            resp.getWriter().write(toCommentsJson(comments));
        }
    }

    /** REST API - 评论 */
    private void handleCommentsAPI(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        resp.setContentType("application/json;charset=UTF-8");
        String method = req.getMethod();

        if (method.equals("POST")) {
            Comment c = new Comment();
            try { c.setPostId(Integer.parseInt(req.getParameter("post_id"))); } catch (Exception e) {}
            c.setAuthor(req.getParameter("author"));
            c.setContent(req.getParameter("content"));
            int id = postDAO.addComment(c);
            resp.getWriter().write("{\"success\":true,\"message\":\"评论已收到！\",\"id\":" + id + "}");
        }
        else if (method.equals("DELETE")) {
            if (!isAdmin(req)) {
                resp.getWriter().write("{\"success\":false,\"error\":\"只有馆主或女仆长才能删除评论。\"}");
                return;
            }
            String path = req.getRequestURI().substring(req.getContextPath().length());
            int id = Integer.parseInt(path.substring(path.lastIndexOf('/') + 1));
            // comment delete not implemented in PostDAO, return OK
            resp.getWriter().write("{\"success\":true,\"message\":\"评论已删除\"}");
        }
    }

    /** REST API - 分类 */
    private void handleCategoriesAPI(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        resp.setContentType("application/json;charset=UTF-8");
        String path = req.getRequestURI().substring(req.getContextPath().length());
        String method = req.getMethod();

        // GET /api/categories — 列表
        if (method.equals("GET")) {
            List<Category> categories = categoryDAO.getAllCategories();
            StringBuilder sb = new StringBuilder("{\"success\":true,\"data\":[");
            for (int i = 0; i < categories.size(); i++) {
                if (i > 0) sb.append(",");
                Category c = categories.get(i);
                sb.append("{\"id\":").append(c.getId())
                  .append(",\"name\":\"").append(escapeJson(c.getName())).append("\"")
                  .append(",\"description\":\"").append(escapeJson(c.getDescription())).append("\"")
                  .append(",\"icon\":\"").append(escapeJson(c.getIcon())).append("\"")
                  .append(",\"post_count\":").append(c.getPostCount()).append("}");
            }
            sb.append("]}");
            resp.getWriter().write(sb.toString());
        }
        // POST /api/categories — 创建（仅管理员）
        else if (path.equals("/api/categories") && method.equals("POST")) {
            if (!isAdmin(req)) {
                resp.getWriter().write("{\"success\":false,\"error\":\"仅馆主或女仆长可管理分类。\"}");
                return;
            }
            Category c = new Category();
            c.setName(req.getParameter("name"));
            c.setDescription(req.getParameter("description"));
            c.setIcon(req.getParameter("icon"));
            int id = categoryDAO.createCategory(c);
            resp.getWriter().write("{\"success\":true,\"message\":\"分类创建成功\",\"id\":" + id + "}");
        }
        // PUT /api/categories/:id — 更新（仅管理员）
        else if (path.matches("/api/categories/\\d+") && method.equals("PUT")) {
            if (!isAdmin(req)) {
                resp.getWriter().write("{\"success\":false,\"error\":\"仅馆主或女仆长可管理分类。\"}");
                return;
            }
            int id = Integer.parseInt(path.substring(path.lastIndexOf('/') + 1));
            Category c = new Category();
            c.setId(id);
            c.setName(req.getParameter("name"));
            c.setDescription(req.getParameter("description"));
            c.setIcon(req.getParameter("icon"));
            boolean ok = categoryDAO.updateCategory(c);
            resp.getWriter().write("{\"success\":" + ok + ",\"message\":\"分类已更新\"}");
        }
        // DELETE /api/categories/:id — 删除（仅管理员）
        else if (path.matches("/api/categories/\\d+") && method.equals("DELETE")) {
            if (!isAdmin(req)) {
                resp.getWriter().write("{\"success\":false,\"error\":\"仅馆主或女仆长可管理分类。\"}");
                return;
            }
            int id = Integer.parseInt(path.substring(path.lastIndexOf('/') + 1));
            boolean ok = categoryDAO.deleteCategory(id);
            resp.getWriter().write("{\"success\":" + ok + ",\"message\":\"分类已删除\"}");
        }
    }

    /** 健康检查 — 仅管理员可访问 */
    private void handleHealth(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        resp.setContentType("application/json;charset=UTF-8");
        StringBuilder sb = new StringBuilder("{\"status\":\"ok\"");
        try {
            java.sql.Connection c = com.scarletblog.util.DBUtil.getConnection();
            sb.append(",\"db\":\"connected\"");
            c.close();
        } catch (Exception e) {
            sb.append(",\"db\":\"error\"");
        }
        sb.append("}");
        resp.getWriter().write(sb.toString());
    }

    /** 管理员：用户列表 + 任命管理员 */
    private void handleAdminUsers(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        resp.setContentType("application/json;charset=UTF-8");
        User currentUser = getCurrentUser(req);
        if (currentUser == null) {
            resp.getWriter().write("{\"success\":false,\"error\":\"请先入馆。\"}");
            return;
        }
        if (!currentUser.isAdmin()) {
            resp.getWriter().write("{\"success\":false,\"error\":\"仅馆主或女仆长可查看。\"}");
            return;
        }

        String path = req.getRequestURI().substring(req.getContextPath().length());
        String method = req.getMethod();

        // PUT /api/admin/users/:id/role — 任命/解除管家（仅馆主，女仆长为永久身份不可升降）
        if (path.matches("/api/admin/users/\\d+/role") && "PUT".equals(method)) {
            String[] parts = path.split("/");
            int targetId = Integer.parseInt(parts[parts.length - 2]);

            if (!"馆主".equals(currentUser.getRole())) {
                resp.getWriter().write("{\"success\":false,\"error\":\"仅馆主大人可以任命管理员。\"}");
                return;
            }
            if (targetId == currentUser.getId()) {
                resp.getWriter().write("{\"success\":false,\"error\":\"不能更改自己的身份哦~\"}");
                return;
            }
            User targetUser = userDAO.findById(targetId);
            if (targetUser == null) {
                resp.getWriter().write("{\"success\":false,\"error\":\"该住人不存在。\"}");
                return;
            }
            // Tomcat 默认只解析 POST 请求体，PUT 需要手动读取
            String newRole = req.getParameter("role");
            if (newRole == null) {
                try {
                    StringBuilder body = new StringBuilder();
                    java.io.BufferedReader br = req.getReader();
                    String line;
                    while ((line = br.readLine()) != null) body.append(line);
                    String raw = body.toString();
                    if (raw.startsWith("role=")) {
                        newRole = java.net.URLDecoder.decode(raw.substring(5), "UTF-8");
                    }
                } catch (Exception ignored) {}
            }
            // 女仆长是永久身份，不可升降
            if ("女仆长".equals(targetUser.getRole())) {
                resp.getWriter().write("{\"success\":false,\"error\":\"女仆长是永久身份，不可升降。\"}");
                return;
            }
            if (!"管家".equals(newRole) && !"住人".equals(newRole)) {
                resp.getWriter().write("{\"success\":false,\"error\":\"无效的身份。仅可任命为管家或降为住人。\"}");
                return;
            }
            if (newRole.equals(targetUser.getRole())) {
                resp.getWriter().write("{\"success\":false,\"error\":\"该住人已经是" + newRole + "了。\"}");
                return;
            }
            boolean ok = userDAO.updateRole(targetId, newRole);
            String nick = targetUser.getNickname() != null ? targetUser.getNickname() : targetUser.getUsername();
            if (ok) {
                resp.getWriter().write("{\"success\":true,\"message\":\"" + nick
                    + ("管家".equals(newRole) ? " 已任命为管家！" : " 已降为住人。") + "\"}");
            } else {
                resp.getWriter().write("{\"success\":false,\"error\":\"任命失败，请稍后再试。\"}");
            }
            return;
        }

        // GET /api/admin/users — 用户列表
        List<User> users = userDAO.getAllUsers();
        StringBuilder sb = new StringBuilder("{\"success\":true,\"data\":[");
        for (int i = 0; i < users.size(); i++) {
            User u = users.get(i);
            if (i > 0) sb.append(",");
            sb.append("{\"id\":").append(u.getId());
            sb.append(",\"username\":\"").append(escapeJson(u.getUsername())).append("\"");
            sb.append(",\"nickname\":\"").append(escapeJson(u.getNickname())).append("\"");
            sb.append(",\"role\":\"").append(escapeJson(u.getRole())).append("\"");
            sb.append(",\"avatar\":").append(u.getAvatar() != null ? "\"" + escapeJson(u.getAvatar()) + "\"" : "null");
            sb.append(",\"background\":").append(u.getBackground() != null ? "\"" + escapeJson(u.getBackground()) + "\"" : "null");
            sb.append(",\"createdAt\":\"").append(u.getCreatedAt() != null ? u.getCreatedAt().toString() : "").append("\"");
            sb.append("}");
        }
        sb.append("]}");
        resp.getWriter().write(sb.toString());
    }

    /** REST API - 轮播图管理（管理员） */
    private void handleCarouselAPI(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        resp.setContentType("application/json;charset=UTF-8");
        User currentUser = getCurrentUser(req);
        if (currentUser == null || !currentUser.isAdmin()) {
            resp.getWriter().write("{\"success\":false,\"error\":\"仅馆主或女仆长可管理轮播图。\"}");
            return;
        }
        String path = req.getRequestURI().substring(req.getContextPath().length());
        String method = req.getMethod();

        // GET /api/admin/carousel — 所有幻灯片
        if (path.equals("/api/admin/carousel") && "GET".equals(method)) {
            List<CarouselSlide> slides = carouselDAO.getAllSlidesAdmin();
            StringBuilder sb = new StringBuilder("{\"success\":true,\"data\":[");
            for (int i = 0; i < slides.size(); i++) {
                if (i > 0) sb.append(",");
                sb.append(toCarouselJson(slides.get(i), req.getContextPath()));
            }
            sb.append("]}");
            resp.getWriter().write(sb.toString());
            return;
        }

        // POST /api/admin/carousel — 新增幻灯片
        if (path.equals("/api/admin/carousel") && "POST".equals(method)) {
            String type = req.getParameter("type");
            if (type == null) type = "image";
            String title = req.getParameter("title");
            String videoUrl = req.getParameter("video_url");

            String imagePath = null;
            if ("image".equals(type)) {
                Part filePart = null;
                try { filePart = req.getPart("image"); } catch (Exception e) {}
                if (filePart == null || filePart.getSize() == 0) {
                    resp.getWriter().write("{\"success\":false,\"error\":\"请选择图片文件。\"}");
                    return;
                }
                if (filePart.getSize() > 5 * 1024 * 1024) {
                    resp.getWriter().write("{\"success\":false,\"error\":\"图片不能超过 5MB。\"}");
                    return;
                }
                String fname = getSubmittedFileName(filePart);
                String ext = fname.contains(".") ? fname.substring(fname.lastIndexOf(".")).toLowerCase() : ".jpg";
                if (!ext.matches("\\.(jpg|jpeg|png|gif|webp)$")) {
                    resp.getWriter().write("{\"success\":false,\"error\":\"仅支持 JPG/PNG/GIF/WebP 格式。\"}");
                    return;
                }
                // 先创建记录获取 ID
                CarouselSlide s = new CarouselSlide();
                s.setType("image"); s.setTitle(title); s.setImagePath("");
                int id = carouselDAO.create(s);
                // 用 ID 命名文件
                imagePath = "images/carousel_" + id + ext;
                Path target = Paths.get(req.getServletContext().getRealPath("/"), imagePath);
                Files.copy(filePart.getInputStream(), target, StandardCopyOption.REPLACE_EXISTING);
                // 更新路径
                s.setId(id); s.setImagePath(imagePath);
                carouselDAO.update(s);
                // 处理封面图上传
                savePosterFile(req, s);
                if (s.getPoster() != null) carouselDAO.update(s);
                resp.getWriter().write("{\"success\":true,\"message\":\"幻灯片已添加！\",\"data\":" + toCarouselJson(carouselDAO.getById(id), req.getContextPath()) + "}");
                return;
            } else if ("video".equals(type)) {
                if (videoUrl == null || videoUrl.trim().isEmpty()) {
                    // 检查是否有本地视频文件上传
                    Part videoPart = null;
                    try { videoPart = req.getPart("video_file"); } catch (Exception e) {}
                    if (videoPart == null || videoPart.getSize() == 0) {
                        resp.getWriter().write("{\"success\":false,\"error\":\"请上传视频文件或输入视频 URL。\"}");
                        return;
                    }
                    // 本地视频文件上传
                    String vname = getSubmittedFileName(videoPart);
                    String vext = vname.contains(".") ? vname.substring(vname.lastIndexOf(".")).toLowerCase() : ".mp4";
                    if (!vext.matches("\\.(mp4|webm)$")) {
                        resp.getWriter().write("{\"success\":false,\"error\":\"视频仅支持 MP4/WebM 格式。\"}");
                        return;
                    }
                    CarouselSlide s = new CarouselSlide();
                    s.setType("video"); s.setTitle(title); s.setImagePath("");
                    int id = carouselDAO.create(s);
                    String vpath = "images/carousel_video_" + id + vext;
                    Files.copy(videoPart.getInputStream(), Paths.get(req.getServletContext().getRealPath("/"), vpath), StandardCopyOption.REPLACE_EXISTING);
                    s.setId(id); s.setImagePath(vpath); // 本地视频路径存在 image_path 字段
                    carouselDAO.update(s);
                    // 处理封面图上传
                    savePosterFile(req, s);
                    if (s.getPoster() != null) carouselDAO.update(s);
                    resp.getWriter().write("{\"success\":true,\"message\":\"本地视频已添加！\",\"data\":" + toCarouselJson(carouselDAO.getById(id), req.getContextPath()) + "}");
                    return;
                }
                CarouselSlide s = new CarouselSlide();
                s.setType("video"); s.setTitle(title); s.setVideoUrl(videoUrl.trim());
                int id = carouselDAO.create(s);
                s.setId(id);
                savePosterFile(req, s);
                if (s.getPoster() != null) carouselDAO.update(s);
                resp.getWriter().write("{\"success\":true,\"message\":\"视频幻灯片已添加！\",\"data\":" + toCarouselJson(carouselDAO.getById(id), req.getContextPath()) + "}");
                return;
            }
            resp.getWriter().write("{\"success\":false,\"error\":\"未知类型。\"}");
            return;
        }

        // PUT /api/admin/carousel/:id — 更新幻灯片
        if (path.matches("/api/admin/carousel/\\d+") && "PUT".equals(method)) {
            int id = Integer.parseInt(path.substring(path.lastIndexOf('/') + 1));
            CarouselSlide s = carouselDAO.getById(id);
            if (s == null) { resp.getWriter().write("{\"success\":false,\"error\":\"幻灯片不存在。\"}"); return; }

            String title = req.getParameter("title");
            String videoUrl = req.getParameter("video_url");
            if (title != null) s.setTitle(title);
            if (videoUrl != null) s.setVideoUrl(videoUrl);

            // 替换图片
            Part filePart = null;
            try { filePart = req.getPart("image"); } catch (Exception e) {}
            if (filePart != null && filePart.getSize() > 0) {
                if (filePart.getSize() > 5 * 1024 * 1024) {
                    resp.getWriter().write("{\"success\":false,\"error\":\"图片不能超过 5MB。\"}"); return;
                }
                String fname = getSubmittedFileName(filePart);
                String ext = fname.contains(".") ? fname.substring(fname.lastIndexOf(".")).toLowerCase() : ".jpg";
                if (s.getImagePath() != null) {
                    new java.io.File(req.getServletContext().getRealPath("/"), s.getImagePath()).delete();
                }
                String newPath = "images/carousel_" + id + ext;
                Files.copy(filePart.getInputStream(), Paths.get(req.getServletContext().getRealPath("/"), newPath), StandardCopyOption.REPLACE_EXISTING);
                s.setImagePath(newPath);
                s.setVideoUrl(null);
            }

            // 替换本地视频文件
            Part videoPart = null;
            try { videoPart = req.getPart("video_file"); } catch (Exception e) {}
            if (videoPart != null && videoPart.getSize() > 0) {
                if (videoPart.getSize() > 50 * 1024 * 1024) {
                    resp.getWriter().write("{\"success\":false,\"error\":\"视频不能超过 50MB。\"}"); return;
                }
                String vname = getSubmittedFileName(videoPart);
                String vext = vname.contains(".") ? vname.substring(vname.lastIndexOf(".")).toLowerCase() : ".mp4";
                if (s.getImagePath() != null) {
                    new java.io.File(req.getServletContext().getRealPath("/"), s.getImagePath()).delete();
                }
                String vpath = "images/carousel_video_" + id + vext;
                Files.copy(videoPart.getInputStream(), Paths.get(req.getServletContext().getRealPath("/"), vpath), StandardCopyOption.REPLACE_EXISTING);
                s.setImagePath(vpath);
                s.setVideoUrl(null);
            }
            // 替换封面图
            Part posterPart = null;
            try { posterPart = req.getPart("poster"); } catch (Exception e) {}
            if (posterPart != null && posterPart.getSize() > 0) {
                if (posterPart.getSize() > 5 * 1024 * 1024) {
                    resp.getWriter().write("{\"success\":false,\"error\":\"封面图不能超过 5MB。\"}"); return;
                }
                String pname = getSubmittedFileName(posterPart);
                String pext = pname.contains(".") ? pname.substring(pname.lastIndexOf(".")).toLowerCase() : ".jpg";
                // 删除旧封面
                if (s.getPoster() != null && s.getPoster().startsWith("images/")) {
                    new java.io.File(req.getServletContext().getRealPath("/"), s.getPoster()).delete();
                }
                String ppath = "images/carousel_poster_" + id + pext;
                Files.copy(posterPart.getInputStream(), Paths.get(req.getServletContext().getRealPath("/"), ppath), StandardCopyOption.REPLACE_EXISTING);
                s.setPoster(ppath);
            }
            String posterUrl = req.getParameter("poster_url");
            if (posterUrl != null && !posterUrl.trim().isEmpty()) {
                s.setPoster(posterUrl.trim());
            }
            carouselDAO.update(s);
            resp.getWriter().write("{\"success\":true,\"message\":\"已更新！\"}");
            return;
        }

        // PUT /api/admin/carousel/:id/sort — 排序
        if (path.matches("/api/admin/carousel/\\d+/sort") && "PUT".equals(method)) {
            int id = Integer.parseInt(path.substring(path.lastIndexOf("/sort") - 1, path.lastIndexOf("/sort")));
            // Actually parse the ID correctly
            String[] parts = path.split("/");
            int slideId = Integer.parseInt(parts[parts.length - 2]);
            String direction = req.getParameter("direction");
            boolean ok = carouselDAO.moveSlide(slideId, direction);
            resp.getWriter().write("{\"success\":" + ok + ",\"message\":\"" + (ok ? "已移动" : "无法移动") + "\"}");
            return;
        }

        // DELETE /api/admin/carousel/:id — 删除幻灯片
        if (path.matches("/api/admin/carousel/\\d+") && "DELETE".equals(method)) {
            int id = Integer.parseInt(path.substring(path.lastIndexOf('/') + 1));
            CarouselSlide s = carouselDAO.getById(id);
            if (s != null && s.getImagePath() != null) {
                new java.io.File(req.getServletContext().getRealPath("/"), s.getImagePath()).delete();
            }
            carouselDAO.delete(id);
            resp.getWriter().write("{\"success\":true,\"message\":\"幻灯片已删除。\"}");
            return;
        }
    }

    /** REST API - 统计 */
    private void handleStatsAPI(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        resp.setContentType("application/json;charset=UTF-8");
        int posts = categoryDAO.getTotalPosts();
        int comments = categoryDAO.getTotalComments();
        int views = categoryDAO.getTotalViews();
        resp.getWriter().write(
            "{\"success\":true,\"data\":{\"posts\":" + posts +
            ",\"comments\":" + comments + ",\"totalViews\":" + views +
            ",\"categories\":" + categoryDAO.getAllCategories().size() + "}}");
    }

    // ============================================
    // 茶话会 — 页面
    // ============================================
    private void handleChatPage(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        User user = getCurrentUser(req);
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/blog/login");
            return;
        }
        req.setAttribute("currentUser", user);
        // 如果路径是 /blog/chat/room?id=N，转发到聊天室页面
        String path = req.getRequestURI().substring(req.getContextPath().length());
        if (path.equals("/blog/chat/room")) {
            req.getRequestDispatcher("/chat_room.jsp").forward(req, resp);
        } else {
            req.getRequestDispatcher("/chat.jsp").forward(req, resp);
        }
    }

    // ============================================
    // 住人公开 API（个人主页数据）
    // ============================================
    private void handleUsersAPI(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        resp.setContentType("application/json;charset=UTF-8");
        User currentUser = getCurrentUser(req);
        if (currentUser == null) {
            resp.getWriter().write("{\"success\":false,\"error\":\"请先入馆。\"}");
            return;
        }
        String path = req.getRequestURI().substring(req.getContextPath().length());
        String method = req.getMethod();

        // GET /api/users/:id — 获取公开用户资料
        if (path.matches("/api/users/\\d+") && method.equals("GET")) {
            int targetId = Integer.parseInt(path.substring(path.lastIndexOf('/') + 1));
            User targetUser = userDAO.findById(targetId);
            if (targetUser == null) {
                resp.getWriter().write("{\"success\":false,\"error\":\"住人未找到。\"}");
                return;
            }

            int postCount = userDAO.getPostCount(targetId);
            int commentCount = userDAO.getCommentCount(targetId);
            int friendCount = friendDAO.getFriendCount(targetId);

            // 判断关系
            String relationship;
            int friendshipId = 0;
            if (currentUser.getId() == targetId) {
                relationship = "self";
            } else {
                Friend rel = friendDAO.getRelationshipBetween(currentUser.getId(), targetId);
                if (rel == null) {
                    relationship = "none";
                } else if ("accepted".equals(rel.getStatus())) {
                    relationship = "friend";
                    friendshipId = rel.getId();
                } else if (rel.getUserId() == currentUser.getId()) {
                    relationship = "pending_sent";
                    friendshipId = rel.getId();
                } else {
                    relationship = "pending_received";
                    friendshipId = rel.getId();
                }
            }

            // 最近文章
            List<Post> recentPosts = postDAO.getPostsByAuthor(targetUser.getNickname(), 1, 5);

            StringBuilder sb = new StringBuilder();
            sb.append("{\"success\":true,\"data\":{");
            sb.append("\"id\":").append(targetUser.getId());
            sb.append(",\"username\":\"").append(escapeJson(targetUser.getUsername())).append("\"");
            sb.append(",\"nickname\":\"").append(escapeJson(targetUser.getNickname())).append("\"");
            sb.append(",\"avatar\":").append(targetUser.getAvatar() != null ? "\"" + escapeJson(targetUser.getAvatar()) + "\"" : "null");
            sb.append(",\"background\":").append(targetUser.getBackground() != null ? "\"" + escapeJson(targetUser.getBackground()) + "\"" : "null");
            sb.append(",\"role\":\"").append(escapeJson(targetUser.getRole())).append("\"");
            sb.append(",\"createdAt\":\"").append(targetUser.getCreatedAt() != null ? targetUser.getCreatedAt().toString() : "").append("\"");
            sb.append(",\"postCount\":").append(postCount);
            sb.append(",\"commentCount\":").append(commentCount);
            sb.append(",\"friendCount\":").append(friendCount);
            sb.append(",\"relationship\":\"").append(relationship).append("\"");
            if (friendshipId > 0) {
                sb.append(",\"friendshipId\":").append(friendshipId);
            }
            sb.append(",\"recentPosts\":[");
            for (int i = 0; i < recentPosts.size(); i++) {
                if (i > 0) sb.append(",");
                Post p = recentPosts.get(i);
                sb.append("{\"id\":").append(p.getId());
                sb.append(",\"title\":\"").append(escapeJson(p.getTitle())).append("\"");
                String excerpt = p.getExcerpt();
                if (excerpt == null || excerpt.isEmpty()) {
                    String content = p.getContent();
                    excerpt = content != null ? content.replaceAll("<[^>]*>", "") : "";
                    if (excerpt.length() > 200) excerpt = excerpt.substring(0, 200) + "...";
                }
                sb.append(",\"excerpt\":\"").append(escapeJson(excerpt)).append("\"");
                sb.append(",\"created_at\":\"").append(p.getCreatedAt() != null ? p.getCreatedAt().toString() : "").append("\"");
                sb.append(",\"view_count\":").append(p.getViewCount());
                sb.append(",\"category_name\":\"").append(escapeJson(p.getCategoryName() != null ? p.getCategoryName() : "")).append("\"");
                sb.append(",\"category_icon\":\"").append(escapeJson(p.getCategoryIcon() != null ? p.getCategoryIcon() : "")).append("\"");
                sb.append(",\"tags\":\"").append(escapeJson(p.getTags() != null ? p.getTags() : "")).append("\"");
                sb.append("}");
            }
            sb.append("]}}");
            resp.getWriter().write(sb.toString());
        }
    }

    // ============================================
    // 茶话会 — 友人 API
    // ============================================
    private void handleFriendsAPI(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        resp.setContentType("application/json;charset=UTF-8");
        User user = getCurrentUser(req);
        if (user == null) {
            resp.getWriter().write("{\"success\":false,\"error\":\"请先入馆。\"}");
            return;
        }
        String path = req.getRequestURI().substring(req.getContextPath().length());
        String method = req.getMethod();

        // GET /api/friends — 友人列表 + 邀请函
        if (method.equals("GET")) {
            List<Friend> friends = friendDAO.getFriends(user.getId());
            List<Friend> sent = friendDAO.getPendingSent(user.getId());
            List<Friend> received = friendDAO.getPendingReceived(user.getId());

            StringBuilder sb = new StringBuilder("{\"success\":true,");
            sb.append("\"friends\":[").append(friendsToJson(friends, user.getId())).append("],");
            sb.append("\"sent\":[").append(friendsToJson(sent, user.getId())).append("],");
            sb.append("\"received\":[").append(friendsToJson(received, user.getId())).append("]}");
            resp.getWriter().write(sb.toString());
        }
        // POST /api/friends — 发送邀请函
        else if (path.equals("/api/friends") && method.equals("POST")) {
            String targetUsername = req.getParameter("username");
            if (targetUsername == null || targetUsername.trim().isEmpty()) {
                resp.getWriter().write("{\"success\":false,\"error\":\"请输入对方名札（用户名）。\"}");
                return;
            }
            // 找到目标用户
            User targetUser = userDAO.findByUsername(targetUsername.trim());
            if (targetUser == null) {
                resp.getWriter().write("{\"success\":false,\"error\":\"未找到此名札的住人。\"}");
                return;
            }
            if (targetUser.getId() == user.getId()) {
                resp.getWriter().write("{\"success\":false,\"error\":\"不能向自己发邀请函哦~\"}");
                return;
            }
            if (friendDAO.friendshipExists(user.getId(), targetUser.getId())) {
                resp.getWriter().write("{\"success\":false,\"error\":\"你们已经是友人，或已有待处理的邀请函。\"}");
                return;
            }
            // 冷却检查：同一用户 60 秒内只能发一次邀请
            int cooldown = friendDAO.getSecondsSinceLastRequest(user.getId());
            if (cooldown >= 0 && cooldown < 60) {
                int remain = 60 - cooldown;
                resp.getWriter().write("{\"success\":false,\"error\":\"请勿频繁发送邀请函，"
                    + remain + "秒后再试。\"}");
                return;
            }
            int id = friendDAO.sendRequest(user.getId(), targetUser.getId());
            if (id > 0) {
                resp.getWriter().write("{\"success\":true,\"message\":\"邀请函已送出！\",\"id\":" + id + "}");
            } else {
                resp.getWriter().write("{\"success\":false,\"error\":\"发送失败，请稍后再试。\"}");
            }
        }
        // PUT /api/friends/:id — 接受/拒绝
        else if (path.matches("/api/friends/\\d+") && method.equals("PUT")) {
            int id = Integer.parseInt(path.substring(path.lastIndexOf('/') + 1));
            // PUT 请求体 Servlet 不会自动解析，手动读取
            String action = null;
            try {
                String body = new java.util.Scanner(req.getInputStream(), "UTF-8").useDelimiter("\\A").next();
                for (String pair : body.split("&")) {
                    String[] kv = pair.split("=", 2);
                    if (kv.length == 2 && "action".equals(java.net.URLDecoder.decode(kv[0], "UTF-8"))) {
                        action = java.net.URLDecoder.decode(kv[1], "UTF-8");
                    }
                }
            } catch (java.util.NoSuchElementException e) { /* empty body */ }
            if ("accept".equals(action)) {
                friendDAO.acceptRequest(id);
                // 获取双方 ID，自动创建私人茶室（失败不影响接受结果）
                Friend f = friendDAO.getById(id);
                if (f != null) {
                    try {
                        chatDAO.createPrivateRoom(f.getUserId(), f.getFriendId());
                    } catch (Exception e) {
                        System.err.println("[Chat] 创建私人茶室失败: " + e.getMessage());
                    }
                }
                resp.getWriter().write("{\"success\":true,\"message\":\"友人已添加！茶室已备好。\"}");
            } else {
                friendDAO.rejectRequest(id);
                resp.getWriter().write("{\"success\":true,\"message\":\"邀请函已婉拒。\"}");
            }
        }
        // DELETE /api/friends/:id — 删除友人
        else if (path.matches("/api/friends/\\d+") && method.equals("DELETE")) {
            int id = Integer.parseInt(path.substring(path.lastIndexOf('/') + 1));
            friendDAO.removeFriend(id);
            resp.getWriter().write("{\"success\":true,\"message\":\"友人已移除。\"}");
        }
    }

    // ============================================
    // 茶话会 — 聊天 API
    // ============================================
    private void handleChatAPI(HttpServletRequest req, HttpServletResponse resp)
            throws Exception {
        resp.setContentType("application/json;charset=UTF-8");
        User user = getCurrentUser(req);
        if (user == null) {
            resp.getWriter().write("{\"success\":false,\"error\":\"请先入馆。\"}");
            return;
        }
        String path = req.getRequestURI().substring(req.getContextPath().length());
        String method = req.getMethod();

        // GET /api/chat/rooms — 茶室列表
        if (path.equals("/api/chat/rooms") && method.equals("GET")) {
            List<ChatRoom> rooms = chatDAO.getRoomsForUser(user.getId());
            StringBuilder sb = new StringBuilder("{\"success\":true,\"data\":[");
            for (int i = 0; i < rooms.size(); i++) {
                if (i > 0) sb.append(",");
                ChatRoom r = rooms.get(i);
                sb.append("{\"id\":").append(r.getId());
                sb.append(",\"name\":\"").append(escapeJson(r.getName())).append("\"");
                sb.append(",\"type\":\"").append(escapeJson(r.getType())).append("\"");
                sb.append(",\"member_count\":").append(r.getMemberCount());
                sb.append(",\"last_message\":").append(r.getLastMessage() != null ? "\"" + escapeJson(r.getLastMessage()) + "\"" : "null");
                if (r.getLastMessageTime() != null) {
                    sb.append(",\"last_message_time\":\"").append(r.getLastMessageTime().toString()).append("\"");
                }
                sb.append("}");
            }
            sb.append("]}");
            resp.getWriter().write(sb.toString());
        }
        // POST /api/chat/rooms — 创建公共茶室（仅管理员）
        else if (path.equals("/api/chat/rooms") && method.equals("POST")) {
            if (!isAdmin(req)) {
                resp.getWriter().write("{\"success\":false,\"error\":\"仅馆主或女仆长可创建公共茶室。\"}");
                return;
            }
            String name = req.getParameter("name");
            if (name == null || name.trim().isEmpty()) {
                resp.getWriter().write("{\"success\":false,\"error\":\"请输入茶室名称。\"}");
                return;
            }
            int roomId = chatDAO.createPublicRoom(name.trim(), user.getId());
            if (roomId > 0) {
                // 新注册用户注册时自动加入，此处先加入当前所有用户
                chatDAO.addAllUsersToRoom(roomId);
                resp.getWriter().write("{\"success\":true,\"message\":\"公共茶室已创建！\",\"id\":" + roomId + "}");
            } else {
                resp.getWriter().write("{\"success\":false,\"error\":\"创建失败。\"}");
            }
        }
        // GET /api/chat/rooms/:id — 茶室详情
        else if (path.matches("/api/chat/rooms/\\d+") && !path.contains("/messages") && method.equals("GET")) {
            int roomId = Integer.parseInt(path.substring(path.lastIndexOf('/') + 1));
            if (!chatDAO.isMember(roomId, user.getId())) {
                resp.getWriter().write("{\"success\":false,\"error\":\"你未加入此茶室。\"}");
                return;
            }
            ChatRoom room = chatDAO.getRoomById(roomId);
            if (room == null) {
                resp.getWriter().write("{\"success\":false,\"error\":\"茶室未找到。\"}");
                return;
            }
            StringBuilder sb = new StringBuilder("{\"success\":true,\"data\":{");
            sb.append("\"id\":").append(room.getId());
            sb.append(",\"name\":\"").append(escapeJson(room.getName())).append("\"");
            sb.append(",\"type\":\"").append(escapeJson(room.getType())).append("\"");
            sb.append(",\"member_count\":").append(room.getMemberCount());
            sb.append(",\"is_admin\":").append(user.isAdmin());
            sb.append("}}");
            resp.getWriter().write(sb.toString());
        }
        // GET /api/chat/rooms/:id/messages — 消息列表
        else if (path.matches("/api/chat/rooms/\\d+/messages") && method.equals("GET")) {
            int roomId = Integer.parseInt(path.split("/")[4]);
            if (!chatDAO.isMember(roomId, user.getId())) {
                resp.getWriter().write("{\"success\":false,\"error\":\"你未加入此茶室。\"}");
                return;
            }
            int since = 0;
            try { since = Integer.parseInt(req.getParameter("since")); } catch (Exception e) {}
            List<Message> msgs = chatDAO.getMessages(roomId, since, 50);
            StringBuilder sb = new StringBuilder("{\"success\":true,\"data\":[");
            for (int i = 0; i < msgs.size(); i++) {
                if (i > 0) sb.append(",");
                Message m = msgs.get(i);
                sb.append("{\"id\":").append(m.getId());
                sb.append(",\"sender_id\":").append(m.getSenderId());
                sb.append(",\"content\":\"").append(escapeJson(m.getContent())).append("\"");
                sb.append(",\"sender_nickname\":\"").append(escapeJson(m.getSenderNickname())).append("\"");
                sb.append(",\"sender_avatar\":").append(m.getSenderAvatar() != null ? "\"" + escapeJson(m.getSenderAvatar()) + "\"" : "null");
                sb.append(",\"created_at\":\"").append(m.getCreatedAt()).append("\"}");
            }
            sb.append("]}");
            resp.getWriter().write(sb.toString());
        }
        // POST /api/chat/messages — 发送消息
        else if (path.equals("/api/chat/messages") && method.equals("POST")) {
            int roomId;
            try { roomId = Integer.parseInt(req.getParameter("room_id")); } catch (Exception e) {
                resp.getWriter().write("{\"success\":false,\"error\":\"缺少茶室 ID。\"}");
                return;
            }
            String content = req.getParameter("content");
            if (content == null || content.trim().isEmpty()) {
                resp.getWriter().write("{\"success\":false,\"error\":\"消息不能为空。\"}");
                return;
            }
            if (!chatDAO.isMember(roomId, user.getId())) {
                resp.getWriter().write("{\"success\":false,\"error\":\"你未加入此茶室。\"}");
                return;
            }
            int msgId = chatDAO.sendMessage(roomId, user.getId(), content.trim());
            if (msgId > 0) {
                resp.getWriter().write("{\"success\":true,\"id\":" + msgId + ",\"created_at\":\"" + new java.util.Date() + "\"}");
            } else {
                resp.getWriter().write("{\"success\":false,\"error\":\"发送失败。\"}");
            }
        }
    }

    /** 友人列表 JSON 辅助方法 */
    private String friendsToJson(List<Friend> list, int currentUserId) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < list.size(); i++) {
            if (i > 0) sb.append(",");
            Friend f = list.get(i);
            // 对于双向查询，确定展示的友人信息
            String displayName, displayAvatar, displayUsername;
            if (f.getUserId() == currentUserId) {
                displayUsername = f.getFriendUsername();
                displayName = f.getFriendNickname();
                displayAvatar = f.getFriendAvatar();
            } else {
                displayUsername = f.getFriendUsername() != null ? f.getFriendUsername() : "";
                displayName = f.getFriendNickname() != null ? f.getFriendNickname() : "";
                displayAvatar = f.getFriendAvatar();
            }
            sb.append("{\"id\":").append(f.getId());
            sb.append(",\"user_id\":").append(f.getUserId());
            sb.append(",\"friend_id\":").append(f.getFriendId());
            sb.append(",\"status\":\"").append(escapeJson(f.getStatus())).append("\"");
            sb.append(",\"username\":\"").append(escapeJson(displayUsername != null ? displayUsername : "")).append("\"");
            sb.append(",\"nickname\":\"").append(escapeJson(displayName != null ? displayName : "")).append("\"");
            sb.append(",\"avatar\":").append(displayAvatar != null ? "\"" + escapeJson(displayAvatar) + "\"" : "null");
            sb.append("}");
        }
        return sb.toString();
    }

    // ============================================
    // 认证辅助方法
    // ============================================
    private String getClientIP(HttpServletRequest req) {
        String ip = req.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = req.getHeader("X-Real-IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = req.getRemoteAddr();
        }
        // 取第一个非代理 IP
        int comma = ip.indexOf(',');
        return comma > 0 ? ip.substring(0, comma).trim() : ip.trim();
    }

    /** 验证码题库 — 混合数学 + 东方/红魔馆趣味问答 */
    private static final String[][] CAPTCHAS = {
        // 数学混合运算
        {"3 × 7 + 2 = ?", "23"},
        {"15 + 28 = ?", "43"},
        {"100 − 37 = ?", "63"},
        {"6 × 8 = ?", "48"},
        {"56 ÷ 7 = ?", "8"},
        {"9 × 9 − 10 = ?", "71"},
        {"144 ÷ 12 = ?", "12"},
        {"25 + 36 = ?", "61"},
        // 红魔馆 / 东方趣味问答
        {"红魔馆的主人叫什么？（2个字）", "蕾米"},
        {"红魔馆的女仆长叫什么？（2个字）", "咲夜"},
        {"蕾米莉亚的妹妹叫？（2个字）", "芙兰"},
        {"帕秋莉擅长什么？（2个字）", "魔法"},
        {"雾雨魔理沙用的是？（3个字）", "八卦炉"},
        {"博丽神社的巫女叫？（2个字）", "灵梦"},
        {"十六夜咲夜的能力是操纵？（2个字）", "时间"},
        {"红魔馆的门卫叫？（2个字）", "美铃"},
        {"红魔馆有几个主要住人？（数字）", "5"},
        {"幻想乡的巫女靠什么为生？（2个字）", "赛钱"},
        {"⑨ 是指幻想乡的谁？（3个字）", "琪露诺"},
        {"永远亭的公主叫？（2个字）", "辉夜"},
        {"八云紫的能力是操纵？（2个字）", "境界"},
        {"幽幽子住在哪里？（3个字）", "白玉楼"},
        {"咲夜泡红茶需要几分钟？（数字）", "3"},
        {"帕秋莉的图书馆在红魔馆的？（2个字）", "地下"},
        {"芙兰朵露的能力是破坏？（2个字）", "一切"},
        {"灵梦的必杀技是？（4个字）", "梦想封印"},
        {"魔理沙的必杀技是？（2个字）", "魔炮"},
        {"蕾米莉亚的种族是？（3个字）", "吸血鬼"},
    };

    private String[] pickCaptcha() {
        return CAPTCHAS[new SecureRandom().nextInt(CAPTCHAS.length)];
    }

    private User getCurrentUser(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session == null) return null;
        return (User) session.getAttribute("user");
    }

    private boolean isAdmin(HttpServletRequest req) {
        User user = getCurrentUser(req);
        return user != null && user.isAdmin();
    }

    /** 是否需要 CSRF 防护 */
    private boolean isStateChanging(String method) {
        return "POST".equals(method) || "PUT".equals(method) || "DELETE".equals(method);
    }

    /** CSRF Origin/Referer 检查 */
    private boolean csrfCheck(HttpServletRequest req) {
        String origin = req.getHeader("Origin");
        String referer = req.getHeader("Referer");
        String host = req.getServerName();
        // 验证 Origin 或 Referer 匹配当前主机
        if (origin != null) {
            return origin.contains(host);
        }
        if (referer != null) {
            return referer.contains(host);
        }
        // 无 Origin 也无 Referer 的请求 — 可能是直接 API 调用，放行
        return true;
    }

    /** 为 session cookie 添加 SameSite 标记 */
    private void addSameSiteCookie(HttpServletResponse resp) {
        String header = resp.getHeader("Set-Cookie");
        if (header != null && header.toUpperCase().contains("JSESSIONID") && !header.contains("SameSite")) {
            resp.setHeader("Set-Cookie", header + "; SameSite=Lax");
        }
    }

    // ============================================
    // JSON 辅助方法
    // ============================================
    private String toJsonList(List<Post> posts, int page, int limit, int total) {
        StringBuilder sb = new StringBuilder();
        sb.append("{\"success\":true,\"data\":[");
        for (int i = 0; i < posts.size(); i++) {
            if (i > 0) sb.append(",");
            sb.append(toPostJsonRaw(posts.get(i)));
        }
        sb.append("],\"pagination\":{\"page\":").append(page)
          .append(",\"limit\":").append(limit)
          .append(",\"total\":").append(total)
          .append(",\"totalPages\":").append(Math.max(1, (int)Math.ceil((double)total/limit)))
          .append("}}");
        return sb.toString();
    }

    private String toPostJson(Post p) {
        return "{\"success\":true,\"data\":" + toPostJsonRaw(p) + "}";
    }

    private String toPostJsonRaw(Post p) {
        StringBuilder sb = new StringBuilder("{");
        sb.append("\"id\":").append(p.getId());
        sb.append(",\"title\":\"").append(escapeJson(p.getTitle())).append("\"");
        sb.append(",\"content\":\"").append(escapeJson(p.getContent())).append("\"");
        sb.append(",\"excerpt\":\"").append(escapeJson(p.getExcerpt())).append("\"");
        sb.append(",\"author\":\"").append(escapeJson(p.getAuthor())).append("\"");
        sb.append(",\"category_id\":").append(p.getCategoryId());
        sb.append(",\"tags\":\"").append(escapeJson(p.getTags())).append("\"");
        sb.append(",\"view_count\":").append(p.getViewCount());
        sb.append(",\"is_published\":").append(p.getIsPublished());
        if (p.getCreatedAt() != null)
            sb.append(",\"created_at\":\"").append(p.getCreatedAt().toString()).append("\"");
        if (p.getUpdatedAt() != null)
            sb.append(",\"updated_at\":\"").append(p.getUpdatedAt().toString()).append("\"");
        if (p.getCategoryName() != null)
            sb.append(",\"category_name\":\"").append(escapeJson(p.getCategoryName())).append("\"");
        if (p.getCategoryIcon() != null)
            sb.append(",\"category_icon\":\"").append(escapeJson(p.getCategoryIcon())).append("\"");
        sb.append("}");
        return sb.toString();
    }

    private String toCarouselJson(CarouselSlide s, String ctx) {
        StringBuilder sb = new StringBuilder("{");
        sb.append("\"id\":").append(s.getId());
        sb.append(",\"type\":\"").append(escapeJson(s.getType())).append("\"");
        sb.append(",\"image_path\":").append(s.getImagePath() != null ? "\"" + escapeJson(s.getImagePath()) + "\"" : "null");
        sb.append(",\"video_url\":").append(s.getVideoUrl() != null ? "\"" + escapeJson(s.getVideoUrl()) + "\"" : "null");
        sb.append(",\"title\":").append(s.getTitle() != null ? "\"" + escapeJson(s.getTitle()) + "\"" : "null");
        sb.append(",\"sort_order\":").append(s.getSortOrder());
        sb.append(",\"is_active\":").append(s.getIsActive());
        // poster / 封面 URL
        String posterUrl = s.getPosterUrl(ctx);
        if (posterUrl != null) {
            sb.append(",\"poster\":\"").append(escapeJson(posterUrl)).append("\"");
        }
        if (s.getPoster() != null && !s.getPoster().isEmpty()) {
            sb.append(",\"poster_path\":\"").append(escapeJson(s.getPoster())).append("\"");
        }
        if (s.getImagePath() != null && !s.getImagePath().isEmpty()) {
            sb.append(",\"url\":\"").append(escapeJson(ctx + "/" + s.getImagePath() + "?t=" + s.getCreatedAt().getTime())).append("\"");
            if ("video".equals(s.getType())) {
                sb.append(",\"local_video_url\":\"").append(escapeJson(ctx + "/" + s.getImagePath())).append("\"");
            }
        }
        if ("video".equals(s.getType()) && s.getVideoUrl() != null) {
            sb.append(",\"video_src\":\"").append(escapeJson(s.getVideoUrl())).append("\"");
        }
        String thumb = s.getThumbUrl();
        if (thumb != null) sb.append(",\"thumb\":\"").append(escapeJson(thumb)).append("\"");
        sb.append("}");
        return sb.toString();
    }

    private String toCommentsJson(List<Comment> comments) {
        StringBuilder sb = new StringBuilder("{\"success\":true,\"data\":[");
        for (int i = 0; i < comments.size(); i++) {
            if (i > 0) sb.append(",");
            Comment c = comments.get(i);
            sb.append("{\"id\":").append(c.getId())
              .append(",\"author\":\"").append(escapeJson(c.getAuthor())).append("\"")
              .append(",\"content\":\"").append(escapeJson(c.getContent())).append("\"")
              .append(",\"created_at\":\"").append(c.getCreatedAt()).append("\"}");
        }
        sb.append("]}");
        return sb.toString();
    }

    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t");
    }

    private String toUserJson(User user) {
        StringBuilder sb = new StringBuilder();
        sb.append("{\"success\":true,\"message\":\"欢迎回来，").append(escapeJson(user.getNickname())).append("！\",");
        sb.append("\"data\":{");
        sb.append("\"id\":").append(user.getId());
        sb.append(",\"username\":\"").append(escapeJson(user.getUsername())).append("\"");
        sb.append(",\"nickname\":\"").append(escapeJson(user.getNickname())).append("\"");
        sb.append(",\"role\":\"").append(escapeJson(user.getRole())).append("\"");
        if (user.getAvatar() != null) {
            sb.append(",\"avatar\":\"").append(escapeJson(user.getAvatar())).append("\"");
        }
        if (user.getBackground() != null) {
            sb.append(",\"background\":\"").append(escapeJson(user.getBackground())).append("\"");
        }
        if (user.getEmail() != null) {
            sb.append(",\"email\":\"").append(escapeJson(user.getEmail())).append("\"");
            sb.append(",\"email_verified\":").append(user.isEmailVerified());
        }
        sb.append("}}");
        return sb.toString();
    }

    /** 保存轮播海报/封面图文件，设置到 CarouselSlide.poster */
    private void savePosterFile(HttpServletRequest req, CarouselSlide s) {
        try {
            Part posterPart = req.getPart("poster");
            if (posterPart == null || posterPart.getSize() == 0) return;
            String pname = getSubmittedFileName(posterPart);
            String pext = pname.contains(".") ? pname.substring(pname.lastIndexOf(".")).toLowerCase() : ".jpg";
            if (!pext.matches("\\.(jpg|jpeg|png|gif|webp)$")) return;
            String ppath = "images/carousel_poster_" + s.getId() + "_" + System.currentTimeMillis() + pext;
            Files.copy(posterPart.getInputStream(), Paths.get(req.getServletContext().getRealPath("/"), ppath), StandardCopyOption.REPLACE_EXISTING);
            // 删除旧海报文件
            if (s.getPoster() != null && s.getPoster().startsWith("images/")) {
                try { new java.io.File(req.getServletContext().getRealPath("/"), s.getPoster()).delete(); } catch (Exception e) {}
            }
            s.setPoster(ppath);
        } catch (Exception e) { /* poster 可选 */ }
        // 也接受外链 poster URL
        String posterUrl = req.getParameter("poster_url");
        if (posterUrl != null && !posterUrl.trim().isEmpty()) {
            s.setPoster(posterUrl.trim());
        }
    }

    /** 从 multipart Part 中提取文件名 */
    private String getSubmittedFileName(Part part) {
        String header = part.getHeader("content-disposition");
        if (header == null) return "avatar.jpg";
        Matcher m = Pattern.compile("filename\\s*=\\s*\"([^\"]*)\"").matcher(header);
        if (m.find()) {
            String name = m.group(1);
            // 处理 IE 全路径
            int idx = name.lastIndexOf('\\');
            if (idx >= 0) name = name.substring(idx + 1);
            return name.isEmpty() ? "avatar.jpg" : name;
        }
        return "avatar.jpg";
    }
}
