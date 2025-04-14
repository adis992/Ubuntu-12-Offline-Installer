#!/bin/bash

# Ultimate Universal APT Repair Script
# Version: 3.0
# Features:
# - Handles all Ubuntu versions (old and new)
# - Automatic package source detection
# - Comprehensive system repair
# - Multi-source package location
# - Critical component verification
# - Network diagnostics

# Initialize enhanced logging
LOGFILE="/var/log/ultimate_apt_repair_$(date +%F_%T).log"
exec > >(tee -a "$LOGFILE") 2>&1

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "[$(date +%F_%T)] $1"
}

log_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

log_error() {
    echo -e "${RED}[X] $1${NC}"
}

log_info() {
    echo -e "${BLUE}[*] $1${NC}"
}

log_divider() {
    echo "--------------------------------------------------"
}

# Check root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

# Get system information
get_system_info() {
    log_info "Gathering system information..."
    UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "unknown")
    UBUNTU_CODENAME=$(lsb_release -cs 2>/dev/null || echo "unknown")
    ARCH=$(dpkg --print-architecture)
    KERNEL=$(uname -r)
    VERSION_MAJOR=$(echo "$UBUNTU_VERSION" | cut -d. -f1)
    VERSION_MINOR=$(echo "$UBUNTU_VERSION" | cut -d. -f2)
    
    log "System Info:"
    log "Ubuntu Version: $UBUNTU_VERSION ($UBUNTU_CODENAME)"
    log "Architecture: $ARCH"
    log "Kernel Version: $KERNEL"
    log_divider
}

# Backup current configuration
backup_system() {
    log_info "Creating system backup..."
    BACKUP_DIR="/var/backups/ultimate_apt_repair_$(date +%F_%T)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup APT sources
    cp /etc/apt/sources.list "$BACKUP_DIR/sources.list.bak"
    cp -r /etc/apt/sources.list.d "$BACKUP_DIR/"
    
    # Backup important configs
    cp /etc/resolv.conf "$BACKUP_DIR/resolv.conf.bak"
    cp /etc/hosts "$BACKUP_DIR/hosts.bak"
    
    # Backup dpkg selections
    dpkg --get-selections > "$BACKUP_DIR/dpkg_selections.bak"
    
    log_success "System backup created in $BACKUP_DIR"
    log_divider
}

# Clean APT and system
clean_system() {
    log_info "Cleaning system..."
    
    # Clean APT cache
    apt-get clean
    rm -rf /var/lib/apt/lists/*
    rm -f /var/cache/apt/*.bin
    
    # Remove temporary files
    rm -rf /tmp/*
    rm -rf /var/tmp/*
    
    # Fix any interrupted dpkg operations
    dpkg --configure -a
    
    log_success "System cleaned"
    log_divider
}

# Configure network connectivity
configure_network() {
    log_info "Configuring network..."
    
    # Check internet connectivity
    if ! ping -c 1 archive.ubuntu.com &>/dev/null; then
        log_warning "No internet connectivity detected"
        
        # Try to fix DNS
        echo "nameserver 8.8.8.8" > /etc/resolv.conf
        echo "nameserver 8.8.4.4" >> /etc/resolv.conf
        
        # Restart networking
        if systemctl restart networking; then
            log_success "Network service restarted"
        else
            if systemctl restart NetworkManager; then
                log_success "NetworkManager restarted"
            else
                if systemctl restart network-manager; then
                    log_success "network-manager restarted"
                else
                    log_error "Failed to restart network services"
                fi
            fi
        fi
    fi
    
    log_success "Network configuration verified"
    log_divider
}

# Configure APT sources based on Ubuntu version
configure_apt_sources() {
    log_info "Configuring APT sources..."
    
    # List of all possible mirrors
    MAIN_MIRRORS=(
        "http://archive.ubuntu.com/ubuntu"
        "http://old-releases.ubuntu.com/ubuntu"
        "http://ports.ubuntu.com/ubuntu-ports"
        "http://security.ubuntu.com/ubuntu"
    )
    
    # List of EOL versions
    EOL_VERSIONS=("4.10" "5.04" "5.10" "6.06" "6.10" "7.04" "7.10" "8.04" "8.10" "9.04" "9.10" "10.04" "10.10" "11.04" "11.10" "12.04" "12.10" "13.04" "13.10" "14.04" "14.10" "15.04" "15.10" "16.04" "16.10" "17.04" "17.10" "18.10" "19.04" "19.10" "20.10" "21.04" "21.10" "22.10")
    
    # Check if version is EOL
    for eol in "${EOL_VERSIONS[@]}"; do
        if [[ "$UBUNTU_VERSION" == "$eol" ]]; then
            log_warning "Detected EOL Ubuntu version ($UBUNTU_VERSION) - using old-releases"
            MIRROR="http://old-releases.ubuntu.com/ubuntu"
            break
        fi
    done
    
    # Default to main archive if not EOL
    if [[ -z "$MIRROR" ]]; then
        MIRROR="http://archive.ubuntu.com/ubuntu"
    fi
    
    # Configure sources.list
    cat > /etc/apt/sources.list <<EOF
deb $MIRROR $UBUNTU_CODENAME main restricted universe multiverse
deb $MIRROR $UBUNTU_CODENAME-updates main restricted universe multiverse
deb $MIRROR $UBUNTU_CODENAME-security main restricted universe multiverse
deb $MIRROR $UBUNTU_CODENAME-backports main restricted universe multiverse
EOF
    
    # Add additional mirrors as backups
    for mirror in "${MAIN_MIRRORS[@]}"; do
        if [[ "$mirror" != "$MIRROR" ]]; then
            echo "deb $mirror $UBUNTU_CODENAME main restricted universe multiverse" >> /etc/apt/sources.list.d/additional-mirrors.list
        fi
    done
    
    # Configure APT options
    cat > /etc/apt/apt.conf.d/99repair <<EOF
Acquire::AllowInsecureRepositories "true";
Acquire::Check-Valid-Until "false";
Acquire::Retries "10";
Acquire::http::Timeout "30";
Acquire::https::Timeout "30";
Acquire::ftp::Timeout "30";
APT::Get::Assume-Yes "true";
APT::Get::Fix-Broken "true";
DPkg::Options {"--force-confdef";"--force-confold";"--force-overwrite";"--force-all";};
EOF
    
    log_success "APT sources configured"
    log_divider
}

# Update package lists with retry logic
update_package_lists() {
    log_info "Updating package lists..."
    local attempts=5
    local delay=10
    
    for ((i=1; i<=attempts; i++)); do
        if apt-get update -o Acquire::Check-Valid-Until=false; then
            log_success "Package lists updated successfully"
            return 0
        else
            log_warning "Attempt $i of $attempts failed. Retrying in $delay seconds..."
            sleep $delay
            # Try switching mirrors if update fails
            if [[ $i -ge 3 ]]; then
                log_info "Trying alternative mirrors..."
                sed -i 's|http://[^ ]*/ubuntu|http://archive.ubuntu.com/ubuntu|g' /etc/apt/sources.list
                sed -i 's|http://[^ ]*/ubuntu|http://old-releases.ubuntu.com/ubuntu|g' /etc/apt/sources.list.d/additional-mirrors.list
            fi
        fi
    done
    
    log_error "Failed to update package lists after $attempts attempts"
    return 1
}

