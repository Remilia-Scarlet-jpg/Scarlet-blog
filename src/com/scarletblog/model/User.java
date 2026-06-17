package com.scarletblog.model;

import java.sql.Timestamp;

/**
 * 访客模型 - 入馆通行
 */
public class User {
    private int id;
    private String username;   // 名札
    private String password;   // 封印密语 (hashed)
    private String nickname;   // 称呼
    private String avatar;     // 头像图片路径
    private String background; // 个人主页背景图 (base64)
    private String role;       // 身份: 馆主/女仆长/住人
    private Timestamp createdAt;

    public User() {}

    // Getters and Setters
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getNickname() { return nickname; }
    public void setNickname(String nickname) { this.nickname = nickname; }

    public String getAvatar() { return avatar; }
    public void setAvatar(String avatar) { this.avatar = avatar; }

    public String getBackground() { return background; }
    public void setBackground(String background) { this.background = background; }

    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    /** 是否是馆主或女仆长（管理员） */
    public boolean isAdmin() {
        return "馆主".equals(role) || "女仆长".equals(role);
    }
}
