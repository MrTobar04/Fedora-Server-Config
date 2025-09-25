#!/bin/bash

# Script para configurar reglas de firewall para DHCP
# Archivo: configure-dhcp-firewall.sh

echo "=== Configurando reglas de firewall para DHCP ==="

# Variables configurables
INTERFACE="enp0s8"
ZONE="internal"
IPV4_NETWORK="172.16.0.0/24"
SERVER_IP="172.16.0.2"

# Verificar si firewalld está ejecutándose
if ! systemctl is-active --quiet firewalld; then
    echo "❌ firewalld no está ejecutándose. Iniciando servicio..."
    sudo systemctl start firewalld
    sudo systemctl enable firewalld
fi

# Crear zona internal si no existe
echo "🔧 Configurando zona $ZONE..."
sudo firewall-cmd --permanent --new-zone=$ZONE 2>/dev/null || true

# Agregar interfaz a la zona internal
echo "🔧 Agregando interfaz $INTERFACE a zona $ZONE..."
sudo firewall-cmd --permanent --zone=$ZONE --add-interface=$INTERFACE

# Reglas para DHCPv4 (puerto 67 UDP)
echo "🔧 Agregando regla para DHCPv4..."
sudo firewall-cmd --permanent --zone=$ZONE --add-rich-rule="rule family=\"ipv4\" source address=\"$IPV4_NETWORK\" destination address=\"$SERVER_IP\" port port=\"67\" protocol=\"udp\" accept"

# Reglas para DHCPv6 (puerto 547 UDP)
echo "🔧 Agregando regla para DHCPv6..."
sudo firewall-cmd --permanent --zone=$ZONE --add-port=547/udp

# Recargar firewall
echo "🔄 Recargando configuración del firewall..."
sudo firewall-cmd --reload

# Verificar reglas
echo "📋 Reglas activas para DHCP:"
echo "=== Rich Rules ==="
sudo firewall-cmd --zone=$ZONE --list-rich-rules
echo "=== Puertos Abiertos ==="
sudo firewall-cmd --zone=$ZONE --list-ports
echo "=== Interfaces en Zona ==="
sudo firewall-cmd --zone=$ZONE --list-interfaces

echo "✅ Configuración de firewall para DHCP completada"