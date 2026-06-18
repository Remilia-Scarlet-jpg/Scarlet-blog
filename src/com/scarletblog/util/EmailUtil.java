package com.scarletblog.util;

import javax.mail.*;
import javax.mail.internet.*;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.Properties;

/**
 * 红魔馆邮件工具 — 支持 SMTP（本地）和 HTTP API（云端 Render）
 * 发验证邮件和密码重置邮件
 */
public class EmailUtil {

    // 环境变量
    private static final String PROVIDER = System.getenv("MAIL_PROVIDER"); // smtp | resend
    private static final String API_KEY  = System.getenv("MAIL_API_KEY");  // Resend API Key
    private static final String FROM     = System.getenv("MAIL_FROM");     // 发件人，如 "红魔馆 <xxx@resend.dev>"
    private static final String USERNAME = System.getenv("MAIL_USERNAME"); // SMTP 用户名
    private static final String PASSWORD = System.getenv("MAIL_PASSWORD"); // SMTP 密码
    private static final String SITE_URL = System.getenv("SITE_URL");

    private static boolean configured = true;
    private static boolean useHttpApi = false;

    static {
        if ("resend".equalsIgnoreCase(PROVIDER)) {
            if (API_KEY == null || API_KEY.isEmpty() || FROM == null || FROM.isEmpty()) {
                configured = false;
                System.err.println("[Email] ⚠ MAIL_PROVIDER=resend 但 MAIL_API_KEY 或 MAIL_FROM 未设置。");
            } else {
                useHttpApi = true;
                System.out.println("[Email] ✓ Resend HTTP API 已配置: " + FROM);
            }
        } else {
            if (USERNAME == null || USERNAME.isEmpty() || PASSWORD == null || PASSWORD.isEmpty()) {
                configured = false;
                System.err.println("[Email] ⚠ SMTP 未配置（MAIL_USERNAME / MAIL_PASSWORD）。");
            } else {
                System.out.println("[Email] ✓ SMTP 已配置: " + USERNAME);
            }
        }
        if (SITE_URL == null || SITE_URL.isEmpty()) {
            System.err.println("[Email] ⚠ SITE_URL 未设置，邮件链接将使用 localhost。");
        } else {
            System.out.println("[Email] ✓ 站点 URL: " + SITE_URL);
        }
    }

    public static boolean isConfigured() { return configured; }
    public static String getSiteUrl() { return SITE_URL != null ? SITE_URL : "http://localhost:8080/myblog"; }

    public static void sendVerifyEmail(String toEmail, String token) {
        if (!configured) { System.err.println("[Email] 未配置，跳过。"); return; }
        String url = getSiteUrl() + "/blog/verify-email?token=" + token;
        String html = buildEmailHtml("🏰 红魔馆 — 验证你的邮箱", "你在红魔馆登记了邮箱。请点击下方按钮完成验证：", "⚜️ 验证邮箱", url, "此链接 30 分钟内有效。若你未进行此操作，请忽略。");
        String subject = "🏰 红魔馆 — 验证你的邮箱";
        doSend(toEmail, subject, html);
    }

    public static void sendResetEmail(String toEmail, String token) {
        if (!configured) { System.err.println("[Email] 未配置，跳过。"); return; }
        String url = getSiteUrl() + "/blog/forgot-password?token=" + token;
        String html = buildEmailHtml("🔑 红魔馆 — 重置封印密语", "有人（希望是你）请求重置你在红魔馆的封印密语。点击下方按钮设置新密语：", "🔐 重置封印密语", url, "此链接 30 分钟内有效。若你未请求重置，请忽略。");
        String subject = "🔑 红魔馆 — 重置你的封印密语";
        doSend(toEmail, subject, html);
    }

    private static void doSend(String toEmail, String subject, String html) {
        if (useHttpApi) {
            sendViaResend(toEmail, subject, html);
        } else {
            sendViaSmtp(toEmail, subject, html);
        }
    }

