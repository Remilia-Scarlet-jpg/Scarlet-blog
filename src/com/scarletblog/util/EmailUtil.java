package com.scarletblog.util;

import javax.mail.*;
import javax.mail.internet.*;
import java.util.Properties;

/**
 * 红魔馆邮件工具 — QQ 邮箱 SMTP
 * 发送验证邮件和密码重置邮件
 */
public class EmailUtil {

    // QQ SMTP 配置
    private static final String SMTP_HOST = "smtp.qq.com";
    private static final int SMTP_PORT = 587;

    // 从环境变量读取发件人配置
    // MAIL_USERNAME = your-email@qq.com
    // MAIL_PASSWORD = QQ邮箱授权码（非QQ密码！）
    private static final String USERNAME = System.getenv("MAIL_USERNAME");
    private static final String PASSWORD = System.getenv("MAIL_PASSWORD");
    private static final String SITE_URL = System.getenv("SITE_URL");

    private static boolean configured = true;

    static {
        if (USERNAME == null || USERNAME.isEmpty() || PASSWORD == null || PASSWORD.isEmpty()) {
            configured = false;
            System.err.println("[Email] ⚠ MAIL_USERNAME 或 MAIL_PASSWORD 环境变量未设置，邮件功能禁用。");
        } else {
            System.out.println("[Email] ✓ 邮件服务已配置: " + USERNAME);
        }
        if (SITE_URL == null || SITE_URL.isEmpty()) {
            System.err.println("[Email] ⚠ SITE_URL 环境变量未设置，邮件中的链接将使用 localhost（可能被 QQ 拦截）。");
            System.err.println("[Email] 请在 setenv.bat 中设置: SITE_URL=http://你的IP:8080/myblog");
        } else {
            System.out.println("[Email] ✓ 站点 URL: " + SITE_URL);
        }
    }

    /** 检查邮件服务是否可用 */
    public static boolean isConfigured() {
        return configured;
    }

    /** 获取站点 URL */
    public static String getSiteUrl() {
        return SITE_URL != null ? SITE_URL : "http://localhost:8080/myblog";
    }

    /**
     * 发送邮箱验证邮件
     * @param toEmail 收件人邮箱
     * @param token   验证 token
     * @param ctxPath 应用 context path（用于构建验证链接）
     */
    public static void sendVerifyEmail(String toEmail, String token) {
        if (!configured) {
            System.err.println("[Email] 邮件服务未配置，跳过发送验证邮件。");
            return;
        }
        String siteUrl = getSiteUrl();
        String verifyUrl = siteUrl + "/blog/verify-email?token=" + token;
        String subject = "🏰 红魔馆 — 验证你的邮箱";
        String html = "<div style=\"max-width:500px;margin:0 auto;font-family:'SimSun',serif;background:linear-gradient(180deg,#1a0a0a,#0d0505);border:1px solid #4a0000;border-radius:8px;padding:30px;color:#d0c0a0;\">"
            + "<div style=\"text-align:center;font-size:3rem;margin-bottom:10px;\">🏰</div>"
            + "<h2 style=\"color:#d4af37;text-align:center;letter-spacing:3px;\">红 魔 馆</h2>"
            + "<p style=\"color:#8b0000;text-align:center;font-style:italic;\">~ Scarlet Devil Mansion ~</p>"
            + "<hr style=\"border-color:#4a0000;margin:20px 0;\">"
            + "<p style=\"color:#d0c0a0;\">你在红魔馆登记了邮箱。请点击下方按钮完成验证：</p>"
            + "<div style=\"text-align:center;margin:25px 0;\">"
            + "<a href=\"" + verifyUrl + "\" style=\"display:inline-block;background:linear-gradient(180deg,#8b0000,#4a0000);color:#d4af37;padding:12px 40px;text-decoration:none;border-radius:4px;font-size:1.1rem;letter-spacing:2px;border:1px solid #d4af37;\">⚜️ 验证邮箱</a>"
            + "</div>"
            + "<p style=\"color:#a08060;font-size:0.85rem;\">如果按钮无法点击，请复制以下链接到浏览器：</p>"
            + "<p style=\"color:#8b0000;font-size:0.8rem;word-break:break-all;\">" + verifyUrl + "</p>"
            + "<hr style=\"border-color:#4a0000;margin:20px 0;\">"
            + "<p style=\"color:#6a5050;font-size:0.75rem;text-align:center;\">此链接 30 分钟内有效。若你未进行此操作，请忽略此邮件。</p>"
            + "</div>";
        send(toEmail, subject, html);
    }

