# CubiVeil

<p align="center">
  <img src="../assets/logo.png" alt="CubiVeil Logo" width="200"/>
</p>

<p align="center">
  <strong>Automated Installation and Management of Marzban + Sing-box</strong>
</p>

<p align="center">
  <a href="../README.md">Русская версия</a>
</p>

---

## 📋 About

**CubiVeil** is a comprehensive solution for deploying and managing proxy infrastructure based on **Marzban** and **Sing-box** on Ubuntu servers.

The project provides:
- 🚀 Automated installation of all components
- 🔒 Firewall, Fail2ban, and SSL certificate configuration
- 📊 Resource monitoring and alerts
- 💾 Automatic backup
- 🤖 Telegram bot for server management
- 🛠 Utility suite for maintenance

## ⚡ Quick Start

### Requirements

- **OS:** Ubuntu 20.04+
- **Privileges:** root (sudo)
- **Domain:** for panel and SSL certificates
- **DNS:** A record pointing to server IP

### Installation

```bash
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
4. Install Sing-box and Marzban
5. Configure Let's Encrypt SSL certificates
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
```

### Modular Installation

To select specific components:

```bash
sudo bash install-modular.sh
```

#### Dry-run Mode

To test installation without making system changes:

```bash
sudo bash install-modular.sh --dry-run
```

Simulation mode will show what actions would be performed, which modules would be installed and configured, but won't make any changes to the system.

## 📦 Components

### Core

| Component | Description |
|-----------|----------|
| **Marzban** | User and subscription management panel |
| **Sing-box** | Proxy core with modern protocol support |
| **Fail2ban** | Brute-force attack protection |
| **UFW** | Firewall |
| **Let's Encrypt** | SSL certificates |

### Utilities

All utilities are located in `utils/` directory:

| Utility | Description |
|---------|----------|
| `cubiveil.sh` | CLI manager (single entry point) |
| `monitor.sh` | Server resource monitoring |
| `backup.sh` | Create and restore backups |
| `diagnose.sh` | Problem diagnostics |
| `manage-profiles.sh` | User profile management |
| `export-config.sh` | Configuration export for migration |
| `update.sh` | Update CubiVeil |
| `rollback.sh` | Rollback to previous version |

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
- `cv profiles list` — profile list
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
- `/services` — all services status
- `/alerts` — alert status and thresholds

#### Backups
- `/backup` — create full backup
- `/backups` — list available backups

#### Users
- `/users` — list all users
- `/qr <username>` — QR code for connection

#### Management
- `/restart <service>` — restart service
- `/update` — check for updates
- `/export` — export configuration
- `/diagnose` — full diagnostics

#### Logs
- `/logs <service> [lines]` — service logs

Detailed documentation: [BOT_INTEGRATION.md](../BOT_INTEGRATION.md)

## 📊 Automation

### Daily Reports

The bot automatically sends reports at scheduled time (default 09:00 UTC):
- CPU, RAM, disk usage
- Server uptime
- Number of active users
- Database backup

### Alerts

Automatic notifications when thresholds are exceeded:
- **CPU:** 80% (configurable)
- **RAM:** 85% (configurable)
- **Disk:** 90% (configurable)

Checks every 15 minutes. Alert sent only on transition from normal to exceeded.

## 🔧 Configuration

### Localization

The project supports Russian and English languages. Switch in `lang.sh`.

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
├── lib/
│   ├── core/
│   ├── modules/
│   ├── common.sh
│   ├── i18n.sh
│   ├── install-steps.sh
│   └── ...
├── utils/
│   ├── cubiveil.sh
│   ├── monitor.sh
│   ├── backup.sh
│   ├── diagnose.sh
│   └── ...
├── tests/
├── install.sh
├── install-modular.sh
├── setup-telegram.sh
└── README.md
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

## 📄 Documentation

- [Telegram Bot Integration](../BOT_INTEGRATION.md)
- [CubiVeil Utilities](../utils/README.md)
- [Russian README](../README.md)

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

### Pre-commit Hooks

Project uses pre-commit for automated checks:

```bash
pip install pre-commit
pre-commit install
```

## 📝 License

MIT License — see [LICENSE](LICENSE) file

## 👤 Author

**cubiculus** — [GitHub](https://github.com/cubiculus/cubiveil)

---

<p align="center">
  <strong>CubiVeil</strong> | 
  <a href="../README.md">Русский</a> | 
  <a href="https://github.com/cubiculus/cubiveil">GitHub</a>
</p>
