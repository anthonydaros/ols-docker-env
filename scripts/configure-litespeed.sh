#!/bin/bash

# Script para configurar OpenLiteSpeed Virtual Host
set -e

echo "🔧 Configurando OpenLiteSpeed Virtual Host..."

# Criar diretórios necessários
mkdir -p /usr/local/lsws/logs
mkdir -p /usr/local/lsws/conf/vhosts/localhost

# Aguardar OpenLiteSpeed estar rodando
sleep 10

# Verificar se WordPress existe antes de sobrescrever
SITE_DIR="/var/www/vhosts/localhost/html"
if [ -f "$SITE_DIR/wp-config.php" ]; then
    echo "✅ WordPress encontrado em $SITE_DIR - mantendo instalação"
    WP_EXISTS=true
else
    echo "⚠️ WordPress não encontrado em $SITE_DIR"
    WP_EXISTS=false
fi

# Configurar virtual host para localhost
VHOST_CONF="/usr/local/lsws/conf/vhosts/localhost/vhconf.conf"
HTTPD_CONF="/usr/local/lsws/conf/httpd_config.conf"

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

# Atualizar configuração principal do httpd apenas se necessário
if ! grep -q "virtualhost localhost" "$HTTPD_CONF"; then
    echo "📝 Atualizando configuração principal..."
    
    # Backup da configuração original
    cp "$HTTPD_CONF" "$HTTPD_CONF.backup"
    
    # Remover configurações antigas de listener se existirem
    sed -i '/listener.*{/,/^}/d' "$HTTPD_CONF"
    sed -i '/virtualhost.*{/,/^}/d' "$HTTPD_CONF"
    
    # Adicionar nova configuração
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

# Criar logs directory se não existir
mkdir -p /var/www/vhosts/localhost/logs

# Configurar permissões
echo "🔧 Configurando permissões..."
chown -R lsadm:lsadm /usr/local/lsws/conf/
chmod -R 755 /usr/local/lsws/conf/
chown -R www-data:www-data /var/www/vhosts/
chmod -R 755 /var/www/vhosts/

# Só criar página de teste se WordPress NÃO existir
if [ "$WP_EXISTS" = false ]; then
    echo "📄 Criando página de teste (WordPress não encontrado)..."
    mkdir -p /var/www/vhosts/localhost/html
    cat > /var/www/vhosts/localhost/html/index.php << 'EOFTEST'
<?php
phpinfo();
echo "<hr><h2>EmalaBox Test Page</h2>";
echo "<p>If you see this page, OpenLiteSpeed is working correctly!</p>";
echo "<p><a href='/wp-admin'>WordPress Admin</a></p>";
EOFTEST
    chown www-data:www-data /var/www/vhosts/localhost/html/index.php
else
    echo "✅ Mantendo WordPress existente"
fi

# Verificar se arquivos WordPress estão presentes
if [ -f "/var/www/vhosts/localhost/html/wp-config.php" ]; then
    echo "✅ wp-config.php encontrado"
    ls -la /var/www/vhosts/localhost/html/ | head -10
else
    echo "❌ wp-config.php NÃO encontrado"
    echo "📂 Conteúdo do diretório:"
    ls -la /var/www/vhosts/localhost/html/ || echo "Diretório não existe"
fi

# Graceful restart do OpenLiteSpeed
echo "🔄 Reiniciando OpenLiteSpeed (graceful)..."
/usr/local/lsws/bin/lswsctrl restart

echo "✅ OpenLiteSpeed configurado com sucesso!"
echo "🌐 Teste: http://103.199.185.165:8086/"
echo "🔒 HTTPS: https://103.199.185.165:8443/" 