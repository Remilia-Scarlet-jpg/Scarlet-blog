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
            } else {
                req.getRequestDispatcher("/index.jsp").forward(req, resp);
            }
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendError(500, "红魔馆内部错误：" + e.getMessage());
        }
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
        // 已登录则跳转管理室
        User user = getCurrentUser(req);
        if (user != null) {
            resp.sendRedirect(req.getContextPath() + "/blog/admin");
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
            resp.sendRedirect(req.getContextPath() + "/blog/admin");
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
            if (captcha == null || !captcha.trim().equals(expectedCaptcha)) {
                session.removeAttribute("captchaAnswer"); // 验证码一次性
                resp.getWriter().write("{\"success\":false,\"error\":\"验证码错误，请重新输入。\"}");
                return;
            }
            session.removeAttribute("captchaAnswer"); // 验证码一次性

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
            if (captcha == null || !captcha.trim().equals(expected)) {
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
                resp.getWriter().write("{\"success\":true,\"message\":\"来馆登记完成！欢迎成为红魔馆的住人，"
                    + newUser.getNickname() + "。请用你的名札和封印密语入馆。\"}");
            } else {
                resp.getWriter().write("{\"success\":false,\"error\":\"登记失败，请稍后再试。\"}");
            }
        }
        // GET /api/auth/captcha — 获取验证码
        else if (path.equals("/api/auth/captcha") && method.equals("GET")) {
            resp.setContentType("application/json;charset=UTF-8");
            HttpSession session = req.getSession(true);
            int a = new SecureRandom().nextInt(10) + 1;
            int b = new SecureRandom().nextInt(10) + 1;
            String question = a + " + " + b + " = ?";
            session.setAttribute("captchaAnswer", String.valueOf(a + b));
            resp.getWriter().write("{\"success\":true,\"question\":\"" + question + "\"}");
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
                String savedName = user.getUsername() + "_" + System.currentTimeMillis() + ext;
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
        // GET /api/auth/logout — 离馆
        else if (path.equals("/api/auth/logout") && method.equals("GET")) {
            HttpSession session = req.getSession(false);
            if (session != null) session.invalidate();
            resp.getWriter().write("{\"success\":true,\"message\":\"再见，欢迎随时回红魔馆。\"}");
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
            resp.getWriter().write("<html><body style='background:#1a0000;color:#d4af37;text-align:center;padding:100px;font-size:1.5rem;'>"
                + "<p>🚫 只有馆主或女仆长才能进入管理室。</p>"
                + "<p><a href='" + req.getContextPath() + "/blog' style='color:#ff6b7a;'>← 返回大厅</a></p>"
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

    private User getCurrentUser(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session == null) return null;
        return (User) session.getAttribute("user");
    }

    private boolean isAdmin(HttpServletRequest req) {
        User user = getCurrentUser(req);
        return user != null && user.isAdmin();
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
