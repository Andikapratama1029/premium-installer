#!/bin/bash

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# URL raw GitHub untuk daftar IP VPS yang diizinkan
ALLOWED_IPS_URL="https://raw.githubusercontent.com/kinanzelina-glitch/security/refs/heads/main/whitelist.txt"

clear
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    VPS INSTALLER WITH IP SECURITY     ${NC}"
echo -e "${BLUE}========================================${NC}"

# Fungsi untuk mendapatkan IP publik
get_public_ip() {
    local ip
    ip=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || \
         curl -s --connect-timeout 5 icanhazip.com 2>/dev/null || \
         curl -s --connect-timeout 5 ipinfo.io/ip 2>/dev/null)
    echo "$ip"
}

# Fungsi untuk check IP di GitHub
check_ip_security() {
    local current_ip="$1"
    echo -e "${YELLOW}[INFO]${NC} Mengecek keamanan IP VPS..."
    
    # Download daftar IP yang diizinkan
    local allowed_ips
    allowed_ips=$(curl -s --connect-timeout 10 "$ALLOWED_IPS_URL")
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}[ERROR]${NC} Gagal mengakses daftar IP keamanan!"
        echo -e "${RED}[ERROR]${NC} Periksa koneksi internet atau URL GitHub"
        exit 1
    fi
    
    # Cek apakah IP ada di daftar
    if echo "$allowed_ips" | grep -Fxq "$current_ip"; then
        echo -e "${GREEN}[OK]${NC} IP VPS ${current_ip} TERVERIFIKASI!"
        return 0
    else
        echo -e "${RED}[DENIED]${NC} IP ${current_ip} TIDAK DIIZINKAN!"
        echo -e "${RED}Hubungi admin untuk menambahkan IP ke whitelist.${NC}"
        return 1
    fi
}

# Fungsi menu pilihan bash/cmd
show_menu() {
    echo -e "\n${GREEN}🎉 IP VPS ANDA SUDAH TERDAFTAR!${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo "Pilih script yang ingin dijalankan:"
    echo "1. ${GREEN}INSTALLER PTERODACTYL & THEMA${NC}"
    echo "2. ${GREEN}INSTALLER CTRL PANEL${NC}"
    echo "0. Keluar"
    echo -e "${BLUE}========================================${NC}"
}

# Main execution
main() {
    echo -e "${YELLOW}[INFO]${NC} Mendapatkan IP publik VPS..."
    CURRENT_IP=$(get_public_ip)
    
    if [[ -z "$CURRENT_IP" ]]; then
        echo -e "${RED}[ERROR]${NC} Gagal mendapatkan IP publik!"
        exit 1
    fi
    
    echo -e "${GREEN}[INFO]${NC} IP VPS Anda: ${BLUE}$CURRENT_IP${NC}"
    
    if ! check_ip_security "$CURRENT_IP"; then
        exit 1
    fi
    
    # Loop menu
    while true; do
        show_menu
        read -p "Pilih opsi [0-2]: " choice
        
        case $choice in
            1)
                echo -e "${GREEN} MELIHAT MENU PTERODACTYL INSTALLER...${NC}"
                bash <(curl -s https://raw.githubusercontent.com/username/repo/main/lemp-install.sh)
                ;;
            2)
                echo -e "${GREEN} MENGINSTALL CTRL PANEL...${NC}"
                bash <(curl -s https://raw.githubusercontent.com/username/repo/main/openvpn-install.sh)
                ;;
            0)
                echo -e "${GREEN}👋 Terima kasih!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Pilihan tidak valid!${NC}"
                ;;
        esac
        
        read -p "Tekan Enter untuk melanjutkan..."
        clear
    done
}

# Jalankan main
main
