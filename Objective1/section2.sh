#!/bin/bash

# Script de Configuración de Seguridad para Linux
# Asegúrate de ejecutar este script como root

echo "Iniciando configuración de seguridad..."

# **1. Configuración de Cuentas de Usuario**

# **1.1 Cuentas de Superusuario**
echo "Configurando cuentas de superusuario..."
# Cambiar la contraseña del root
echo "Introduce la nueva contraseña para la cuenta root:"
passwd root

# Restringir el acceso a la cuenta root por SSH
echo "Deshabilitando el acceso root por SSH..."
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl reload sshd

# **1.2 Cuentas Normales**
echo "Creando una cuenta de usuario normal..."
# Crear un nuevo usuario
useradd -m newuser
echo "Introduce la contraseña para el nuevo usuario 'newuser':"
passwd newuser

# **1.3 Cuentas del Sistema**
echo "Creando una cuenta del sistema..."
# Crear una cuenta de sistema
useradd -r -s /sbin/nologin systemuser

# **1.4 Cuentas de Servicios**
echo "Creando una cuenta de servicio..."
# Crear una cuenta para un servicio específico
useradd -r -d /var/lib/myservice myserviceuser

# **2. Configuración de Grupos**

# **2.1 Grupos Primarios**
echo "Creando un nuevo grupo primario..."
# Crear un nuevo grupo
groupadd mygroup
# Asignar un usuario a un grupo
usermod -aG mygroup newuser

# **2.2 Grupos Secundarios**
echo "Añadiendo un usuario a un grupo secundario..."
# Añadir un usuario a un grupo secundario
usermod -aG supplementarygroup newuser

# **3. Administración de Cuentas**

# **3.1 Auditoría de Cuentas**
echo "Realizando auditoría de cuentas..."
# Mostrar información de usuarios
cat /etc/passwd

# **4. Políticas de Seguridad**

# **4.1 Configuración de SELinux**
echo "Configurando SELinux en modo enforcing..."
# Cambiar a modo enforcing
setenforce 1
# Cambiar configuración permanente
sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

# **4.2 Configuración de AppArmor**
echo "Configurando perfiles de AppArmor..."
# Instalar y configurar AppArmor
apt-get install -y apparmor-utils
aa-status

# **4.3 Configuración de PAM**
echo "Configurando PAM..."
# Editar configuración PAM para mejorar la seguridad
# Ejemplo para agregar autenticación adicional en /etc/pam.d/common-auth

# **5. Configuración de Accesos Remotos**

# **5.1 Configuración de SSH**
echo "Configurando SSH..."
# Configurar SSH para usar puerto 2222 y deshabilitar root login
sed -i 's/^#Port.*/Port 2222/' /etc/ssh/sshd_config
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl reload sshd

# **5.2 Configuración de MFA**
echo "Instalando Google Authenticator..."
# Instalar y configurar Google Authenticator
apt-get install -y libpam-google-authenticator
echo "MFA ha sido instalado. Configura cada usuario con 'google-authenticator'."

# **6. Configuración de Registro y Auditoría**

# **6.1 Auditoría de Eventos**
echo "Configurando auditoría de eventos..."
# Configurar auditoría
apt-get install -y auditd
systemctl enable auditd
systemctl start auditd

# **6.2 Análisis de Logs**
echo "Mostrando logs de autenticación..."
# Ver registros de autenticación
ausearch -m USER_LOGIN

echo "Configuración de seguridad completada."

# Fin del script
