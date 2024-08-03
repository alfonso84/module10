#!/bin/bash

# Actualizar sistema y herramientas básicas
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y curl wget unzip

# Instalar SELinux
sudo apt-get install -y selinux-utils selinux-policy-default

# Configuración básica de SELinux
sudo setenforce 1
sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

# Configuración de autenticación multifactor
sudo apt-get install -y libpam-google-authenticator
echo "auth required pam_google_authenticator.so" | sudo tee -a /etc/pam.d/sshd

# Configuración de SSH
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Configuración de políticas de SELinux
echo "module mypolicy 1.0; require { type sshd_t; } allow sshd_t self:process r;" | sudo tee /etc/selinux/targeted/modules/active/modules/mypolicy.te
sudo checkmodule -M -m -o /etc/selinux/targeted/modules/active/modules/mypolicy.mod /etc/selinux/targeted/modules/active/modules/mypolicy.te
sudo semodule -i /etc/selinux/targeted/modules/active/modules/mypolicy.pp

# Configuración de firewalls
sudo ufw allow 22/tcp # SSH
sudo ufw allow 80/tcp # HTTP
sudo ufw allow 443/tcp # HTTPS
sudo ufw enable

# Crear usuario admin y establecer permisos
sudo adduser --disabled-password --gecos "Admin User" admin
echo "admin:YourSecurePassword" | sudo chpasswd
sudo usermod -aG sudo admin

# Instalar AWS CLI
sudo apt-get install -y awscli

# Crear una clave de acceso para el usuario admin
aws iam create-user --user-name admin

# Crear una clave de acceso para el usuario admin
aws iam create-access-key --user-name admin > /home/admin/access_key.json

# Configuración de AWS CLI con la clave de acceso
sudo -u admin aws configure set aws_access_key_id $(jq -r '.AccessKey.AccessKeyId' /home/admin/access_key.json)
sudo -u admin aws configure set aws_secret_access_key $(jq -r '.AccessKey.SecretAccessKey' /home/admin/access_key.json)
sudo -u admin aws configure set default.region us-west-2
sudo -u admin aws configure set output json

# Crear archivo de variables de entorno
cat <<EOL > /home/admin/aws_env_variables.sh
#!/bin/bash
export AWS_ACCESS_KEY_ID=$(jq -r '.AccessKey.AccessKeyId' /home/admin/access_key.json)
export AWS_SECRET_ACCESS_KEY=$(jq -r '.AccessKey.SecretAccessKey' /home/admin/access_key.json)
export AWS_REGION=us-west-2
export S3_BUCKET_NAME=my-example-bucket
export IAM_ROLE_NAME=my-role
export USER_NAME=admin
export DB_INSTANCE_ID=mydbinstance
export DB_USERNAME=admin
export DB_PASSWORD=YourSecurePassword
export IP_RUSIA=203.0.113.0/24
export IP_CHINA=198.51.100.0/24
EOL
sudo chmod +x /home/admin/aws_env_variables.sh

echo "Configuración completa de la instancia EC2 y AWS CLI."
