# CubiVeil

<p align="center">
  <img src="../assets/logo.png" alt="CubiVeil Logo" width="200"/>
</p>

<p align="center">
  <strong>Automated Installation and Management of s-ui (Sing-box)</strong>
</p>

<p align="center">
  <a href="../README.md">Русская версия</a>
</p>

<p align="center">
  <a href="https://github.com/cubiculus/CubiVeil/actions/workflows/ci.yml"><img src="https://github.com/cubiculus/CubiVeil/actions/workflows/ci.yml/badge.svg" alt="CI"/></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"/></a>
  <a href="https://ubuntu.com/"><img src="https://img.shields.io/badge/platform-Ubuntu%2022.04%20%7C%2024.04-orange" alt="Platform"/></a>
  <a href="https://www.python.org/"><img src="https://img.shields.io/badge/python-3.10-blue" alt="Python"/></a>
  <a href="https://mypy.readthedocs.io/"><img src="https://img.shields.io/badge/type%20checked-mypy-blue" alt="myPy"/></a>
  <a href="https://github.com/PyCQA/bandit"><img src="https://img.shields.io/badge/security-bandit-green" alt="Security: Bandit"/></a>
</p>

---

## 🚀 Quick Start

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/cubiculus/cubiveil/main/install.sh)
```

---

## 📋 About

**CubiVeil** is a comprehensive solution for deploying and managing infrastructure based on **S-UI** (alireza0/s-ui) with built-in Sing-box on Ubuntu servers.

The project provides:
- 🚀 Automated installation of all components
- 🔒 Firewall, Fail2ban, and SSL certificate configuration
- 📊 Resource monitoring and alerts
- 💾 Automatic backup
- 🤖 Telegram bot for server management
- 🛠 Utility suite for maintenance
- 🎭 Decoy site with realistic traffic generation
- 🌐 Traffic shaping for unique server "fingerprint"

## ⚡ Quick Start

### Requirements

- **OS:** Ubuntu 20.04+
- **Privileges:** root (sudo)
- **Domain:** for panel and SSL certificates
- **DNS:** A record pointing to server IP
- **Port 80:** must be open for SSL (opens automatically)

### Installation

```bash
# Install git (if not installed)
sudo apt update && sudo apt install -y git

# Clone repository
git clone https://github.com/cubiculus/cubiveil.git
cd cubiveil

# Run installer
sudo bash install.sh
```

The installer will automatically:
1. Check environment
2. Update system
3. Configure firewall and Fail2ban
4. Install s-ui panel (with built-in Xray/Sing-box)
5. Configure Let's Encrypt SSL certificates (via s-ui built-in ACME)
6. Generate keys and configurations

### Dev Mode (for testing)

For installation on a test virtual machine without a domain:

```bash
sudo bash install.sh --dev
```

**Dev Mode:**
- ✅ No domain required
- ✅ Uses self-signed SSL certificate (valid for 100 years)
- ✅ No DNS A-record validation
- ✅ Perfect for testing and development
- ⚠️ Browsers will show security warning
- ⚠️ Do not use in production!

### Dry-run Mode (simulation)

To test the installer without making changes to the system:

```bash
sudo bash install.sh --dry-run
```

**Dry-run Mode:**
- ✅ No changes made to the system
- ✅ Shows all steps that will be executed
- ✅ Checks environment and dependencies
- ✅ Safe to run on any system
- ✅ Can be combined with `--dev`

**Dry-run Mode:**
- ✅ No system changes made
- ✅ Shows all steps that would be executed
- ✅ Validates environment and dependencies
- ✅ Safe to run on any system
- ✅ Can be combined with `--dev`

**Combining modes:**

```bash
# Dev + Dry-run: test dev installation without changes
sudo bash install.sh --dev --dry-run
```

**With options:**

```bash
# Dev mode with custom domain
sudo bash install.sh --dev --domain=mytest.local

# Show help
sudo bash install.sh --help

# Debug mode (verbose output + DEBUG logs)
sudo bash install.sh --debug

# Debug mode + simulation (no system changes)
sudo bash install.sh --debug --dry-run

# Debug mode + dev mode (testing with verbose output)
sudo bash install.sh --debug --dev

# Skip decoy-site installation
sudo bash install.sh --no-decoy

# Skip Traffic Shaping module
sudo bash install.sh --no-traffic-shaping

# Install Telegram bot (interactive setup)
sudo bash install.sh --telegram

