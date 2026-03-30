/**
 * CubiVeil Stats.js - Страница статистики
 */

(function() {
    'use strict';

    function init() {
        if (typeof window.SITE_CONFIG === 'undefined') return;

        const config = window.SITE_CONFIG;
        const stats = config.stats;

        if (!stats) return;

        // Заполняем таблицу статистики
        const table = document.querySelector('.stats-table tbody');
        if (table) {
            const rows = [
                ['Всего пользователей', stats.users.total],
                ['Активных пользователей', stats.users.active],
                ['Онлайн сейчас', stats.users.online],
                ['Всего файлов', stats.content.total_files],
                ['Всего папок', stats.content.total_folders],
                ['Общий объём', stats.storage.total_formatted],
                ['Использовано', stats.storage.used_formatted],
                ['Свободно', stats.storage.free_formatted]
            ];

            table.innerHTML = rows.map(([label, value]) => `
                <tr>
                    <td>${label}</td>
                    <td>${value}</td>
                </tr>
            `).join('');
        }

        // Анимация прогресс-бара
        const progressFill = document.querySelector('.progress-fill');
        if (progressFill && stats.storage.usage_percent) {
            setTimeout(() => {
                progressFill.style.width = stats.storage.usage_percent + '%';
            }, 100);
        }

        // Генерация случайных данных для графика активности
        const bars = document.querySelectorAll('.bar-chart .bar');
        bars.forEach(bar => {
            const height = 40 + Math.random() * 50;
            bar.style.height = height + '%';
        });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
