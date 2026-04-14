#!/bin/bash

# Warna output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# KONFIGURASI - UBAH INI SESUAI GITHUB KAMU
WHITELIST_URL="https://raw.githubusercontent.com/kinanzelina-glitch/security/refs/heads/main/whitelist.txt"
GITHUB_REPO="https://github.com/kinanzelina-glitch/security"

clear
echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     🚀 VPS INSTALLER PRO v2.0       ║${NC}"
echo -e "${CYAN}║        IP WHITELIST SECURITY        ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""

# ========================================
# FUNGSI DEBUG - CETAK SEMUA INFO
# ========================================
debug_info() {
    echo -e "${PURPLE}🔍 DEBUG MODE - INFORMASI LENGKAP:${NC}"
    echo "----------------------------------------"
    
    # Method 1: ifconfig.me
    IP1=$(timeout 5 curl -s ifconfig.me 2>/dev/null)
    echo "📡 ifconfig.me    : $IP1"
    
    # Method 2: icanhazip.com
    IP2=$(timeout 5 curl -s icanhazip.com 2>/dev/null)
    echo "📡 icanhazip.com  : $IP2"
    
    # Method 3: ipinfo.io
    IP3=$(timeout 5 curl -s ipinfo.io/ip 2>/dev/null)
    echo "📡 ipinfo.io      : $IP3"
    
    # Method 4: ip-api.com
    IP4=$(timeout 5 curl -s "https://ip-api.com/json/?fields=query" 2>/dev/null | grep -o '"query":"[^"]*"' | cut -d'"' -f4)
    echo "📡 ip-api.com     : $IP4"
    
    # Method 5: Check internal interfaces
    IP5=$(ip route get 1 | awk '{print $7;exit}')
    echo "🌐 Internal route : $IP5"
    
    # Method 6: Check all interfaces
    IP6=$(hostname -I | awk '{print $1}')
    echo "🔌 Local network  : $IP6"
    
    echo "----------------------------------------"
}

# ========================================
# GET PUBLIC IP - MULTIPLE FALLBACK
# ========================================
get_public_ip() {
    local ips
    
    # Coba semua method
    ips=(
        $(timeout 5 curl -s ifconfig.me 2>/dev/null)
        $(timeout 5 curl -s icanhazip.com 2>/dev/null)
        $(timeout 5 curl -s ipinfo.io/ip 2>/dev/null)
        $(timeout 5 curl -s "https://ip-api.com/json/?fields=query" 2>/dev/null | grep -o '"query":"[^"]*"' | cut -d'"' -f4)
        $(timeout 5 curl -s "https://api.ipify.org" 2>/dev/null)
        $(timeout 5 curl -s "https://wtfismyip.com/text" 2>/dev/null)
    )
    
    # Filter IP valid
    for ip in "${ips[@]}"; do
        if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            # Validasi IP range 0-255
            valid=true
            IFS='.' read -ra ADDR <<< "$ip"
            for i in "${ADDR[@]}"; do
                if [[ $i -lt 0 || $i -gt 255 ]]; then
                    valid=false
                    break
                fi
            done
            
            if [[ $valid == true ]]; then
                echo "$ip"
                return 0
            fi
        fi
    done
    
    echo ""
    return 1
}

