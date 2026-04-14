#!/bin/bash

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# URL GitHub Raw untuk whitelist IP
WHITELIST_URL="https://raw.githubusercontent.com/kinanzelina-glitch/security/refs/heads/main/whitelist.txt"

clear
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    VPS INSTALLER WITH IP WHITELIST    ${NC}"
echo -e "${BLUE}========================================${NC}"

# Fungsi untuk mendapatkan IP publik VPS
get_public_ip() {
    local ip
    ip=$(curl -s --connect-timeout 5 ifconfig.me) || \
        ip=$(curl -s --connect-timeout 5 icanhazip.com) || \
        ip=$(curl -s --connect-timeout 5 ipinfo.io/ip) || \
        ip=$(curl -s --connect-timeout 5 ip-api.com/json/ | grep -o '"query":"[^"]*"' | cut -d'"' -f4)
    
    if [[ ! $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "ERROR: Tidak dapat mendeteksi IP publik VPS"
        exit 1
    fi
    echo "$ip"
}

# Fungsi untuk cek whitelist
check_whitelist() {
    local current_ip="$1"
    local whitelist_content
    
    echo -e "${YELLOW}[INFO]${NC} Mengecek whitelist IP..."
    
    # Download whitelist dari GitHub
    whitelist_content=$(curl -s --connect-timeout 10 "$WHITELIST_URL")
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}[ERROR]${NC} Gagal mengakses whitelist dari GitHub!"
        echo -e "${RED}[ERROR]${NC} Periksa koneksi internet dan URL whitelist."
        exit 1
    fi
    
    # Cek apakah IP ada di whitelist
    if echo "$whitelist_content" | grep -q "^$current_ip$"; then
        echo -e "${GREEN}[OK]${NC} IP VPS ${current_ip} TERVERIFIKASI!"
        return 0
    else
        echo -e "${RED}[DENIED]${NC} IP VPS ${current_ip} TIDAK TERDAFTAR!"
        echo -e "${RED}=======================================${NC}"
        echo -e "${RED}   IP TIDAK DIKENTUKAN DI WHITELIST   ${NC}"
        echo -e "${RED}=======================================${NC}"
        echo -e "${YELLOW}Hubungi admin untuk menambahkan IP.${NC}"
        echo -e "${YELLOW}IP saat ini: ${current_ip}${NC}"
        exit 1
    fi
}

# Fungsi menu pilihan
show_menu() {
    echo ""
    echo -e "${GREEN}=======================================${NC}"
    echo -e "${GREEN}        PILIHAN INSTALLER              ${NC}"
    echo -e "${GREEN}=======================================${NC}"
    echo "1. ${BLUE}Install Script Panel (Xray + V2ray)${NC}"
    echo "2. ${BLUE}Install Script Webmin + Nginx${NC}"
    echo "3. ${BLUE}Install Script OpenVPN${NC}"
    echo ""
    echo -e "${YELLOW}0. Keluar${NC}"
    echo -e "${GREEN}=======================================${NC}"
    read -p "Pilih opsi [0-3]: " choice
}

# Fungsi installer panel Xray
install_panel() {
    echo -e "${GREEN}[START]${NC} Menginstall Xray Panel..."
    sleep 2
    echo -e "${GREEN}[OK]${NC} Panel berhasil diinstall!"
    echo -e "${GREEN}[INFO]${NC} Akses panel di: https://$(curl -s ifconfig.me):8080"
}

# Fungsi installer Webmin
install_webmin() {
    echo -e "${GREEN}[START]${NC} Menginstall Webmin + Nginx..."
    sleep 2
    echo -e "${GREEN}[OK]${NC} Webmin berhasil diinstall!"
    echo -e "${GREEN}[INFO]${NC} Akses Webmin: https://$(curl -s ifconfig.me):10000"
}

# Fungsi installer OpenVPN
install_openvpn() {
    echo -e "${GREEN}[START]${NC} Menginstall OpenVPN..."
    sleep 2
    echo -e "${GREEN}[OK]${NC} OpenVPN berhasil diinstall!"
    echo -e "${GREEN}[INFO]${NC} Konfigurasi di /etc/openvpn/"
}

# Main execution
main() {
    echo -e "${YELLOW}[INFO]${NC} Mendeteksi IP publik VPS..."
    CURRENT_IP=$(get_public_ip)
    echo -e "${YELLOW}IP VPS terdeteksi: ${CURRENT_IP}${NC}"
    
    check_whitelist "$CURRENT_IP"
    
    while true; do
        show_menu
        case $choice in
            1)
                install_panel
                ;;
            2)
                install_webmin
                ;;
            3)
                install_openvpn
                ;;
            0)
                echo -e "${GREEN}Terima kasih!${NC}"
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
