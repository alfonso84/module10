#!/bin/bash

# Script para integrar Linux con Active Directory
# Asegúrate de ejecutar este script con privilegios de superusuario

# Variables de configuración
DOMAIN="example.com"
DOMAIN_USER="admin@example.com"
DOMAIN_PASSWORD="yourpassword"
REALM="EXAMPLE.COM"
AD_SERVER="ad.example.com"

echo "Iniciando integración con Active Directory..."

# 1. Instalación de paquetes necesarios
echo "Instalando paquetes necesarios..."
apt-get update
apt-get install -y realmd sssd krb5-user samba-common-bin

# 2. Configuración de Kerberos
echo "Configurando Kerberos..."
cat <<EOF > /etc/krb5.conf
[libdefaults]
    default_realm = $REALM
    dns_lookup_realm = false
    dns_lookup_kdc = true
[realms]
    $REALM = {
        kdc = $AD_SERVER
        admin_server = $AD_SERVER
    }
[domain_realm]
    .$DOMAIN = $REALM
    $DOMAIN = $REALM
EOF

# 3. Unirse al dominio Active Directory
echo "Uniéndose al dominio Active Directory..."
echo $DOMAIN_PASSWORD | realm join --user=$DOMAIN_USER $DOMAIN --password-file=-

# 4. Configuración de SSSD
echo "Configurando SSSD..."
cat <<EOF > /etc/sssd/sssd.conf
[sssd]
services = nss, pam
config_file_version = 2
domains = $DOMAIN

[nss]
filter_users = root
filter_groups = root

[pam]

[domain/$DOMAIN]
id_provider = ad
access_provider = ad
chpass_provider = ad
ldap_schema = ad
krb5_realm = $REALM
realmd_tags = manages-system joined-with-samba
cache_credentials = True
EOF
chmod 600 /etc/sssd/sssd.conf

# 5. Configuración de PAM
echo "Configurando PAM..."
cat <<EOF > /etc/pam.d/common-auth
auth  [success=1 default=ignore]  pam_sssd.so
auth  requisite  pam_deny.so
auth  required  pam_permit.so
EOF

cat <<EOF > /etc/pam.d/common-account
account [success=1 new_authtok_reqd=done default=ignore] pam_sssd.so
account requisite pam_deny.so
account required pam_permit.so
EOF

cat <<EOF > /etc/pam.d/common-password
password [success=1 default=ignore] pam_sssd.so
password requisite pam_deny.so
password required pam_permit.so
EOF

cat <<EOF > /etc/pam.d/common-session
session [success=1 default=ignore] pam_sssd.so
session requisite pam_deny.so
session required pam_permit.so
EOF

# 6. Configuración de ACLs y ACEs (Ejemplo)
echo "Configurando ACLs y ACEs..."
cat <<EOF > /etc/ldap/ldap.conf
BASE dc=example,dc=com
URI ldap://$AD_SERVER
EOF

ldapmodify <<EOL
dn: ou=users,dc=example,dc=com
changetype: modify
add: acl
acl: (ou=users,dc=example,dc=com)(group:admin)(allow:read,write)
EOL

# 7. Verificación de Configuración
echo "Verificando la configuración..."
realm list
sssd --debug-level=9
ldapsearch -x -b "dc=example,dc=com" "(objectClass=user)"
nslookup -type=SRV _ldap._tcp.dc._msdcs.example.com

echo "Configuración completada. Por favor, reinicia el sistema para aplicar todos los cambios."

# Fin del script
