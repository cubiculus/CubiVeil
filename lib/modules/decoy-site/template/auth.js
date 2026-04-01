// auth.js — Обработка авторизации для decoy-сайтов CubiVeil
// Всегда показывает ошибку "пользователь не найден"

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
                showError('Пожалуйста, заполните все поля');
                return;
            }

            // Имитируем проверку (всегда неудачно)
            showError('Пользователь с таким логином не найден в базе данных');
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
