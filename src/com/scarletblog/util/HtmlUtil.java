package com.scarletblog.util;

/**
 * HTML/JavaScript 转义工具 — 防 XSS
 */
public class HtmlUtil {

    /**
     * HTML 实体转义 — 用于所有 <%= ... %> 输出
     */
    public static String escape(String s) {
        if (s == null || s.isEmpty()) return "";
        StringBuilder sb = new StringBuilder(s.length() + 16);
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '&':  sb.append("&amp;");  break;
                case '<':  sb.append("&lt;");   break;
                case '>':  sb.append("&gt;");   break;
                case '"':  sb.append("&quot;"); break;
                case '\'': sb.append("&#39;");  break;
                default:   sb.append(c);
            }
        }
        return sb.toString();
    }

    /**
     * JavaScript 字符串转义 — 用于内联 JS 中的动态值
     * 转义 \ ' " 换行 和 </ 序列（防 </script> 注入）
     */
    public static String escapeJs(String s) {
        if (s == null || s.isEmpty()) return "";
        StringBuilder sb = new StringBuilder(s.length() + 16);
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '\\': sb.append("\\\\"); break;
                case '\'': sb.append("\\'");  break;
                case '"':  sb.append("\\\""); break;
                case '\n': sb.append("\\n");  break;
                case '\r': sb.append("\\r");  break;
                case '<':
                    if (i + 1 < s.length() && s.charAt(i + 1) == '/') {
                        sb.append("<\\/");
                        i++;
                    } else {
                        sb.append(c);
                    }
                    break;
                default: sb.append(c);
            }
        }
        return sb.toString();
    }
}
