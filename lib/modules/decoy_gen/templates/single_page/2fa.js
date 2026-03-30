/**
 * CubiVeil 2FA.js - Двухфакторная аутентификация
 */

(function() {
    'use strict';

    // Сообщения об ошибках
    const ERROR_MESSAGES = [
        'Неверный код',
        'Код истёк',
        'Неверный код. Попробуйте ещё раз',
        'Слишком много попыток',
        'Требуется повторная аутентификация',
        'Аккаунт заблокирован',
        'Неверный пароль',
        'Сессия истекла'
    ];

    function init() {
        const form = document.getElementById('2fa-form');
        if (!form) return;

        const codeInput = document.getElementById('code');

        // Автофокус на поле ввода
        if (codeInput) {
            codeInput.focus();

            // Автоматическая отправка при вводе 6 цифр
            codeInput.addEventListener('input', function() {
                // Удаляем нецифровые символы
                this.value = this.value.replace(/[^0-9]/g, '');

                if (this.value.length === 6) {
                    form.requestSubmit();
                }
            });
        }

        form.addEventListener('submit', function(e) {
            e.preventDefault();

            const errorEl = document.getElementById('error-message');
            const submitBtn = form.querySelector('button[type="submit"]');
            const code = codeInput?.value || '';

            if (!code || code.length !== 6) {
                showError(errorEl, 'Введите 6-значный код');
                return;
            }

            // Имитация проверки
            if (submitBtn) {
                submitBtn.disabled = true;
                submitBtn.textContent = 'Проверка...';
            }

            setTimeout(() => {
                // Всегда ошибка (фейковая 2FA)
                const randomError = ERROR_MESSAGES[Math.floor(Math.random() * ERROR_MESSAGES.length)];
                showError(errorEl, '❌ ' + randomError);

                if (submitBtn) {
                    submitBtn.disabled = false;
                    submitBtn.textContent = 'Подтвердить';
                }

                // Очищаем поле
                if (codeInput) {
                    codeInput.value = '';
                    codeInput.focus();
                }
            }, 800 + Math.random() * 700);
        });
    }

    function showError(element, message) {
        if (element) {
            element.textContent = message;
            element.style.display = 'block';
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
