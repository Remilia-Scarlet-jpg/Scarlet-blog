// ============================================
// 🏰 紅魔館ブログ - API通信モジュール
// すべてのAPIリクエストをここで管理
// ============================================

// 自动检测 context path（兼容 /myblog、/ 等不同部署路径）
var CTX_PATH = typeof CTX_PATH !== 'undefined' ? CTX_PATH : (function() {
    var p = window.location.pathname;
    // 从 /<ctx>/blog/... 或 /<ctx>/post 等路径中提取 context path
    var m = p.match(/^(\/[^/]+)\/(?:blog|post|admin|chat|profile|login|register)/);
    return m ? m[1] : '';
})();
const API_BASE = CTX_PATH + '/api';

const ScarletAPI = {
    /**
     * GET リクエスト
     */
    async get(endpoint) {
        try {
            const res = await fetch(`${API_BASE}${endpoint}`);
            const data = await res.json();
            if (!res.ok) throw new Error(data.error || 'APIエラー');
            return data;
        } catch (err) {
            console.error('GET Error:', err);
            throw err;
        }
    },

    /**
     * POST リクエスト
     */
    async post(endpoint, body) {
        try {
            const res = await fetch(`${API_BASE}${endpoint}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(body)
            });
            const data = await res.json();
            if (!res.ok) throw new Error(data.error || 'APIエラー');
            return data;
        } catch (err) {
            console.error('POST Error:', err);
            throw err;
        }
    },

    /**
     * PUT リクエスト
     */
    async put(endpoint, body) {
        try {
            const res = await fetch(`${API_BASE}${endpoint}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(body)
            });
            const data = await res.json();
            if (!res.ok) throw new Error(data.error || 'APIエラー');
            return data;
        } catch (err) {
            console.error('PUT Error:', err);
            throw err;
        }
    },

    /**
     * DELETE リクエスト
     */
    async delete(endpoint) {
        try {
            const res = await fetch(`${API_BASE}${endpoint}`, { method: 'DELETE' });
            const data = await res.json();
            if (!res.ok) throw new Error(data.error || 'APIエラー');
            return data;
        } catch (err) {
            console.error('DELETE Error:', err);
            throw err;
        }
    },

    // ============================================
    // 記事 API
    // ============================================
    posts: {
        list(params = {}) {
            const query = new URLSearchParams(params).toString();
            return ScarletAPI.get(`/posts${query ? '?' + query : ''}`);
        },
        get(id) {
            return ScarletAPI.get(`/posts/${id}`);
        },
        create(data) {
            return ScarletAPI.post('/posts', data);
        },
        update(id, data) {
            return ScarletAPI.put(`/posts/${id}`, data);
        },
        delete(id) {
            return ScarletAPI.delete(`/posts/${id}`);
        }
    },

    // ============================================
    // コメント API
    // ============================================
    comments: {
        list(postId) {
            return ScarletAPI.get(`/posts/${postId}/comments`);
        },
        create(data) {
            return ScarletAPI.post('/comments', data);
        },
        delete(id) {
            return ScarletAPI.delete(`/comments/${id}`);
        }
    },

    // ============================================
    // カテゴリー API
    // ============================================
    categories: {
        list() {
            return ScarletAPI.get('/categories');
        },
        create(data) {
            return ScarletAPI.post('/categories', data);
        },
        update(id, data) {
            return ScarletAPI.put(`/categories/${id}`, data);
        },
        delete(id) {
            return ScarletAPI.delete(`/categories/${id}`);
        }
    },

    // ============================================
    // 統計 API
    // ============================================
    stats: {
        get() {
            return ScarletAPI.get('/stats');
        }
    },

    // ============================================
    // ユーザー API
    // ============================================
    users: {
        get(id) {
            return ScarletAPI.get('/users/' + id);
        }
    }
};

// ============================================
// ユーティリティ関数
// ============================================

/** 日付をフォーマット */
function formatDate(dateStr) {
    const d = new Date(dateStr);
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${y}年${m}月${day}日`;
}

/** 日時をフォーマット */
function formatDateTime(dateStr) {
    const d = new Date(dateStr);
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    const h = String(d.getHours()).padStart(2, '0');
    const min = String(d.getMinutes()).padStart(2, '0');
    return `${y}/${m}/${day} ${h}:${min}`;
}

/** テキストを切り詰め */
function truncate(text, maxLen = 150) {
    if (!text) return '';
    // HTMLタグを除去
    const plain = text.replace(/<[^>]*>/g, '');
    return plain.length > maxLen ? plain.substring(0, maxLen) + '...' : plain;
}

/** URLからパラメータ取得 */
function getUrlParam(name) {
    const params = new URLSearchParams(window.location.search);
    return params.get(name);
}

/** トースト通知を表示 */
function showToast(message, type = 'success') {
    const container = document.getElementById('toastContainer');
    if (!container) return;

    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.textContent = message;
    container.appendChild(toast);

    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transform = 'translateX(120%)';
        toast.style.transition = 'all 0.4s ease';
        setTimeout(() => toast.remove(), 400);
    }, 3500);
}
