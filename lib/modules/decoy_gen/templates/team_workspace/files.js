/**
 * CubiVeil Files.js - Управление файлами
 */

(function() {
    'use strict';

    function init() {
        if (typeof window.SITE_CONFIG === 'undefined') return;

        const config = window.SITE_CONFIG;

        // Обновляем общую статистику
        const totalFilesEl = document.getElementById('total-files');
        const totalFoldersEl = document.getElementById('total-folders');

        if (totalFilesEl && config.stats?.content) {
            totalFilesEl.textContent = config.stats.content.total_files.toLocaleString('ru-RU');
        }
        if (totalFoldersEl && config.stats?.content) {
            totalFoldersEl.textContent = config.stats.content.total_folders.toLocaleString('ru-RU');
        }

        // Динамическая загрузка файлов из конфига
        const filesContainer = document.getElementById('files-container');
        if (filesContainer && config.files) {
            // Добавляем файлы из конфига
            config.files.slice(0, 8).forEach(file => {
                const fileEl = createFileElement(file);
                filesContainer.appendChild(fileEl);
            });
        }
    }

    function createFileElement(file) {
        const div = document.createElement('div');
        div.className = 'file-item file';
        div.dataset.type = 'file';
        div.dataset.ext = file.extension;

        const icon = getFileIcon(file.extension);

        div.innerHTML = `
            <span class="file-icon">${icon}</span>
            <span class="file-name">${file.name}</span>
            <span class="file-meta">${formatSize(file.size)}</span>
        `;

        return div;
    }

    function getFileIcon(ext) {
        const icons = {
            'pdf': '📄',
            'doc': '📝', 'docx': '📝',
            'xls': '📊', 'xlsx': '📊',
            'ppt': '📽️', 'pptx': '📽️',
            'jpg': '🖼️', 'jpeg': '🖼️', 'png': '🖼️', 'gif': '🖼️', 'webp': '🖼️',
            'mp4': '🎬', 'avi': '🎬', 'mov': '🎬',
            'mp3': '🎵', 'wav': '🎵',
            'zip': '📦', 'rar': '📦', '7z': '📦',
            'txt': '📃', 'md': '📃',
            'json': '⚙️', 'xml': '⚙️', 'yaml': '⚙️',
            'py': '🐍', 'js': '📜', 'html': '🌐', 'css': '🎨'
        };
        return icons[ext] || '📄';
    }

    function formatSize(bytes) {
        if (bytes < 1024) return bytes + ' B';
        if (bytes < 1048576) return (bytes / 1024).toFixed(1) + ' KB';
        if (bytes < 1073741824) return (bytes / 1048576).toFixed(1) + ' MB';
        return (bytes / 1073741824).toFixed(1) + ' GB';
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