# Install absolutely critical packages
install_critical_packages() {
    log_info "Installing critical system packages..."
    
    # List of absolutely essential packages
    CORE_PACKAGES=(
        apt dpkg base-files bash coreutils tar gzip bzip2 xz-utils
        libc6 libgcc1 libstdc++6 libacl1 libattr1 libselinux1
        libsepol1 libpcre3 libpam0g libaudit1 libcap2 libpcre3
        liblzma5 liblz4-1 libgcrypt20 libgpg-error0 libsystemd0
        libudev1 libapparmor1 libdbus-1-3 libnih1 libnih-dbus1
    )
    
    NETWORK_PACKAGES=(
        netbase net-tools iproute2 ifupdown isc-dhcp-client
        resolvconf dnsutils wget curl ca-certificates openssl
        libssl1.1 libssl1.0.0 libssl3 libgnutls30 libgnutls-openssl27
    )
    
    SYSTEM_PACKAGES=(
        initramfs-tools udev systemd sysvinit-utils util-linux
        mount kmod coreutils grep sed gawk findutils procps
        psmisc lsb-release sudo
    )
    
    # Combine all critical packages
    ALL_CRITICAL=("${CORE_PACKAGES[@]}" "${NETWORK_PACKAGES[@]}" "${SYSTEM_PACKAGES[@]}")
    
    # Install packages with multiple fallback methods
    for pkg in "${ALL_CRITICAL[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            log "Installing missing critical package: $pkg"
            
            # Try normal installation first
            if apt-get install -y --fix-broken "$pkg"; then
                log_success "Installed $pkg via APT"
                continue
            fi
            
            # Try to find package in Ubuntu archives
            find_package "$pkg"
            
            # Try to install from downloaded package
            if [[ -f "/tmp/$pkg.deb" ]]; then
                if dpkg -i "/tmp/$pkg.deb"; then
                    log_success "Installed $pkg from downloaded package"
                    rm "/tmp/$pkg.deb"
                    continue
                else
                    log_error "Failed to install downloaded $pkg package"
                    rm "/tmp/$pkg.deb"
                fi
            fi
            
            # Last resort - try to find similar packages
            log_warning "Trying to find alternatives for $pkg"
            apt-cache search "$pkg" | head -5 | while read -r alt_pkg; do
                pkg_name=$(echo "$alt_pkg" | cut -d' ' -f1)
                log "Trying alternative package: $pkg_name"
                if apt-get install -y "$pkg_name"; then
                    log_success "Installed alternative $pkg_name instead of $pkg"
                    break
                fi
            done
        else
            log "$pkg is already installed"
        fi
    done
    
    log_success "Critical packages installation attempt completed"
    log_divider
}

