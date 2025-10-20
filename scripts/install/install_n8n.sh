#!/bin/bash

# ============================================================================
# n8n One-Step Installation Script
# Author: Chetansingh Rajput
# Description: Automatically installs n8n with all prerequisites
# Supports: macOS, Linux (Ubuntu/Debian), Windows (via Git Bash/WSL)
# ============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MIN_NODE_VERSION="18.10.0"
N8N_PORT="${N8N_PORT:-5678}"

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║               ${GREEN}n8n One-Step Installation Script       ║${NC}"
    echo -e "${BLUE}║               Automate your workflow automation!             ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_step() {
    echo -e "\n${BLUE}==>${NC} ${1}"
}

# ============================================================================
# OS Detection
# ============================================================================

detect_os() {
    print_step "Detecting operating system..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
            OS_VERSION=$VERSION_ID
            print_success "Detected Linux: $NAME $VERSION"
        else
            OS="linux"
            print_success "Detected Linux (generic)"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        OS_VERSION=$(sw_vers -productVersion)
        print_success "Detected macOS: $OS_VERSION"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
        print_success "Detected Windows (Git Bash/Cygwin)"
    else
        print_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
}

# ============================================================================
# Check if command exists
# ============================================================================

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ============================================================================
# Version Comparison
# ============================================================================

version_ge() {
    # Returns 0 if $1 >= $2
    printf '%s\n%s\n' "$2" "$1" | sort -V -C
}

# ============================================================================
# Node.js Installation
# ============================================================================

check_node() {
    print_step "Checking Node.js installation..."
    
    if command_exists node; then
        NODE_VERSION=$(node --version | cut -d 'v' -f 2)
        print_info "Found Node.js version: $NODE_VERSION"
        
        if version_ge "$NODE_VERSION" "$MIN_NODE_VERSION"; then
            print_success "Node.js version is compatible (>= $MIN_NODE_VERSION)"
            return 0
        else
            print_warning "Node.js version is too old. Minimum required: $MIN_NODE_VERSION"
            return 1
        fi
    else
        print_warning "Node.js is not installed"
        return 1
    fi
}

install_node_macos() {
    print_step "Installing Node.js on macOS..."
    
    if ! command_exists brew; then
        print_info "Installing Homebrew first..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        print_success "Homebrew installed"
    fi
    
    brew install node
    print_success "Node.js installed via Homebrew"
}

install_node_linux() {
    print_step "Installing Node.js on Linux..."
    
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        # Install using NodeSource repository
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs
        print_success "Node.js installed via NodeSource"
        
    elif [[ "$OS" == "fedora" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "centos" ]]; then
        curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
        sudo yum install -y nodejs
        print_success "Node.js installed via NodeSource"
        
    else
        print_error "Automatic Node.js installation not supported for this Linux distribution"
        print_info "Please install Node.js manually: https://nodejs.org/"
        exit 1
    fi
}

install_node_windows() {
    print_step "Node.js installation on Windows..."
    print_warning "Please install Node.js manually from: https://nodejs.org/"
    print_info "Download the LTS version and run the installer"
    print_info "After installation, restart Git Bash and run this script again"
    exit 1
}

install_node() {
    case $OS in
        macos)
            install_node_macos
            ;;
        ubuntu|debian)
            install_node_linux
            ;;
        fedora|rhel|centos)
            install_node_linux
            ;;
        windows)
            install_node_windows
            ;;
        *)
            print_error "Unsupported OS for automatic Node.js installation"
            exit 1
            ;;
    esac
}

# ============================================================================
# Check System Resources
# ============================================================================

check_system_resources() {
    print_step "Checking system resources..."
    
    # Check available RAM
    if [[ "$OS" == "macos" ]]; then
        TOTAL_RAM=$(sysctl hw.memsize | awk '{print int($2/1024/1024/1024)}')
    elif [[ "$OS" == "linux" ]]; then
        TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
    else
        print_warning "Cannot check RAM on this system"
        return
    fi
    
    print_info "Total RAM: ${TOTAL_RAM}GB"
    
    if [ "$TOTAL_RAM" -lt 4 ]; then
        print_warning "Less than 4GB RAM detected. n8n may run slowly"
    else
        print_success "Sufficient RAM available"
    fi
}

# ============================================================================
# Check Port Availability
# ============================================================================

