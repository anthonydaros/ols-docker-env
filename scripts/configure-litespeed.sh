#!/bin/bash

# Script para configurar OpenLiteSpeed Virtual Host
set -e

echo "🔧 Configurando OpenLiteSpeed Virtual Host..."

# Criar diretórios necessários PRIMEIRO
mkdir -p /usr/local/lsws/logs
mkdir -p /usr/local/lsws/conf/vhosts/localhost
mkdir -p /var/www/vhosts/localhost/logs

# Aguardar OpenLiteSpeed estar rodando
sleep 15

# Verificar se WordPress existe antes de sobrescrever
SITE_DIR="/var/www/vhosts/localhost/html"
if [ -f "$SITE_DIR/wp-config.php" ]; then
    echo "✅ WordPress encontrado em $SITE_DIR - mantendo instalação"
    WP_EXISTS=true
else
    echo "⚠️ WordPress não encontrado em $SITE_DIR"
    WP_EXISTS=false
fi

# FORÇA RECRIAÇÃO COMPLETA DA CONFIGURAÇÃO
echo "🔧 FORÇANDO recriação completa da configuração..."

# Configurar virtual host para localhost
VHOST_CONF="/usr/local/lsws/conf/vhosts/localhost/vhconf.conf"
HTTPD_CONF="/usr/local/lsws/conf/httpd_config.conf"

# Configurar virtual host
cat > "$VHOST_CONF" << 'EOF'
docRoot                   /var/www/vhosts/localhost/html/
vhDomain                  *
vhAliases                 
enableGzip                1

errorlog /var/www/vhosts/localhost/logs/error.log {
  useServer               1
  logLevel                DEBUG
  rollingSize             10M
}

accesslog /var/www/vhosts/localhost/logs/access.log {
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

# FORÇA RECRIAÇÃO do httpd_config.conf
echo "📝 RECRIANDO httpd_config.conf COMPLETAMENTE..."

cat > "$HTTPD_CONF" << 'EOF'
serverRoot              /usr/local/lsws/
user                    www-data
group                   www-data
priority                0
inMemBufSize            60M
swappingDir             /tmp/lshttpd/swap
autoFix503              1

mime                    /usr/local/lsws/conf/mime.properties

showVersionNumber       0
enableLVE               0

adminEmails             admin@localhost
adminRoot               /usr/local/lsws/admin/

indexFiles              index.html, index.php
autoIndex               0

expires  {
  enableExpires           1
  expiresByType           image/*=A604800,text/css=A604800,application/x-javascript=A604800,application/javascript=A604800,font/*=A604800,application/x-font-ttf=A604800
}

autoLoadHtaccess        1

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
chown -R lsadm:lsadm /usr/local/lsws/conf/ 2>/dev/null || echo "Usuário lsadm não encontrado, usando root"
chmod -R 755 /usr/local/lsws/conf/
chown -R www-data:www-data /var/www/vhosts/ 2>/dev/null || chown -R nobody:nogroup /var/www/vhosts/
chmod -R 755 /var/www/vhosts/

# Só criar página de teste se WordPress NÃO existir
if [ "$WP_EXISTS" = false ]; then
    echo "📄 Criando página de teste (WordPress não encontrado)..."
    mkdir -p /var/www/vhosts/localhost/html
    cat > /var/www/vhosts/localhost/html/index.php << 'EOFTEST'
<?php
echo "<h1>🎉 OpenLiteSpeed funcionando!</h1>";
echo "<p>Virtual host configurado com sucesso.</p>";
echo "<p><strong>Document Root:</strong> " . $_SERVER['DOCUMENT_ROOT'] . "</p>";
echo "<p><strong>Server:</strong> " . $_SERVER['SERVER_SOFTWARE'] . "</p>";
echo "<hr>";
phpinfo();
EOFTEST
    chown www-data:www-data /var/www/vhosts/localhost/html/index.php 2>/dev/null || chown nobody:nogroup /var/www/vhosts/localhost/html/index.php
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

# MÚLTIPLAS tentativas de restart
echo "🔄 Reiniciando OpenLiteSpeed (múltiplas tentativas)..."

# Tentativa 1: Graceful restart
/usr/local/lsws/bin/lswsctrl restart

# Aguardar um pouco
sleep 5

# Tentativa 2: Stop e start
/usr/local/lsws/bin/lswsctrl stop
sleep 3
/usr/local/lsws/bin/lswsctrl start

# Verificar se está rodando
echo "📊 Verificando processos do LiteSpeed:"
ps aux | grep lshttpd || echo "❌ LiteSpeed não encontrado nos processos"

echo "✅ OpenLiteSpeed configurado com sucesso!"
echo "🌐 Teste: http://103.199.185.165:8086/"
echo "🔒 HTTPS: https://103.199.185.165:8443/"

# DEBUG ADICIONAL
echo ""
echo "🔍 DEBUG - Verificando configuração final:"
echo "📁 Arquivos de configuração:"
ls -la /usr/local/lsws/conf/vhosts/localhost/ || echo "Diretório vhost não existe"
echo ""
echo "📁 Document root:"
ls -la /var/www/vhosts/localhost/html/ | head -5 || echo "Document root não existe" 