package com.scarletblog.dao;

import com.scarletblog.model.ChatRoom;
import com.scarletblog.model.Message;
import com.scarletblog.util.DBUtil;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * 茶话会 DAO — 茶室管理 + 消息收发
 */
public class ChatDAO {

    /** 获取用户的茶室列表（含最后消息预览） */
    public List<ChatRoom> getRoomsForUser(int userId) throws SQLException {
        List<ChatRoom> list = new ArrayList<>();
        String sql = "SELECT cr.*, " +
            "COUNT(DISTINCT m2.id) AS member_count, " +
            "(SELECT content FROM messages WHERE room_id = cr.id ORDER BY created_at DESC LIMIT 1) AS last_message, " +
            "(SELECT created_at FROM messages WHERE room_id = cr.id ORDER BY created_at DESC LIMIT 1) AS last_message_time " +
            "FROM chat_rooms cr " +
            "JOIN chat_room_members crm ON cr.id = crm.room_id " +
            "LEFT JOIN chat_room_members m2 ON cr.id = m2.room_id " +
            "WHERE crm.user_id = ? " +
            "GROUP BY cr.id ORDER BY cr.type ASC, cr.created_at DESC";
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, userId);
            rs = pstmt.executeQuery();
            while (rs.next()) {
                list.add(mapRoom(rs));
            }
        } finally {
            DBUtil.close(conn, pstmt, rs);
        }
        return list;
    }

    /** 获取单个茶室信息 */
    public ChatRoom getRoomById(int roomId) throws SQLException {
        String sql = "SELECT cr.*, " +
            "COUNT(crm.id) AS member_count " +
            "FROM chat_rooms cr " +
            "LEFT JOIN chat_room_members crm ON cr.id = crm.room_id " +
            "WHERE cr.id = ? GROUP BY cr.id";
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, roomId);
            rs = pstmt.executeQuery();
            if (rs.next()) return mapRoom(rs);
        } finally {
            DBUtil.close(conn, pstmt, rs);
        }
        return null;
    }

    /** 创建私人茶室（接受友人邀请时自动创建） */
    public int createPrivateRoom(int userId1, int userId2) throws SQLException {
        // 先检查是否已有私人茶室
        String checkSql = "SELECT cr.id FROM chat_rooms cr " +
            "JOIN chat_room_members crm1 ON cr.id = crm1.room_id AND crm1.user_id = ? " +
            "JOIN chat_room_members crm2 ON cr.id = crm2.room_id AND crm2.user_id = ? " +
            "WHERE cr.type = 'private'";
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(checkSql);
            pstmt.setInt(1, userId1);
            pstmt.setInt(2, userId2);
            rs = pstmt.executeQuery();
            if (rs.next()) {
                // 已有私人茶室，直接返回 ID
                int existingId = rs.getInt(1);
                DBUtil.close(null, pstmt, rs);
                return existingId;
            }
            DBUtil.close(null, pstmt, rs);

            // 获取两人昵称作为茶室名
            String name = getNickname(conn, userId1) + " & " + getNickname(conn, userId2) + " 的茶室";

            // 创建茶室
            pstmt = conn.prepareStatement(
                "INSERT INTO chat_rooms (name, type, created_by) VALUES (?, 'private', ?)",
                Statement.RETURN_GENERATED_KEYS);
            pstmt.setString(1, name);
            pstmt.setInt(2, userId1);
            pstmt.executeUpdate();
            rs = pstmt.getGeneratedKeys();
            int roomId = rs.next() ? rs.getInt(1) : -1;
            DBUtil.close(null, pstmt, rs);

            if (roomId > 0) {
                // 添加双方为成员
                pstmt = conn.prepareStatement(
                    "INSERT INTO chat_room_members (room_id, user_id) VALUES (?, ?), (?, ?)");
                pstmt.setInt(1, roomId);
                pstmt.setInt(2, userId1);
                pstmt.setInt(3, roomId);
                pstmt.setInt(4, userId2);
                pstmt.executeUpdate();
            }
            return roomId;
        } finally {
            DBUtil.close(conn, pstmt, rs);
        }
    }

    /** 创建公共茶室（管理员） */
    public int createPublicRoom(String name, int createdBy) throws SQLException {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(
                "INSERT INTO chat_rooms (name, type, created_by) VALUES (?, 'public', ?)",
                Statement.RETURN_GENERATED_KEYS);
            pstmt.setString(1, name);
            pstmt.setInt(2, createdBy);
            pstmt.executeUpdate();
            rs = pstmt.getGeneratedKeys();
            if (rs.next()) {
                return rs.getInt(1);
            }
            return -1;
        } finally {
            DBUtil.close(conn, pstmt, rs);
        }
    }

    /** 新注册用户自动加入所有公共茶室 */
    public void addUserToPublicRooms(int userId) throws SQLException {
        Connection conn = null;
        PreparedStatement pstmt = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(
                "INSERT IGNORE INTO chat_room_members (room_id, user_id) " +
                "SELECT id, ? FROM chat_rooms WHERE type = 'public'");
            pstmt.setInt(1, userId);
            pstmt.executeUpdate();
        } finally {
            DBUtil.close(conn, pstmt, null);
        }
    }

    /** 添加全部注册用户到公共茶室 */
    public void addAllUsersToRoom(int roomId) throws SQLException {
        Connection conn = null;
        PreparedStatement pstmt = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(
                "INSERT INTO chat_room_members (room_id, user_id) " +
                "SELECT ?, id FROM users " +
                "WHERE NOT EXISTS (SELECT 1 FROM chat_room_members WHERE room_id = ? AND user_id = users.id)");
            pstmt.setInt(1, roomId);
            pstmt.setInt(2, roomId);
            pstmt.executeUpdate();
        } finally {
            DBUtil.close(conn, pstmt, null);
        }
    }

    /** 检查用户是否茶室成员 */
    public boolean isMember(int roomId, int userId) throws SQLException {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(
                "SELECT COUNT(*) FROM chat_room_members WHERE room_id = ? AND user_id = ?");
            pstmt.setInt(1, roomId);
            pstmt.setInt(2, userId);
            rs = pstmt.executeQuery();
            if (rs.next()) return rs.getInt(1) > 0;
            return false;
        } finally {
            DBUtil.close(conn, pstmt, rs);
        }
    }

    /** 获取茶室消息（支持 sinceId 增量轮询） */
    public List<Message> getMessages(int roomId, int sinceId, int limit) throws SQLException {
        List<Message> list = new ArrayList<>();
        String sql = "SELECT m.*, u.username AS s_username, u.nickname AS s_nickname, u.avatar AS s_avatar " +
            "FROM messages m JOIN users u ON m.sender_id = u.id " +
            "WHERE m.room_id = ? AND (? = 0 OR m.id > ?) " +
            "ORDER BY m.id ASC LIMIT ?";
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, roomId);
            pstmt.setInt(2, sinceId);
            pstmt.setInt(3, sinceId);
            pstmt.setInt(4, limit);
            rs = pstmt.executeQuery();
            while (rs.next()) {
                list.add(mapMessage(rs));
            }
        } finally {
            DBUtil.close(conn, pstmt, rs);
        }
        return list;
    }

    /** 发送消息 */
    public int sendMessage(int roomId, int senderId, String content) throws SQLException {
        Connection conn = null;
        PreparedStatement pstmt = null;
        try {
            conn = DBUtil.getConnection();
            pstmt = conn.prepareStatement(
                "INSERT INTO messages (room_id, sender_id, content) VALUES (?, ?, ?)",
                Statement.RETURN_GENERATED_KEYS);
            pstmt.setInt(1, roomId);
            pstmt.setInt(2, senderId);
            pstmt.setString(3, content);
            pstmt.executeUpdate();
            ResultSet rs = pstmt.getGeneratedKeys();
            if (rs.next()) return rs.getInt(1);
            return -1;
        } finally {
            DBUtil.close(conn, pstmt, null);
        }
    }

    private String getNickname(Connection conn, int userId) throws SQLException {
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        try {
            pstmt = conn.prepareStatement("SELECT nickname FROM users WHERE id = ?");
            pstmt.setInt(1, userId);
            rs = pstmt.executeQuery();
            if (rs.next()) return rs.getString("nickname");
            return "住人";
        } finally {
            DBUtil.close(null, pstmt, rs);
        }
    }

    private ChatRoom mapRoom(ResultSet rs) throws SQLException {
        ChatRoom r = new ChatRoom();
        r.setId(rs.getInt("id"));
        r.setName(rs.getString("name"));
        r.setType(rs.getString("type"));
        r.setCreatedBy(rs.getInt("created_by"));
        r.setCreatedAt(rs.getTimestamp("created_at"));
        try { r.setMemberCount(rs.getInt("member_count")); } catch (SQLException e) {}
        try { r.setLastMessage(rs.getString("last_message")); } catch (SQLException e) {}
        try { r.setLastMessageTime(rs.getTimestamp("last_message_time")); } catch (SQLException e) {}
        return r;
    }

    private Message mapMessage(ResultSet rs) throws SQLException {
        Message m = new Message();
        m.setId(rs.getInt("id"));
        m.setRoomId(rs.getInt("room_id"));
        m.setSenderId(rs.getInt("sender_id"));
        m.setContent(rs.getString("content"));
        m.setCreatedAt(rs.getTimestamp("created_at"));
        try { m.setSenderUsername(rs.getString("s_username")); } catch (SQLException e) {}
        try { m.setSenderNickname(rs.getString("s_nickname")); } catch (SQLException e) {}
        try { m.setSenderAvatar(rs.getString("s_avatar")); } catch (SQLException e) {}
        return m;
    }
}
