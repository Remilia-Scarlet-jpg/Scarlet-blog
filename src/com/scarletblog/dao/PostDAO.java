package com.scarletblog.dao;

import com.scarletblog.model.Post;
import com.scarletblog.model.Comment;
import com.scarletblog.util.DBUtil;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * 文章数据访问对象 - CRUD 操作
 */
public class PostDAO {

    /** 获取文章列表 (支持搜索和分类筛选) */
    public List<Post> getPosts(String search, String category, int page, int limit) throws SQLException {
        List<Post> posts = new ArrayList<>();
        int offset = (page - 1) * limit;

        StringBuilder sql = new StringBuilder(
            "SELECT p.*, c.name AS category_name, c.icon AS category_icon " +
            "FROM posts p LEFT JOIN categories c ON p.category_id = c.id " +
            "WHERE p.is_published = 1"
        );
        List<Object> params = new ArrayList<>();

        if (search != null && !search.trim().isEmpty()) {
            sql.append(" AND (p.title LIKE ? OR p.content LIKE ? OR p.tags LIKE ?)");
            String keyword = "%" + search.trim() + "%";
            params.add(keyword); params.add(keyword); params.add(keyword);
        }
        if (category != null && !category.trim().isEmpty()) {
            sql.append(" AND (c.name = ? OR c.id = ?)");
            params.add(category.trim()); params.add(category.trim());
        }

        sql.append(" ORDER BY p.created_at DESC LIMIT ? OFFSET ?");
        params.add(limit); params.add(offset);

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql.toString());
            for (int i = 0; i < params.size(); i++) {
                pstmt.setObject(i + 1, params.get(i));
            }
            rs = pstmt.executeQuery();
            while (rs.next()) {
                posts.add(mapPost(rs));
            }
        } finally {
            DBUtil.close(conn, pstmt, rs);
        }
        return posts;
    }

    /** 获取文章总数 */
    public int getPostCount(String search, String category) throws SQLException {
        StringBuilder sql = new StringBuilder(
            "SELECT COUNT(*) FROM posts p WHERE p.is_published = 1"
        );
        List<Object> params = new ArrayList<>();

        if (search != null && !search.trim().isEmpty()) {
            sql.append(" AND (p.title LIKE ? OR p.content LIKE ? OR p.tags LIKE ?)");
            String keyword = "%" + search.trim() + "%";
            params.add(keyword); params.add(keyword); params.add(keyword);
        }
        if (category != null && !category.trim().isEmpty()) {
            sql.append(" AND p.category_id IN (SELECT id FROM categories WHERE name = ? OR id = ?)");
            params.add(category.trim()); params.add(category.trim());
        }

        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql.toString());
            for (int i = 0; i < params.size(); i++) pstmt.setObject(i + 1, params.get(i));
            rs = pstmt.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } finally { DBUtil.close(conn, pstmt, rs); }
        return 0;
    }

    /** 获取指定作者的文章列表（用于个人主页） */
    public List<Post> getPostsByAuthor(String author, int page, int limit) throws SQLException {
        List<Post> posts = new ArrayList<>();
        int offset = (page - 1) * limit;
        String sql = "SELECT p.*, c.name AS category_name, c.icon AS category_icon " +
                     "FROM posts p LEFT JOIN categories c ON p.category_id = c.id " +
                     "WHERE p.is_published = 1 AND p.author = ? " +
                     "ORDER BY p.created_at DESC LIMIT ? OFFSET ?";

        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, author);
            pstmt.setInt(2, limit);
            pstmt.setInt(3, offset);
            rs = pstmt.executeQuery();
            while (rs.next()) posts.add(mapPost(rs));
        } finally { DBUtil.close(conn, pstmt, rs); }
        return posts;
    }

    /** 获取指定作者的文章总数 */
    public int getPostCountByAuthor(String author) throws SQLException {
        String sql = "SELECT COUNT(*) FROM posts WHERE is_published = 1 AND author = ?";
        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, author);
            rs = pstmt.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } finally { DBUtil.close(conn, pstmt, rs); }
        return 0;
    }

    /** 获取单篇文章 */
    public Post getPostById(int id) throws SQLException {
        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            // 增加浏览量
            pstmt = conn.prepareStatement("UPDATE posts SET view_count = view_count + 1 WHERE id = ?");
            pstmt.setInt(1, id);
            pstmt.executeUpdate();
            pstmt.close();

            pstmt = conn.prepareStatement(
                "SELECT p.*, c.name AS category_name, c.icon AS category_icon " +
                "FROM posts p LEFT JOIN categories c ON p.category_id = c.id WHERE p.id = ?");
            pstmt.setInt(1, id);
            rs = pstmt.executeQuery();
            if (rs.next()) return mapPost(rs);
        } finally { DBUtil.close(conn, pstmt, rs); }
        return null;
    }

    /** 创建文章 */
    public int createPost(Post post) throws SQLException {
        String sql = "INSERT INTO posts (title, content, excerpt, author, category_id, tags, cover_image) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?)";
        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            pstmt.setString(1, post.getTitle());
            pstmt.setString(2, post.getContent());
            pstmt.setString(3, post.getExcerpt() != null ? post.getExcerpt() : post.getContent().substring(0, Math.min(200, post.getContent().length())));
            pstmt.setString(4, post.getAuthor() != null ? post.getAuthor() : "红魔馆之主");
            if (post.getCategoryId() > 0) pstmt.setInt(5, post.getCategoryId());
            else pstmt.setNull(5, Types.INTEGER);
            pstmt.setString(6, post.getTags());
            pstmt.setString(7, post.getCoverImage());
            pstmt.executeUpdate();
            rs = pstmt.getGeneratedKeys();
            if (rs.next()) return rs.getInt(1);
        } finally { DBUtil.close(conn, pstmt, rs); }
        return -1;
    }

    /** 更新文章 */
    public boolean updatePost(Post post) throws SQLException {
        StringBuilder sql = new StringBuilder("UPDATE posts SET ");
        List<Object> params = new ArrayList<>();

        if (post.getTitle() != null) { sql.append("title = ?, "); params.add(post.getTitle()); }
        if (post.getContent() != null) { sql.append("content = ?, "); params.add(post.getContent()); }
        if (post.getExcerpt() != null) { sql.append("excerpt = ?, "); params.add(post.getExcerpt()); }
        if (post.getAuthor() != null) { sql.append("author = ?, "); params.add(post.getAuthor()); }
        sql.append("category_id = ?, "); params.add(post.getCategoryId() > 0 ? post.getCategoryId() : null);
        if (post.getTags() != null) { sql.append("tags = ?, "); params.add(post.getTags()); }
        if (post.getCoverImage() != null) { sql.append("cover_image = ?, "); params.add(post.getCoverImage()); }
        sql.append("is_published = ? "); params.add(post.getIsPublished());

        sql.append("WHERE id = ?");
        params.add(post.getId());

        Connection conn = null; PreparedStatement pstmt = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql.toString());
            for (int i = 0; i < params.size(); i++) pstmt.setObject(i + 1, params.get(i));
            return pstmt.executeUpdate() > 0;
        } finally { DBUtil.close(conn, pstmt, null); }
    }

    /** 删除文章 */
    public boolean deletePost(int id) throws SQLException {
        Connection conn = null; PreparedStatement pstmt = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement("DELETE FROM posts WHERE id = ?");
            pstmt.setInt(1, id);
            return pstmt.executeUpdate() > 0;
        } finally { DBUtil.close(conn, pstmt, null); }
    }

    /** 获取文章评论 */
    public List<Comment> getComments(int postId) throws SQLException {
        List<Comment> comments = new ArrayList<>();
        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement("SELECT * FROM comments WHERE post_id = ? ORDER BY created_at DESC");
            pstmt.setInt(1, postId);
            rs = pstmt.executeQuery();
            while (rs.next()) {
                Comment c = new Comment();
                c.setId(rs.getInt("id"));
                c.setPostId(rs.getInt("post_id"));
                c.setAuthor(rs.getString("author"));
                c.setContent(rs.getString("content"));
                c.setCreatedAt(rs.getTimestamp("created_at"));
                comments.add(c);
            }
        } finally { DBUtil.close(conn, pstmt, rs); }
        return comments;
    }

    /** 添加评论 */
    public int addComment(Comment comment) throws SQLException {
        String sql = "INSERT INTO comments (post_id, author, content) VALUES (?, ?, ?)";
        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            pstmt.setInt(1, comment.getPostId());
            pstmt.setString(2, comment.getAuthor() != null ? comment.getAuthor() : "匿名访客");
            pstmt.setString(3, comment.getContent());
            pstmt.executeUpdate();
            rs = pstmt.getGeneratedKeys();
            if (rs.next()) return rs.getInt(1);
        } finally { DBUtil.close(conn, pstmt, rs); }
        return -1;
    }

    /** ResultSet -> Post 映射 */
    private Post mapPost(ResultSet rs) throws SQLException {
        Post p = new Post();
        p.setId(rs.getInt("id"));
        p.setTitle(rs.getString("title"));
        p.setContent(rs.getString("content"));
        p.setExcerpt(rs.getString("excerpt"));
        p.setAuthor(rs.getString("author"));
        p.setCategoryId(rs.getInt("category_id"));
        p.setCoverImage(rs.getString("cover_image"));
        p.setTags(rs.getString("tags"));
        p.setViewCount(rs.getInt("view_count"));
        p.setIsPublished(rs.getInt("is_published"));
        p.setCreatedAt(rs.getTimestamp("created_at"));
        p.setUpdatedAt(rs.getTimestamp("updated_at"));
        try { p.setCategoryName(rs.getString("category_name")); } catch (SQLException e) {}
        try { p.setCategoryIcon(rs.getString("category_icon")); } catch (SQLException e) {}
        return p;
    }
}
