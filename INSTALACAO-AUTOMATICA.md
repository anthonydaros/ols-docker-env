# 🚀 EmalaBox - Instalação Automática do WordPress

## ✨ **Instalação Totalmente Automática**

Este projeto agora inclui **instalação automática do WordPress** durante o deployment. Nenhuma configuração manual é necessária!

## 🔧 **O que é instalado automaticamente:**

### ✅ **WordPress Completo:**
- ✅ Download e instalação da versão mais recente
- ✅ Configuração automática do banco de dados
- ✅ Criação do usuário administrador
- ✅ Configuração das URLs corretas
- ✅ Instalação do plugin **LiteSpeed Cache**
- ✅ Configuração do **Redis** para cache
- ✅ Tema padrão ativado

### ✅ **Configurações de Segurança:**
- ✅ Chaves de segurança geradas automaticamente
- ✅ Permissões de arquivo configuradas corretamente
- ✅ wp-config.php otimizado

## 🌐 **URLs de Acesso:**

Após o deployment, acesse:

- **🌍 Site WordPress**: `http://103.199.185.165:8086`
- **👨‍💻 Admin WordPress**: `http://103.199.185.165:8086/wp-admin`
- **⚙️ OpenLiteSpeed Admin**: `https://103.199.185.165:7080`
- **🗄️ phpMyAdmin**: `http://103.199.185.165:8081`

## 🔐 **Credenciais Configuradas:**

### WordPress Admin:
- **👤 Usuário**: `admin`
- **🔑 Senha**: `EmalaBox2024!`
- **📧 Email**: `admin@103.199.185.165`

### OpenLiteSpeed Admin:
- **👤 Usuário**: `admin`
- **🔑 Senha**: `EmalaBox2024!`

### MySQL/MariaDB:
- **👤 Usuário**: `embalabox_user`
- **🔑 Senha**: `embalabox_pass_2024!`
- **🏠 Database**: `embalabox_db`

## 🚀 **Como Funciona:**

1. **MySQL** é iniciado primeiro
2. **WordPress Installer** executa automaticamente:
   - Aguarda MySQL estar disponível
   - Baixa WordPress
   - Configura banco de dados
   - Instala WordPress
   - Configura plugins e tema
3. **OpenLiteSpeed** inicia e serve o site
4. **Site fica disponível automaticamente!**

## 📊 **Status da Instalação:**

Para verificar se a instalação foi concluída, você pode:

1. **Acessar o site**: `http://103.199.185.165:8086`
2. **Verificar logs**: No Dokploy, visualizar logs do container `wordpress-installer`
3. **Arquivo de sucesso**: Criado em `/tmp/wordpress-installed` no container

## 🔍 **Troubleshooting:**

### Se o site ainda mostrar 404:
1. **Aguarde alguns minutos** - a instalação pode levar tempo
2. **Verifique logs** do container `wordpress-installer`
3. **Reinicie o deployment** se necessário

### Se houver problemas de banco:
1. **Verifique** se o MySQL está rodando
2. **Confirme** as credenciais no arquivo `.env`
3. **Aguarde** o MySQL estar totalmente inicializado

## 🎯 **Funcionalidades Incluídas:**

- ✅ **LiteSpeed Cache Plugin** (alta performance)
- ✅ **Redis Cache** (cache avançado)
- ✅ **SSL Ready** (preparado para HTTPS)
- ✅ **Otimizações de Performance**
- ✅ **Tema Moderno** (Twenty Twenty-Four)
- ✅ **Configurações de Segurança**

## 📝 **Próximos Passos Após Instalação:**

1. ✅ **Faça login** no WordPress Admin
2. ✅ **Configure seu site** (título, descrição, etc.)
3. ✅ **Instale temas/plugins** adicionais se necessário
4. ✅ **Configure SSL** se desejar HTTPS
5. ✅ **Personalize** o LiteSpeed Cache conforme necessário

**🎉 Pronto! Seu WordPress está funcionando automaticamente!** 