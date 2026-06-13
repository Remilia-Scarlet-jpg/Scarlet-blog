package com.scarletblog.model;

import java.sql.Timestamp;

/**
 * 博客文章模型
 */
public class Post {
    private int id;
    private String title;
    private String content;
    private String excerpt;
    private String author;
    private int categoryId;
    private String coverImage;
    private String tags;
    private int viewCount;
    private int isPublished;
    private Timestamp createdAt;
    private Timestamp updatedAt;

    // 关联字段
    private String categoryName;
    private String categoryIcon;

    public Post() {}

    // Getters and Setters
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public String getExcerpt() { return excerpt; }
    public void setExcerpt(String excerpt) { this.excerpt = excerpt; }

    public String getAuthor() { return author; }
    public void setAuthor(String author) { this.author = author; }

    public int getCategoryId() { return categoryId; }
    public void setCategoryId(int categoryId) { this.categoryId = categoryId; }

    public String getCoverImage() { return coverImage; }
    public void setCoverImage(String coverImage) { this.coverImage = coverImage; }

    public String getTags() { return tags; }
    public void setTags(String tags) { this.tags = tags; }

    public int getViewCount() { return viewCount; }
    public void setViewCount(int viewCount) { this.viewCount = viewCount; }

    public int getIsPublished() { return isPublished; }
    public void setIsPublished(int isPublished) { this.isPublished = isPublished; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    public Timestamp getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Timestamp updatedAt) { this.updatedAt = updatedAt; }

    public String getCategoryName() { return categoryName; }
    public void setCategoryName(String categoryName) { this.categoryName = categoryName; }

    public String getCategoryIcon() { return categoryIcon; }
    public void setCategoryIcon(String categoryIcon) { this.categoryIcon = categoryIcon; }
}
