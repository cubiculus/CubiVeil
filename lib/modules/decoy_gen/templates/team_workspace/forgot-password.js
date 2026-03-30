/**
 * CubiVeil Forgot Password.js - Восстановление пароля
 */

(function() {
    'use strict';

    function init() {
        const form = document.getElementById('forgot-form');
        if (!form) return;

        form.addEventListener('submit', function(e) {
            e.preventDefault();

            const emailInput = document.getElementById('email');
            const errorEl = document.getElementById('error-message');
            const successEl = document.getElementById('success-message');
            const submitBtn = form.querySelector('button[type="submit"]');

            if (!emailInput.value) {
                showError(errorEl, 'Введите email');
                return;
            }

            // Имитация отправки
            if (submitBtn) {
                submitBtn.disabled = true;
                submitBtn.textContent = 'Отправка...';
            }

            setTimeout(() => {
                // Всегда показываем успех (безопасность - не раскрываем существование аккаунтов)
                if (successEl) {
                    successEl.style.display = 'block';
                }
                if (errorEl) {
                    errorEl.style.display = 'none';
                }
                if (submitBtn) {
                    submitBtn.disabled = false;
                    submitBtn.textContent = 'Отправить инструкции';
                }

                // Очищаем форму
                emailInput.value = '';
            }, 1000);
        });
    }

    function showError(element, message) {
        if (element) {
            element.textContent = '❌ ' + message;
            element.style.display = 'block';
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