# ========================================
# DOWNLOAD & VALIDASI WHITELIST
# ========================================
check_whitelist() {
    local current_ip="$1"
    local whitelist_content
    local whitelist_ips
    
    echo -e "${YELLOW}🌐 Mengecek koneksi internet...${NC}"
    if ! ping -c 1 8.8.8.8 &>/dev/null; then
        echo -e "${RED}❌ Tidak ada koneksi internet!${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}📥 Mengunduh whitelist dari GitHub...${NC}"
    whitelist_content=$(timeout 10 curl -s -L "$WHITELIST_URL")
    
    if [[ $? -ne 0 || -z "$whitelist_content" ]]; then
        echo -e "${RED}❌ GAGAL download whitelist!${NC}"
        echo -e "${YELLOW}🔗 URL: $WHITELIST_URL${NC}"
        echo -e "${YELLOW}📂 Cek manual: $GITHUB_REPO${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Whitelist berhasil diunduh (${#whitelist_content} bytes)${NC}"
    
    # Extract IP dari whitelist (skip comment & kosong)
    whitelist_ips=$(echo "$whitelist_content" | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' | sort -u)
    
    echo -e "${PURPLE}📋 Daftar IP Whitelist (${$(echo "$whitelist_ips" | wc -l)} IP):${NC}"
    echo "$whitelist_ips" | head -5
    if [[ $(echo "$whitelist_ips" | wc -l) -gt 5 ]]; then
        echo "... dan $(($(echo "$whitelist_ips" | wc -l)-5)) IP lainnya"
    fi
    echo ""
    
    # Cek apakah IP ada di whitelist
    if echo "$whitelist_ips" | grep -q "^$current_ip$"; then
        echo -e "${GREEN}🎉 IP VPS ${current_ip} ✅ TERVERIFIKASI!${NC}"
        echo -e "${GREEN}🚀 Anda dapat melanjutkan instalasi...${NC}"
        sleep 2
        return 0
    else
        echo -e "${RED}🚫 IP VPS ${current_ip} ❌ TIDAK TERDAFTAR!${NC}"
        echo -e "${RED}══════════════════════════════════════════${NC}"
        echo -e "${RED}       IP ANDA BELUM DI WHITELIST        ${NC}"
        echo -e "${RED}══════════════════════════════════════════${NC}"
        echo -e "${YELLOW}📧 IP Anda: ${current_ip}${NC}"
        echo -e "${YELLOW}📂 Tambahkan IP ke: $GITHUB_REPO${NC}"
        echo -e "${YELLOW}🔗 Whitelist: $WHITELIST_URL${NC}"
        echo ""
        echo -e "${PURPLE}💡 Cara tambah IP:${NC}"
        echo "   1. Buka $GITHUB_REPO"
        echo "   2. Edit whitelist.txt"
        echo "   3. Tambah: YOUR_IP_HERE"
        echo "   4. Commit & Push"
        echo ""
        exit 1
    fi
}

# ========================================
# MENU INSTALLER
# ========================================
show_menu() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           🎯 MENU INSTALLER          ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
    echo ""
    echo "1.  ${BLUE}⚡ Xray + V2ray Panel${NC}"
    echo "2.  ${BLUE}🌐 Webmin + Nginx + PHP${NC}"
    echo "3.  ${BLUE}🔒 OpenVPN Server${NC}"
    echo "4.  ${BLUE}📦 Update System & Security${NC}"
    echo ""
    echo "0.  ${RED}❌ Keluar${NC}"
    echo ""
    read -p "👉 Pilih menu [0-4]: " choice
}

# Installers (contoh sederhana)
install_xray() {
    echo -e "${GREEN}🚀 Menginstall Xray Panel...${NC}"
    sleep 3
    echo -e "${GREEN}✅ Xray Panel berhasil diinstall!${NC}"
}

install_webmin() {
    echo -e "${GREEN}🌐 Menginstall Webmin + Stack...${NC}"
    sleep 3
    echo -e "${GREEN}✅ Webmin siap digunakan!${NC}"
}

install_openvpn() {
    echo -e "${GREEN}🔒 Menginstall OpenVPN...${NC}"
    sleep 3
    echo -e "${GREEN}✅ OpenVPN Server aktif!${NC}"
}

install_security() {
    echo -e "${GREEN}🛡️ Update sistem & security...${NC}"
    apt update && apt upgrade -y
    echo -e "${GREEN}✅ Sistem diperbarui!${NC}"
}

# MAIN EXECUTION
main() {
    echo -e "${YELLOW}🔍 DETEKSI IP PUBLIK VPS...${NC}"
    
    CURRENT_IP=$(get_public_ip)
    
    if [[ -z "$CURRENT_IP" ]]; then
        echo -e "${RED}❌ GAGAL deteksi IP publik!${NC}"
        echo -e "${YELLOW}Jalankan debug mode? (y/n)${NC}"
        read -r debug_choice
        if [[ $debug_choice =~ ^[Yy] ]]; then
            debug_info
        fi
        exit 1
    fi
    
    echo -e "${GREEN}✅ IP VPS Anda: ${CYAN}$CURRENT_IP${NC}"
    echo ""
    
    # Verifikasi whitelist
    check_whitelist "$CURRENT_IP"
    
    # Menu utama
    while true; do
        show_menu
        case $choice in
            1) install_xray ;;
            2) install_webmin ;;
            3) install_openvpn ;;
            4) install_security ;;
            0) echo -e "${GREEN}👋 Terima kasih!${NC}"; exit 0 ;;
            *) echo -e "${RED}❌ Pilihan tidak valid!${NC}" ;;
        esac
        
        read -p $'\n👉 Tekan Enter untuk lanjut...'
    done
}

# Jalankan
main
