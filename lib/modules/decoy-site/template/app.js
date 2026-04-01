// app.js — Основной JavaScript для decoy-сайтов CubiVeil
// Добавляет интерактивность главной странице

document.addEventListener('DOMContentLoaded', function() {
    // Имитируем загрузку файлов/статистики
    const fileGrid = document.getElementById('file-grid');
    const filesFooter = document.getElementById('files-footer');
    const activityBars = document.querySelector('.activity-bars');

    if (fileGrid && window.SITE_CONFIG) {
        // Имитируем загрузку файлов через 1 секунду
        setTimeout(() => {
            if (filesFooter) {
                filesFooter.innerHTML = `
                    <div class="files-info">
                        Показано ${Math.floor(Math.random() * 50) + 10} из ${window.SITE_CONFIG.stats.content.total_files} файлов
                    </div>
                `;
            }
        }, 1000);
    }

    if (activityBars) {
        // Генерируем случайные полоски активности
        activityBars.innerHTML = '';
        for (let i = 0; i < 24; i++) {
            const height = Math.floor(Math.random() * 100) + 10;
            const bar = document.createElement('div');
            bar.className = 'activity-bar';
            bar.style.height = height + '%';
            bar.style.background = 'var(--color-primary)';
            bar.style.borderRadius = '2px';
            bar.style.width = '4px';
            activityBars.appendChild(bar);
        }
    }

    // Добавляем hover эффекты для карточек
    const cards = document.querySelectorAll('.file-card, .media-card');
    cards.forEach(card => {
        card.addEventListener('click', function() {
            // Имитируем загрузку
            this.style.opacity = '0.7';
            setTimeout(() => {
                this.style.opacity = '1';
            }, 200);
        });
    });
});
