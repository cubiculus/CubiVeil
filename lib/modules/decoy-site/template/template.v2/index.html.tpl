<!DOCTYPE html>
<html lang="{{LANG}}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{SITE_NAME}} — {{SITE_TITLE}}</title>
    <link rel="stylesheet" href="style.css">
</head>
<body class="layout-{{LAYOUT_CLASS}}">
<div class="app">

    <header class="header">
        <div class="logo">
            <span class="logo-icon">{{SITE_ICON}}</span>
            <span class="logo-text">{{SITE_NAME}}</span>
        </div>
        <nav class="nav">
            {{NAV_ITEMS}}
        </nav>
        <div class="header-actions">
            <a href="login.html" class="btn btn-outline btn-sm">{{LOGIN_BUTTON}}</a>
        </div>
    </header>

    <main class="main">

        <section class="hero">
            <div class="hero-icon">{{SITE_ICON}}</div>
            <h1>{{SITE_NAME}}</h1>
            <p class="hero-tagline">{{SITE_TAGLINE}}</p>

            <div class="stats-strip">
                <div class="stat-item">
                    <span class="stat-value">{{TOTAL_STORAGE}}</span>
                    <span class="stat-label">{{STORAGE_LABEL}}</span>
                </div>
                <div class="stat-item">
                    <span class="stat-value">{{TOTAL_USERS}}</span>
                    <span class="stat-label">{{USERS_LABEL}}</span>
                </div>
                <div class="stat-item">
                    <span class="stat-value">{{TOTAL_FILES}}</span>
                    <span class="stat-label">{{FILES_LABEL}}</span>
                </div>
                <div class="stat-item">
                    <span class="stat-value">{{ONLINE_USERS}}</span>
                    <span class="stat-label">{{ONLINE_LABEL}}</span>
                </div>
            </div>

            <div class="hero-actions">
                <a href="login.html" class="btn btn-primary btn-lg">{{LOGIN_BUTTON}}</a>
                <a href="#features" class="btn btn-ghost btn-lg">{{LEARN_MORE}}</a>
            </div>
        </section>

        <section class="features" id="features">
            {{FEATURE_BLOCKS}}
        </section>

        <section class="content-preview">
            <div class="content-preview-inner layout-{{LAYOUT_CLASS}}">
                {{CONTENT_PREVIEW}}
            </div>
        </section>

    </main>

    <footer class="footer">
        <div class="footer-inner">
            <span class="footer-logo">{{SITE_ICON}} {{SITE_NAME}}</span>
            <span class="footer-copy">© {{YEAR}} {{SITE_NAME}}. {{RIGHTS_TEXT}}</span>
            <nav class="footer-links">
                <a href="#">{{PRIVACY_TEXT}}</a>
                <a href="#">{{TERMS_TEXT}}</a>
                <a href="login.html">{{LOGIN_BUTTON}}</a>
            </nav>
        </div>
    </footer>

</div>
<script src="config.js"></script>
<script src="app.js"></script>
</body>
</html>
