#!/bin/bash

# Script para configuración de autenticación en Linux

# Actualizar el sistema
sudo apt-get update
sudo apt-get upgrade -y

# Instalación de herramientas básicas
sudo apt-get install -y sssd xmlsec1 python3-pip

# Instalación y configuración de SSSD
sudo apt-get install -y sssd
sudo tee /etc/sssd/sssd.conf <<EOF
[sssd]
services = nss, pam
config_file_version = 2
domains = example.com

[domain/example.com]
id_provider = ldap
ldap_uri = ldap://ldap.example.com
ldap_search_base = dc=example,dc=com
EOF
sudo systemctl restart sssd

# Configuración de JWT en Python
pip3 install pyjwt

# Ejemplo de verificación de JWT en Python
cat <<EOF > verify_jwt.py
import jwt

token = 'your_jwt_token'
try:
    decoded = jwt.decode(token, 'your_secret', algorithms=['HS256'])
    print(decoded)
except jwt.ExpiredSignatureError:
    print('Token expirado')
except jwt.InvalidTokenError:
    print('Token inválido')
EOF
python3 verify_jwt.py

# Configuración de autenticación multifactor (MFA) en SSH
sudo tee -a /etc/ssh/sshd_config <<EOF
ChallengeResponseAuthentication yes
AuthenticationMethods publickey,keyboard-interactive
EOF
sudo systemctl restart sshd

# Generación de certificados SSH
ssh-keygen -t rsa -b 4096 -C "user@example.com"
ssh-copy-id user@server

# Instalación de FreeIPA
sudo apt-get install -y freeipa-server
sudo ipa-server-install --unattended --realm=EXAMPLE.COM --domain=example.com --server-ip=192.168.1.1 --hostname=ipa.example.com

echo "Configuración completa."
