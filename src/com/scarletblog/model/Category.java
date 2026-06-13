package com.scarletblog.model;

import java.sql.Timestamp;

public class Category {
    private int id;
    private String name;
    private String description;
    private String icon;
    private int postCount;
    private Timestamp createdAt;

    public Category() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getIcon() { return icon; }
    public void setIcon(String icon) { this.icon = icon; }
    public int getPostCount() { return postCount; }
    public void setPostCount(int postCount) { this.postCount = postCount; }
    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }
}
