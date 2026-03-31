#!/usr/bin/env bash
#
# generators/content.sh - Генератор контента
# Генерирует фейковые имена папок, файлов, пользователей
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2034
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Функция для получения случайного элемента массива
random_element() {
    local -n arr=$1
    local len=${#arr[@]}
    local idx
    idx=$(od -An -tu4 -N4 /dev/urandom | tr -d ' ' | awk -v len="$len" '{print int($1 % len)}')
    echo "${arr[$idx]}"
}

# Словари имён папок (EN)
# shellcheck disable=SC2034
FOLDER_CATEGORIES_EN=(
    "Documents" "Projects" "Media" "Archive" "Personal" "Work" "Shared"
    "Photos" "Videos" "Music" "Downloads" "Backups" "Reports" "Templates"
)

# shellcheck disable=SC2034
FOLDER_NAMES_EN=(
    # Документы
    "Contracts" "Invoices" "Proposals" "Presentations" "Spreadsheets" "Notes"
    "Meeting Minutes" "Policies" "Guidelines" "Manuals" "Documentation"
    # Проекты
    "Project Alpha" "Project Beta" "Project Gamma" "Project Delta"
    "Development" "Marketing" "Sales" "HR" "Finance" "Legal" "Operations"
    # Медиа
    "Vacation 2024" "Family Photos" "Product Shots" "Events" "Conferences"
    "Webinars" "Podcasts" "Recordings" "Screenshots" "Design Assets"
    # Архив
    "Old Projects" "2023 Archive" "2022 Archive" "Legacy Files" "Deprecated"
    # Личное
    "Resume" "Certificates" "Tax Documents" "Insurance" "Medical Records"
    # Работа
    "Client Files" "Internal" "External" "Drafts" "Final" "Review"
)

# Словари имён папок (RU)
# shellcheck disable=SC2034
FOLDER_CATEGORIES_RU=(
    "Документы" "Проекты" "Медиа" "Архив" "Личное" "Работа" "Общее"
    "Фото" "Видео" "Музыка" "Загрузки" "Резервные копии" "Отчёты" "Шаблоны"
)

# shellcheck disable=SC2034
FOLDER_NAMES_RU=(
    # Документы
    "Договоры" "Счета" "Предложения" "Презентации" "Таблицы" "Заметки"
    "Протоколы встреч" "Политики" "Инструкции" "Руководства" "Документация"
    # Проекты
    "Проект Альфа" "Проект Бета" "Проект Гамма" "Проект Дельта"
    "Разработка" "Маркетинг" "Продажи" "HR" "Финансы" "Юридический" "Операции"
    # Медиа
    "Отпуск 2024" "Семейные фото" "Фото продуктов" "Мероприятия" "Конференции"
    "Вебинары" "Подкасты" "Записи" "Скриншоты" "Дизайн материалы"
    # Архив
    "Старые проекты" "Архив 2023" "Архив 2022" "Устаревшие файлы" "Неактуальное"
    # Личное
    "Резюме" "Сертификаты" "Налоговые документы" "Страховка" "Медицинские записи"
    # Работа
    "Файлы клиентов" "Внутреннее" "Внешнее" "Черновики" "Финальные" "На проверке"
)

# shellcheck disable=SC2034
FILE_EXTENSIONS=(
    "doc" "docx" "pdf" "xlsx" "xls" "ppt" "pptx" "txt" "rtf" "odt"
    "jpg" "jpeg" "png" "gif" "bmp" "svg" "webp" "tiff" "raw" "psd"
    "mp4" "avi" "mov" "mkv" "wmv" "flv" "webm" "mp3" "wav" "flac"
    "zip" "rar" "7z" "tar" "gz" "bz2" "xz"
    "csv" "json" "xml" "yaml" "yml" "md" "html" "css" "js" "py"
)

# shellcheck disable=SC2034
FILE_PREFIXES_EN=(
    "Final" "Draft" "Copy" "New" "Old" "Temp" "Backup" "Archive"
    "Report" "Summary" "Analysis" "Overview" "Details" "Notes" "Memo"
    "Version" "Updated" "Revised" "Approved" "Pending" "Review"
)

# shellcheck disable=SC2034
FILE_PREFIXES_RU=(
    "Финальный" "Черновик" "Копия" "Новый" "Старый" "Временный" "Резервный" "Архивный"
    "Отчёт" "Сводка" "Анализ" "Обзор" "Детали" "Заметки" "Записка"
    "Версия" "Обновлённый" "Пересмотренный" "Утверждённый" "Ожидающий" "На проверке"
)

# shellcheck disable=SC2034
FIRST_NAMES_EN=(
    "James" "John" "Robert" "Michael" "William" "David" "Richard" "Joseph"
    "Mary" "Patricia" "Jennifer" "Linda" "Elizabeth" "Barbara" "Susan" "Jessica"
    "Alexander" "Daniel" "Matthew" "Anthony" "Donald" "Mark" "Paul" "Steven"
    "Sarah" "Karen" "Nancy" "Lisa" "Betty" "Margaret" "Sandra" "Ashley"
    "Thomas" "Charles" "Christopher" "Joshua" "Andrew" "Kevin" "Brian" "George"
    "Dorothy" "Kimberly" "Emily" "Donna" "Michelle" "Carol" "Amanda" "Melissa"
)

# shellcheck disable=SC2034
LAST_NAMES_EN=(
    "Smith" "Johnson" "Williams" "Brown" "Jones" "Garcia" "Miller" "Davis"
    "Rodriguez" "Martinez" "Hernandez" "Lopez" "Gonzalez" "Wilson" "Anderson" "Thomas"
    "Taylor" "Moore" "Jackson" "Martin" "Lee" "Perez" "Thompson" "White"
    "Harris" "Sanchez" "Clark" "Ramirez" "Lewis" "Robinson" "Walker" "Young"
    "Allen" "King" "Wright" "Scott" "Torres" "Nguyen" "Hill" "Flores"
    "Green" "Adams" "Nelson" "Baker" "Hall" "Rivera" "Campbell" "Mitchell"
)

# shellcheck disable=SC2034
FIRST_NAMES_RU=(
    "Александр" "Дмитрий" "Максим" "Сергей" "Андрей" "Алексей" "Артём" "Илья"
    "Елена" "Ольга" "Наталья" "Ирина" "Анна" "Татьяна" "Екатерина" "Светлана"
    "Михаил" "Владимир" "Иван" "Денис" "Павел" "Петр" "Николай" "Константин"
    "Мария" "Анастасия" "Ксения" "Вероника" "Виктория" "Юлия" "Дарья" "Алина"
    "Евгений" "Кирилл" "Тимофей" "Григорий" "Роман" "Вадим" "Олег" "Игорь"
    "Полина" "Алина" "Кристина" "Людмила" "Галина" "Нина" "Зинаида" "Валентина"
)

# shellcheck disable=SC2034
LAST_NAMES_RU=(
    "Иванов" "Смирнов" "Кузнецов" "Попов" "Васильев" "Петров" "Соколов" "Михайлов"
    "Новиков" "Фёдоров" "Морозов" "Волков" "Алексеев" "Лебедев" "Семёнов" "Егоров"
    "Павлов" "Козлов" "Степанов" "Николаев" "Орлов" "Андреев" "Борисов" "Волков"
    "Захаров" "Яковлев" "Соловьёв" "Козлов" "Виноградов" "Богданов" "Воробьёв" "Фролов"
    "Жуков" "Беляев" "Тарасов" "Белов" "Комаров" "Ломоносов" "Ковалёв" "Ильин"
    "Гусев" "Титов" "Аксёнов" "Седов" "Григорьев" "Лазарев" "Рыбаков" "Филиппов"
)

# shellcheck disable=SC2034
POSITIONS_EN=(
    "Administrator" "Manager" "User" "Editor" "Viewer" "Contributor"
    "Developer" "Designer" "Analyst" "Coordinator" "Specialist" "Director"
)

# shellcheck disable=SC2034
POSITIONS_RU=(
    "Администратор" "Менеджер" "Пользователь" "Редактор" "Наблюдатель" "Автор"
    "Разработчик" "Дизайнер" "Аналитик" "Координатор" "Специалист" "Директор"
)

# Генерация случайного числа в диапазоне
random_range() {
    local min=$1
    local max=$2
    local range=$((max - min + 1))
    local rand
    rand=$(od -An -tu4 -N4 /dev/urandom | tr -d ' ')
    echo $((min + rand % range))
}

# Генерация имени папки
generate_folder_name() {
    local lang="${1:-en}"

    case "$lang" in
        ru|RU|русский|Russian)
            random_element FOLDER_NAMES_RU
            ;;
        en|EN|english|English)
            random_element FOLDER_NAMES_EN
            ;;
        *)
            random_element FOLDER_NAMES_EN
            ;;
    esac
}

