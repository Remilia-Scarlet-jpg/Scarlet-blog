// ============================================
// 红魔馆博客 - 管理后台逻辑
// 文章的 CRUD 操作全部在这里管理
// ============================================

let isEditing = false;

document.addEventListener('DOMContentLoaded', () => {
    loadStats();
    loadPostsTable();
    loadCategoryOptions();
});

// ============================================
// 📊 统计
// ============================================
async function loadStats() {
    try {
        const result = await ScarletAPI.stats.get();
        document.getElementById('statPosts').textContent = result.data.posts;
        document.getElementById('statComments').textContent = result.data.comments;
        document.getElementById('statViews').textContent = result.data.totalViews;
        document.getElementById('statCategories').textContent = result.data.categories;
    } catch (err) {
        console.error('获取统计失败:', err);
    }
}

// ============================================
// 📋 文章列表
// ============================================
async function loadPostsTable() {
    const tbody = document.getElementById('adminTableBody');
    tbody.innerHTML = '<tr><td colspan="8"><div class="loading-spinner">加载中...</div></td></tr>';

    try {
        const result = await ScarletAPI.posts.list({ limit: 100 });
        const posts = result.data;

        if (posts.length === 0) {
            tbody.innerHTML = `<tr><td colspan="8">
                <div class="empty-state">
                    <div class="empty-icon">📜</div>
                    <p>还没有文章。点击「新建文章」开始写第一篇吧！</p>
                </div>
            </td></tr>`;
            return;
        }

        tbody.innerHTML = posts.map(post => `
            <tr>
                <td>#${post.id}</td>
                <td><strong>${post.title}</strong></td>
                <td>${post.author}</td>
                <td>${post.category_name ? post.category_icon + ' ' + post.category_name : '—'}</td>
                <td>${post.view_count || 0}</td>
                <td>${post.is_published ? '✅ 公开' : '🔒 隐藏'}</td>
                <td>${formatDate(post.updated_at)}</td>
                <td class="actions">
                    <button class="btn-scarlet-outline" onclick="viewPost(${post.id})" title="预览">👁️</button>
                    <button class="btn-scarlet-outline" onclick="openEditModal(${post.id})" title="编辑">✏️</button>
                    <button class="btn-danger btn-scarlet-outline" onclick="confirmDelete(${post.id}, '${post.title.replace(/'/g, "\\'")}')" title="删除">🗑️</button>
                </td>
            </tr>
        `).join('');

    } catch (err) {
        tbody.innerHTML = `<tr><td colspan="8">
            <div class="empty-state">
                <div class="empty-icon">💥</div>
                <p>加载失败。请检查服务器和数据库连接。</p>
            </div>
        </td></tr>`;
    }
}

// ============================================
// ➕ 新建文章
// ============================================
function openCreateModal() {
    isEditing = false;
    document.getElementById('modalTitle').textContent = '✨ 新建文章';
    document.getElementById('editPostId').value = '';
    document.getElementById('editTitle').value = '';
    document.getElementById('editAuthor').value = '红魔馆之主';
    document.getElementById('editCategory').value = '';
    document.getElementById('editTags').value = '';
    document.getElementById('editContent').value = '';
    document.getElementById('editCoverImage').value = '';
    document.getElementById('editPublished').checked = true;
    document.getElementById('btnSave').textContent = '💾 创建';

    document.getElementById('postModal').classList.add('active');
    loadCategoryOptions();
}

// ============================================
// ✏️ 编辑文章
// ============================================
async function openEditModal(id) {
    try {
        const result = await ScarletAPI.posts.get(id);
        const post = result.data;

        isEditing = true;
        document.getElementById('modalTitle').textContent = '✏️ 编辑文章';
        document.getElementById('editPostId').value = post.id;
        document.getElementById('editTitle').value = post.title;
        document.getElementById('editAuthor').value = post.author;
        document.getElementById('editCategory').value = post.category_id || '';
        document.getElementById('editTags').value = post.tags || '';
        document.getElementById('editContent').value = post.content;
        document.getElementById('editCoverImage').value = post.cover_image || '';
        document.getElementById('editPublished').checked = post.is_published === 1;
        document.getElementById('btnSave').textContent = '💾 更新';

        document.getElementById('postModal').classList.add('active');
        loadCategoryOptions();
    } catch (err) {
        showToast('加载文章失败', 'error');
    }
}

// ============================================
// 💾 保存 (创建 / 更新)
// ============================================
async function savePost() {
    const id = document.getElementById('editPostId').value;
    const title = document.getElementById('editTitle').value.trim();
    const author = document.getElementById('editAuthor').value.trim();
    const categoryId = document.getElementById('editCategory').value;
    const tags = document.getElementById('editTags').value.trim();
    const content = document.getElementById('editContent').value.trim();
    const coverImage = document.getElementById('editCoverImage').value.trim();
    const isPublished = document.getElementById('editPublished').checked ? 1 : 0;

    if (!title) { alert('标题不能为空！'); return; }
    if (!content) { alert('内容不能为空！'); return; }

    const btn = document.getElementById('btnSave');
    btn.disabled = true;
    btn.textContent = '保存中...';

    try {
        const data = {
            title, content, author,
            category_id: categoryId ? parseInt(categoryId) : null,
            tags: tags || null,
            cover_image: coverImage || null,
            is_published: isPublished,
            excerpt: truncate(content, 200)
        };

        if (isEditing) {
            await ScarletAPI.posts.update(id, data);
            showToast('文章已更新！✨');
        } else {
            await ScarletAPI.posts.create(data);
            showToast('新文章创建成功！🎉');
        }

        closeModal();
        loadPostsTable();
        loadStats();
    } catch (err) {
        alert('保存失败: ' + err.message);
        showToast('保存失败', 'error');
    } finally {
        btn.disabled = false;
        btn.textContent = isEditing ? '💾 更新' : '💾 创建';
    }
}

// ============================================
// 🗑️ 删除
// ============================================
function confirmDelete(id, title) {
    if (confirm(`确定要删除吗？\n\n「${title}」\n\n此操作不可撤销。芙兰会把它破坏掉... 💥`)) {
        deletePost(id);
    }
}

async function deletePost(id) {
    try {
        const result = await ScarletAPI.posts.delete(id);
        showToast(result.message);
        loadPostsTable();
        loadStats();
    } catch (err) {
        showToast('删除失败', 'error');
    }
}

// ============================================
// 👁️ 预览
// ============================================
function viewPost(id) {
    window.open(`/post?id=${id}`, '_blank');
}

// ============================================
// ❌ 关闭弹窗
// ============================================
function closeModal() {
    document.getElementById('postModal').classList.remove('active');
}

document.addEventListener('click', (e) => {
    if (e.target.classList.contains('modal-overlay')) {
        closeModal();
    }
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeModal();
});

// ============================================
// 📂 加载分类选项
// ============================================
async function loadCategoryOptions() {
    try {
        const result = await ScarletAPI.categories.list();
        const select = document.getElementById('editCategory');
        select.innerHTML = '<option value="">无分类</option>';

        result.data.forEach(cat => {
            select.innerHTML += `<option value="${cat.id}">${cat.icon} ${cat.name}</option>`;
        });
    } catch (err) {
        console.error('加载分类选项失败:', err);
    }
}