    /**
     * 发送密码重置邮件
     * @param toEmail 收件人邮箱
     * @param token   重置 token
     * @param ctxPath 应用 context path
     */
    public static void sendResetEmail(String toEmail, String token) {
        if (!configured) {
            System.err.println("[Email] 邮件服务未配置，跳过发送重置邮件。");
            return;
        }
        String siteUrl = getSiteUrl();
        String resetUrl = siteUrl + "/blog/forgot-password?token=" + token;
        String subject = "🔑 红魔馆 — 重置你的封印密语";
        String html = "<div style=\"max-width:500px;margin:0 auto;font-family:'SimSun',serif;background:linear-gradient(180deg,#1a0a0a,#0d0505);border:1px solid #4a0000;border-radius:8px;padding:30px;color:#d0c0a0;\">"
            + "<div style=\"text-align:center;font-size:3rem;margin-bottom:10px;\">🔑</div>"
            + "<h2 style=\"color:#d4af37;text-align:center;letter-spacing:3px;\">红 魔 馆</h2>"
            + "<p style=\"color:#8b0000;text-align:center;font-style:italic;\">~ 找回封印密语 ~</p>"
            + "<hr style=\"border-color:#4a0000;margin:20px 0;\">"
            + "<p style=\"color:#d0c0a0;\">有人（希望是你）请求重置你在红魔馆的封印密语。点击下方按钮设置新密语：</p>"
            + "<div style=\"text-align:center;margin:25px 0;\">"
            + "<a href=\"" + resetUrl + "\" style=\"display:inline-block;background:linear-gradient(180deg,#8b0000,#4a0000);color:#d4af37;padding:12px 40px;text-decoration:none;border-radius:4px;font-size:1.1rem;letter-spacing:2px;border:1px solid #d4af37;\">🔐 重置封印密语</a>"
            + "</div>"
            + "<p style=\"color:#a08060;font-size:0.85rem;\">如果按钮无法点击，请复制以下链接到浏览器：</p>"
            + "<p style=\"color:#8b0000;font-size:0.8rem;word-break:break-all;\">" + resetUrl + "</p>"
            + "<hr style=\"border-color:#4a0000;margin:20px 0;\">"
            + "<p style=\"color:#6a5050;font-size:0.75rem;text-align:center;\">此链接 30 分钟内有效。若你未请求重置密码，请忽略此邮件。</p>"
            + "</div>";
        send(toEmail, subject, html);
    }

    /**
     * 发送邮件
     */
    private static void send(String toEmail, String subject, String htmlBody) {
        new Thread(() -> {
            try {
                Properties props = new Properties();
                props.put("mail.smtp.host", SMTP_HOST);
                props.put("mail.smtp.port", String.valueOf(SMTP_PORT));
                props.put("mail.smtp.auth", "true");
                props.put("mail.smtp.starttls.enable", "true");
                props.put("mail.smtp.connectiontimeout", "10000");
                props.put("mail.smtp.timeout", "10000");
                props.put("mail.smtp.writetimeout", "10000");

                Session session = Session.getInstance(props, new Authenticator() {
                    protected PasswordAuthentication getPasswordAuthentication() {
                        return new PasswordAuthentication(USERNAME, PASSWORD);
                    }
                });

                Message message = new MimeMessage(session);
                message.setFrom(new InternetAddress(USERNAME, "红魔馆"));
                message.setRecipient(Message.RecipientType.TO, new InternetAddress(toEmail));
                message.setSubject(subject);
                message.setContent(htmlBody, "text/html;charset=UTF-8");

                Transport.send(message);
                System.out.println("[Email] ✓ 邮件已发送: " + toEmail + " -> " + subject);
            } catch (Exception e) {
                System.err.println("[Email] ✗ 邮件发送失败: " + e.getMessage());
            }
        }, "EmailSender").start();
    }
}
