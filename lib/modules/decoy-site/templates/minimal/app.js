/**
 * CubiVeil App.js - Основное приложение
 */

(function() {
    'use strict';

    // Инициализация статистики на главной странице
    function initStats() {
        if (typeof window.SITE_CONFIG === 'undefined') return;

        const stats = window.SITE_CONFIG.stats;
        if (!stats) return;

        // Обновляем значения на главной
        const storageEl = document.getElementById('storage-value');
        const usersEl = document.getElementById('users-value');
        const filesEl = document.getElementById('files-value');
        const trafficEl = document.getElementById('traffic-value');

        if (storageEl && stats.storage) {
            storageEl.textContent = stats.storage.total_formatted;
        }
        if (usersEl && stats.users) {
            usersEl.textContent = stats.users.total;
        }
        if (filesEl && stats.content) {
            filesEl.textContent = stats.content.total_files;
        }
        if (trafficEl && stats.traffic) {
            trafficEl.textContent = stats.traffic.daily_formatted;
        }
    }

    // Анимация чисел
    function animateValue(element, start, end, duration) {
        if (!element) return;

        const range = end - start;
        const startTime = performance.now();

        function update(currentTime) {
            const elapsed = currentTime - startTime;
            const progress = Math.min(elapsed / duration, 1);

            // Easing function
            const easeOutQuart = 1 - Math.pow(1 - progress, 4);
            const current = Math.floor(start + (range * easeOutQuart));

            element.textContent = current.toLocaleString('ru-RU');

            if (progress < 1) {
                requestAnimationFrame(update);
            }
        }

        requestAnimationFrame(update);
    }

    // Инициализация
    function init() {
        initStats();

        // Добавляем интерактивности
        const fileItems = document.querySelectorAll('.file-item');
        fileItems.forEach(item => {
            item.addEventListener('click', function() {
                const type = this.dataset.type;
                const name = this.querySelector('.file-name')?.textContent;

                if (type === 'folder') {
                    console.log('Opening folder:', name);
                    // В реальной реализации здесь было бы открытие папки
                } else {
                    console.log('Opening file:', name);
                    // В реальной реализации здесь было бы открытие файла
                }
            });
        });

        // Кнопки действий
        const uploadBtn = document.getElementById('upload-btn');
        if (uploadBtn) {
            uploadBtn.addEventListener('click', function() {
                alert('Функция загрузки файлов будет доступна после авторизации');
            });
        }

        const newFolderBtn = document.getElementById('new-folder-btn');
        if (newFolderBtn) {
            newFolderBtn.addEventListener('click', function() {
                alert('Функция создания папки будет доступна после авторизации');
            });
        }

        // Поиск пользователей
        const userSearch = document.getElementById('user-search');
        if (userSearch) {
            userSearch.addEventListener('input', function() {
                const query = this.value.toLowerCase();
                const userCards = document.querySelectorAll('.user-card');

                userCards.forEach(card => {
                    const name = card.querySelector('.user-info h4')?.textContent?.toLowerCase() || '';
                    const position = card.querySelector('.user-info p')?.textContent?.toLowerCase() || '';

                    if (name.includes(query) || position.includes(query)) {
                        card.style.display = 'flex';
                    } else {
                        card.style.display = 'none';
                    }
                });
            });
        }
    }

    // Запуск после загрузки DOM
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