check_port() {
    print_step "Checking if port $N8N_PORT is available..."
    
    if command_exists lsof; then
        if lsof -Pi :$N8N_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
            print_warning "Port $N8N_PORT is already in use"
            print_info "You can use a different port by setting: export N8N_PORT=5679"
            read -p "Continue anyway? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        else
            print_success "Port $N8N_PORT is available"
        fi
    else
        print_warning "Cannot check port availability (lsof not found)"
    fi
}

# ============================================================================
# Install n8n
# ============================================================================

install_n8n() {
    print_step "Installing n8n globally..."
    
    if [[ "$OS" == "linux" ]] && [[ "$EUID" -ne 0 ]]; then
        # On Linux, check if we need sudo
        if npm config get prefix | grep -q "/usr"; then
            print_info "Installing with sudo (system-wide installation)..."
            sudo npm install -g n8n
        else
            npm install -g n8n
        fi
    else
        npm install -g n8n
    fi
    
    print_success "n8n installed successfully!"
}

# ============================================================================
# Create Configuration
# ============================================================================

create_config() {
    print_step "Creating n8n configuration..."
    
    N8N_DIR="$HOME/.n8n"
    mkdir -p "$N8N_DIR"
    
    if [ ! -f "$N8N_DIR/.env" ]; then
        cat > "$N8N_DIR/.env" << EOF
# n8n Configuration
# Generated by n8n-installer

# Basic Authentication
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=change_this_password

# Server Configuration
N8N_PORT=$N8N_PORT
N8N_PROTOCOL=http
N8N_HOST=localhost

# Timezone
GENERIC_TIMEZONE=$(date +%Z)

# Execution Mode
EXECUTIONS_MODE=regular

# Security
N8N_BLOCK_ENV_ACCESS_IN_NODE=true
EOF
        print_success "Configuration file created at: $N8N_DIR/.env"
        print_warning "Please change the default password in: $N8N_DIR/.env"
    else
        print_info "Configuration file already exists, skipping..."
    fi
}

# ============================================================================
# Create Launch Scripts
# ============================================================================

create_launch_script() {
    print_step "Creating convenient launch script..."
    
    if [[ "$OS" == "windows" ]]; then
        SCRIPT_NAME="start-n8n.bat"
        cat > "$HOME/$SCRIPT_NAME" << 'EOF'
@echo off
echo Starting n8n...
n8n start
EOF
    else
        SCRIPT_NAME="start-n8n.sh"
        cat > "$HOME/$SCRIPT_NAME" << 'EOF'
#!/bin/bash
echo "Starting n8n..."
n8n start
EOF
        chmod +x "$HOME/$SCRIPT_NAME"
    fi
    
    print_success "Launch script created: ~/$SCRIPT_NAME"
}

# ============================================================================
# Post-Installation Instructions
# ============================================================================

print_post_install() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}               ${BLUE}Installation Complete!${NC}                        ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    print_success "n8n is now installed and ready to use!"
    echo ""
    echo -e "${BLUE}Quick Start:${NC}"
    echo "  1. Start n8n:"
    echo "     ${YELLOW}n8n start${NC}"
    echo ""
    echo "  2. Open your browser:"
    echo "     ${YELLOW}http://localhost:$N8N_PORT${NC}"
    echo ""
    echo "  3. Login credentials:"
    echo "     Username: ${YELLOW}admin${NC}"
    echo "     Password: ${YELLOW}change_this_password${NC}"
    echo ""
    echo -e "${RED}⚠ IMPORTANT:${NC} Change your password in ~/.n8n/.env"
    echo ""
    echo -e "${BLUE}Useful Commands:${NC}"
    echo "  • Start n8n:     ${YELLOW}n8n start${NC}"
    echo "  • Custom port:   ${YELLOW}n8n start --port 5679${NC}"
    echo "  • Open browser:  ${YELLOW}n8n start -o${NC}"
    echo ""
    echo -e "${BLUE}Documentation:${NC}"
    echo "  • Official docs: https://docs.n8n.io/"
    echo "  • GitHub repo:   https://github.com/[your-username]/n8n-installer"
    echo ""
    echo -e "${GREEN}Happy Automating! 🚀${NC}"
    echo ""
}

# ============================================================================
# Installation Method Selection
# ============================================================================

