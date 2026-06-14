package com.scarletblog.model;

import java.sql.Timestamp;

/**
 * 茶室模型 — 私人 / 公共
 */
public class ChatRoom {
    private int id;
    private String name;
    private String type;         // private / public
    private int createdBy;
    private Timestamp createdAt;
    // 关联字段（展示用）
    private int memberCount;
    private String lastMessage;
    private Timestamp lastMessageTime;

    public ChatRoom() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public int getCreatedBy() { return createdBy; }
    public void setCreatedBy(int createdBy) { this.createdBy = createdBy; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    public int getMemberCount() { return memberCount; }
    public void setMemberCount(int memberCount) { this.memberCount = memberCount; }

    public String getLastMessage() { return lastMessage; }
    public void setLastMessage(String lastMessage) { this.lastMessage = lastMessage; }

    public Timestamp getLastMessageTime() { return lastMessageTime; }
    public void setLastMessageTime(Timestamp lastMessageTime) { this.lastMessageTime = lastMessageTime; }
}
