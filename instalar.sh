#!/bin/bash
# ============================================================
#  INSTALADOR AUTOMATICO VPS-MX - Replica exacta del servidor
#  Compatible con: Ubuntu 20.04 / 22.04 / 24.04
#  Uso: sudo bash instalar.sh
# ============================================================

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Este script debe ejecutarse como root (sudo bash instalar.sh)${NC}"
   exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo -e "${YELLOW}============================================${NC}"
echo -e "${GREEN}   INSTALADOR AUTOMATICO VPS-MX v8.5${NC}"
echo -e "${YELLOW}============================================${NC}"
echo ""

# --- PASO 1: Actualizar sistema ---
echo -e "${GREEN}[1/8]${NC} Actualizando sistema..."
apt-get update -y > /dev/null 2>&1
apt-get upgrade -y > /dev/null 2>&1

# --- PASO 2: Instalar dependencias ---
echo -e "${GREEN}[2/8]${NC} Instalando dependencias..."
apt-get install -y \
    dropbear \
    squid \
    stunnel4 \
    apache2 \
    screen \
    bc \
    lsof \
    net-tools \
    curl \
    wget \
    unzip \
    cron \
    python3 \
    htop \
    netcat-openbsd \
    > /dev/null 2>&1
echo -e "       ${GREEN}Dependencias instaladas correctamente${NC}"

# --- PASO 3: Instalar panel VPS-MX ---
echo -e "${GREEN}[3/8]${NC} Instalando panel VPS-MX..."
mkdir -p /etc/VPS-MX
cp -rv "${SCRIPT_DIR}/VPS-MX/"* /etc/VPS-MX/
# Agregar archivo de versión faltante
echo "8.5" > /etc/versin_script_new
chmod -R 755 /etc/VPS-MX
# Limpiar IP cacheada para que detecte la nueva
rm -f /etc/VPS-MX/MEUIPvps
echo -e "       ${GREEN}Panel VPS-MX instalado en /etc/VPS-MX${NC}"

# --- PASO 4: Configurar Dropbear (puertos 44, 143, 442) ---
echo -e "${GREEN}[4/8]${NC} Configurando Dropbear (puertos 44, 143, 442)..."
cp "${SCRIPT_DIR}/configs/dropbear.conf" /etc/default/dropbear
systemctl enable dropbear > /dev/null 2>&1
systemctl restart dropbear > /dev/null 2>&1
echo -e "       ${GREEN}Dropbear configurado${NC}"

# --- PASO 5: Configurar Squid (puerto 3128) ---
echo -e "${GREEN}[5/8]${NC} Configurando Squid (puerto 3128)..."
cp "${SCRIPT_DIR}/configs/squid.conf" /etc/squid/squid.conf
systemctl enable squid > /dev/null 2>&1
systemctl restart squid > /dev/null 2>&1
echo -e "       ${GREEN}Squid configurado${NC}"

# --- PASO 6: Configurar SSL/Stunnel (puerto 443) ---
echo -e "${GREEN}[6/8]${NC} Configurando Stunnel/SSL (puerto 443)..."
cp "${SCRIPT_DIR}/configs/stunnel.conf" /etc/stunnel/stunnel.conf
cp "${SCRIPT_DIR}/configs/stunnel.pem" /etc/stunnel/stunnel.pem
# Habilitar stunnel
sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4 2>/dev/null
echo "ENABLED=1" > /etc/default/stunnel4
systemctl enable stunnel4 > /dev/null 2>&1
systemctl restart stunnel4 > /dev/null 2>&1
echo -e "       ${GREEN}Stunnel/SSL configurado${NC}"

# --- PASO 7: Configurar Apache (puerto 81) ---
echo -e "${GREEN}[7/8]${NC} Configurando Apache (puerto 81)..."
cp "${SCRIPT_DIR}/configs/apache-ports.conf" /etc/apache2/ports.conf
systemctl enable apache2 > /dev/null 2>&1
systemctl restart apache2 > /dev/null 2>&1
echo -e "       ${GREEN}Apache configurado en puerto 81${NC}"

# --- PASO 8: Configurar accesos y scripts ---
echo -e "${GREEN}[8/8]${NC} Configurando accesos del sistema..."

# Banner de SSH
cp "${SCRIPT_DIR}/configs/issue.net" /etc/issue.net

# Script de reinicio de servicios
cp "${SCRIPT_DIR}/configs/resetsshdrop" /bin/resetsshdrop
chmod +x /bin/resetsshdrop

# Crear comandos de acceso rapido
echo "/etc/VPS-MX/menu" > /bin/menu && chmod +x /bin/menu
echo "/etc/VPS-MX/menu" > /usr/bin/menu && chmod +x /usr/bin/menu
echo "/etc/VPS-MX/menu" > /bin/VPSMX && chmod +x /bin/VPSMX
echo "/etc/VPS-MX/menu" > /usr/bin/VPSMX && chmod +x /usr/bin/VPSMX

# Iniciar el proxy WebSocket en puerto 80
nohup python3 /etc/VPS-MX/protocolos/PDirect.py > /dev/null 2>&1 &

# Configurar SSH para permitir root
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart sshd > /dev/null 2>&1

# Deshabilitar IPv6
sysctl -w net.ipv6.conf.all.disable_ipv6=1 > /dev/null 2>&1
sysctl -w net.ipv6.conf.default.disable_ipv6=1 > /dev/null 2>&1
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf

echo -e "       ${GREEN}Accesos configurados${NC}"

# --- RESULTADO FINAL ---
NEW_IP=$(curl -s https://v4.ident.me)
echo ""
echo -e "${YELLOW}============================================${NC}"
echo -e "${GREEN}   INSTALACION COMPLETADA CON EXITO!${NC}"
echo -e "${YELLOW}============================================${NC}"
echo ""
echo -e " ${GREEN}IP del servidor:${NC} $NEW_IP"
echo ""
echo -e " ${YELLOW}Servicios activos:${NC}"
echo -e "   SSH ............... puerto ${GREEN}22${NC}"
echo -e "   Dropbear .......... puertos ${GREEN}44, 143, 442${NC}"
echo -e "   Proxy WS (Python).. puerto ${GREEN}80${NC}"
echo -e "   Apache ............ puerto ${GREEN}81${NC}"
echo -e "   Squid ............. puerto ${GREEN}3128${NC}"
echo -e "   Stunnel/SSL ....... puerto ${GREEN}443${NC}"
echo ""
echo -e " ${YELLOW}Comandos disponibles:${NC}"
echo -e "   ${GREEN}menu${NC}   - Abrir el panel VPS-MX"
echo -e "   ${GREEN}VPSMX${NC}  - Abrir el panel VPS-MX"
echo ""
echo -e "${YELLOW}============================================${NC}"
echo -e " Ejecuta ${GREEN}sudo menu${NC} para abrir el panel"
echo -e "${YELLOW}============================================${NC}"

