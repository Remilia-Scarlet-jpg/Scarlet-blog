package com.scarletblog.model;

import java.sql.Timestamp;

/**
 * 友人关系模型 — 茶话会准入
 */
public class Friend {
    private int id;
    private int userId;
    private int friendId;
    private String status;       // pending / accepted / rejected
    private Timestamp createdAt;
    // 关联字段（展示用）
    private String friendUsername;
    private String friendNickname;
    private String friendAvatar;

    public Friend() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }

    public int getFriendId() { return friendId; }
    public void setFriendId(int friendId) { this.friendId = friendId; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    public String getFriendUsername() { return friendUsername; }
    public void setFriendUsername(String friendUsername) { this.friendUsername = friendUsername; }

    public String getFriendNickname() { return friendNickname; }
    public void setFriendNickname(String friendNickname) { this.friendNickname = friendNickname; }

    public String getFriendAvatar() { return friendAvatar; }
    public void setFriendAvatar(String friendAvatar) { this.friendAvatar = friendAvatar; }
}
