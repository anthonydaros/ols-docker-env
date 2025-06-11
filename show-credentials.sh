#!/bin/bash

# Script para exibir credenciais do EmalaBox
# Carrega variáveis do arquivo .env

if [ -f .env ]; then
    source .env
else
    echo "❌ Arquivo .env não encontrado!"
    exit 1
fi

echo "🔐 ===== CREDENCIAIS DO EMBALABOX ===== 🔐"
echo ""
echo "📦 WORDPRESS ADMIN:"
echo "   👤 Usuário: ${WP_ADMIN_USER:-admin}"
echo "   🔑 Senha: ${WP_ADMIN_PASSWORD:-EmalaBox2024!}"
echo ""
echo "🌐 OPENLITESPEED ADMIN:"
echo "   👤 Usuário: ${OLS_ADMIN_USER:-admin}"
echo "   🔑 Senha: ${OLS_ADMIN_PASSWORD:-EmalaBox2024!}"
echo "   🔗 URL: https://localhost:7080"
echo ""
echo "🗄️  MARIADB/MYSQL:"
echo "   👤 Usuário: ${MYSQL_USER:-embalabox_user}"
echo "   🔑 Senha: ${MYSQL_PASSWORD:-embalabox_pass_2024!}"
echo "   🏠 Database: ${MYSQL_DATABASE:-embalabox_db}"
echo "   🔑 Root Password: ${MYSQL_ROOT_PASSWORD:-embalabox_root_2024!}"
echo ""
echo "🔧 PHPMYADMIN:"
echo "   🔗 URL: http://localhost:8080"
echo "   👤 Usuário: root ou ${MYSQL_USER:-embalabox_user}"
echo "   🔑 Senha: ${MYSQL_ROOT_PASSWORD:-embalabox_root_2024!} ou ${MYSQL_PASSWORD:-embalabox_pass_2024!}"
echo ""
echo "📊 REDIS:"
echo "   🔗 Host: redis"
echo "   📡 Porta: 6379"
echo ""
echo "🌍 CONFIGURAÇÕES GERAIS:"
echo "   🌐 Domínio: ${DOMAIN:-localhost}"
echo "   🕒 Timezone: ${TimeZone:-America/Sao_Paulo}"
echo "   📦 OLS Version: ${OLS_VERSION:-1.7.19}"
echo "   🐘 PHP Version: ${PHP_VERSION:-lsphp83}"
echo ""
echo "===============================================" 