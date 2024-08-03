#!/bin/bash

# Variables de configuración
ROLE_NAME="MyEC2Role"
POLICY_NAME="MyCustomPolicy"
USER_NAME="MyUser"
BUCKET_NAME="mybucket"
TRAIL_NAME="MyTrail"
S3_BUCKET_NAME="my-trail-bucket"

# Archivos JSON
TRUST_POLICY_FILE="trust-policy.json"
CUSTOM_POLICY_FILE="custom-policy.json"

# Crear archivo trust-policy.json
cat <<EOL > $TRUST_POLICY_FILE
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOL

# Crear archivo custom-policy.json
cat <<EOL > $CUSTOM_POLICY_FILE
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::$BUCKET_NAME",
        "arn:aws:s3:::$BUCKET_NAME/*"
      ]
    }
  ]
}
EOL

# Crear rol IAM
echo "Creando rol IAM..."
aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://$TRUST_POLICY_FILE

# Adjuntar política al rol
echo "Adjuntando política al rol..."
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# Crear política personalizada
echo "Creando política personalizada..."
aws iam create-policy --policy-name $POLICY_NAME --policy-document file://$CUSTOM_POLICY_FILE

# Adjuntar política a usuario
echo "Adjuntando política a usuario..."
aws iam attach-user-policy --user-name $USER_NAME --policy-arn arn:aws:iam::123456789012:policy/$POLICY_NAME

# Crear dispositivo virtual MFA
echo "Creando dispositivo virtual MFA..."
aws iam create-virtual-mfa-device --virtual-mfa-device-name MyVirtualMFA --outfile /path/to/mfa-qr.png

# Habilitar MFA para el usuario
echo "Habilitando MFA para el usuario..."
# Asegúrate de reemplazar '123456' y '654321' con los códigos generados por tu dispositivo MFA
aws iam enable-mfa-device --user-name $USER_NAME --serial-number arn:aws:iam::123456789012:mfa/MyVirtualMFA --authentication-code1 123456 --authentication-code2 654321

# Crear y activar CloudTrail
echo "Creando y activando CloudTrail..."
aws cloudtrail create-trail --name $TRAIL_NAME --s3-bucket-name $S3_BUCKET_NAME
aws cloudtrail start-logging --name $TRAIL_NAME

echo "Configuración completada."

# Fin del script
