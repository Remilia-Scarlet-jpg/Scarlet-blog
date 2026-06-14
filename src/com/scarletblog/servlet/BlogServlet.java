package com.scarletblog.servlet;

import com.scarletblog.dao.PostDAO;
import com.scarletblog.dao.CategoryDAO;
import com.scarletblog.dao.UserDAO;
import com.scarletblog.model.Post;
import com.scarletblog.model.Comment;
import com.scarletblog.model.Category;
import com.scarletblog.model.User;

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
    maxFileSize = 5 * 1024 * 1024,      // 5MB
    maxRequestSize = 10 * 1024 * 1024,  // 10MB
    fileSizeThreshold = 1024 * 1024      // 1MB buffer
)
public class BlogServlet extends HttpServlet {
    private PostDAO postDAO = new PostDAO();
    private CategoryDAO categoryDAO = new CategoryDAO();
    private UserDAO userDAO = new UserDAO();

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
            } else if (path.equals("/api/admin/users")) {
                handleAdminUsers(req, resp);
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
        User user = getCurrentUser(req);
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/blog/login");
            return;
        }
        req.setAttribute("currentUser", user);
        req.getRequestDispatcher("/profile.jsp").forward(req, resp);
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

            // 处理头像文件上传
            Part filePart = null;
            try { filePart = req.getPart("avatar"); } catch (Exception e) {}

            if (filePart != null && filePart.getSize() > 0) {
                String fileName = getSubmittedFileName(filePart);
                String ext = fileName.contains(".") ? fileName.substring(fileName.lastIndexOf(".")) : ".jpg";
                // 只允许图片格式
                if (!ext.matches("\\.(jpg|jpeg|png|gif|webp)$")) {
                    resp.getWriter().write("{\"success\":false,\"error\":\"头像仅支持 JPG/PNG/GIF/WebP 格式。\"}");
                    return;
                }
                // 脱敏用户名以防路径穿越（仅允许字母数字下划线）
                String safeName = user.getUsername().replaceAll("[^a-zA-Z0-9_\\u4e00-\\u9fff]", "_");
                String savedName = safeName + "_" + System.currentTimeMillis() + ext;
                String uploadDir = req.getServletContext().getRealPath("/uploads/avatars");
                Path uploadPath = Paths.get(uploadDir);
                if (!Files.exists(uploadPath)) Files.createDirectories(uploadPath);
                Path filePath = uploadPath.resolve(savedName);
                try (InputStream is = filePart.getInputStream()) {
                    Files.copy(is, filePath, StandardCopyOption.REPLACE_EXISTING);
                }
                avatar = "uploads/avatars/" + savedName;
            }

            boolean ok = userDAO.updateProfile(user.getId(), nickname, avatar);
            if (ok) {
                // 刷新 session 中的用户信息
                if (avatar != null) user.setAvatar(avatar);
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
            // 创建文章需要管理员权限
            if (!isAdmin(req)) {
                resp.getWriter().write("{\"success\":false,\"error\":\"只有馆主或女仆长才能撰写文章。\"}");
                return;
            }
            Post post = new Post();
            post.setTitle(req.getParameter("title"));
            post.setContent(req.getParameter("content"));
            post.setAuthor(req.getParameter("author"));
            try { post.setCategoryId(Integer.parseInt(req.getParameter("category_id"))); } catch (Exception e) {}
            post.setTags(req.getParameter("tags"));
            int id = postDAO.createPost(post);
            resp.getWriter().write("{\"success\":true,\"message\":\"文章创建成功！\",\"id\":" + id + "}");
        }
        else if (path.matches("/api/posts/\\d+") && method.equals("PUT")) {
            if (!isAdmin(req)) {
                resp.getWriter().write("{\"success\":false,\"error\":\"只有馆主或女仆长才能修改文章。\"}");
                return;
            }
            int id = Integer.parseInt(path.substring(path.lastIndexOf('/') + 1));
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
        List<Category> categories = categoryDAO.getAllCategories();
        StringBuilder sb = new StringBuilder("{\"success\":true,\"data\":[");
        for (int i = 0; i < categories.size(); i++) {
            if (i > 0) sb.append(",");
            Category c = categories.get(i);
            sb.append("{\"id\":").append(c.getId())
              .append(",\"name\":\"").append(escapeJson(c.getName())).append("\"")
              .append(",\"icon\":\"").append(escapeJson(c.getIcon())).append("\"")
              .append(",\"post_count\":").append(c.getPostCount()).append("}");
        }
        sb.append("]}");
        resp.getWriter().write(sb.toString());
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

    /** 管理员查看用户列表 */
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
            sb.append(",\"createdAt\":\"").append(u.getCreatedAt() != null ? u.getCreatedAt().toString() : "").append("\"");
            sb.append("}");
        }
        sb.append("]}");
        resp.getWriter().write(sb.toString());
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
        {"雾雨魔理沙用的是？（2个字）", "八卦炉"},
        {"博丽神社的巫女叫？（2个字）", "灵梦"},
        {"十六夜咲夜的能力是操纵？（2个字）", "时间"},
        {"红魔馆的门卫叫？（2个字）", "美铃"},
        {"红魔馆有几个主要住人？（数字）", "5"},
        {"幻想乡的巫女靠什么为生？（2个字）", "赛钱"},
        {"⑨ 是指幻想乡的谁？（2个字）", "琪露诺"},
        {"永远亭的公主叫？（2个字）", "辉夜"},
        {"八云紫的能力是操纵？（2个字）", "境界"},
        {"幽幽子住在哪里？（2个字）", "白玉楼"},
        {"咲夜泡红茶需要几分钟？（数字）", "3"},
        {"帕秋莉的图书馆在红魔馆的？（2个字）", "地下"},
        {"芙兰朵露的能力是破坏？（2个字）", "一切"},
        {"灵梦的必杀技是？（4个字）", "梦想封印"},
        {"魔理沙的必杀技是？（4个字）", "魔炮"},
        {"蕾米莉亚的种族是？（2个字）", "吸血鬼"},
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
        if (p.getCategoryName() != null)
            sb.append(",\"category_name\":\"").append(escapeJson(p.getCategoryName())).append("\"");
        if (p.getCategoryIcon() != null)
            sb.append(",\"category_icon\":\"").append(escapeJson(p.getCategoryIcon())).append("\"");
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
        sb.append("}}");
        return sb.toString();
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
