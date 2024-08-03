#!/bin/bash

# Verificar si AWS CLI está instalado
if ! command -v aws &> /dev/null
then
    echo "AWS CLI no está instalado. Instalando..."
    sudo apt-get install -y awscli
fi

# Cargar variables de entorno
source /home/admin/aws_env_variables.sh

# Configuración de AWS CLI
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure set default.region $AWS_REGION
aws configure set output json

echo "AWS CLI configurado correctamente."
