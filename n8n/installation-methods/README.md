# 🚀 n8n One-Step Installer

> **Automate your workflow automation!** Install n8n on any OS with a single command.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Supported OS](https://img.shields.io/badge/OS-macOS%20%7C%20Linux%20%7C%20Windows-blue)](https://github.com/yourusername/n8n-installer)
[![n8n Version](https://img.shields.io/badge/n8n-latest-brightgreen)](https://n8n.io/)

## 📋 Table of Contents

- [What is This?](#-what-is-this)
- [Features](#-features)
- [Quick Start](#-quick-start)
- [Supported Operating Systems](#-supported-operating-systems)
- [What Gets Installed](#-what-gets-installed)
- [Manual Installation](#-manual-installation)
- [Configuration](#-configuration)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [About the Author](#-about-the-author)

## 🎯 What is This?

A smart installation script that automatically detects your operating system and installs [n8n](https://n8n.io/) with all prerequisites. No more following complex installation guides or troubleshooting dependency issues.

**Perfect for:**
- Developers who want to get started with n8n quickly
- Teams standardizing their n8n installations
- Anyone who values their time over reading lengthy docs

## ✨ Features

- 🔍 **Auto OS Detection** - Automatically identifies macOS, Linux (Ubuntu/Debian/Fedora), or Windows
- 🎯 **Interactive Method Selection** - Choose between npm, Docker, npx, or build from source
- 📦 **Dependency Management** - Installs Node.js if missing or outdated
- 🐳 **Docker Support** - Full Docker and Docker Compose setup with helper scripts
- ✅ **Version Checking** - Ensures Node.js >= 18.10.0
- 🎨 **Beautiful CLI Output** - Color-coded progress indicators
- ⚙️ **Smart Configuration** - Creates sensible defaults with security in mind
- 🔒 **Security First** - Sets up basic authentication out of the box
- 🚦 **Port Conflict Detection** - Checks if port 5678 is available
- 💾 **Resource Validation** - Warns if system RAM is low
- 📝 **Launch Scripts** - Creates convenient startup scripts for each method
- 🛡️ **Error Handling** - Fails gracefully with helpful error messages

## ⚡ Quick Start

### One-Line Installation

**macOS/Linux:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/cloudbunny17/n8n/refs/heads/main/n8n/installation-methods/install_n8n.sh)
```

**Windows (Git Bash/WSL):**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/cloudbunny17/n8n/refs/heads/main/n8n/installation-methods/install_n8n.sh)
```

### What Happens Next?

After running the command, you'll see:

1. **OS Detection** - Script automatically detects your operating system
2. **Method Selection Menu** - Choose your preferred installation method:
   - **npm** (Recommended) - Simple, global installation
   - **Docker** - Containerized, isolated environment
   - **npx** - Run without permanent installation (great for testing)
   - **Build from source** - Latest development version

3. **Automated Setup** - Script handles all dependencies and configuration
4. **Ready to Use** - Access n8n at http://localhost:5678

### Installation Methods Explained

#### 1️⃣ npm Installation
- ✅ **Best for:** Most users, everyday use
- ✅ **Pros:** Fast, simple, direct access to `n8n` command
- ❌ **Cons:** Requires Node.js on your system

#### 2️⃣ Docker Installation
- ✅ **Best for:** Clean environments, production-like setups
- ✅ **Pros:** Isolated, easy updates, no Node.js conflicts
- ❌ **Cons:** Requires Docker, slight overhead
- 🎁 **Bonus:** Includes helper scripts (start, stop, logs)

#### 3️⃣ npx Method
- ✅ **Best for:** Testing, one-time use, minimal footprint
- ✅ **Pros:** No permanent installation, always latest version
- ❌ **Cons:** Slower startup, still needs Node.js

#### 4️⃣ Build from Source
- ✅ **Best for:** Developers, contributors, bleeding-edge features
- ✅ **Pros:** Latest commits, full control, can contribute
- ❌ **Cons:** Longest setup time, requires build tools

### Manual Download & Run

```bash
# Download the script
curl -O https://raw.githubusercontent.com/cloudbunny17/n8n/refs/heads/main/n8n/installation-methods/install_n8n.sh

# Make it executable
chmod +x install-n8n.sh

# Run it
./install-n8n.sh
```

### Using a Custom Port

```bash
export N8N_PORT=5679
./install-n8n.sh
```

## 💻 Supported Operating Systems

| OS | Version | Status | Method |
|---|---|---|---|
| macOS | 10.15+ | ✅ Fully Supported | Homebrew + npm |
| Ubuntu | 18.04+ | ✅ Fully Supported | NodeSource + npm |
| Debian | 10+ | ✅ Fully Supported | NodeSource + npm |
| Fedora | 33+ | ✅ Fully Supported | NodeSource + npm |
| RHEL/CentOS | 8+ | ✅ Fully Supported | NodeSource + npm |
| Windows 10/11 | WSL/Git Bash | ⚠️ Partial Support | Manual Node.js required | ⚠️ May Work |
| Other Linux | - | ⚠️ May Work | Generic Linux support |

## 📦 What Gets Installed

The script installs and configures based on your chosen method:

### npm Method
1. **Node.js** (LTS version, >= 18.10.0)
   - Via Homebrew on macOS
   - Via NodeSource on Linux
   - Manual installation prompt on Windows

2. **n8n** (Latest version)
   - Global npm installation
   - Accessible from anywhere via `n8n` command

3. **Configuration Files**
   - `~/.n8n/.env` - Environment variables
   - Default credentials (username: admin)
   - Basic security settings

4. **Launch Script**
   - `~/start-n8n.sh` (macOS/Linux)
   - `~/start-n8n.bat` (Windows)

### Docker Method
1. **Docker** (if not already installed)
   - Docker Engine
   - Docker Compose

2. **n8n Container**
   - Latest n8n Docker image
   - Configured with docker-compose.yml
   - Auto-restart enabled

3. **Helper Scripts**
   - `~/start-n8n.sh` - Start container
   - `~/stop-n8n.sh` - Stop container
   - `~/n8n-logs.sh` - View logs

### npx Method
1. **Node.js** (LTS version)
2. **Launch Script**
   - `~/start-n8n.sh` - Runs npx n8n

### Source Method
1. **Node.js** and **pnpm**
2. **n8n Source Code**
   - Cloned to `~/n8n-source`
   - All dependencies installed
   - Built and ready to run

3. **Launch Script**
   - `~/start-n8n.sh` - Starts from source

## 🔧 Manual Installation

If the automatic script doesn't work for your setup, follow these manual steps:

### Prerequisites

Install Node.js 18.10 or higher:

**macOS:**
```bash
brew install node
```

**Ubuntu/Debian:**
```bash
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs
```

**Windows:**
Download from [nodejs.org](https://nodejs.org/)

### Install n8n

```bash
npm install -g n8n
```

### Run n8n

```bash
n8n start
```

Open http://localhost:5678 in your browser.

## ⚙️ Configuration

After installation, configure n8n by editing `~/.n8n/.env`:

```bash
# Essential Settings
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=your_username
N8N_BASIC_AUTH_PASSWORD=your_secure_password

# Server Configuration
N8N_PORT=5678
N8N_HOST=localhost
N8N_PROTOCOL=http

# Timezone
GENERIC_TIMEZONE=America/New_York

# Security
N8N_BLOCK_ENV_ACCESS_IN_NODE=true
```

**🔒 Security Tip:** Always change the default password immediately after installation!

### Advanced Configuration

Explore more options in the [official n8n documentation](https://docs.n8n.io/hosting/configuration/).

## 🐛 Troubleshooting

### Port Already in Use

**Error:** `Port 5678 is already in use`

**Solution:**
```bash
# Use a different port
export N8N_PORT=5679
n8n start --port 5679
```

### Node.js Version Too Old

**Error:** `Node.js version is too old`

**Solution:**
```bash
# Update Node.js
# macOS
brew upgrade node

# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### Permission Errors (Linux)

**Error:** `EACCES: permission denied`

**Solution:**
```bash
# Configure npm to install globally without sudo
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Reinstall n8n
npm install -g n8n
```

### n8n Command Not Found

**Solution:**
```bash
# Verify npm global bin path is in PATH
echo $PATH

# Add npm global bin to PATH
echo 'export PATH="$(npm config get prefix)/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Windows-Specific Issues

For Windows users, we recommend:
1. Use **WSL2** (Windows Subsystem for Linux) for the best experience
2. Use **Git Bash** if you prefer staying in Windows
3. Ensure Node.js is added to your PATH during installation

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Report Bugs** - Open an issue with details about the problem
2. **Suggest Features** - Share ideas for improvements
3. **Submit PRs** - Fix bugs or add new features
4. **Improve Docs** - Help make this README better

### Development Setup

```bash
# Clone the repository
git clone git@github.com:cloudbunny17/n8n.git
cd n8n-installer

# Test the script
./install-n8n.sh

# Make changes and submit a PR
```

## 📚 Learn More

- **n8n Documentation:** https://docs.n8n.io/
- **n8n Community:** https://community.n8n.io/
- **My Blog Post:** [Complete Guide to Installing n8n Locally](https://medium.com/@yourhandle/your-article)
- **YouTube Tutorial:** [Coming Soon]

## 🎓 About the Author

Hi! I'm Chetansingh Rajput, an AI/automation enthusiast specializing in workflow optimization and intelligent automation solutions.

**What I Do:**
- Build AI-powered automation workflows
- Create developer tools and scripts
- Write about n8n, AI, and productivity

**Connect With Me:**
- 💼 LinkedIn: [Chetansingh Rajput](www.linkedin.com/in/chetansingh-rajput-45672774)
- 📝 Blog: https://medium.com/@cloudbunny
- 📧 Email: ping2cloudbunny@gmail.com

### Why I Built This Script

As someone who has installed n8n dozens of times across different machines and operating systems, I noticed everyone struggles with the same issues most of the times:
- Outdated Node.js versions
- Permission errors
- Port conflicts
- Configuration confusion

This script solves all those problems in one go. I built it for myself, but I'm sharing it because I believe great tools should be easy to use.

## 📄 License

MIT License - feel free to use this in your own projects!

---

## ⭐ Show Your Support

If this script saved you time, please:
- Star this repository ⭐
- Share it with your team 🔄
- Follow me for more automation content 👨‍💻

## 🔄 Updates

**Latest Version:** v1.0.0
- ✅ Initial release
- ✅ Support for macOS, Linux, Windows
- ✅ Auto OS detection
- ✅ Node.js version checking
- ✅ Configuration management

**Coming Soon:**
- Docker installation option
- Update checker
- Uninstallation script

---

<div align="center">

**Made with ❤️ and lots of coffee**

[Request Feature](https://github.com/cloudbunny17/n8n/issues) · 

</div>