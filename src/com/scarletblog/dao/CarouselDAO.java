package com.scarletblog.dao;

import com.scarletblog.model.CarouselSlide;
import com.scarletblog.util.DBUtil;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * 轮播图数据访问对象 — CRUD + 排序
 */
public class CarouselDAO {

    /** 获取所有启用的幻灯片（首页用） */
    public List<CarouselSlide> getAllSlides() throws SQLException {
        List<CarouselSlide> list = new ArrayList<>();
        String sql = "SELECT * FROM carousel_slides WHERE is_active = 1 ORDER BY sort_order";
        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql);
            rs = pstmt.executeQuery();
            while (rs.next()) list.add(mapSlide(rs));
        } finally { DBUtil.close(conn, pstmt, rs); }
        return list;
    }

    /** 获取所有幻灯片（管理用，含禁用） */
    public List<CarouselSlide> getAllSlidesAdmin() throws SQLException {
        List<CarouselSlide> list = new ArrayList<>();
        String sql = "SELECT * FROM carousel_slides ORDER BY sort_order";
        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql);
            rs = pstmt.executeQuery();
            while (rs.next()) list.add(mapSlide(rs));
        } finally { DBUtil.close(conn, pstmt, rs); }
        return list;
    }

    /** 创建幻灯片，返回 ID */
    public int create(CarouselSlide s) throws SQLException {
        // 新幻灯片的 sort_order = 当前最大 + 1
        String nextOrderSql = "SELECT COALESCE(MAX(sort_order), 0) + 1 FROM carousel_slides";
        String sql = "INSERT INTO carousel_slides (type, image_path, video_url, title, sort_order) VALUES (?, ?, ?, ?, ?)";
        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(nextOrderSql);
            rs = pstmt.executeQuery();
            int nextOrder = 1;
            if (rs.next()) nextOrder = rs.getInt(1);
            rs.close(); pstmt.close();

            pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            pstmt.setString(1, s.getType());
            pstmt.setString(2, s.getImagePath());
            pstmt.setString(3, s.getVideoUrl());
            pstmt.setString(4, s.getTitle());
            pstmt.setInt(5, nextOrder);
            pstmt.executeUpdate();
            rs = pstmt.getGeneratedKeys();
            if (rs.next()) return rs.getInt(1);
        } finally { DBUtil.close(conn, pstmt, rs); }
        return -1;
    }

    /** 更新幻灯片（类型/路径/URL/标题） */
    public boolean update(CarouselSlide s) throws SQLException {
        String sql = "UPDATE carousel_slides SET type=?, image_path=?, video_url=?, title=? WHERE id=?";
        Connection conn = null; PreparedStatement pstmt = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, s.getType());
            pstmt.setString(2, s.getImagePath());
            pstmt.setString(3, s.getVideoUrl());
            pstmt.setString(4, s.getTitle());
            pstmt.setInt(5, s.getId());
            return pstmt.executeUpdate() > 0;
        } finally { DBUtil.close(conn, pstmt, null); }
    }

    /** 删除幻灯片 */
    public boolean delete(int id) throws SQLException {
        String sql = "DELETE FROM carousel_slides WHERE id = ?";
        Connection conn = null; PreparedStatement pstmt = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, id);
            return pstmt.executeUpdate() > 0;
        } finally { DBUtil.close(conn, pstmt, null); }
    }

    /** 上移/下移：交换相邻幻灯片的 sort_order */
    public boolean moveSlide(int id, String direction) throws SQLException {
        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            // 获取当前幻灯片的 sort_order
            pstmt = conn.prepareStatement("SELECT sort_order FROM carousel_slides WHERE id = ?");
            pstmt.setInt(1, id);
            rs = pstmt.executeQuery();
            if (!rs.next()) return false;
            int currentOrder = rs.getInt(1);
            rs.close(); pstmt.close();

            // 找到相邻的幻灯片
            String operator = "up".equals(direction) ? "<" : ">";
            String orderDir = "up".equals(direction) ? "DESC" : "ASC";
            pstmt = conn.prepareStatement(
                "SELECT id, sort_order FROM carousel_slides WHERE sort_order " + operator + " ? ORDER BY sort_order " + orderDir + " LIMIT 1");
            pstmt.setInt(1, currentOrder);
            rs = pstmt.executeQuery();
            if (!rs.next()) return false; // 已经是第一个/最后一个
            int neighborId = rs.getInt("id");
            int neighborOrder = rs.getInt("sort_order");
            rs.close(); pstmt.close();

            // 交换 sort_order
            pstmt = conn.prepareStatement("UPDATE carousel_slides SET sort_order = ? WHERE id = ?");
            pstmt.setInt(1, neighborOrder);
            pstmt.setInt(2, id);
            pstmt.executeUpdate(); pstmt.close();

            pstmt = conn.prepareStatement("UPDATE carousel_slides SET sort_order = ? WHERE id = ?");
            pstmt.setInt(1, currentOrder);
            pstmt.setInt(2, neighborId);
            pstmt.executeUpdate();

            return true;
        } finally { DBUtil.close(conn, pstmt, rs); }
    }

    /** 获取单个幻灯片 */
    public CarouselSlide getById(int id) throws SQLException {
        String sql = "SELECT * FROM carousel_slides WHERE id = ?";
        Connection conn = null; PreparedStatement pstmt = null; ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, id);
            rs = pstmt.executeQuery();
            if (rs.next()) return mapSlide(rs);
        } finally { DBUtil.close(conn, pstmt, rs); }
        return null;
    }

    private CarouselSlide mapSlide(ResultSet rs) throws SQLException {
        CarouselSlide s = new CarouselSlide();
        s.setId(rs.getInt("id"));
        s.setType(rs.getString("type"));
        s.setImagePath(rs.getString("image_path"));
        s.setVideoUrl(rs.getString("video_url"));
        s.setTitle(rs.getString("title"));
        s.setSortOrder(rs.getInt("sort_order"));
        s.setIsActive(rs.getInt("is_active"));
        s.setCreatedAt(rs.getTimestamp("created_at"));
        return s;
    }
}
