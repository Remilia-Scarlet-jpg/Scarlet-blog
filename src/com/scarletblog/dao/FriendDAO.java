package com.scarletblog.dao;

import com.scarletblog.model.Friend;
import com.scarletblog.util.DBUtil;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * 友人关系 DAO — 邀请函、接受、拒绝、删除
 */
public class FriendDAO {

    /** 获取已接受的友人列表（双向） */
    public List<Friend> getFriends(int userId) throws SQLException {
        List<Friend> list = new ArrayList<>();
        String sql = "SELECT f.id, f.user_id, f.friend_id, f.status, f.created_at, " +
            "u.username AS f_username, u.nickname AS f_nickname, u.avatar AS f_avatar " +
            "FROM friends f JOIN users u ON u.id = f.friend_id " +
            "WHERE f.user_id = ? AND f.status = 'accepted' " +
            "UNION " +
            "SELECT f.id, f.user_id, f.friend_id, f.status, f.created_at, " +
            "u.username AS f_username, u.nickname AS f_nickname, u.avatar AS f_avatar " +
            "FROM friends f JOIN users u ON u.id = f.user_id " +
            "WHERE f.friend_id = ? AND f.status = 'accepted' " +
            "ORDER BY created_at";
        return queryFriends(sql, userId, userId, list);
    }

    /** 获取已发送的待处理邀请函 */
    public List<Friend> getPendingSent(int userId) throws SQLException {
        List<Friend> list = new ArrayList<>();
        String sql = "SELECT f.id, f.user_id, f.friend_id, f.status, f.created_at, " +
            "u.username AS f_username, u.nickname AS f_nickname, u.avatar AS f_avatar " +
            "FROM friends f JOIN users u ON u.id = f.friend_id " +
            "WHERE f.user_id = ? AND f.status = 'pending' ORDER BY f.created_at DESC";
        return queryFriends(sql, userId, -1, list);
    }

    /** 获取收到的待处理邀请函 */
    public List<Friend> getPendingReceived(int userId) throws SQLException {
        List<Friend> list = new ArrayList<>();
        String sql = "SELECT f.id, f.user_id, f.friend_id, f.status, f.created_at, " +
            "u.username AS f_username, u.nickname AS f_nickname, u.avatar AS f_avatar " +
            "FROM friends f JOIN users u ON u.id = f.user_id " +
            "WHERE f.friend_id = ? AND f.status = 'pending' ORDER BY f.created_at DESC";
        return queryFriends(sql, userId, -1, list);
    }

    private List<Friend> queryFriends(String sql, int param1, int param2, List<Friend> list) throws SQLException {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, param1);
            if (param2 != -1) pstmt.setInt(2, param2);
            rs = pstmt.executeQuery();
            while (rs.next()) {
                list.add(mapFriend(rs));
            }
        } finally {
            DBUtil.close(conn, pstmt, rs);
        }
        return list;
    }

    /** 发送邀请函 */
    public int sendRequest(int fromUserId, int toUserId) throws SQLException {
        Connection conn = null;
        PreparedStatement pstmt = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(
                "INSERT INTO friends (user_id, friend_id, status) VALUES (?, ?, 'pending')",
                Statement.RETURN_GENERATED_KEYS);
            pstmt.setInt(1, fromUserId);
            pstmt.setInt(2, toUserId);
            pstmt.executeUpdate();
            ResultSet rs = pstmt.getGeneratedKeys();
            if (rs.next()) return rs.getInt(1);
            return -1;
        } finally {
            DBUtil.close(conn, pstmt, null);
        }
    }

    /** 接受邀请函 */
    public boolean acceptRequest(int friendshipId) throws SQLException {
        Connection conn = null;
        PreparedStatement pstmt = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(
                "UPDATE friends SET status = 'accepted' WHERE id = ?");
            pstmt.setInt(1, friendshipId);
            return pstmt.executeUpdate() > 0;
        } finally {
            DBUtil.close(conn, pstmt, null);
        }
    }

    /** 拒绝邀请函 */
    public boolean rejectRequest(int friendshipId) throws SQLException {
        Connection conn = null;
        PreparedStatement pstmt = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(
                "UPDATE friends SET status = 'rejected' WHERE id = ?");
            pstmt.setInt(1, friendshipId);
            return pstmt.executeUpdate() > 0;
        } finally {
            DBUtil.close(conn, pstmt, null);
        }
    }

    /** 删除友人 */
    public boolean removeFriend(int friendshipId) throws SQLException {
        Connection conn = null;
        PreparedStatement pstmt = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement("DELETE FROM friends WHERE id = ?");
            pstmt.setInt(1, friendshipId);
            return pstmt.executeUpdate() > 0;
        } finally {
            DBUtil.close(conn, pstmt, null);
        }
    }

    /** 检查是否已存在友人关系（任意方向、pending 或 accepted） */
    public boolean friendshipExists(int userId1, int userId2) throws SQLException {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(
                "SELECT COUNT(*) FROM friends WHERE " +
                "((user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)) " +
                "AND status IN ('pending', 'accepted')");
            pstmt.setInt(1, userId1);
            pstmt.setInt(2, userId2);
            pstmt.setInt(3, userId2);
            pstmt.setInt(4, userId1);
            rs = pstmt.executeQuery();
            if (rs.next()) return rs.getInt(1) > 0;
            return false;
        } finally {
            DBUtil.close(conn, pstmt, rs);
        }
    }

    /** 通过 ID 获取单条友人记录（用于获取双方 userId 后创建私人茶室） */
    public Friend getById(int friendshipId) throws SQLException {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(
                "SELECT f.id, f.user_id, f.friend_id, f.status, f.created_at, " +
                "u.username AS f_username, u.nickname AS f_nickname, u.avatar AS f_avatar " +
                "FROM friends f JOIN users u ON u.id = f.friend_id " +
                "WHERE f.id = ?");
            pstmt.setInt(1, friendshipId);
            rs = pstmt.executeQuery();
            if (rs.next()) return mapFriend(rs);
        } finally {
            DBUtil.close(conn, pstmt, rs);
        }
        return null;
    }

    private Friend mapFriend(ResultSet rs) throws SQLException {
        Friend f = new Friend();
        f.setId(rs.getInt("id"));
        f.setUserId(rs.getInt("user_id"));
        f.setFriendId(rs.getInt("friend_id"));
        f.setStatus(rs.getString("status"));
        f.setCreatedAt(rs.getTimestamp("created_at"));
        try { f.setFriendUsername(rs.getString("f_username")); } catch (SQLException e) {}
        try { f.setFriendNickname(rs.getString("f_nickname")); } catch (SQLException e) {}
        try { f.setFriendAvatar(rs.getString("f_avatar")); } catch (SQLException e) {}
        return f;
    }
}
