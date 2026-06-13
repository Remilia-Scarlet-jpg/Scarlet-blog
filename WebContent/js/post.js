// ============================================
// 红魔馆博客 - 文章详情页逻辑
// ============================================

let currentPostId = null;

document.addEventListener('DOMContentLoaded', () => {
    const postId = getUrlParam('id');
    if (!postId) {
        document.getElementById('articleContent').innerHTML = `
            <div class="empty-state">
                <div class="empty-icon">🔍</div>
                <p>未指定文章ID</p>
                <a href="/" style="color:var(--gold);margin-top:15px;display:inline-block;">← 返回大厅</a>
            </div>`;
        return;
    }

    currentPostId = parseInt(postId);
    loadPost(currentPostId);
});

/** 加载文章详情 */
async function loadPost(id) {
    const container = document.getElementById('articleContent');
    container.innerHTML = '<div class="loading-spinner">正在加载文章...</div>';

    try {
        const result = await ScarletAPI.posts.get(id);
        const post = result.data;

        document.title = `${post.title} - 红魔馆博客`;

        const catBadge = post.category_name
            ? `<span class="post-card-category">${post.category_icon || '📜'} ${post.category_name}</span>`
            : '';

        container.innerHTML = `
            <div class="post-card-meta" style="margin-bottom:20px;">
                ${catBadge}
                <span>📅 ${formatDate(post.created_at)}</span>
                <span>✍️ ${post.author}</span>
                <span>👁️ ${post.view_count} 次</span>
                ${post.tags ? post.tags.split(',').map(t =>
                    `<span class="post-card-tag">#${t.trim()}</span>`
                ).join('') : ''}
            </div>
            <h1>${post.title}</h1>
            <div class="article-content-body">
                ${post.content}
            </div>
            <div style="margin-top:30px;padding-top:20px;border-top:1px solid var(--border-dark);
                display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:10px;">
                <a href="/" style="color:var(--gold);text-decoration:none;">← 返回大厅</a>
                <span style="color:var(--text-muted);font-size:0.8rem;">
                    最后更新: ${formatDateTime(post.updated_at)}
                </span>
            </div>`;

        loadComments(post.comments || []);
        document.getElementById('commentsSection').style.display = 'block';

    } catch (err) {
        container.innerHTML = `
            <div class="empty-state">
                <div class="empty-icon">💥</div>
                <p>加载文章失败</p>
                <a href="/" style="color:var(--gold);margin-top:15px;display:inline-block;">← 返回大厅</a>
            </div>`;
    }
}

/** 显示评论列表 */
function loadComments(comments) {
    const list = document.getElementById('commentsList');

    if (comments.length === 0) {
        list.innerHTML = `
            <div style="text-align:center;padding:20px;color:var(--text-muted);">
                <p>还没有人评论。</p>
                <p style="font-size:0.85rem;">成为第一个留言的访客吧？</p>
            </div>`;
        return;
    }

    list.innerHTML = comments.map(c => `
        <div class="comment-item">
            <div class="comment-author">💭 ${c.author}</div>
            <div class="comment-date">${formatDateTime(c.created_at)}</div>
            <div class="comment-content">${c.content}</div>
        </div>
    `).join('');
}

/** 提交评论 */
async function submitComment() {
    const author = document.getElementById('commentAuthor').value.trim();
    const content = document.getElementById('commentContent').value.trim();

    if (!content) {
        alert('请填写评论内容！');
        return;
    }

    const btn = document.querySelector('.comment-form .btn-scarlet');
    btn.disabled = true;
    btn.textContent = '提交中...';

    try {
        await ScarletAPI.comments.create({
            post_id: currentPostId,
            author: author || '匿名访客',
            content: content
        });

        document.getElementById('commentAuthor').value = '';
        document.getElementById('commentContent').value = '';

        const result = await ScarletAPI.posts.get(currentPostId);
        loadComments(result.data.comments || []);

        showToast('评论发布成功！感谢留言 ✨');
    } catch (err) {
        alert('评论发布失败: ' + err.message);
    } finally {
        btn.disabled = false;
        btn.textContent = '📝 发布评论';
    }
}
