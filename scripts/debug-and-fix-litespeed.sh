#!/bin/bash

# Script de Debug e Correção do OpenLiteSpeed
set -e

echo "🔍 DEBUG: Verificando configuração do OpenLiteSpeed..."

# Verificar se LiteSpeed está rodando
echo "📊 Status do LiteSpeed:"
ps aux | grep lshttpd || echo "❌ LiteSpeed não encontrado nos processos"

# Verificar arquivos WordPress
echo ""
echo "📂 Verificando arquivos WordPress:"
ls -la /var/www/vhosts/localhost/html/ | head -10

# Verificar configuração do virtual host
echo ""
echo "🔧 Configuração do Virtual Host:"
if [ -f "/usr/local/lsws/conf/vhosts/localhost/vhconf.conf" ]; then
    echo "✅ Arquivo vhconf.conf existe"
    cat /usr/local/lsws/conf/vhosts/localhost/vhconf.conf
else
    echo "❌ Arquivo vhconf.conf NÃO existe"
fi

# Verificar configuração principal
echo ""
echo "🔧 Configuração Principal (httpd_config.conf):"
if [ -f "/usr/local/lsws/conf/httpd_config.conf" ]; then
    echo "✅ Arquivo httpd_config.conf existe"
    grep -A 10 -B 5 "virtualhost\|listener" /usr/local/lsws/conf/httpd_config.conf || echo "Nenhum virtual host encontrado"
else
    echo "❌ Arquivo httpd_config.conf NÃO existe"
fi

# Verificar logs do LiteSpeed
echo ""
echo "📋 Logs recentes do LiteSpeed:"
if [ -f "/usr/local/lsws/logs/error.log" ]; then
    echo "📄 Error Log:"
    tail -20 /usr/local/lsws/logs/error.log
else
    echo "❌ Error log não encontrado"
fi

if [ -f "/usr/local/lsws/logs/access.log" ]; then
    echo "📄 Access Log:"
    tail -10 /usr/local/lsws/logs/access.log
else
    echo "❌ Access log não encontrado"
fi

# Verificar permissões
echo ""
echo "🔒 Verificando permissões:"
ls -la /var/www/vhosts/localhost/

echo ""
echo "🔧 APLICANDO CORREÇÕES..."

# Criar diretórios necessários
mkdir -p /usr/local/lsws/logs
mkdir -p /usr/local/lsws/conf/vhosts/localhost
mkdir -p /var/www/vhosts/localhost/logs

# Recriar configuração do virtual host
echo "📝 Recriando configuração do virtual host..."
cat > /usr/local/lsws/conf/vhosts/localhost/vhconf.conf << 'EOF'
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

# Verificar se httpd_config.conf existe, senão criar
if [ ! -f "/usr/local/lsws/conf/httpd_config.conf" ]; then
    echo "📝 Criando httpd_config.conf básico..."
    cat > /usr/local/lsws/conf/httpd_config.conf << 'EOF'
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
else
    echo "📝 Adicionando virtual host ao httpd_config.conf existente..."
    # Remove configurações antigas
    sed -i '/virtualhost.*{/,/^}/d' /usr/local/lsws/conf/httpd_config.conf
    sed -i '/listener.*{/,/^}/d' /usr/local/lsws/conf/httpd_config.conf
    
    # Adiciona nova configuração
    cat >> /usr/local/lsws/conf/httpd_config.conf << 'EOF'

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

# Gerar certificados SSL se não existirem
if [ ! -f "/usr/local/lsws/conf/cert/localhost.crt" ]; then
    echo "🔐 Gerando certificados SSL..."
    mkdir -p /usr/local/lsws/conf/cert
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /usr/local/lsws/conf/cert/localhost.key \
        -out /usr/local/lsws/conf/cert/localhost.crt \
        -subj "/C=BR/ST=SP/L=SaoPaulo/O=EmalaBox/CN=localhost"
fi

# Configurar permissões
echo "🔒 Configurando permissões..."
chown -R lsadm:lsadm /usr/local/lsws/conf/ 2>/dev/null || echo "Usuário lsadm não encontrado, usando root"
chmod -R 755 /usr/local/lsws/conf/
chown -R www-data:www-data /var/www/vhosts/ 2>/dev/null || chown -R nobody:nogroup /var/www/vhosts/
chmod -R 755 /var/www/vhosts/

# Verificar se o index.php existe e tem conteúdo
if [ ! -f "/var/www/vhosts/localhost/html/index.php" ] || [ ! -s "/var/www/vhosts/localhost/html/index.php" ]; then
    echo "⚠️ index.php não encontrado ou vazio, criando arquivo de teste..."
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
fi

# Restart do LiteSpeed
echo "🔄 Reiniciando LiteSpeed..."
/usr/local/lsws/bin/lswsctrl restart

echo ""
echo "✅ Debug e correção concluídos!"
echo "🌐 Teste agora: http://103.199.185.165:8086/"
echo ""
echo "📋 Resumo das verificações:"
echo "- Configuração virtual host: Recriada"
echo "- Permissões: Configuradas"
echo "- Certificados SSL: Verificados"
echo "- LiteSpeed: Reiniciado" 