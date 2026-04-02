// auth.js — Обработка авторизации для decoy-сайтов CubiVeil
// Всегда показывает ошибку "пользователь не найден"

// Локализация сообщений об ошибках
const ERROR_MESSAGES = {
    en: {
        fillAllFields: 'Please fill in all fields',
        userNotFound: 'User with this username was not found in the database'
    },
    ru: {
        fillAllFields: 'Пожалуйста, заполните все поля',
        userNotFound: 'Пользователь с таким логином не найден в базе данных'
    }
};

// Получение языка из window.SITE_CONFIG или fallback на русский
function getLanguage() {
    if (typeof window.SITE_CONFIG !== 'undefined' && window.SITE_CONFIG) {
        return window.SITE_CONFIG.language || 'ru';
    }
    return 'ru';
}

// Получение локализованного сообщения
function getMessage(key) {
    const lang = getLanguage();
    const messages = ERROR_MESSAGES[lang] || ERROR_MESSAGES.ru;
    return messages[key] || ERROR_MESSAGES.ru[key];
}

document.addEventListener('DOMContentLoaded', function() {
    const loginForm = document.getElementById('login-form');
    const errorMessage = document.getElementById('error-message');

    if (loginForm) {
        loginForm.addEventListener('submit', function(e) {
            e.preventDefault(); // Предотвращаем отправку формы

            const username = document.getElementById('username').value.trim();
            const password = document.getElementById('password').value.trim();

            // Проверяем, что поля заполнены
            if (!username || !password) {
                showError(getMessage('fillAllFields'));
                return;
            }

            // Имитируем проверку (всегда неудачно)
            showError(getMessage('userNotFound'));
        });
    }

    function showError(message) {
        if (errorMessage) {
            errorMessage.textContent = message;
            errorMessage.style.display = 'block';

            // Автоматически скрываем через 5 секунд
            setTimeout(() => {
                errorMessage.style.display = 'none';
            }, 5000);
        }
    }
});
