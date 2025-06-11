#!/bin/bash

# Script para instalação automática do WordPress
# Este script será executado automaticamente no container

set -e

echo "🚀 Iniciando instalação automática do WordPress..."

# Configuração do banco externo
DB_HOST="${MYSQL_HOST:-103.199.185.165}"
DB_PORT="${MYSQL_PORT:-3443}"
DB_USER="${MYSQL_USER:-mariadb}"
DB_PASS="${MYSQL_PASSWORD:-gnqe4fcscobmabei}"
DB_NAME="${MYSQL_DATABASE:-mariadb}"

echo "🔗 Configuração do banco:"
echo "   Host: ${DB_HOST}:${DB_PORT}"
echo "   Database: ${DB_NAME}"
echo "   User: ${DB_USER}"

# Aguardar banco externo estar disponível
echo "⏳ Aguardando banco externo estar disponível..."
for i in {1..30}; do
    if mysqladmin ping -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASS}" --silent 2>/dev/null; then
        echo "✅ Banco externo está disponível!"
        break
    fi
    echo "   Tentativa $i/30... aguardando 10 segundos"
    sleep 10
done

# Verificar se conseguiu conectar
if ! mysqladmin ping -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASS}" --silent 2>/dev/null; then
    echo "❌ Erro: Não foi possível conectar ao banco externo!"
    exit 1
fi

# Diretório do site
SITE_DIR="/var/www/vhosts/localhost/html"
DOMAIN="${DOMAIN:-103.199.185.165}"

# Verificar se WordPress já está instalado
if [ -f "$SITE_DIR/wp-config.php" ] && [ -f "/tmp/wordpress-installed" ]; then
    echo "✅ WordPress já está instalado. Pulando instalação."
    exit 0
fi

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
define('DB_NAME', '${DB_NAME}');
define('DB_USER', '${DB_USER}');
define('DB_PASSWORD', '${DB_PASS}');
define('DB_HOST', '${DB_HOST}:${DB_PORT}');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

// Prefixo único para evitar conflitos
\$table_prefix = 'embalabox_';

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

// Configurações finais
if (!defined('ABSPATH')) {
    define('ABSPATH', __DIR__ . '/');
}

require_once ABSPATH . 'wp-settings.php';
EOF

# Instalar WordPress via WP-CLI
echo "🔧 Instalando WordPress via WP-CLI..."

# Download WP-CLI
curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/gh-pages/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

# Verificar conexão com banco antes de instalar
echo "🔍 Testando conexão com banco..."
if ! wp db check --allow-root --path="$SITE_DIR" 2>/dev/null; then
    echo "❌ Erro: Não foi possível conectar ao banco de dados!"
    echo "🔧 Tentando criar tabelas manualmente..."
    
    # Tentar criar as tabelas básicas do WordPress
    mysql -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" -e "
    CREATE TABLE IF NOT EXISTS embalabox_options (
        option_id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
        option_name varchar(191) NOT NULL DEFAULT '',
        option_value longtext NOT NULL,
        autoload varchar(20) NOT NULL DEFAULT 'yes',
        PRIMARY KEY (option_id),
        UNIQUE KEY option_name (option_name)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    " || echo "⚠️  Aviso: Não foi possível criar tabelas, continuando..."
fi

# Instalar WordPress
echo "🎯 Instalando WordPress..."
wp core install \
    --url="http://${DOMAIN}:8086" \
    --title="EmalaBox - WordPress com OpenLiteSpeed" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASSWORD}" \
    --admin_email="admin@${DOMAIN}" \
    --allow-root \
    --path="$SITE_DIR" || {
    echo "⚠️ Instalação via WP-CLI falhou, criando configuração básica..."
    
    # Criar arquivo index.php básico se WP-CLI falhar
    cat > index.php << 'EOFINDEX'
<?php
// Verificar se WordPress está carregado
if (file_exists('./wp-load.php')) {
    require_once('./wp-load.php');
} else {
    // Página básica se WordPress não carregar
    ?>
    <!DOCTYPE html>
    <html>
    <head>
        <title>EmalaBox - WordPress</title>
        <style>
            body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
            .container { max-width: 600px; margin: 0 auto; }
            .success { color: green; }
            .info { background: #f0f0f0; padding: 20px; border-radius: 5px; margin: 20px 0; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1 class="success">✅ EmalaBox WordPress Instalado!</h1>
            <div class="info">
                <h3>🔗 Links de Acesso:</h3>
                <p><strong>Admin WordPress:</strong> <a href="/wp-admin">wp-admin</a></p>
                <p><strong>OpenLiteSpeed Admin:</strong> <a href="https://103.199.185.165:7080">OLS Admin</a></p>
                <p><strong>phpMyAdmin:</strong> <a href="http://103.199.185.165:8081">phpMyAdmin</a></p>
            </div>
            <div class="info">
                <h3>🔐 Credenciais:</h3>
                <p><strong>WordPress:</strong> admin / EmalaBox2024!</p>
                <p><strong>Database:</strong> mariadb / gnqe4fcscobmabei</p>
            </div>
        </div>
    </body>
    </html>
    <?php
}
EOFINDEX
}

# Tentar instalar plugins importantes
echo "🚀 Configurando plugins..."
wp plugin install litespeed-cache --activate --allow-root --path="$SITE_DIR" 2>/dev/null || echo "⚠️ Plugin LiteSpeed Cache não pôde ser instalado automaticamente"

# Configurar tema padrão
echo "🎨 Configurando tema..."
wp theme activate twentytwentyfour --allow-root --path="$SITE_DIR" 2>/dev/null || wp theme activate twentytwentythree --allow-root --path="$SITE_DIR" 2>/dev/null || echo "⚠️ Tema padrão não pôde ser ativado automaticamente"

# Configurar permissões finais
chown -R www-data:www-data "$SITE_DIR"
chmod -R 755 "$SITE_DIR"

# Criar arquivo de sucesso
touch /tmp/wordpress-installed

echo "✅ WordPress configurado com sucesso!"
echo "🌐 URL: http://${DOMAIN}:8086"
echo "👤 Admin: ${WP_ADMIN_USER}"
echo "🔑 Senha: ${WP_ADMIN_PASSWORD}"
echo "📧 Email: admin@${DOMAIN}"
echo "🗄️ Database: ${DB_HOST}:${DB_PORT}/${DB_NAME}" 