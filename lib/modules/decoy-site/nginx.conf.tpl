server {
    listen 80;
    listen [::]:80;
    server_name {{DOMAIN}};
    return 301 https://$host$request_uri;
}

server {
    {{HTTP2_LISTEN}}
    listen [::]:443 ssl;
    {{HTTP2_DIRECTIVE}}
    server_name {{DOMAIN}};

    root {{WEBROOT}};
    index index.html;

    ssl_certificate     {{CERT_FILE}};
    ssl_certificate_key {{KEY_FILE}};
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;
    ssl_session_cache   shared:SSL:10m;

    # Подмена Server: заголовка
    # Требует: libnginx-mod-http-headers-more-filter
    # Если модуль не установлен — директива игнорируется, nginx не падает
    more_set_headers "Server: {{SERVER_TOKEN}}";

    add_header X-Content-Type-Options  "nosniff"             always;
    add_header X-Frame-Options         "SAMEORIGIN"          always;
    add_header Referrer-Policy         "{{REFERRER_POLICY}}" always;
    add_header X-XSS-Protection        "1; mode=block"       always;

    error_page 404 /404.html;
    location = /404.html { internal; }

    # POST на форму логина — редирект с fake-ошибкой
    location = / {
        limit_except GET HEAD {
            return 302 /?error=invalid_credentials;
        }
        try_files $uri $uri/ =404;
    }

    # POST на upload — редирект как будто ошибка
    location = /files/upload {
        limit_except GET HEAD {
            return 302 /files/upload/?error=upload_failed;
        }
        try_files $uri $uri/ =404;
    }

    # Динамические разделы — отдаём index.html
    location /files/ {
        add_header Cache-Control "no-store, no-cache, must-revalidate" always;
        add_header Pragma "no-cache" always;
        try_files $uri $uri/index.html =404;
    }

    location /audit/ {
        try_files $uri $uri/index.html =404;
    }

    location ~ /\. { deny all; }
}
