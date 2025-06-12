#!/bin/bash

# Script de Debug Automático do OpenLiteSpeed
set -e

echo "🕐 Aguardando outros containers terminarem..."

# Aguardar 30 segundos para garantir que outros containers terminaram
sleep 30

echo "🔍 Verificando se WordPress installer terminou..."

# Aguardar até que WordPress esteja instalado
max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if [ -f "/var/www/vhosts/localhost/html/wp-config.php" ]; then
        echo "✅ WordPress encontrado!"
        break
    fi
    echo "⏳ Aguardando WordPress... (tentativa $((attempt + 1))/$max_attempts)"
    sleep 10
    attempt=$((attempt + 1))
done

if [ $attempt -eq $max_attempts ]; then
    echo "⚠️ WordPress não encontrado após ${max_attempts} tentativas, prosseguindo mesmo assim..."
fi

echo "🚀 Iniciando debug e correção do LiteSpeed..."

# Executar o script de debug original
/scripts/debug-and-fix-litespeed.sh

echo "✅ Debug automático concluído!"
echo "🌐 Teste o site: http://103.199.185.165:8086/" 