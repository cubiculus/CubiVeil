/**
 * CubiVeil Users.js - Страница пользователей
 */

(function() {
    'use strict';

    function init() {
        if (typeof window.SITE_CONFIG === 'undefined') return;

        const config = window.SITE_CONFIG;

        // Обновляем статистику пользователей
        const userStats = document.querySelectorAll('.user-stat');
        if (userStats.length >= 3 && config.stats?.users) {
            userStats[0].querySelector('.user-stat-value').textContent = config.stats.users.total;
            userStats[1].querySelector('.user-stat-value').textContent = config.stats.users.active;
            userStats[2].querySelector('.user-stat-value').textContent = config.stats.users.online;
        }

        // Динамическая загрузка пользователей
        const usersContainer = document.getElementById('users-container');
        if (usersContainer && config.users) {
            // Очищаем и добавляем пользователей из конфига
            usersContainer.innerHTML = '';

            config.users.slice(0, 12).forEach(user => {
                const userEl = createUserElement(user);
                usersContainer.appendChild(userEl);
            });
        }
    }

    function createUserElement(user) {
        const div = document.createElement('div');
        div.className = 'user-card';

        // Генерируем инициалы
        const initials = getInitials(user.username);

        // Определяем статус
        const statusClass = user.status === 'active' ? 'active' :
                           user.status === 'pending' ? 'active' : 'inactive';
        const statusText = user.status === 'active' ? 'Активен' :
                          user.status === 'pending' ? 'Ожидает' : 'Офлайн';

        div.innerHTML = `
            <div class="user-avatar">${initials}</div>
            <div class="user-info">
                <h4>${user.username}</h4>
                <p>${user.position}</p>
                <span class="user-status ${statusClass}">${statusText}</span>
            </div>
        `;

        return div;
    }

    function getInitials(username) {
        const parts = username.split('.');
        if (parts.length >= 2) {
            return (parts[0][0] + parts[1][0]).toUpperCase();
        }
        return username.substring(0, 2).toUpperCase();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
