<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, com.scarletblog.model.Post, com.scarletblog.model.Category, com.scarletblog.model.User" %>
<%@ page import="com.scarletblog.util.HtmlUtil" %>
<%
    List<Post> posts = (List<Post>) request.getAttribute("posts");
    List<Category> categories = (List<Category>) request.getAttribute("categories");
    Integer totalPosts = (Integer) request.getAttribute("totalPosts");
    Integer totalComments = (Integer) request.getAttribute("totalComments");
    Integer totalViews = (Integer) request.getAttribute("totalViews");
    User currentUser = (User) request.getAttribute("currentUser");
    String ctxPath = request.getContextPath();
    java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyy/MM/dd HH:mm");
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>管理室 - 红魔馆博客</title>
    <link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Ctext y='50' font-size='50'%3E⚙️%3C/text%3E%3C/svg%3E">
    <link rel="stylesheet" href="<%=ctxPath%>/css/scarlet.css">
</head>
<body>
    <header class="scarlet-header">
        <div class="header-inner">
            <div class="logo-area">
                <div class="logo-icon">⚙️</div>
                <div class="logo-text">
                    <h1>管 理 室</h1>
                    <span class="subtitle">~ 咲夜的执务室 ~</span>
                </div>
            </div>
            <nav class="nav-links">
                <a href="<%=ctxPath%>/blog">🏠 大厅</a>
                <a href="<%=ctxPath%>/blog/admin" class="active">⚙️ 管理室</a>
                <% if (currentUser != null) { %>
                    <a href="<%=ctxPath%>/blog/chat" title="茶话会">🍵 茶话会</a>
                    <a href="<%=ctxPath%>/blog/profile" title="访客档案" style="display:flex;align-items:center;gap:6px;">
                        <img src="<%= currentUser.getAvatar() != null ? (currentUser.getAvatar().startsWith("data:") ? currentUser.getAvatar() : ctxPath + "/" + currentUser.getAvatar()) : "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Ccircle cx='12' cy='12' r='12' fill='%234a0000'/%3E%3Ctext x='12' y='16' text-anchor='middle' font-size='12'%3E👤%3C/text%3E%3C/svg%3E" %>"
                             style="width:28px;height:28px;border-radius:50%;object-fit:cover;border:1px solid var(--gold);">
                        <span style="color:var(--gold);font-size:0.85rem;"><%= HtmlUtil.escape(currentUser.getNickname()) %></span>
                        <span style="color:var(--text-muted);font-size:0.7rem;">(<%= HtmlUtil.escape(currentUser.getRole()) %>)</span>
                    </a>
                    <a href="<%=ctxPath%>/api/auth/logout" title="离馆" style="color:var(--scarlet-light);border:1px solid var(--scarlet);">🚪 离馆</a>
                <% } else { %>
                    <a href="<%=ctxPath%>/blog/login">⚜️ 入馆</a>
                <% } %>
            </nav>
        </div>
    </header>

    <div class="toast-container" id="toastContainer"></div>

    <div class="main-container full-width">
        <div class="content-area">
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-icon">📝</div>
                    <div class="stat-value"><%= totalPosts != null ? totalPosts : 0 %></div>
                    <div class="stat-label">文章数</div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon">💬</div>
                    <div class="stat-value"><%= totalComments != null ? totalComments : 0 %></div>
                    <div class="stat-label">评论数</div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon">👁️</div>
                    <div class="stat-value"><%= totalViews != null ? totalViews : 0 %></div>
                    <div class="stat-label">总浏览量</div>
                </div>
                <div class="stat-card">
                    <div class="stat-icon">📂</div>
                    <div class="stat-value"><%= categories != null ? categories.size() : 0 %></div>
                    <div class="stat-label">分类数</div>
                </div>
            </div>

            <!-- 管理标签页 -->
            <div class="admin-tabs">
                <button class="admin-tab active" onclick="switchAdminTab('posts')">📋 文章管理</button>
                <button class="admin-tab" onclick="switchAdminTab('categories')">📂 分类管理</button>
            </div>

            <!-- 文章管理 -->
            <div id="admin-tab-posts" class="admin-tab-content active">
                <div class="admin-header">
                    <h2>📋 文章列表</h2>
                    <button class="btn-scarlet" onclick="openCreateModal()">✨ 新建文章</button>
                </div>

                <div style="overflow-x:auto;">
                    <table class="admin-table">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>标题</th>
                                <th>作者</th>
                                <th>分类</th>
                                <th>浏览</th>
                                <th>状态</th>
                                <th>更新日期</th>
                                <th>操作</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (posts != null && !posts.isEmpty()) {
                                for (Post p : posts) {
                                    String catName = p.getCategoryName() != null ? p.getCategoryName() : "-";
                                    String catIcon = p.getCategoryIcon() != null ? p.getCategoryIcon() : "";
                            %>
                            <tr>
                                <td><%= p.getId() %></td>
                                <td><strong><%= HtmlUtil.escape(p.getTitle()) %></strong></td>
                                <td><%= HtmlUtil.escape(p.getAuthor() != null ? p.getAuthor() : "-") %></td>
                                <td><%= HtmlUtil.escape(catIcon) %> <%= HtmlUtil.escape(catName) %></td>
                                <td><%= p.getViewCount() %></td>
                                <td><%= p.getIsPublished() == 1 ? "✅ 公开" : "📝 草稿" %></td>
                                <td><%= p.getUpdatedAt() != null ? sdf.format(p.getUpdatedAt()) : "-" %></td>
                                <td>
                                    <div class="actions" style="display:flex;gap:6px;">
                                        <button class="btn-scarlet-outline btn-edit-post"
                                            data-id="<%=p.getId()%>"
                                            data-title="<%= HtmlUtil.escape(p.getTitle()) %>"
                                            data-content="<%= HtmlUtil.escape(p.getContent() != null ? p.getContent() : "") %>"
                                            data-author="<%= HtmlUtil.escape(p.getAuthor() != null ? p.getAuthor() : "红魔馆之主") %>"
                                            data-category="<%= p.getCategoryId() %>"
                                            data-tags="<%= HtmlUtil.escape(p.getTags() != null ? p.getTags() : "") %>"
                                            data-published="<%= p.getIsPublished() %>"
                                            style="padding:5px 10px;font-size:0.8rem;">✏️</button>
                                        <button class="btn-scarlet-outline btn-danger btn-delete-post"
                                            data-id="<%=p.getId()%>"
                                            style="padding:5px 10px;font-size:0.8rem;">🗑️</button>
                                    </div>
                                </td>
                            </tr>
                            <%     }
                               } else { %>
                            <tr><td colspan="8"><div class="loading-spinner">暂无文章</div></td></tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- 分类管理 -->
            <div id="admin-tab-categories" class="admin-tab-content">
                <div class="admin-header">
                    <h2>📂 分类列表</h2>
                    <button class="btn-scarlet" onclick="openCatModal()">➕ 新建分类</button>
                </div>
                <div style="overflow-x:auto;">
                    <table class="admin-table">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>图标</th>
                                <th>名称</th>
                                <th>描述</th>
                                <th>文章数</th>
                                <th>操作</th>
                            </tr>
                        </thead>
                        <tbody id="catTableBody">
                            <tr><td colspan="6">加载中...</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <!-- 文章编辑弹窗 -->
    <div class="modal-overlay" id="postModal">
        <div class="modal-dialog">
            <div class="modal-header">
                <h3 id="modalTitle">📝 新建文章</h3>
                <button class="modal-close" onclick="closeModal()">✕</button>
            </div>
            <div class="modal-body">
                <form id="postForm" onsubmit="savePost(event)">
                    <input type="hidden" id="editPostId">
                    <div class="form-group">
                        <label>📌 标题 *</label>
                        <input type="text" id="editTitle" placeholder="输入文章标题" maxlength="200" required>
                    </div>
                    <div class="form-group">
                        <label>✍️ 作者</label>
                        <input type="text" id="editAuthor" placeholder="作者名" maxlength="50" value="红魔馆之主">
                    </div>
                    <div class="form-group">
                        <label>📂 分类</label>
                        <select id="editCategory">
                            <option value="">无分类</option>
                            <% if (categories != null) {
                                for (Category c : categories) { %>
                            <option value="<%=c.getId()%>"><%= HtmlUtil.escape(c.getIcon() != null ? c.getIcon() : "") %> <%= HtmlUtil.escape(c.getName()) %></option>
                            <%     }
                               } %>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>🏷️ 标签（逗号分隔）</label>
                        <input type="text" id="editTags" placeholder="例: 东方,红魔馆,Java" maxlength="200">
                    </div>
                    <div class="form-group">
                        <label>📝 内容 *（支持HTML）</label>
                        <textarea id="editContent" placeholder="在这里写下文章内容..." required></textarea>
                    </div>
                    <div class="form-group">
                        <label>🖼️ 封面图片URL</label>
                        <input type="text" id="editCoverImage" placeholder="https://example.com/image.jpg" maxlength="500">
                    </div>
                    <div class="form-group">
                        <label>
                            <input type="checkbox" id="editPublished" checked>
                            公开发布
                        </label>
                    </div>
                    <div class="form-actions">
                        <button type="button" class="btn-scarlet-outline" onclick="closeModal()">取消</button>
                        <button type="submit" class="btn-scarlet">💾 保存</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <footer class="scarlet-footer">
        <div class="footer-ornament">◆ ◇ ◆</div>
        <p>🏰 红魔馆博客 — 管理室</p>
        <p>© 2024 红魔馆 | Powered by Java Servlet &amp; MySQL</p>
    </footer>

    <script>
        var API_BASE = '<%=ctxPath%>/api';
        var ctxPath = '<%=ctxPath%>';

        function openCreateModal() {
            document.getElementById('modalTitle').textContent = '📝 新建文章';
            document.getElementById('editPostId').value = '';
            document.getElementById('editTitle').value = '';
            document.getElementById('editAuthor').value = '红魔馆之主';
            document.getElementById('editCategory').value = '';
            document.getElementById('editTags').value = '';
            document.getElementById('editContent').value = '';
            document.getElementById('editCoverImage').value = '';
            document.getElementById('editPublished').checked = true;
            document.getElementById('postModal').classList.add('active');
        }

        function editPost(id, title, content, author, categoryId, tags, isPublished) {
            document.getElementById('modalTitle').textContent = '✏️ 编辑文章 #' + id;
            document.getElementById('editPostId').value = id;
            document.getElementById('editTitle').value = title;
            document.getElementById('editAuthor').value = author || '红魔馆之主';
            document.getElementById('editCategory').value = categoryId || '';
            document.getElementById('editTags').value = tags || '';
            document.getElementById('editContent').value = content || '';
            document.getElementById('editCoverImage').value = '';
            document.getElementById('editPublished').checked = isPublished == 1;
            document.getElementById('postModal').classList.add('active');
        }

        function closeModal() {
            document.getElementById('postModal').classList.remove('active');
        }

        function savePost(e) {
            e.preventDefault();
            var id = document.getElementById('editPostId').value;
            var data = {
                title: document.getElementById('editTitle').value,
                author: document.getElementById('editAuthor').value,
                category_id: parseInt(document.getElementById('editCategory').value) || null,
                tags: document.getElementById('editTags').value,
                content: document.getElementById('editContent').value,
                cover_image: document.getElementById('editCoverImage').value || null,
                is_published: document.getElementById('editPublished').checked ? 1 : 0
            };

            var method = id ? 'PUT' : 'POST';
            var url = id ? API_BASE + '/posts/' + id : API_BASE + '/posts';

            var xhr = new XMLHttpRequest();
            xhr.open(method, url, true);
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            xhr.onload = function() {
                try {
                    var resp = JSON.parse(xhr.responseText);
                    if (resp.success) {
                        showToast(resp.message || '保存成功！', 'success');
                        closeModal();
                        setTimeout(function() { location.reload(); }, 800);
                    } else {
                        showToast(resp.error || '保存失败', 'error');
                    }
                } catch(e) {
                    showToast('操作失败', 'error');
                }
            };
            var params = [];
            for (var k in data) {
                if (data[k] !== null && data[k] !== undefined) {
                    params.push(encodeURIComponent(k) + '=' + encodeURIComponent(data[k]));
                }
            }
            xhr.send(params.join('&'));
        }

        function deletePost(id) {
            if (!confirm('确定要删除文章 #' + id + ' 吗？此操作不可恢复！')) return;

            var xhr = new XMLHttpRequest();
            xhr.open('DELETE', API_BASE + '/posts/' + id, true);
            xhr.onload = function() {
                try {
                    var resp = JSON.parse(xhr.responseText);
                    if (resp.success) {
                        showToast(resp.message || '文章已删除', 'success');
                        setTimeout(function() { location.reload(); }, 800);
                    } else {
                        showToast(resp.error || '删除失败', 'error');
                    }
                } catch(e) {
                    showToast('删除失败', 'error');
                }
            };
            xhr.send();
        }

        function showToast(message, type) {
            var container = document.getElementById('toastContainer');
            var toast = document.createElement('div');
            toast.className = 'toast ' + (type || 'success');
            toast.textContent = message;
            container.appendChild(toast);
            setTimeout(function() {
                toast.style.opacity = '0';
                toast.style.transition = 'all 0.4s';
                setTimeout(function() { toast.remove(); }, 400);
            }, 3000);
        }

        // Close modal on overlay click
        document.getElementById('postModal').addEventListener('click', function(e) {
            if (e.target === this) closeModal();
        });

        // 事件委托：编辑 / 删除按钮
        document.querySelector('.admin-table tbody').addEventListener('click', function(e) {
            var editBtn = e.target.closest('.btn-edit-post');
            if (editBtn) {
                editPost(
                    parseInt(editBtn.dataset.id),
                    editBtn.dataset.title,
                    editBtn.dataset.content,
                    editBtn.dataset.author,
                    parseInt(editBtn.dataset.category) || 0,
                    editBtn.dataset.tags,
                    parseInt(editBtn.dataset.published)
                );
                return;
            }
            var delBtn = e.target.closest('.btn-delete-post');
            if (delBtn) {
                deletePost(parseInt(delBtn.dataset.id));
            }
        });

        // 点击模态框外部关闭
        document.getElementById('postModal').addEventListener('click', function(e) {
            if (e.target === this) closeModal();
        });

        // ===== 分类管理 =====
        function switchAdminTab(tab) {
            document.querySelectorAll('.admin-tab').forEach(function(t) { t.classList.remove('active'); });
            document.querySelectorAll('.admin-tab-content').forEach(function(c) { c.classList.remove('active'); });
            if (tab === 'posts') {
                document.querySelectorAll('.admin-tab')[0].classList.add('active');
                document.getElementById('admin-tab-posts').classList.add('active');
            } else {
                document.querySelectorAll('.admin-tab')[1].classList.add('active');
                document.getElementById('admin-tab-categories').classList.add('active');
                loadCategories();
            }
        }

        function loadCategories() {
            fetch(API_BASE + '/categories')
                .then(r => r.json())
                .then(d => {
                    if (!d.success) return;
                    var html = '';
                    d.data.forEach(function(c) {
                        html += '<tr>' +
                            '<td>' + c.id + '</td>' +
                            '<td>' + escHtml(c.icon || '📜') + '</td>' +
                            '<td><strong>' + escHtml(c.name) + '</strong></td>' +
                            '<td>' + escHtml(c.description || '-') + '</td>' +
                            '<td>' + (c.post_count || 0) + '</td>' +
                            '<td><div style="display:flex;gap:6px;">' +
                            '<button class="btn-scarlet-outline" onclick="openCatModal(' + c.id + ',\'' + escHtml(c.name) + '\',\'' + escHtml(c.description || '') + '\',\'' + escHtml(c.icon || '') + '\')" style="padding:5px 10px;font-size:0.8rem;">✏️</button>' +
                            '<button class="btn-scarlet-outline btn-danger" onclick="deleteCategory(' + c.id + ')" style="padding:5px 10px;font-size:0.8rem;">🗑️</button>' +
                            '</div></td></tr>';
                    });
                    if (!d.data.length) html = '<tr><td colspan="6">暂无分类</td></tr>';
                    document.getElementById('catTableBody').innerHTML = html;
                });
        }

        function openCatModal(id, name, description, icon) {
            document.getElementById('catModalTitle').textContent = id ? '✏️ 编辑分类' : '➕ 新建分类';
            document.getElementById('editCatId').value = id || '';
            document.getElementById('editCatName').value = name || '';
            document.getElementById('editCatDesc').value = description || '';
            document.getElementById('editCatIcon').value = icon || '📜';
            document.getElementById('catModal').classList.add('active');
        }

        function closeCatModal() {
            document.getElementById('catModal').classList.remove('active');
        }

        function saveCategory(e) {
            e.preventDefault();
            var id = document.getElementById('editCatId').value;
            var name = document.getElementById('editCatName').value.trim();
            var desc = document.getElementById('editCatDesc').value.trim();
            var icon = document.getElementById('editCatIcon').value.trim();
            if (!name) { showToast('请输入分类名称', 'error'); return; }
            var method = id ? 'PUT' : 'POST';
            var url = id ? API_BASE + '/categories/' + id : API_BASE + '/categories';
            var params = 'name=' + encodeURIComponent(name)
                + '&description=' + encodeURIComponent(desc)
                + '&icon=' + encodeURIComponent(icon);
            var xhr = new XMLHttpRequest();
            xhr.open(method, url, true);
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            xhr.onload = function() {
                try {
                    var resp = JSON.parse(xhr.responseText);
                    if (resp.success) {
                        showToast(resp.message || '保存成功！', 'success');
                        closeCatModal();
                        loadCategories();
                    } else {
                        showToast(resp.error || '保存失败', 'error');
                    }
                } catch(e) { showToast('操作失败', 'error'); }
            };
            xhr.send(params);
        }

        function deleteCategory(id) {
            if (!confirm('确定要删除此分类吗？相关文章将变为「未分类」。')) return;
            var xhr = new XMLHttpRequest();
            xhr.open('DELETE', API_BASE + '/categories/' + id, true);
            xhr.onload = function() {
                try {
                    var resp = JSON.parse(xhr.responseText);
                    if (resp.success) { showToast(resp.message, 'success'); loadCategories(); }
                    else { showToast(resp.error, 'error'); }
                } catch(e) { showToast('删除失败', 'error'); }
            };
            xhr.send();
        }

        function escHtml(s) {
            if (!s) return '';
            return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
        }
    </script>

    <!-- 分类编辑弹窗 -->
    <div class="modal-overlay" id="catModal">
        <div class="modal-dialog">
            <div class="modal-header">
                <h3 id="catModalTitle">➕ 新建分类</h3>
                <button class="modal-close" onclick="closeCatModal()">✕</button>
            </div>
            <div class="modal-body">
                <form onsubmit="saveCategory(event)">
                    <input type="hidden" id="editCatId">
                    <div class="form-group">
                        <label>📛 分类名称 *</label>
                        <input type="text" id="editCatName" placeholder="分类名称" maxlength="50" required>
                    </div>
                    <div class="form-group">
                        <label>📝 描述</label>
                        <input type="text" id="editCatDesc" placeholder="简短描述" maxlength="200">
                    </div>
                    <div class="form-group">
                        <label>🎨 图标（emoji）</label>
                        <input type="text" id="editCatIcon" placeholder="📜" maxlength="50">
                    </div>
                    <div class="form-actions">
                        <button type="button" class="btn-scarlet-outline" onclick="closeCatModal()">取消</button>
                        <button type="submit" class="btn-scarlet">💾 保存</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</body>
</html>