select_installation_method() {
    print_step "Choose your installation method..."
    echo ""
    echo -e "${BLUE}Available installation methods:${NC}"
    echo ""
    echo -e "${GREEN}1)${NC} npm (Recommended)"
    echo -e "   • Simple and straightforward"
    echo -e "   • Global installation"
    echo -e "   • Best for most users"
    echo ""
    echo -e "${GREEN}2)${NC} Docker"
    echo -e "   • Isolated container environment"
    echo -e "   • Easy to update and manage"
    echo -e "   • Requires Docker installed"
    echo ""
    echo -e "${GREEN}3)${NC} npx (No permanent installation)"
    echo -e "   • Run without installing"
    echo -e "   • Perfect for testing"
    echo -e "   • Slightly slower startup"
    echo ""
    echo -e "${GREEN}4)${NC} Build from source"
    echo -e "   • Latest development version"
    echo -e "   • For contributors/developers"
    echo -e "   • Takes longer to build"
    echo ""
    
    while true; do
        read -p "$(echo -e ${YELLOW}Enter your choice [1-4]:${NC} )" choice
        case $choice in
            1)
                INSTALL_METHOD="npm"
                print_success "Selected: npm installation"
                break
                ;;
            2)
                INSTALL_METHOD="docker"
                print_success "Selected: Docker installation"
                break
                ;;
            3)
                INSTALL_METHOD="npx"
                print_success "Selected: npx (temporary) installation"
                break
                ;;
            4)
                INSTALL_METHOD="source"
                print_success "Selected: Build from source"
                break
                ;;
            *)
                print_error "Invalid choice. Please enter 1, 2, 3, or 4."
                ;;
        esac
    done
    echo ""
}

# ============================================================================
# Docker Installation Functions
# ============================================================================

check_docker() {
    if command_exists docker; then
        print_success "Docker is already installed"
        DOCKER_VERSION=$(docker --version | cut -d ' ' -f 3 | cut -d ',' -f 1)
        print_info "Docker version: $DOCKER_VERSION"
        return 0
    else
        print_warning "Docker is not installed"
        return 1
    fi
}

install_docker() {
    print_step "Installing Docker..."
    
    case $OS in
        macos)
            print_info "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop/"
            print_warning "After installing, restart this script"
            exit 0
            ;;
        ubuntu|debian)
            # Install Docker on Ubuntu/Debian
            sudo apt-get update
            sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
            curl -fsSL https://download.docker.com/linux/${OS}/gpg | sudo apt-key add -
            sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/${OS} $(lsb_release -cs) stable"
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io
            
            # Add current user to docker group
            sudo usermod -aG docker $USER
            print_success "Docker installed successfully"
            print_warning "Please log out and log back in for group changes to take effect"
            ;;
        fedora|rhel|centos)
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
            print_success "Docker installed successfully"
            ;;
        *)
            print_error "Automatic Docker installation not supported for this OS"
            print_info "Please install Docker manually: https://docs.docker.com/get-docker/"
            exit 1
            ;;
    esac
}

install_n8n_docker() {
    print_step "Installing n8n via Docker..."
    
    # Create n8n directory
    N8N_DIR="$HOME/.n8n"
    mkdir -p "$N8N_DIR"
    
    # Create docker-compose.yml
    cat > "$N8N_DIR/docker-compose.yml" << EOF
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: always
    ports:
      - "${N8N_PORT}:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=change_this_password
      - N8N_HOST=localhost
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - WEBHOOK_URL=http://localhost:${N8N_PORT}/
      - GENERIC_TIMEZONE=$(date +%Z)
    volumes:
      - $N8N_DIR:/home/node/.n8n
EOF
    
    print_success "Docker Compose file created"
    
    # Pull and start container
    print_info "Pulling n8n Docker image (this may take a few minutes)..."
    cd "$N8N_DIR"
    docker-compose pull
    
    print_info "Starting n8n container..."
    docker-compose up -d
    
    print_success "n8n Docker container is running!"
    
    # Create convenience scripts
    cat > "$HOME/start-n8n.sh" << 'SCRIPT'
#!/bin/bash
cd ~/.n8n
docker-compose up -d
echo "n8n started! Access at http://localhost:5678"
SCRIPT
    
    cat > "$HOME/stop-n8n.sh" << 'SCRIPT'
#!/bin/bash
cd ~/.n8n
docker-compose down
echo "n8n stopped"
SCRIPT
    
    cat > "$HOME/n8n-logs.sh" << 'SCRIPT'
#!/bin/bash
cd ~/.n8n
docker-compose logs -f
SCRIPT
    
    chmod +x "$HOME/start-n8n.sh" "$HOME/stop-n8n.sh" "$HOME/n8n-logs.sh"
    
    print_success "Helper scripts created: start-n8n.sh, stop-n8n.sh, n8n-logs.sh"
}