# Save installation log
sudo bash install.sh --debug 2>&1 | tee install_debug.log
```

**All options:**

| Option | Description |
|--------|-------------|
| `--dev` | Dev mode: self-signed SSL, no domain required |
| `--dry-run` | Simulate installation without system changes |
| `--debug`, `-v` | Debug mode: verbose output + DEBUG logs |
| `--domain=NAME` | Set domain (default in dev: dev.cubiveil.local) |
| `--no-decoy` | Skip decoy-site installation |
| `--no-traffic-shaping` | Skip Traffic Shaping module |
| `--telegram` | Install Telegram bot |
| `--help`, `-h` | Show help |

## 📦 Components

### Core

| Component | Description |
|-----------|----------|
| **s-ui** | Management panel with built-in Xray/Sing-box |
| **Fail2ban** | Brute-force attack protection |
| **UFW** | Firewall |
| **Let's Encrypt** | SSL certificates (via s-ui ACME) |
| **Decoy Site** | Decoy website with realistic traffic generation |
| **Traffic Shaping** | Network parameter control for unique "fingerprint" |

### Utilities

All utilities are located in `utils/` directory:

| Utility | Description |
|---------|----------|
| `cubiveil.sh` | CLI manager (single entry point) |
| `monitor.sh` | Server resource monitoring |
| `backup.sh` | Create and restore backups |
| `diagnose.sh` | Problem diagnostics |
| `export-config.sh` | Configuration export for migration |
| `update.sh` | Update CubiVeil |
| `rollback.sh` | Rollback to previous version |
| `import-config.sh` | Configuration import |

#### Installing Aliases

For convenient utility access:

```bash
sudo bash utils/install-aliases.sh
source /root/.bashrc
```

After installation, available commands:
- `cv` — help
- `cv monitor` — monitoring
- `cv backup create` — create backup
- `cv diagnose` — diagnostics

## 🤖 Telegram Bot

CubiVeil Bot provides full server control via Telegram.

### Bot Installation

```bash
bash setup-telegram.sh
```

### Main Commands

#### Monitoring
- `/status` — brief server status
- `/monitor` — full state snapshot
- `/alerts` — alert status and thresholds

#### Backups
- `/backup` — create full backup
- `/backups` — list available backups

#### Management
- `/restart` — restart s-ui service
- `/update` — check for updates
- `/export` — export configuration
- `/diagnose` — full diagnostics
- `/logs <service> [lines]` — service logs

#### Decoy Site
- `/decoy` — decoy management menu
- `/decoy_status` — show decoy status
- `/decoy_rotate` — rotate decoy files
- `/decoy_files` — list decoy files
- `/decoy_config` — show decoy config

#### Settings
- `/set_cpu <percent>` — CPU threshold
- `/set_ram <percent>` — RAM threshold
- `/set_disk <percent>` — Disk threshold

Detailed documentation: [BOT_INTEGRATION.md](../BOT_INTEGRATION.md)

## 📊 Automation

### Daily Reports

The bot automatically sends reports at scheduled time (default 09:00 UTC):
- CPU, RAM, disk usage
- Server uptime
- Database backup

### Alerts

Automatic notifications when thresholds are exceeded:
- **CPU:** 80% (configurable)
- **RAM:** 85% (configurable)
- **Disk:** 90% (configurable)

Checks every 15 minutes. Alert sent only on transition from normal to exceeded.

## 🔧 Configuration

### Localization

The project supports Russian and English languages. Switch in `lang/main.sh`.

### Environment Variables

Bot settings via systemd Environment:
- `TG_TOKEN` — Telegram bot token
- `TG_CHAT_ID` — authorized chat_id
- `ALERT_CPU`, `ALERT_RAM`, `ALERT_DISK` — alert thresholds

## 🛡 Security

### Bot Restrictions

Bot systemd service has restrictions:
- `ProtectHome=true` — no access to home directories
- `ProtectSystem=strict` — read-only system files
- `NoNewPrivileges=true` — no additional privileges
- `ReadWritePaths` — write only to `/opt/cubiveil-bot/`

### Authorization

Bot accepts commands only from authorized `CHAT_ID`.

### Backup Encryption

Utilities support encryption via `age`. Use SSH for encrypted backups.

## 📁 Project Structure

```
cubiveil/
├── assets/
│   ├── logo.png
│   └── telegram-bot/
│       ├── bot.py
│       ├── commands.py
│       ├── metrics.py
│       └── ...
├── lang/
│   ├── main.sh           # Main localization (EN/RU)
│   └── telegram.sh       # Telegram bot localization
├── lib/
│   ├── core/
│   │   ├── installer/        # Installer modules (new architecture)
│   │   │   ├── bootstrap.sh  # Repository file download
│   │   │   ├── cli.sh        # Command-line argument parsing
│   │   │   ├── orchestrator.sh # Module installation orchestration
│   │   │   ├── prompt.sh     # Interactive prompts
│   │   │   └── ui.sh         # UI functions (banner, reports)
│   │   ├── log.sh        # Logging with localization support
│   │   └── system.sh     # System functions
│   ├── modules/
│   │   ├── backup/           # Backup module
│   │   ├── decoy-site/       # Decoy site module
│   │   ├── fail2ban/         # Fail2ban module
│   │   ├── firewall/         # UFW firewall module
│   │   ├── monitoring/       # Resource monitoring
│   │   ├── rollback/         # Version rollback
│   │   ├── ssl/              # SSL certificates (Let's Encrypt)
│   │   ├── system/           # System module
│   │   ├── s-ui/             # s-ui panel module
│   │   └── traffic-shaping/  # Traffic shaping
│   ├── common.sh         # Common functions
│   ├── fallback.sh       # Fallback functions
│   ├── i18n.sh           # Internationalization API
│   ├── output.sh         # Output functions (unified style)
│   ├── security.sh       # Security functions
│   ├── utils.sh          # Utilities
│   └── validation.sh     # Data validation
├── utils/
│   ├── cubiveil.sh           # CLI manager
│   ├── install-aliases.sh    # Alias installation
│   ├── update.sh             # CubiVeil update
│   ├── rollback.sh           # Version rollback
│   ├── export-config.sh      # Config export
│   ├── import-config.sh      # Config import
│   ├── monitor.sh            # Resource monitoring
│   ├── diagnose.sh           # Problem diagnosis
│   ├── backup.sh             # Backups
│   └── README.md
├── tests/
│   ├── unit-lang.sh          # Localization tests
│   ├── unit-install.sh       # Installer tests
│   ├── unit-telegram.sh      # Telegram bot tests
│   └── ...
├── docs/
│   ├── README_EN.md          # English documentation
│   └── ...
├── .github/workflows/
│   └── ci.yml                # CI/CD pipeline
├── install.sh                # Main installer
├── setup-telegram.sh         # Telegram bot setup
├── run-tests.sh              # Run tests
├── .pre-commit-config.yaml   # Pre-commit hooks
└── README.md                 # Documentation (RU)
```

## 🧪 Testing

Run tests:

```bash
bash run-tests.sh
```

CI/CD includes checks:
- **Shellcheck** — bash script static analysis
- **shfmt** — code formatting
- **bash -n** — syntax check
- **Mypy** — Python type checking
- **Bandit** — Python security analysis

## 🔧 Troubleshooting

### Bot Not Responding

```bash
# Check status
systemctl status cubiveil-bot

