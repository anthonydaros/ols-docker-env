# 🚀 EmalaBox - Deployment no Dokploy

## 📋 Problemas Identificados e Soluções

### ❌ Problemas Encontrados:
1. **Arquivo .env ausente** - ✅ Resolvido
2. **Conflitos de porta com Traefik** - ✅ Resolvido
3. **Logging desabilitado** - ✅ Resolvido
4. **Configurações de porta inadequadas** - ✅ Resolvido

## 🔧 Configurações Atualizadas

### Portas Configuradas:
- **OpenLiteSpeed Web**: 8086:80 (evita conflito com Traefik)
- **OpenLiteSpeed HTTPS**: 8443:443
- **OpenLiteSpeed Admin**: 7080:7080
- **phpMyAdmin**: 8081:8080
- **MySQL**: Exposta internamente (3306)
- **Redis**: Exposta internamente (6379)

### 🌐 URLs de Acesso:
- **WordPress**: http://SEU_DOMINIO:8086
- **OpenLiteSpeed Admin**: https://SEU_DOMINIO:7080
- **phpMyAdmin**: http://SEU_DOMINIO:8081

## 📝 Instruções de Deployment

### 1. Usar o docker-compose correto no Dokploy:
```bash
# No campo "Compose File" do Dokploy, usar:
docker-compose.dokploy.yml
```

### 2. Configurar variáveis de ambiente:
Todas as variáveis já estão no arquivo `.env` criado.

### 3. Verificar credenciais:
```bash
./show-credentials.sh
```

## 🔐 Credenciais Padrão

### WordPress Admin:
- **Usuário**: admin
- **Senha**: EmalaBox2024!

### OpenLiteSpeed Admin:
- **Usuário**: admin  
- **Senha**: EmalaBox2024!
- **URL**: https://SEU_DOMINIO:7080

### MySQL/MariaDB:
- **Usuário**: embalabox_user
- **Senha**: embalabox_pass_2024!
- **Database**: embalabox_db
- **Root Password**: embalabox_root_2024!

## 🐛 Troubleshooting

### Se ainda não conseguir acessar:

1. **Verificar logs dos containers**:
```bash
docker logs litespeed
docker logs embalabox-woocomerce-7ef9oe-mysql-1
```

2. **Verificar se as portas estão livres**:
```bash
netstat -tulpn | grep :8086
netstat -tulpn | grep :7080
netstat -tulpn | grep :8081
```

3. **Reiniciar o deployment**:
```bash
docker-compose -f docker-compose.dokploy.yml down
docker-compose -f docker-compose.dokploy.yml up -d
```

4. **Verificar configuração do Traefik**:
   - Certificar que não há conflitos nas portas 80/443
   - Usar labels do Traefik se necessário

## 📊 Monitoramento

### Verificar status dos containers:
```bash
docker ps | grep embalabox
```

### Verificar logs em tempo real:
```bash
docker-compose -f docker-compose.dokploy.yml logs -f
```

## 🔄 Próximos Passos

1. ✅ Fazer commit das alterações
2. ✅ Fazer redeploy no Dokploy usando `docker-compose.dokploy.yml`
3. ✅ Testar acesso nas novas portas
4. ✅ Configurar domínio personalizado se necessário
5. ✅ Instalar WordPress usando os scripts do projeto

## 📞 Suporte

Se continuar com problemas, verificar:
- Configurações de firewall da VPS
- Configurações de DNS se usando domínio personalizado
- Logs do Traefik no Dokploy 