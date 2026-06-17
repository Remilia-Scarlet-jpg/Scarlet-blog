package com.scarletblog.model;

import java.sql.Timestamp;

/**
 * 轮播图幻灯片模型 — 支持图片和视频
 */
public class CarouselSlide {
    private int id;
    private String type = "image";  // "image" or "video"
    private String imagePath;
    private String videoUrl;
    private String poster;      // 封面图（视频用）
    private String title;
    private int sortOrder;
    private int isActive = 1;
    private Timestamp createdAt;

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getImagePath() { return imagePath; }
    public void setImagePath(String imagePath) { this.imagePath = imagePath; }

    public String getVideoUrl() { return videoUrl; }
    public void setVideoUrl(String videoUrl) { this.videoUrl = videoUrl; }

    public String getPoster() { return poster; }
    public void setPoster(String poster) { this.poster = poster; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public int getSortOrder() { return sortOrder; }
    public void setSortOrder(int sortOrder) { this.sortOrder = sortOrder; }

    public int getIsActive() { return isActive; }
    public void setIsActive(int isActive) { this.isActive = isActive; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    /** 获取封面 URL（优先 poster → imagePath → YouTube 缩略图） */
    public String getPosterUrl(String ctxPath) {
        // 自定义 poster
        if (poster != null && !poster.isEmpty()) {
            if (poster.startsWith("http")) return poster;
            return ctxPath + "/" + poster;
        }
        // 图片直接返回自身
        if ("image".equals(type) && imagePath != null && !imagePath.isEmpty()) {
            return ctxPath + "/" + imagePath;
        }
        // 视频有本地文件 → 返回本地视频文件路径（浏览器取第一帧）
        if ("video".equals(type) && imagePath != null && !imagePath.isEmpty()) {
            return ctxPath + "/" + imagePath;
        }
        // YouTube 缩略图
        if ("video".equals(type) && videoUrl != null) {
            if (videoUrl.contains("youtube.com/watch?v=")) {
                String vid = videoUrl.substring(videoUrl.indexOf("v=") + 2);
                int amp = vid.indexOf('&');
                if (amp > 0) vid = vid.substring(0, amp);
                return "https://img.youtube.com/vi/" + vid + "/hqdefault.jpg";
            }
            if (videoUrl.contains("youtu.be/")) {
                String vid = videoUrl.substring(videoUrl.lastIndexOf('/') + 1);
                return "https://img.youtube.com/vi/" + vid + "/hqdefault.jpg";
            }
        }
        return null;
    }

    /** @deprecated 使用 getPosterUrl(ctx) 代替 */
    public String getThumbUrl() {
        if (poster != null && !poster.isEmpty()) return poster;
        if ("image".equals(type) && imagePath != null) return imagePath;
        if ("video".equals(type) && videoUrl != null) {
            if (videoUrl.contains("youtube.com/watch?v=")) {
                String vid = videoUrl.substring(videoUrl.indexOf("v=") + 2);
                int amp = vid.indexOf('&');
                if (amp > 0) vid = vid.substring(0, amp);
                return "https://img.youtube.com/vi/" + vid + "/hqdefault.jpg";
            }
            if (videoUrl.contains("youtu.be/")) {
                String vid = videoUrl.substring(videoUrl.lastIndexOf('/') + 1);
                return "https://img.youtube.com/vi/" + vid + "/hqdefault.jpg";
            }
        }
        return null;
    }
}
