#!/bin/bash

# Script para configurar reglas de firewall para DNS
# Archivo: configure-dns-firewall.sh

echo "=== Configurando reglas de firewall para DNS ==="

# Variables configurables
ZONE="internal"
IPV4_NETWORK="172.16.0.0/24"
IPV6_NETWORK="2001:db7:dea:a::/64"

# Verificar si firewalld está ejecutándose
if ! systemctl is-active --quiet firewalld; then
    echo "❌ firewalld no está ejecutándose. Iniciando servicio..."
    sudo systemctl start firewalld
    sudo systemctl enable firewalld
fi

# Agregar servicio DNS a la zona internal
echo "🔧 Agregando servicio DNS a zona $ZONE..."

# Regla para IPv4
echo "🔧 Agregando regla DNS para IPv4..."
sudo firewall-cmd --permanent --zone=$ZONE --add-rich-rule="rule family=\"ipv4\" source address=\"$IPV4_NETWORK\" service name=\"dns\" accept"

# Regla para IPv6
echo "🔧 Agregando regla DNS para IPv6..."
sudo firewall-cmd --permanent --zone=$ZONE --add-rich-rule="rule family=\"ipv6\" source address=\"$IPV6_NETWORK\" service name=\"dns\" accept"

# También agregar el servicio DNS directamente (como respaldo)
echo "🔧 Agregando servicio DNS directamente..."
sudo firewall-cmd --permanent --zone=$ZONE --add-service=dns

# Recargar firewall
echo "🔄 Recargando configuración del firewall..."
sudo firewall-cmd --reload

# Verificar reglas
echo "📋 Reglas activas para DNS:"
echo "=== Rich Rules ==="
sudo firewall-cmd --zone=$ZONE --list-rich-rules | grep dns
echo "=== Servicios ==="
sudo firewall-cmd --zone=$ZONE --list-services | grep dns

echo "✅ Configuración de firewall para DNS completada"