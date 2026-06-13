package com.scarletblog.dao;

import com.scarletblog.model.User;
import com.scarletblog.util.DBUtil;
import java.sql.*;
import java.security.MessageDigest;

/**
 * 访客数据访问对象 - 入馆通行 / 来馆登记
 */
public class UserDAO {

    /**
     * SHA-256 哈希（在 Java 层做，兼容 H2 和 MySQL）
     */
    private static String sha256(String input) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(input.getBytes("UTF-8"));
            StringBuilder hex = new StringBuilder();
            for (byte b : hash) hex.append(String.format("%02x", b));
            return hex.toString();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

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
            pstmt.setString(2, sha256(user.getPassword()));
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
        String sql = "SELECT * FROM users WHERE username = ? AND password = ?";

        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, username);
            pstmt.setString(2, sha256(password));
            rs = pstmt.executeQuery();
            if (rs.next()) {
                return mapUser(rs);
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

    private User mapUser(ResultSet rs) throws SQLException {
        User u = new User();
        u.setId(rs.getInt("id"));
        u.setUsername(rs.getString("username"));
        u.setPassword(null);
        u.setNickname(rs.getString("nickname"));
        u.setRole(rs.getString("role"));
        u.setCreatedAt(rs.getTimestamp("created_at"));
        return u;
    }
}
