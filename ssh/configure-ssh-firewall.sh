#!/bin/bash

# Script para configurar reglas de firewall para SSH
# Archivo: configure-ssh-firewall.sh

echo "=== Configurando reglas de firewall para SSH ==="

# Verificar si firewalld está ejecutándose
if ! systemctl is-active --quiet firewalld; then
    echo "❌ firewalld no está ejecutándose. Iniciando servicio..."
    sudo systemctl start firewalld
    sudo systemctl enable firewalld
fi

# Agregar regla para permitir SSH desde IP específica
echo "🔧 Agregando regla para SSH desde 10.0.2.2..."
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.0.2.2" port port="22" protocol="tcp" accept'

# Agregar también regla general para SSH (opcional)
echo "🔧 Agregando regla general para SSH..."
sudo firewall-cmd --permanent --add-service=ssh

# Recargar firewall
echo "🔄 Recargando configuración del firewall..."
sudo firewall-cmd --reload

# Verificar reglas
echo "📋 Reglas activas para SSH:"
sudo firewall-cmd --list-rich-rules | grep ssh
sudo firewall-cmd --list-services | grep ssh

echo "✅ Configuración de firewall para SSH completada"