# Генерация имени файла
generate_filename() {
    local lang="${1:-en}"
    local prefix ext name

    case "$lang" in
        ru|RU|русский|Russian)
            prefix=$(random_element FILE_PREFIXES_RU)
            ;;
        *)
            prefix=$(random_element FILE_PREFIXES_EN)
            ;;
    esac

    ext=$(random_element FILE_EXTENSIONS)

    # Генерируем случайное число для уникальности
    local num
    num=$(random_range 1 999)

    # Формируем имя файла
    local clean_prefix
    clean_prefix=$(echo "$prefix" | tr ' ' '_' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_]//g')

    if [[ -z "$clean_prefix" ]]; then
        clean_prefix="file"
    fi

    echo "${clean_prefix}_${num}.${ext}"
}

# Генерация размера файла (в байтах)
generate_file_size() {
    local max_size="${1:-104857600}"  # 100MB по умолчанию

    # Распределение: много мелких, меньше крупных
    local roll
    roll=$(od -An -tu4 -N4 /dev/urandom | tr -d ' ' | awk '{print $1 % 100}')

    if [[ $roll -lt 50 ]]; then
        # 50% файлов: 1KB - 100KB
        random_range 1024 102400
    elif [[ $roll -lt 80 ]]; then
        # 30% файлов: 100KB - 10MB
        random_range 102400 10485760
    elif [[ $roll -lt 95 ]]; then
        # 15% файлов: 10MB - 50MB
        random_range 10485760 52428800
    else
        # 5% файлов: 50MB - max_size
        random_range 52428800 $max_size
    fi
}

