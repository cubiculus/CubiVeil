/**
 * CubiVeil Auth.js - Фейковая система авторизации
 * Любой логин/пароль возвращает случайную ошибку
 */

(function() {
    'use strict';

    // Сообщения об ошибках (8 вариантов)
    const ERROR_MESSAGES = [
        'Неверный пароль',
        'Аккаунт заблокирован',
        'Требуется 2FA',
        'Слишком много попыток',
        'Аккаунт не найден',
        'Неверное имя пользователя',
        'Сессия истекла',
        'Требуется подтверждение email'
    ];

    // Ключ для sessionStorage
    const ATTEMPTS_KEY = 'cubiveil_login_attempts';
    const BLOCKED_KEY = 'cubiveil_blocked_until';

    // Проверка блокировки
    function isBlocked() {
        const blockedUntil = sessionStorage.getItem(BLOCKED_KEY);
        if (!blockedUntil) return false;

        const now = Date.now();
        if (now < parseInt(blockedUntil, 10)) {
            const remaining = Math.ceil((parseInt(blockedUntil, 10) - now) / 1000);
            return { blocked: true, remaining: remaining };
        }

        // Блокировка истекла
        sessionStorage.removeItem(BLOCKED_KEY);
        sessionStorage.removeItem(ATTEMPTS_KEY);
        return false;
    }

    // Получение числа попыток
    function getAttempts() {
        return parseInt(sessionStorage.getItem(ATTEMPTS_KEY) || '0', 10);
    }

    // Увеличение числа попыток
    function incrementAttempts() {
        const attempts = getAttempts() + 1;
        sessionStorage.setItem(ATTEMPTS_KEY, attempts.toString());

        // Блокировка после 3 попыток
        if (attempts >= 3) {
            const blockedUntil = Date.now() + (5 * 60 * 1000); // 5 минут
            sessionStorage.setItem(BLOCKED_KEY, blockedUntil.toString());
            return true;
        }
        return false;
    }

    // Сброс попыток
    function resetAttempts() {
        sessionStorage.removeItem(ATTEMPTS_KEY);
        sessionStorage.removeItem(BLOCKED_KEY);
    }

    // Получение случайной ошибки
    function getRandomError() {
        const index = Math.floor(Math.random() * ERROR_MESSAGES.length);
        return ERROR_MESSAGES[index];
    }

    // Показать ошибку
    function showError(message) {
        const errorEl = document.getElementById('error-message');
        if (errorEl) {
            errorEl.textContent = '❌ ' + message;
            errorEl.style.display = 'block';
        }
    }

    // Скрыть ошибку
    function hideError() {
        const errorEl = document.getElementById('error-message');
        if (errorEl) {
            errorEl.style.display = 'none';
        }
    }

    // Обработка формы входа
    function handleLogin(e) {
        e.preventDefault();

        // Проверка блокировки
        const blockStatus = isBlocked();
        if (blockStatus && blockStatus.blocked) {
            showError('Слишком много попыток. Попробуйте через ' + blockStatus.remaining + ' сек.');
            return;
        }

        const form = e.target;
        const username = form.querySelector('#username')?.value || '';
        const password = form.querySelector('#password')?.value || '';

        // Валидация
        if (!username || !password) {
            showError('Введите имя пользователя и пароль');
            return;
        }

        // Увеличиваем счётчик попыток
        const justBlocked = incrementAttempts();

        // Всегда показываем ошибку (фейковая авторизация)
        let errorMessage = getRandomError();

        if (justBlocked) {
            errorMessage = 'Слишком много попыток. Попробуйте через 5 минут.';
        }

        // Имитация задержки сети
        const submitBtn = form.querySelector('button[type="submit"]');
        if (submitBtn) {
            submitBtn.disabled = true;
            submitBtn.textContent = 'Проверка...';
        }

        setTimeout(() => {
            showError(errorMessage);

            if (submitBtn) {
                submitBtn.disabled = false;
                submitBtn.textContent = 'Войти';
            }

            // Если ошибка про 2FA, перенаправляем на страницу 2FA
            if (errorMessage.includes('2FA')) {
                setTimeout(() => {
                    window.location.href = '2fa.html';
                }, 1000);
            }
        }, 800 + Math.random() * 700);
    }

    // Обработка формы 2FA
    function handle2FA(e) {
        e.preventDefault();

        const form = e.target;
        const code = form.querySelector('#code')?.value || '';

        if (!code || code.length !== 6) {
            showError('Введите 6-значный код');
            return;
        }

        // Всегда ошибка
        const submitBtn = form.querySelector('button[type="submit"]');
        if (submitBtn) {
            submitBtn.disabled = true;
            submitBtn.textContent = 'Проверка...';
        }

        setTimeout(() => {
            showError(getRandomError());

            if (submitBtn) {
                submitBtn.disabled = false;
                submitBtn.textContent = 'Подтвердить';
            }
        }, 800 + Math.random() * 700);
    }

    // Обработка формы восстановления пароля
    function handleForgotPassword(e) {
        e.preventDefault();

        const form = e.target;
        const email = form.querySelector('#email')?.value || '';

        if (!email) {
            showError('Введите email');
            return;
        }

        const submitBtn = form.querySelector('button[type="submit"]');
        if (submitBtn) {
            submitBtn.disabled = true;
            submitBtn.textContent = 'Отправка...';
        }

        setTimeout(() => {
            // Всегда показываем успех (безопасность)
            const successEl = document.getElementById('success-message');
            if (successEl) {
                successEl.style.display = 'block';
            }
            hideError();

            if (submitBtn) {
                submitBtn.disabled = false;
                submitBtn.textContent = 'Отправить инструкции';
            }
        }, 1000);
    }

    // Инициализация
    function init() {
        // Форма входа
        const loginForm = document.getElementById('login-form');
        if (loginForm) {
            loginForm.addEventListener('submit', handleLogin);
            hideError();
        }

        // Форма 2FA
        const twoFaForm = document.getElementById('2fa-form');
        if (twoFaForm) {
            twoFaForm.addEventListener('submit', handle2FA);
            hideError();
        }

        // Форма восстановления пароля
        const forgotForm = document.getElementById('forgot-form');
        if (forgotForm) {
            forgotForm.addEventListener('submit', handleForgotPassword);
            hideError();
        }

        // Проверка блокировки при загрузке
        const blockStatus = isBlocked();
        if (blockStatus && blockStatus.blocked) {
            const errorEl = document.getElementById('error-message');
            if (errorEl) {
                errorEl.textContent = 'Слишком много попыток. Попробуйте через ' + blockStatus.remaining + ' сек.';
                errorEl.style.display = 'block';
            }
        }
    }

    // Запуск после загрузки DOM
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
