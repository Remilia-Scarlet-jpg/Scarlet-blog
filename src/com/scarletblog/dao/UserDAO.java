package com.scarletblog.dao;

import com.scarletblog.model.User;
import com.scarletblog.util.DBUtil;
import com.scarletblog.util.SecurityUtil;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * 访客数据访问对象 - 入馆通行 / 来馆登记
 * 密码使用 PBKDF2-SHA256（盐值 + 12 万次迭代）
 */
public class UserDAO {

    /**
     * 来馆登记 - 注册新访客
     */
    public int register(User user) throws SQLException {
        String sql = "INSERT INTO users (username, password, nickname, role) VALUES (?, ?, ?, '住人')";

        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            pstmt.setString(1, user.getUsername());
            pstmt.setString(2, SecurityUtil.hashPassword(user.getPassword()));
            pstmt.setString(3, user.getNickname() != null ? user.getNickname() : user.getUsername());
            pstmt.executeUpdate();
            rs = pstmt.getGeneratedKeys();
            if (rs.next()) return rs.getInt(1);
        } finally { DBUtil.close(conn, pstmt, rs); }
        return -1;
    }

    /**
     * 入馆通行 - 登录验证
     */
    public User login(String username, String password) throws SQLException {
        // 先取出用户记录，在 Java 层验证密码（PBKDF2 不支持 SQL 内验证）
        String sql = "SELECT * FROM users WHERE username = ?";

        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, username);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                User user = mapUser(rs);
                // 获取存储的哈希
                rs.close(); pstmt.close();
                // 重新查询获取密码字段（mapUser 会清掉 password）
                pstmt = conn.prepareStatement("SELECT password FROM users WHERE id = ?");
                pstmt.setInt(1, user.getId());
                rs = pstmt.executeQuery();
                if (rs.next()) {
                    String storedHash = rs.getString("password");
                    if (SecurityUtil.verifyPassword(password, storedHash)) {
                        return user;
                    }
                }
            }
        } finally { DBUtil.close(conn, pstmt, rs); }
        return null;
    }

    /**
     * 检查名札是否已被登记
     */
    public boolean usernameExists(String username) throws SQLException {
        String sql = "SELECT COUNT(*) FROM users WHERE username = ?";
        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, username);
            rs = pstmt.executeQuery();
            if (rs.next()) return rs.getInt(1) > 0;
        } finally { DBUtil.close(conn, pstmt, rs); }
        return false;
    }

    /**
     * 按用户名查找用户（不含密码）
     */
    public User findByUsername(String username) throws SQLException {
        String sql = "SELECT id, username, nickname, avatar, background, role, created_at FROM users WHERE username = ?";
        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, username);
            rs = pstmt.executeQuery();
            if (rs.next()) return mapUser(rs);
        } finally { DBUtil.close(conn, pstmt, rs); }
        return null;
    }

    /**
     * 按 ID 查找用户（不含密码，用于公开主页）
     */
    public User findById(int userId) throws SQLException {
        String sql = "SELECT id, username, nickname, avatar, background, role, created_at FROM users WHERE id = ?";
        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, userId);
            rs = pstmt.executeQuery();
            if (rs.next()) return mapUser(rs);
        } finally { DBUtil.close(conn, pstmt, rs); }
        return null;
    }

    /**
     * 查询指定用户的已发布文章数（通过 nickname→author 关联）
     */
    public int getPostCount(int userId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM posts p JOIN users u ON u.nickname = p.author WHERE u.id = ? AND p.is_published = 1";
        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, userId);
            rs = pstmt.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } finally { DBUtil.close(conn, pstmt, rs); }
        return 0;
    }

    /**
     * 查询指定用户的评论数（通过 nickname→author 关联）
     */
    public int getCommentCount(int userId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM comments c JOIN users u ON u.nickname = c.author WHERE u.id = ?";
        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, userId);
            rs = pstmt.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } finally { DBUtil.close(conn, pstmt, rs); }
        return 0;
    }

    /**
     * 查询全部用户（仅管理员）
     */
    public List<User> getAllUsers() throws SQLException {
        List<User> users = new ArrayList<>();
        String sql = "SELECT id, username, nickname, role, avatar, background, created_at FROM users ORDER BY id";
        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql);
            rs = pstmt.executeQuery();
            while (rs.next()) users.add(mapUser(rs));
        } finally { DBUtil.close(conn, pstmt, rs); }
        return users;
    }

    /**
     * 更新用户资料（昵称、头像、背景图）
     */
    public boolean updateProfile(int userId, String nickname, String avatar, String background) throws SQLException {
        StringBuilder sql = new StringBuilder("UPDATE users SET ");
        List<Object> params = new ArrayList<>();

        if (nickname != null) { sql.append("nickname = ?, "); params.add(nickname); }
        if (avatar != null) { sql.append("avatar = ?, "); params.add(avatar); }
        if (background != null) { sql.append("background = ?, "); params.add(background); }
        if (params.isEmpty()) return false;

        sql.setLength(sql.length() - 2);
        sql.append(" WHERE id = ?");
        params.add(userId);

        Connection conn = null; PreparedStatement pstmt = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql.toString());
            for (int i = 0; i < params.size(); i++) pstmt.setObject(i + 1, params.get(i));
            return pstmt.executeUpdate() > 0;
        } finally { DBUtil.close(conn, pstmt, null); }
    }

    /**
     * 更新用户身份（仅馆主可调用，Servlet 层鉴权）
     */
    public boolean updateRole(int userId, String newRole) throws SQLException {
        String sql = "UPDATE users SET role = ? WHERE id = ?";
        Connection conn = null; PreparedStatement pstmt = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, newRole);
            pstmt.setInt(2, userId);
            return pstmt.executeUpdate() > 0;
        } finally { DBUtil.close(conn, pstmt, null); }
    }

    /**
     * 修改密码（PBKDF2）
     */
    public boolean changePassword(int userId, String oldPassword, String newPassword) throws SQLException {
        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            // 取出旧密码哈希并验证
            pstmt = conn.prepareStatement("SELECT password FROM users WHERE id = ?");
            pstmt.setInt(1, userId);
            rs = pstmt.executeQuery();
            if (!rs.next()) return false;
            String storedHash = rs.getString("password");
            if (!SecurityUtil.verifyPassword(oldPassword, storedHash)) return false;
            pstmt.close();

            // 更新为新密码
            pstmt = conn.prepareStatement("UPDATE users SET password = ? WHERE id = ?");
            pstmt.setString(1, SecurityUtil.hashPassword(newPassword));
            pstmt.setInt(2, userId);
            return pstmt.executeUpdate() > 0;
        } finally { DBUtil.close(conn, pstmt, rs); }
    }

    private User mapUser(ResultSet rs) throws SQLException {
        User u = new User();
        u.setId(rs.getInt("id"));
        u.setUsername(rs.getString("username"));
        u.setPassword(null);
        u.setNickname(rs.getString("nickname"));
        try { u.setAvatar(rs.getString("avatar")); } catch (SQLException e) {}
        try { u.setBackground(rs.getString("background")); } catch (SQLException e) {}
        u.setRole(rs.getString("role"));
        u.setCreatedAt(rs.getTimestamp("created_at"));
        return u;
    }
}
