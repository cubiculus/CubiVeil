server {
    listen 80;
    listen [::]:80;
    server_name _;

    # Redirect HTTP to HTTPS (optional)
    # return 301 https://$host$request_uri;

    # For decoy site, serve HTTP on port 80
    root {{DECOY_WEBROOT}};
    index index.html;

    # Site: {{SITE_NAME}}
    # Template: {{TEMPLATE}}
    # Generated: {{GENERATED_AT}}

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Hide nginx version
    server_tokens off;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/json application/xml;

    # Cache static assets
    location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf|eot|pdf|mp4|mp3)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Handle SPA routing - all requests go to index.html
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Error pages
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;

    location = /50x.html {
        root {{DECOY_WEBROOT}};
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Deny access to sensitive files
    location ~* \.(git|htaccess|htpasswd|env|config|sql)$ {
        deny all;
    }
}

# HTTPS server (if SSL is configured)
# server {
#     listen 443 ssl http2;
#     listen [::]:443 ssl http2;
#     server_name _;
#
#     ssl_certificate /etc/ssl/certs/decoy.crt;
#     ssl_certificate_key /etc/ssl/private/decoy.key;
#     ssl_protocols TLSv1.2 TLSv1.3;
#     ssl_ciphers HIGH:!aNULL:!MD5;
#
#     root {{DECOY_WEBROOT}};
#     index index.html;
#
#     # Same configuration as HTTP server
#     location / {
#         try_files $uri $uri/ /index.html;
#     }
# }