    // ===== Resend HTTP API =====
    private static void sendViaResend(String toEmail, String subject, String html) {
        new Thread(() -> {
            try {
                URL url = new URL("https://api.resend.com/emails");
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setRequestMethod("POST");
                conn.setRequestProperty("Authorization", "Bearer " + API_KEY);
                conn.setRequestProperty("Content-Type", "application/json");
                conn.setDoOutput(true);
                conn.setConnectTimeout(10000);
                conn.setReadTimeout(10000);

                String json = "{\"from\":\"" + escapeJson(FROM) + "\","
                    + "\"to\":\"" + escapeJson(toEmail) + "\","
                    + "\"subject\":\"" + escapeJson(subject) + "\","
                    + "\"html\":\"" + escapeJson(html) + "\"}";

                try (OutputStream os = conn.getOutputStream()) {
                    os.write(json.getBytes(StandardCharsets.UTF_8));
                }
                int code = conn.getResponseCode();
                if (code == 200 || code == 201) {
                    System.out.println("[Email] ✓ (Resend) 已发送: " + toEmail);
                } else {
                    byte[] err = conn.getErrorStream().readAllBytes();
                    System.err.println("[Email] ✗ Resend 返回 " + code + ": " + new String(err, StandardCharsets.UTF_8));
                }
            } catch (Exception e) {
                System.err.println("[Email] ✗ Resend 发送失败: " + e.getMessage());
            }
        }, "EmailSender").start();
    }

    // ===== SMTP（本地用） =====
    private static void sendViaSmtp(String toEmail, String subject, String html) {
        new Thread(() -> {
            try {
                Properties props = new Properties();
                props.put("mail.smtp.host", "smtp.qq.com");
                props.put("mail.smtp.port", "587");
                props.put("mail.smtp.auth", "true");
                props.put("mail.smtp.starttls.enable", "true");
                props.put("mail.smtp.connectiontimeout", "10000");
                props.put("mail.smtp.timeout", "10000");

                Session session = Session.getInstance(props, new Authenticator() {
                    protected PasswordAuthentication getPasswordAuthentication() {
                        return new PasswordAuthentication(USERNAME, PASSWORD);
                    }
                });
                Message msg = new MimeMessage(session);
                msg.setFrom(new InternetAddress(USERNAME, "红魔馆"));
                msg.setRecipient(Message.RecipientType.TO, new InternetAddress(toEmail));
                msg.setSubject(subject);
                msg.setContent(html, "text/html;charset=UTF-8");
                Transport.send(msg);
                System.out.println("[Email] ✓ (SMTP) 已发送: " + toEmail);
            } catch (Exception e) {
                System.err.println("[Email] ✗ SMTP 发送失败: " + e.getMessage());
            }
        }, "EmailSender").start();
    }

    // ===== HTML 模板 =====
    private static String buildEmailHtml(String title, String body, String btnText, String linkUrl, String footer) {
        return "<div style=\"max-width:500px;margin:0 auto;font-family:'SimSun',serif;background:linear-gradient(180deg,#1a0a0a,#0d0505);border:1px solid #4a0000;border-radius:8px;padding:30px;color:#d0c0a0;\">"
            + "<div style=\"text-align:center;font-size:3rem;margin-bottom:10px;\">🏰</div>"
            + "<h2 style=\"color:#d4af37;text-align:center;letter-spacing:3px;\">红 魔 馆</h2>"
            + "<p style=\"color:#8b0000;text-align:center;font-style:italic;\">~ Scarlet Devil Mansion ~</p>"
            + "<hr style=\"border-color:#4a0000;margin:20px 0;\">"
            + "<p style=\"color:#d0c0a0;\">" + body + "</p>"
            + "<div style=\"text-align:center;margin:25px 0;\">"
            + "<a href=\"" + linkUrl + "\" style=\"display:inline-block;background:linear-gradient(180deg,#8b0000,#4a0000);color:#d4af37;padding:12px 40px;text-decoration:none;border-radius:4px;font-size:1.1rem;letter-spacing:2px;border:1px solid #d4af37;\">" + btnText + "</a>"
            + "</div>"
            + "<p style=\"color:#a08060;font-size:0.85rem;\">如果按钮无法点击，请复制以下链接到浏览器：</p>"
            + "<p style=\"color:#8b0000;font-size:0.8rem;word-break:break-all;\">" + linkUrl + "</p>"
            + "<hr style=\"border-color:#4a0000;margin:20px 0;\">"
            + "<p style=\"color:#6a5050;font-size:0.75rem;text-align:center;\">" + footer + "</p>"
            + "</div>";
    }

    private static String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t");
    }
}
