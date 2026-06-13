package com.scarletblog.util;

import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import java.security.SecureRandom;
import java.security.spec.KeySpec;
import java.util.Base64;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 红魔馆安全工具
 * - PBKDF2-SHA256 密码哈希（盐值 + 迭代）
 * - 登录失败限流（IP 级别，5 次失败锁 15 分钟）
 */
public class SecurityUtil {

    private static final int ITERATIONS = 120_000;  // PBKDF2 迭代次数
    private static final int KEY_LENGTH = 256;       // 哈希输出长度
    private static final SecureRandom RANDOM = new SecureRandom();

    // ============================================
    // 密码哈希（PBKDF2WithHmacSHA256）
    // ============================================

    /** 对明文密码进行哈希，返回格式: $iterations$base64_salt$base64_hash */
    public static String hashPassword(String password) {
        try {
            byte[] salt = new byte[16];
            RANDOM.nextBytes(salt);
            KeySpec spec = new PBEKeySpec(password.toCharArray(), salt, ITERATIONS, KEY_LENGTH);
            SecretKeyFactory factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");
            byte[] hash = factory.generateSecret(spec).getEncoded();
            return ITERATIONS + "$" + Base64.getEncoder().encodeToString(salt)
                   + "$" + Base64.getEncoder().encodeToString(hash);
        } catch (Exception e) {
            throw new RuntimeException("密码哈希失败", e);
        }
    }

    /** 验证密码 */
    public static boolean verifyPassword(String password, String storedHash) {
        try {
            String[] parts = storedHash.split("\\$");
            if (parts.length != 3) return false;
            int iterations = Integer.parseInt(parts[0]);
            byte[] salt = Base64.getDecoder().decode(parts[1]);
            byte[] expectedHash = Base64.getDecoder().decode(parts[2]);

            KeySpec spec = new PBEKeySpec(password.toCharArray(), salt, iterations, KEY_LENGTH);
            SecretKeyFactory factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");
            byte[] actualHash = factory.generateSecret(spec).getEncoded();

            // 恒定时间比较
            return MessageDigestUtil.constantTimeEquals(expectedHash, actualHash);
        } catch (Exception e) {
            return false;
        }
    }

    // ============================================
    // 登录失败限流
    // ============================================
    private static final int MAX_ATTEMPTS = 5;
    private static final long LOCK_MS = 15 * 60 * 1000; // 15 分钟

    private static class AttemptRecord {
        int count;
        long lockedUntil;
    }

    private static final Map<String, AttemptRecord> attempts = new ConcurrentHashMap<>();

    /** 清除过期记录 */
    private static void cleanUp() {
        long now = System.currentTimeMillis();
        attempts.entrySet().removeIf(e -> e.getValue().lockedUntil > 0 && now > e.getValue().lockedUntil);
    }

    /** 检查 IP 是否被临时封禁 */
    public static boolean isBlocked(String ip) {
        cleanUp();
        AttemptRecord r = attempts.get(ip);
        if (r == null) return false;
        if (r.lockedUntil > 0 && System.currentTimeMillis() < r.lockedUntil) return true;
        return false;
    }

    /** 获取剩余锁定秒数（0 = 未锁定） */
    public static long getBlockSeconds(String ip) {
        AttemptRecord r = attempts.get(ip);
        if (r == null || r.lockedUntil <= 0) return 0;
        long remain = (r.lockedUntil - System.currentTimeMillis()) / 1000;
        return Math.max(0, remain);
    }

    /** 记录一次登录失败 */
    public static void recordFailure(String ip) {
        AttemptRecord r = attempts.computeIfAbsent(ip, k -> new AttemptRecord());
        r.count++;
        if (r.count >= MAX_ATTEMPTS) {
            r.lockedUntil = System.currentTimeMillis() + LOCK_MS;
        }
    }

    /** 登录成功后清除失败记录 */
    public static void clearAttempts(String ip) {
        attempts.remove(ip);
    }
}

/** 内部类：恒定时间字节比较（防时序攻击） */
class MessageDigestUtil {
    static boolean constantTimeEquals(byte[] a, byte[] b) {
        if (a.length != b.length) return false;
        int diff = 0;
        for (int i = 0; i < a.length; i++) {
            diff |= a[i] ^ b[i];
        }
        return diff == 0;
    }
}
