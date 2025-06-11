#!/bin/bash

# Script para configurar OpenLiteSpeed Virtual Host
set -e

echo "🔧 Configurando OpenLiteSpeed Virtual Host..."

# Aguardar OpenLiteSpeed estar rodando
sleep 10

# Configurar virtual host para localhost
VHOST_CONF="/usr/local/lsws/conf/vhosts/localhost/vhconf.conf"
HTTPD_CONF="/usr/local/lsws/conf/httpd_config.conf"

# Criar diretório de configuração do vhost se não existir
mkdir -p /usr/local/lsws/conf/vhosts/localhost

# Configurar virtual host
cat > "$VHOST_CONF" << 'EOF'
docRoot                   /var/www/vhosts/localhost/html/
vhDomain                  *
vhAliases                 
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

phpIniOverride  {
php_admin_value open_basedir "/var/www/vhosts/localhost/:/tmp/"
}

rewrite  {
  enable                  1
  autoLoadHtaccess        1
  logLevel                0
}

vhssl  {
  keyFile                 /usr/local/lsws/conf/cert/localhost.key
  certFile                /usr/local/lsws/conf/cert/localhost.crt
}
EOF

# Atualizar configuração principal do httpd
if ! grep -q "vhost localhost" "$HTTPD_CONF"; then
    echo "📝 Atualizando configuração principal..."
    
    # Backup da configuração original
    cp "$HTTPD_CONF" "$HTTPD_CONF.backup"
    
    # Adicionar virtual host à configuração principal
    cat >> "$HTTPD_CONF" << 'EOF'

virtualhost localhost {
  vhRoot                  /var/www/vhosts/localhost/
  configFile              /usr/local/lsws/conf/vhosts/localhost/vhconf.conf
  allowSymbolLink         1
  enableScript            1
  restrained              0
  setUIDMode              0
}

listener HTTP {
  address                 *:80
  secure                  0
  map                     localhost *
}

listener HTTPS {
  address                 *:443
  secure                  1
  keyFile                 /usr/local/lsws/conf/cert/localhost.key
  certFile                /usr/local/lsws/conf/cert/localhost.crt
  map                     localhost *
}
EOF
fi

# Gerar certificados SSL auto-assinados se não existirem
if [ ! -f "/usr/local/lsws/conf/cert/localhost.crt" ]; then
    echo "🔐 Gerando certificados SSL..."
    mkdir -p /usr/local/lsws/conf/cert
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /usr/local/lsws/conf/cert/localhost.key \
        -out /usr/local/lsws/conf/cert/localhost.crt \
        -subj "/C=BR/ST=SP/L=SaoPaulo/O=EmalaBox/CN=localhost"
fi

# Configurar permissões
echo "🔧 Configurando permissões..."
chown -R lsadm:lsadm /usr/local/lsws/conf/
chmod -R 755 /usr/local/lsws/conf/
chown -R www-data:www-data /var/www/vhosts/
chmod -R 755 /var/www/vhosts/

# Criar arquivo de teste se WordPress não estiver funcionando
if [ ! -f "/var/www/vhosts/localhost/html/index.php" ]; then
    echo "⚠️ WordPress não encontrado, criando página de teste..."
    mkdir -p /var/www/vhosts/localhost/html
    cat > /var/www/vhosts/localhost/html/index.php << 'EOFTEST'
<?php
phpinfo();
echo "<hr><h2>EmalaBox Test Page</h2>";
echo "<p>If you see this page, OpenLiteSpeed is working correctly!</p>";
echo "<p><a href='/wp-admin'>WordPress Admin</a></p>";
EOFTEST
    chown www-data:www-data /var/www/vhosts/localhost/html/index.php
fi

# Restart OpenLiteSpeed
echo "🔄 Reiniciando OpenLiteSpeed..."
/usr/local/lsws/bin/lswsctrl restart

echo "✅ OpenLiteSpeed configurado com sucesso!"
echo "🌐 Teste: http://localhost/"
echo "🔒 HTTPS: https://localhost/" 