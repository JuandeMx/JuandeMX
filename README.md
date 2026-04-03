# 🐲 SCRIPT VPS-MX v8.5 - Backup Personalizado

Este repositorio contiene una copia completa y funcional del panel VPS-MX, incluyendo las configuraciones específicas de protocolos (Dropbear, Squid, Stunnel, Apache) y los parches aplicados para compatibilidad con Ubuntu 24.04.

## 🚀 Instalación Rápida (One-Liner)

Para instalar este panel en un VPS nuevo con Ubuntu, ejecuta el siguiente comando:

```bash
apt update && apt install git -y && git clone https://github.com/USUARIO/REPO.git vps-mx && cd vps-mx && sudo bash instalar.sh
```

> **Nota:** Reemplaza `USUARIO/REPO` con tu nombre de usuario y el nombre del repositorio donde subas estos archivos.

## 📦 Qué incluye este backup:
- **Panel VPS-MX:** Carpeta completa `/etc/VPS-MX` con menús corregidos.
- **WebSocket:** Proxy Python configurado para el puerto 80 (compatible con Cloudflare).
- **SSL / Stunnel:** Configurado en el puerto 443.
- **Dropbear:** Configurado en los puertos 44, 143 y 442.
- **Squid:** Proxy configurado en el puerto 3128.
- **Apache:** Configurado en el puerto 81.
- **Compatibilidad:** Ajustes para la visualización de puertos en Ubuntu 24.04.

## 📖 Instrucciones de Uso
Una vez instalado, puedes acceder al panel en cualquier momento escribiendo:
```bash
menu
```
o
```bash
VPSMX
```

---
*Backup generado automáticamente por Antigravity.*