# ============================================================================
# npx Installation
# ============================================================================

setup_npx_method() {
    print_step "Setting up npx method..."
    
    print_info "npx allows you to run n8n without permanent installation"
    
    # Create convenience script
    cat > "$HOME/start-n8n.sh" << 'SCRIPT'
#!/bin/bash
echo "Starting n8n via npx..."
echo "This may take a moment on first run..."
npx n8n
SCRIPT
    
    chmod +x "$HOME/start-n8n.sh"
    
    print_success "Launch script created: ~/start-n8n.sh"
    print_info "n8n will be downloaded on first run"
}

# ============================================================================
# Build from Source
# ============================================================================

install_pnpm() {
    if ! command_exists pnpm; then
        print_step "Installing pnpm..."
        npm install -g pnpm
        print_success "pnpm installed"
    else
        print_success "pnpm is already installed"
    fi
}

install_n8n_from_source() {
    print_step "Building n8n from source..."
    
    # Install git if needed
    if ! command_exists git; then
        print_warning "Git is required to clone the repository"
        case $OS in
            macos)
                brew install git
                ;;
            ubuntu|debian)
                sudo apt-get install -y git
                ;;
            fedora|rhel|centos)
                sudo yum install -y git
                ;;
        esac
    fi
    
    # Install pnpm
    install_pnpm
    
    # Clone repository
    BUILD_DIR="$HOME/n8n-source"
    if [ -d "$BUILD_DIR" ]; then
        print_warning "Source directory already exists, removing..."
        rm -rf "$BUILD_DIR"
    fi
    
    print_info "Cloning n8n repository..."
    git clone https://github.com/n8n-io/n8n.git "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    print_info "Installing dependencies (this will take several minutes)..."
    pnpm install
    
    print_info "Building n8n (this will also take several minutes)..."
    pnpm build
    
    print_success "Build complete!"
    
    # Create launch script
    cat > "$HOME/start-n8n.sh" << SCRIPT
#!/bin/bash
cd $BUILD_DIR
pnpm start
SCRIPT
    
    chmod +x "$HOME/start-n8n.sh"
    
    print_success "Launch script created: ~/start-n8n.sh"
}

# ============================================================================
# Main Installation Flow
# ============================================================================

main() {
    clear
    print_header
    
    # Detect OS
    detect_os
    
    # Let user choose installation method
    select_installation_method
    
    # Handle installation based on selected method
    case $INSTALL_METHOD in
        npm)
            # Check and install Node.js
            if ! check_node; then
                print_warning "Node.js needs to be installed or updated"
                read -p "Install/Update Node.js now? (y/n): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    install_node
                    # Verify installation
                    if ! check_node; then
                        print_error "Node.js installation failed"
                        exit 1
                    fi
                else
                    print_error "Node.js is required for npm installation"
                    exit 1
                fi
            fi
            
            # Check system resources
            check_system_resources
            
            # Check port availability
            check_port
            
            # Install n8n
            install_n8n
            
            # Create configuration
            create_config
            
            # Create launch script
            create_launch_script
            ;;
            
        docker)
            # Check Docker
            if ! check_docker; then
                read -p "Install Docker now? (y/n): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    install_docker
                    if ! check_docker; then
                        print_error "Docker installation failed or requires logout"
                        exit 1
                    fi
                else
                    print_error "Docker is required for Docker installation method"
                    exit 1
                fi
            fi
            
            # Check port availability
            check_port
            
            # Install n8n via Docker
            install_n8n_docker
            ;;
            
        npx)
            # Check Node.js for npx
            if ! check_node; then
                print_warning "Node.js needs to be installed for npx"
                read -p "Install Node.js now? (y/n): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    install_node
                    if ! check_node; then
                        print_error "Node.js installation failed"
                        exit 1
                    fi
                else
                    print_error "Node.js is required for npx method"
                    exit 1
                fi
            fi
            
            # Setup npx method
            setup_npx_method
            ;;
            
        source)
            # Check Node.js
            if ! check_node; then
                print_warning "Node.js needs to be installed"
                read -p "Install Node.js now? (y/n): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    install_node
                    if ! check_node; then
                        print_error "Node.js installation failed"
                        exit 1
                    fi
                else
                    print_error "Node.js is required to build from source"
                    exit 1
                fi
            fi
            
            # Build from source
            install_n8n_from_source
            ;;
    esac
    
    # Show post-installation instructions
    print_post_install
}

# ============================================================================
# Run Main
# ============================================================================

main "$@"