# Restart
systemctl restart cubiveil-bot

# View logs
journalctl -u cubiveil-bot -n 50
```

### Utilities Not Executing

```bash
# Check paths
ls -la /opt/cubiveil/utils/

# Check permissions
chmod +x /opt/cubiveil/utils/*.sh
```

### SSL Issues

Ensure:
- Domain A record points to server IP
- Port 80/443 open in firewall
- Domain is not internal (not localhost, not .local)
- Use s-ui web panel to manage SSL certificates

### s-ui Panel Access

```bash
# Check s-ui status
systemctl status s-ui

# View s-ui logs
journalctl -u s-ui -n 50

# Check panel port
netstat -tlnp | grep s-ui
```

## 📄 Documentation

- [Telegram Bot Integration](../BOT_INTEGRATION.md)
- [CubiVeil Utilities](../utils/README.md)
- [Testing](../tests/README.md)
- [Russian README](../README.md)

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

### Pre-commit Hooks

Project uses pre-commit for automated checks before commit:

```bash
# Install dependencies
pip install pre-commit detect-secrets

# Activate hooks
pre-commit install
```

**What is checked:**
- 🔐 Passwords, API keys, tokens (detect-secrets)
- 🔐 SSH/GPG/SSL private keys
- 🐛 Bash script syntax (shellcheck)
- 📦 Files >1MB are blocked

**Optionally (for full protection):**
```bash
# Install trufflehog for Git history check
# Linux/MacOS:
go install github.com/trufflesecurity/trufflehog/v3@latest

# Manual history check:
trufflehog git file://. --only-verified --fail
```

**Initial secrets scan:**
```bash
detect-secrets scan --baseline .secrets.baseline
```

> **Note for Windows:** shellcheck may have encoding issues. To fix, convert files to Unix LF: `tr -d '\r' < file.sh > file.tmp`

## 🧪 Testing

Run tests:

```bash
bash run-tests.sh
```

CI/CD includes checks:
- **Shellcheck** — bash script static analysis
- **shfmt** — code formatting
- **bash -n** — syntax check
- **Mypy** — Python type checking
- **Bandit** — Python security analysis

## 📝 License

MIT License — see [LICENSE](LICENSE) file

## 👤 Author

**cubiculus** — [GitHub](https://github.com/cubiculus/cubiveil)

---

<p align="center">
  <strong>CubiVeil</strong> |
  <a href="../README.md">Русский</a> |
  <a href="../tests/README.md">Tests</a> |
  <a href="https://github.com/cubiculus/cubiveil">GitHub</a>
</p>
