/**
 * CubiVeil Settings.js - Страница настроек
 */

(function() {
    'use strict';

    function init() {
        // Обработка форм настроек
        const settingsCards = document.querySelectorAll('.settings-card');

        settingsCards.forEach(card => {
            const saveBtn = card.querySelector('button');
            if (saveBtn && !saveBtn.classList.contains('btn-danger')) {
                saveBtn.addEventListener('click', function(e) {
                    e.preventDefault();
                    showNotification('Настройки сохранены', 'success');
                });
            }
        });

        // Опасная кнопка
        const dangerBtn = document.querySelector('.settings-card.danger .btn-danger');
        if (dangerBtn) {
            dangerBtn.addEventListener('click', function() {
                if (confirm('Вы уверены? Это действие нельзя отменить.')) {
                    showNotification('Функция недоступна в демо-режиме', 'error');
                }
            });
        }

        // Переключатели
        const toggles = document.querySelectorAll('.toggle-label input[type="checkbox"]');
        toggles.forEach(toggle => {
            toggle.addEventListener('change', function() {
                showNotification('Настройка применена', 'success');
            });
        });
    }

    function showNotification(message, type = 'info') {
        // Удаляем существующие уведомления
        const existing = document.querySelector('.notification');
        if (existing) existing.remove();

        const notification = document.createElement('div');
        notification.className = 'notification';
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 12px 20px;
            border-radius: 8px;
            background: ${type === 'success' ? '#16a34a' : type === 'error' ? '#dc2626' : '#3b82f6'};
            color: white;
            font-weight: 500;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            z-index: 1000;
            animation: slideIn 0.3s ease;
        `;
        notification.textContent = message;

        document.body.appendChild(notification);

        setTimeout(() => {
            notification.style.opacity = '0';
            notification.style.transition = 'opacity 0.3s';
            setTimeout(() => notification.remove(), 300);
        }, 3000);
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
