// ============================================
// 红魔馆博客 - 首页逻辑
// ============================================

let currentPage = 1;
let currentCategory = 'all';
let currentSearch = '';

document.addEventListener('DOMContentLoaded', () => {
    loadPosts();
    loadCategories();
    loadStats();
});

/** 加载文章列表 */
async function loadPosts(page = 1) {
    currentPage = page;
    const container = document.getElementById('posts-container');
    container.innerHTML = '<div class="loading-spinner">正在加载文章...</div>';

    try {
        const params = { page, limit: 10 };
        if (currentCategory !== 'all') params.category = currentCategory;
        if (currentSearch) params.search = currentSearch;

        const result = await ScarletAPI.posts.list(params);

        if (result.data.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <div class="empty-icon">📜</div>
                    <p>未找到相关文章...</p>
                    <p style="font-size:0.9rem;margin-top:10px;">试试其他关键词吧</p>
                </div>`;
            document.getElementById('pagination').innerHTML = '';
            return;
        }

        container.innerHTML = result.data.map(post => createPostCard(post)).join('');
        renderPagination(result.pagination);
    } catch (err) {
        container.innerHTML = `
            <div class="empty-state">
                <div class="empty-icon">💥</div>
                <p>加载文章失败...</p>
                <p style="font-size:0.8rem;color:var(--scarlet-light);">请检查服务器和数据库连接</p>
            </div>`;
    }
}

/** 生成文章卡片HTML */
function createPostCard(post) {
    const tags = post.tags ? post.tags.split(',').map(t =>
        `<a href="#" class="post-card-tag" onclick="searchByTag('${t.trim()}');return false;">#${t.trim()}</a>`
    ).join('') : '';

    const categoryBadge = post.category_name
        ? `<span class="post-card-category">${post.category_icon || '📜'} ${post.category_name}</span>`
        : '';

    return `
        <article class="post-card">
            <div class="post-card-body">
                <div class="post-card-meta">
                    ${categoryBadge}
                    <span>📅 ${formatDate(post.created_at)}</span>
                    <span>✍️ ${post.author}</span>
                </div>
                <h2 class="post-card-title">
                    <a href="post?id=${post.id}">${post.title}</a>
                </h2>
                <p class="post-card-excerpt">${truncate(post.excerpt || post.content, 200)}</p>
                <div class="post-card-footer">
                    <div class="post-card-stats">
                        <span>👁️ ${post.view_count || 0}</span>
                    </div>
                    <div class="post-card-tags">${tags}</div>
                </div>
            </div>
        </article>`;
}

/** 分页 */
function renderPagination(pagination) {
    const container = document.getElementById('pagination');
    if (pagination.totalPages <= 1) {
        container.innerHTML = '';
        return;
    }

    let html = '';
    html += `<button ${pagination.page === 1 ? 'disabled' : ''}
        onclick="loadPosts(${pagination.page - 1})">◀ 上一页</button>`;

    for (let i = 1; i <= pagination.totalPages; i++) {
        html += `<button class="${i === pagination.page ? 'active' : ''}"
            onclick="loadPosts(${i})">${i}</button>`;
    }

    html += `<button ${pagination.page === pagination.totalPages ? 'disabled' : ''}
        onclick="loadPosts(${pagination.page + 1})">下一页 ▶</button>`;

    container.innerHTML = html;
}

/** 加载分类列表 */
async function loadCategories() {
    try {
        const result = await ScarletAPI.categories.list();
        const list = document.getElementById('categoryList');
        list.innerHTML = '<li><a href="#" onclick="filterByCategory(\'all\');return false;">📜 全部文章</a></li>';

        result.data.forEach(cat => {
            list.innerHTML += `
                <li>
                    <a href="#" onclick="filterByCategory('${cat.name}');return false;">
                        ${cat.icon} ${cat.name}
                        <span style="margin-left:auto;font-size:0.8rem;color:var(--text-muted)">(${cat.post_count})</span>
                    </a>
                </li>`;
        });
    } catch (err) {
        console.error('加载分类失败:', err);
    }
}

/** 加载统计 */
async function loadStats() {
    try {
        const result = await ScarletAPI.stats.get();
        const stats = result.data;
        document.getElementById('statsBox').innerHTML = `
            <p>📝 文章: <strong style="color:var(--gold)">${stats.posts}</strong> 篇</p>
            <p>💬 评论: <strong style="color:var(--gold)">${stats.comments}</strong> 条</p>
            <p>👁️ 总浏览: <strong style="color:var(--gold)">${stats.totalViews}</strong> 次</p>
            <p>📂 分类: <strong style="color:var(--gold)">${stats.categories}</strong> 个</p>`;
    } catch (err) {
        document.getElementById('statsBox').innerHTML =
            '<p style="color:var(--scarlet-light)">获取统计失败</p>';
    }
}

/** 按分类筛选 */
function filterByCategory(cat) {
    currentCategory = cat;
    currentSearch = '';
    document.getElementById('searchInput').value = '';
    loadPosts(1);
}

/** 搜索 */
function searchPosts() {
    currentSearch = document.getElementById('searchInput').value.trim();
    currentCategory = 'all';
    loadPosts(1);
}

/** 按标签搜索 */
function searchByTag(tag) {
    currentSearch = tag;
    currentCategory = 'all';
    document.getElementById('searchInput').value = tag;
    loadPosts(1);
    window.scrollTo({ top: 0, behavior: 'smooth' });
}
