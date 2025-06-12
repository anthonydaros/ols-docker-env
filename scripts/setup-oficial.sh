#!/bin/bash

# Setup Oficial baseado na documentação LiteSpeed
set -e

echo "🚀 Setup Oficial LiteSpeed + WordPress"
echo "📖 Baseado em: https://docs.litespeedtech.com/cloud/docker/ols-wordpress/"

# Aguardar LiteSpeed estar pronto
echo "⏳ Aguardando LiteSpeed inicializar..."
sleep 20

# Verificar se banco externo está disponível
echo "🔗 Verificando conexão com banco externo..."
echo "Host: ${WORDPRESS_DB_HOST}"
echo "Database: ${WORDPRESS_DB_NAME}"
echo "User: ${WORDPRESS_DB_USER}"

max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if mysqladmin ping -h${WORDPRESS_DB_HOST%:*} -P${WORDPRESS_DB_HOST#*:} -u${WORDPRESS_DB_USER} -p${WORDPRESS_DB_PASSWORD} --silent; then
        echo "✅ Banco externo conectado!"
        break
    fi
    echo "⏳ Aguardando banco... (tentativa $((attempt + 1))/$max_attempts)"
    sleep 10
    attempt=$((attempt + 1))
done

if [ $attempt -eq $max_attempts ]; then
    echo "❌ Não foi possível conectar ao banco externo"
    exit 1
fi

# Criar estrutura de diretórios conforme documentação oficial
echo "📁 Criando estrutura de diretórios oficial..."
mkdir -p /var/www/vhosts/localhost
mkdir -p /usr/local/lsws/logs

# Usar o script demosite.sh oficial (se disponível) ou criar manualmente
echo "🌐 Configurando site demo..."

# Simular o comando oficial: bash bin/demosite.sh
# Como não temos acesso direto, vamos replicar a funcionalidade

# 1. Baixar WordPress
echo "📥 Baixando WordPress..."
cd /var/www/vhosts/localhost
wget -q https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
mv wordpress/* .
rm -rf wordpress latest.tar.gz

# 2. Configurar permissões
echo "🔒 Configurando permissões..."
chown -R www-data:www-data /var/www/vhosts/localhost
chmod -R 755 /var/www/vhosts/localhost

# 3. Configurar wp-config.php para banco externo
echo "⚙️ Configurando wp-config.php..."
cat > wp-config.php << EOF
<?php
define('DB_NAME', '${WORDPRESS_DB_NAME}');
define('DB_USER', '${WORDPRESS_DB_USER}');
define('DB_PASSWORD', '${WORDPRESS_DB_PASSWORD}');
define('DB_HOST', '${WORDPRESS_DB_HOST}');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

define('WP_HOME', 'http://${DOMAIN}');
define('WP_SITEURL', 'http://${DOMAIN}');

\$table_prefix = 'embalabox_';

define('WP_DEBUG', false);

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';
EOF

# 4. Instalar WordPress via WP-CLI
echo "🔧 Instalando WordPress via WP-CLI..."

# Baixar WP-CLI
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

# Verificar se tabelas já existem
if wp core is-installed --path=/var/www/vhosts/localhost 2>/dev/null; then
    echo "✅ WordPress já instalado, pulando instalação"
else
    echo "🎯 Instalando WordPress..."
    wp core install \
        --path=/var/www/vhosts/localhost \
        --url="http://${DOMAIN}" \
        --title="EmalaBox WordPress" \
        --admin_user="admin" \
        --admin_password="EmalaBox2024!" \
        --admin_email="admin@${DOMAIN}" \
        --allow-root
fi

# 5. Instalar LiteSpeed Cache Plugin
echo "🚀 Instalando LiteSpeed Cache Plugin..."
wp plugin install litespeed-cache --activate --path=/var/www/vhosts/localhost --allow-root || echo "Plugin já instalado"

# 6. Configurar tema
echo "🎨 Ativando tema Twenty Twenty-Four..."
wp theme activate twentytwentyfour --path=/var/www/vhosts/localhost --allow-root || echo "Tema não encontrado, usando padrão"

# 7. Verificar configuração do LiteSpeed
echo "🔧 Verificando configuração do LiteSpeed..."

# Verificar se httpd_config.conf tem virtual host
if ! grep -q "virtualhost localhost" /usr/local/lsws/conf/httpd_config.conf 2>/dev/null; then
    echo "📝 Adicionando virtual host ao httpd_config.conf..."
    
    # Backup
    cp /usr/local/lsws/conf/httpd_config.conf /usr/local/lsws/conf/httpd_config.conf.backup 2>/dev/null || true
    
    # Adicionar virtual host básico
    cat >> /usr/local/lsws/conf/httpd_config.conf << 'EOF'

virtualhost localhost {
  vhRoot                  /var/www/vhosts/localhost/
  configFile              /usr/local/lsws/conf/vhosts/localhost/vhconf.conf
  allowSymbolLink         1
  enableScript            1
  restrained              0
}

listener Default {
  address                 *:80
  secure                  0
  map                     localhost *
}
EOF
fi

# 8. Criar configuração do virtual host se não existir
echo "📝 Criando configuração do virtual host..."
mkdir -p /usr/local/lsws/conf/vhosts/localhost

cat > /usr/local/lsws/conf/vhosts/localhost/vhconf.conf << 'EOF'
docRoot                   $VH_ROOT/
enableGzip                1

errorlog $VH_ROOT/logs/error.log {
  useServer               1
  logLevel                DEBUG
  rollingSize             10M
}

accesslog $VH_ROOT/logs/access.log {
  useServer               0
  logFormat               "%h %l %u %t \"%r\" %>s %b"
  logHeaders              5
  rollingSize             10M
  keepDays                10  
}

index  {
  useServer               0
  indexFiles              index.php, index.html
}

scripthandler  {
  add                     lsphp83 php
}

rewrite  {
  enable                  1
  autoLoadHtaccess        1
  logLevel                0
}
EOF

# 9. Configurar permissões finais
echo "🔒 Configurando permissões finais..."
chown -R www-data:www-data /var/www/vhosts/localhost
chmod -R 755 /var/www/vhosts/localhost
chown -R lsadm:lsadm /usr/local/lsws/conf/ 2>/dev/null || echo "Usuário lsadm não encontrado"

# 10. Reiniciar LiteSpeed
echo "🔄 Reiniciando LiteSpeed..."
/usr/local/lsws/bin/lswsctrl restart

echo ""
echo "✅ Setup Oficial Concluído!"
echo "🌐 Site: http://${DOMAIN}/"
echo "🔧 Admin WordPress: http://${DOMAIN}/wp-admin"
echo "👤 Usuário: admin"
echo "🔑 Senha: EmalaBox2024!"
echo "🗄️ Banco: ${WORDPRESS_DB_HOST}/${WORDPRESS_DB_NAME}"
echo ""
echo "📊 Verificando instalação:"
ls -la /var/www/vhosts/localhost/ | head -10 