# Генерация имени пользователя
generate_username() {
    local lang="${1:-en}"
    local first last

    # Для usernames всегда используем английские имена (стандарт для логинов)
    first=$(random_element FIRST_NAMES_EN)
    last=$(random_element LAST_NAMES_EN)

    # Формат: firstname.lastname
    local clean_first clean_last
    clean_first=$(echo "$first" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z]//g')
    clean_last=$(echo "$last" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z]//g')

    if [[ -z "$clean_first" ]]; then
        clean_first="user"
    fi
    if [[ -z "$clean_last" ]]; then
        clean_last="unknown"
    fi

    echo "${clean_first}.${clean_last}"
}

# Генерация email
generate_email() {
    local username="${1:-}"
    local domain="${2:-example.com}"

    if [[ -z "$username" ]]; then
        username=$(generate_username)
    fi

    echo "${username}@${domain}"
}

# Генерация списка пользователей
generate_users() {
    local count="${1:-10}"
    local lang="${2:-en}"
    local domain="${3:-example.com}"

    echo "["
    for ((i=0; i<count; i++)); do
        local username position email
        username=$(generate_username "$lang")
        position=$(random_element POSITIONS_EN)  # Должности всегда на EN для универсальности
        email=$(generate_email "$username" "$domain")

        # Случайный статус
        local statuses=("active" "inactive" "pending" "blocked")
        local status_idx
        status_idx=$(od -An -tu4 -N4 /dev/urandom | tr -d ' ' | awk '{print $1 % 4}')
        local status="${statuses[$status_idx]}"

        # Случайная дата регистрации
        local days_ago
        days_ago=$(random_range 1 730)
        local reg_date
        reg_date=$(date -d "$days_ago days ago" +"%Y-%m-%d" 2>/dev/null || date -v-${days_ago}d +"%Y-%m-%d" 2>/dev/null || echo "2024-01-01")

        local comma=""
        if [[ $i -lt $((count - 1)) ]]; then
            comma=","
        fi

        cat <<EOF
    {
        "username": "$username",
        "email": "$email",
        "position": "$position",
        "status": "$status",
        "registered": "$reg_date"
    }$comma
EOF
    done
    echo "]"
}

