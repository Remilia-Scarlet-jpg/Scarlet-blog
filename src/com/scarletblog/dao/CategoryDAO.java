package com.scarletblog.dao;

import com.scarletblog.model.Category;
import com.scarletblog.util.DBUtil;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class CategoryDAO {

    public List<Category> getAllCategories() throws SQLException {
        List<Category> list = new ArrayList<>();
        String sql = "SELECT c.*, COUNT(p.id) AS post_count FROM categories c " +
                     "LEFT JOIN posts p ON c.id = p.category_id AND p.is_published = 1 " +
                     "GROUP BY c.id ORDER BY c.id";
        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql);
            rs = pstmt.executeQuery();
            while (rs.next()) {
                Category c = new Category();
                c.setId(rs.getInt("id"));
                c.setName(rs.getString("name"));
                c.setDescription(rs.getString("description"));
                c.setIcon(rs.getString("icon"));
                c.setPostCount(rs.getInt("post_count"));
                c.setCreatedAt(rs.getTimestamp("created_at"));
                list.add(c);
            }
        } finally { DBUtil.close(conn, pstmt, rs); }
        return list;
    }

    public int getTotalPosts() throws SQLException {
        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement("SELECT COUNT(*) FROM posts WHERE is_published = 1");
            rs = pstmt.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } finally { DBUtil.close(conn, pstmt, rs); }
        return 0;
    }

    public int getTotalComments() throws SQLException {
        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement("SELECT COUNT(*) FROM comments");
            rs = pstmt.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } finally { DBUtil.close(conn, pstmt, rs); }
        return 0;
    }

    public int getTotalViews() throws SQLException {
        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement("SELECT COALESCE(SUM(view_count), 0) FROM posts");
            rs = pstmt.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } finally { DBUtil.close(conn, pstmt, rs); }
        return 0;
    }

    /** 创建分类 */
    public int createCategory(Category c) throws SQLException {
        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(
                "INSERT INTO categories (name, description, icon) VALUES (?, ?, ?)",
                Statement.RETURN_GENERATED_KEYS);
            pstmt.setString(1, c.getName());
            pstmt.setString(2, c.getDescription());
            pstmt.setString(3, c.getIcon() != null ? c.getIcon() : "📜");
            pstmt.executeUpdate();
            rs = pstmt.getGeneratedKeys();
            if (rs.next()) return rs.getInt(1);
            return -1;
        } finally { DBUtil.close(conn, pstmt, rs); }
    }

    /** 更新分类 */
    public boolean updateCategory(Category c) throws SQLException {
        Connection conn = null; PreparedStatement pstmt = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(
                "UPDATE categories SET name = ?, description = ?, icon = ? WHERE id = ?");
            pstmt.setString(1, c.getName());
            pstmt.setString(2, c.getDescription());
            pstmt.setString(3, c.getIcon() != null ? c.getIcon() : "📜");
            pstmt.setInt(4, c.getId());
            return pstmt.executeUpdate() > 0;
        } finally { DBUtil.close(conn, pstmt, null); }
    }

    /** 删除分类（文章 category_id 外键 SET NULL，安全删除） */
    public boolean deleteCategory(int id) throws SQLException {
        Connection conn = null; PreparedStatement pstmt = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement("DELETE FROM categories WHERE id = ?");
            pstmt.setInt(1, id);
            return pstmt.executeUpdate() > 0;
        } finally { DBUtil.close(conn, pstmt, null); }
    }
}