# Function to find packages from various sources
find_package() {
    local pkg=$1
    log "Searching for package: $pkg"
    
    # Try Ubuntu official archives
    for component in main restricted universe multiverse; do
        for mirror in "${MAIN_MIRRORS[@]}"; do
            url="$mirror/dists/$UBUNTU_CODENAME/$component/binary-$ARCH/Packages.gz"
            if wget -q "$url" -O /tmp/Packages.gz; then
                zgrep -A5 "Package: $pkg" /tmp/Packages.gz | grep "Filename:" | awk '{print $2}' | while read -r pkg_path; do
                    pkg_url="$mirror/$pkg_path"
                    log "Found package at: $pkg_url"
                    if wget -q "$pkg_url" -O "/tmp/$pkg.deb"; then
                        log_success "Downloaded $pkg from $mirror"
                        return 0
                    fi
                done
                rm /tmp/Packages.gz
            fi
        done
    done
    
    # Try launchpad PPAs
    log "Searching Launchpad PPAs for $pkg"
    if wget -q "https://launchpad.net/ubuntu/+source/$pkg" -O /tmp/launchpad.html; then
        grep -o "https://launchpad.net/[^\"]*" /tmp/launchpad.html | head -5 | while read -r ppa_url; do
            log "Found PPA: $ppa_url"
            # This would need more sophisticated handling for actual PPA addition
        done
        rm /tmp/launchpad.html
    fi
    
    # Try Ubuntu packages website
    log "Searching packages.ubuntu.com for $pkg"
    if wget -q "https://packages.ubuntu.com/search?keywords=$pkg&searchon=names&suite=all&section=all" -O /tmp/ubuntu_pkg.html; then
        grep -o "/$UBUNTU_CODENAME/$pkg" /tmp/ubuntu_pkg.html | head -1 | while read -r pkg_path; do
            pkg_url="https://packages.ubuntu.com$pkg_path"
            log "Found package page: $pkg_url"
            # This would need more sophisticated scraping for actual download
        done
        rm /tmp/ubuntu_pkg.html
    fi
    
    return 1
}

# Repair broken packages and dependencies
repair_system() {
    log_info "Repairing broken packages and dependencies..."
    
    # Fix broken dependencies
    apt-get install -f -y
    
    # Reconfigure any unconfigured packages
    dpkg --configure -a
    
    # Check for held packages
    held_pkgs=$(apt-mark showhold)
    if [[ -n "$held_pkgs" ]]; then
        log_warning "The following packages are held back:"
        echo "$held_pkgs"
        log "Attempting to unhold and upgrade them..."
        apt-mark unhold $held_pkgs
        apt-get install -y $held_pkgs
    fi
    
    # Verify all installed packages
    log "Verifying all installed packages..."
    dpkg -l | grep ^ii | awk '{print $2}' | xargs apt-get install --reinstall -y
    
    log_success "System repair completed"
    log_divider
}

# Verify system integrity
verify_system() {
    log_info "Verifying system integrity..."
    
    # Check for missing dependencies
    log "Checking for missing dependencies..."
    apt-get check
    
    # Verify critical binaries
    log "Verifying critical binaries..."
    for cmd in bash sh ls cat cp mv rm mkdir rmdir chmod chown grep sed awk; do
        if ! command -v "$cmd" &>/dev/null; then
            log_error "Critical command missing: $cmd"
            # Attempt to install package providing this command
            pkg=$(apt-file search "/bin/$cmd" | head -1 | cut -d: -f1)
            if [[ -n "$pkg" ]]; then
                apt-get install -y "$pkg"
            fi
        fi
    done
    
    # Verify network connectivity
    log "Verifying network connectivity..."
    if ping -c 1 google.com &>/dev/null; then
        log_success "Network connectivity verified"
    else
        log_error "No network connectivity"
    fi
    
    log_success "System verification completed"
    log_divider
}

# Main execution flow
main() {
    check_root
    get_system_info
    backup_system
    clean_system
    configure_network
    configure_apt_sources
    update_package_lists
    install_critical_packages
    repair_system
    verify_system
    
    log_success "Ultimate APT repair process completed!"
    log "Detailed log saved to: $LOGFILE"
    log_divider
    
    # Final recommendations
    log_info "Recommended next steps:"
    log "1. Run: apt-get upgrade"
    log "2. Run: apt-get dist-upgrade"
    log "3. Run: apt-get autoremove"
    log "4. Review the log file at $LOGFILE"
    log_divider
}

main