# Генерация списка файлов
generate_files() {
    local count="${1:-10}"
    local lang="${2:-en}"
    local max_total_size="${3:-1073741824}"  # 1GB по умолчанию

    local total_size=0
    local files_json="["

    for ((i=0; i<count; i++)); do
        local filename size ext modified

        filename=$(generate_filename "$lang")
        ext="${filename##*.}"
        size=$(generate_file_size)

        # Проверяем, не превысим ли лимит
        if [[ $((total_size + size)) -gt $max_total_size ]]; then
            size=$((max_total_size - total_size))
            if [[ $size -lt 1024 ]]; then
                break
            fi
        fi

        total_size=$((total_size + size))

        # Случайная дата модификации
        local days_ago
        days_ago=$(random_range 1 365)
        modified=$(date -d "$days_ago days ago" +"%Y-%m-%d %H:%M:%S" 2>/dev/null || date -v-${days_ago}d +"%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "2024-01-01 12:00:00")

        # Случайный владелец
        local owner
        owner=$(generate_username "$lang")

        local comma=""
        if [[ $i -lt $((count - 1)) ]]; then
            comma=","
        fi

        files_json+=$(cat <<EOF

    {
        "name": "$filename",
        "extension": "$ext",
        "size": $size,
        "modified": "$modified",
        "owner": "$owner"
    }$comma
EOF
)
    done

    files_json+=$'\n]'
    echo "$files_json"
}

# Генерация структуры папок
generate_folders() {
    local count="${1:-10}"
    local lang="${2:-en}"

    echo "["
    for ((i=0; i<count; i++)); do
        local name files_count size

        name=$(generate_folder_name "$lang")
        files_count=$(random_range 1 100)
        size=$(random_range 1048576 1073741824)  # 1MB - 1GB

        # Случайная дата создания
        local days_ago
        days_ago=$(random_range 1 365)
        local created
        created=$(date -d "$days_ago days ago" +"%Y-%m-%d" 2>/dev/null || date -v-${days_ago}d +"%Y-%m-%d" 2>/dev/null || echo "2024-01-01")

        local comma=""
        if [[ $i -lt $((count - 1)) ]]; then
            comma=","
        fi

        cat <<EOF
    {
        "name": "$name",
        "files_count": $files_count,
        "size": $size,
        "created": "$created"
    }$comma
EOF
    done
    echo "]"
}

# Генерация всего контента в JSON
generate_content() {
    local users_count="${1:-10}"
    local files_count="${2:-20}"
    local folders_count="${3:-10}"
    local lang="${4:-en}"
    local domain="${5:-example.com}"
    local max_storage="${6:-10737418240}"  # 10GB

    cat <<EOF
{
    "users": $(generate_users "$users_count" "$lang" "$domain"),
    "files": $(generate_files "$files_count" "$lang" "$max_storage"),
    "folders": $(generate_folders "$folders_count" "$lang")
}
EOF
}

# Основная функция
main() {
    local users_count=10
    local files_count=20
    local folders_count=10
    local lang="en"
    local domain="example.com"
    local max_storage=10737418240
    local mode="all"

    # Парсинг аргументов
    while [[ $# -gt 0 ]]; do
        case $1 in
            --users|-u)
                users_count="$2"
                shift 2
                ;;
            --files|-f)
                files_count="$2"
                shift 2
                ;;
            --folders)
                folders_count="$2"
                shift 2
                ;;
            --lang|-l)
                lang="$2"
                shift 2
                ;;
            --domain|-d)
                domain="$2"
                shift 2
                ;;
            --storage)
                max_storage="$2"
                shift 2
                ;;
            --mode|-m)
                mode="$2"
                shift 2
                ;;
            --help)
                echo "Usage: $0 [--users <N>] [--files <N>] [--folders <N>] [--lang <ru|en>] [--domain <domain>]"
                echo ""
                echo "Options:"
                echo "  --users, -u     Number of users to generate (default: 10)"
                echo "  --files, -f     Number of files to generate (default: 20)"
                echo "  --folders       Number of folders to generate (default: 10)"
                echo "  --lang, -l      Language (ru or en, default: en)"
                echo "  --domain, -d    Email domain (default: example.com)"
                echo "  --storage       Max storage in bytes (default: 10GB)"
                echo "  --mode, -m      Mode: all, users, files, folders (default: all)"
                echo "  --help          Show this help"
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
        esac
    done

    case "$mode" in
        users)
            generate_users "$users_count" "$lang" "$domain"
            ;;
        files)
            generate_files "$files_count" "$lang" "$max_storage"
            ;;
        folders)
            generate_folders "$folders_count" "$lang"
            ;;
        all|*)
            generate_content "$users_count" "$files_count" "$folders_count" "$lang" "$domain" "$max_storage"
            ;;
    esac
}

# Запуск только если скрипт вызван напрямую
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
