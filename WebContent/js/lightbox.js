/**
 * 红魔馆图片 Lightbox — 点击放大 / 双击图片
 * 触屏可双指缩放，桌面端点击关闭
 */
(function() {
    var overlay, imgEl, closeBtn;
    var isOpen = false;

    function create() {
        if (overlay) return;

        overlay = document.createElement('div');
        overlay.className = 'img-lightbox-overlay';

        imgEl = document.createElement('img');
        imgEl.alt = '';
        overlay.appendChild(imgEl);

        closeBtn = document.createElement('div');
        closeBtn.className = 'img-lightbox-close';
        closeBtn.innerHTML = '&times;';
        closeBtn.title = '关闭';
        document.body.appendChild(closeBtn);

        document.body.appendChild(overlay);

        // 点击遮罩关闭
        overlay.addEventListener('click', close);

        // 关闭按钮
        closeBtn.addEventListener('click', function(e) {
            e.stopPropagation();
            close();
        });

        // ESC 关闭
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape' && isOpen) close();
        });
    }

    function open(src) {
        create();
        imgEl.src = src;
        overlay.classList.remove('closing');
        overlay.classList.add('active');
        closeBtn.classList.add('show');
        isOpen = true;
        document.body.style.overflow = 'hidden';
    }

    function close() {
        if (!isOpen) return;
        overlay.classList.add('closing');
        overlay.classList.remove('active');
        closeBtn.classList.remove('show');
        isOpen = false;
        document.body.style.overflow = '';
        setTimeout(function() {
            overlay.classList.remove('closing');
        }, 200);
    }

    // 绑定文章内容区图片
    function bindImages() {
        var containers = document.querySelectorAll('.article-content');
        containers.forEach(function(container) {
            container.addEventListener('click', function(e) {
                var target = e.target;
                if (target.tagName === 'IMG') {
                    e.preventDefault();
                    open(target.src);
                }
            });
        });
    }

    // 初始化
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', bindImages);
    } else {
        bindImages();
    }
})();
