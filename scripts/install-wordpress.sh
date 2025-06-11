#!/bin/bash

# Script para instalação automática do WordPress
# Este script será executado automaticamente no container

set -e

echo "🚀 Iniciando instalação automática do WordPress..."

# Aguardar MySQL estar disponível
echo "⏳ Aguardando MySQL estar disponível..."
while ! mysqladmin ping -h"mysql" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent; do
    echo "   MySQL ainda não está pronto... aguardando 5 segundos"
    sleep 5
done
echo "✅ MySQL está disponível!"

# Diretório do site
SITE_DIR="/var/www/vhosts/localhost/html"
DOMAIN="${DOMAIN:-localhost}"

# Limpar diretório se já existir conteúdo
if [ -d "$SITE_DIR" ]; then
    echo "🧹 Limpando diretório do site..."
    rm -rf "$SITE_DIR"/*
fi

# Criar diretório se não existir
mkdir -p "$SITE_DIR"
cd "$SITE_DIR"

# Download do WordPress
echo "📥 Baixando WordPress..."
wget -q https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz --strip-components=1
rm latest.tar.gz

# Configurar permissões
echo "🔧 Configurando permissões..."
chown -R www-data:www-data "$SITE_DIR"
chmod -R 755 "$SITE_DIR"

# Criar wp-config.php
echo "⚙️ Configurando wp-config.php..."
cat > wp-config.php << EOF
<?php
define('DB_NAME', '${MYSQL_DATABASE}');
define('DB_USER', '${MYSQL_USER}');
define('DB_PASSWORD', '${MYSQL_PASSWORD}');
define('DB_HOST', 'mysql');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

// Chaves de segurança
define('AUTH_KEY',         '$(openssl rand -base64 48)');
define('SECURE_AUTH_KEY',  '$(openssl rand -base64 48)');
define('LOGGED_IN_KEY',    '$(openssl rand -base64 48)');
define('NONCE_KEY',        '$(openssl rand -base64 48)');
define('AUTH_SALT',        '$(openssl rand -base64 48)');
define('SECURE_AUTH_SALT', '$(openssl rand -base64 48)');
define('LOGGED_IN_SALT',   '$(openssl rand -base64 48)');
define('NONCE_SALT',       '$(openssl rand -base64 48)');

// Configurações do Redis (se disponível)
define('WP_REDIS_HOST', 'redis');
define('WP_REDIS_PORT', 6379);
define('WP_REDIS_TIMEOUT', 1);
define('WP_REDIS_READ_TIMEOUT', 1);
define('WP_REDIS_DATABASE', 0);

// Configurações adicionais
define('WP_DEBUG', false);
define('WP_DEBUG_LOG', false);
define('WP_DEBUG_DISPLAY', false);
define('SCRIPT_DEBUG', false);
define('WP_MEMORY_LIMIT', '256M');

// Forçar HTTPS se disponível
if (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    \$_SERVER['HTTPS'] = 'on';
    \$_SERVER['SERVER_PORT'] = 443;
}

// URL do site
define('WP_HOME', 'http://${DOMAIN}:8086');
define('WP_SITEURL', 'http://${DOMAIN}:8086');

// Tabela prefix
\$table_prefix = 'wp_';

// Configurações finais
if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}

require_once ABSPATH . 'wp-settings.php';
EOF

# Aguardar um pouco para MySQL estar totalmente pronto
echo "⏳ Aguardando MySQL estar totalmente pronto..."
sleep 10

# Instalar WordPress via WP-CLI
echo "🔧 Instalando WordPress via WP-CLI..."

# Download WP-CLI
curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/gh-pages/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

# Instalar WordPress
wp core install \
    --url="http://${DOMAIN}:8086" \
    --title="EmalaBox - WordPress com OpenLiteSpeed" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASSWORD}" \
    --admin_email="admin@${DOMAIN}" \
    --allow-root \
    --path="$SITE_DIR"

# Instalar e ativar plugin LiteSpeed Cache
echo "🚀 Instalando LiteSpeed Cache Plugin..."
wp plugin install litespeed-cache --activate --allow-root --path="$SITE_DIR"

# Configurar tema padrão
echo "🎨 Configurando tema..."
wp theme activate twentytwentyfour --allow-root --path="$SITE_DIR" || wp theme activate twentytwentythree --allow-root --path="$SITE_DIR"

# Configurar permissões finais
chown -R www-data:www-data "$SITE_DIR"
chmod -R 755 "$SITE_DIR"

# Criar arquivo de sucesso
touch /tmp/wordpress-installed

echo "✅ WordPress instalado com sucesso!"
echo "🌐 URL: http://${DOMAIN}:8086"
echo "👤 Admin: ${WP_ADMIN_USER}"
echo "🔑 Senha: ${WP_ADMIN_PASSWORD}"
echo "📧 Email: admin@${DOMAIN}" 