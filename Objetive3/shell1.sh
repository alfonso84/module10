#!/bin/bash

# Configuración de variables
REGION="us-west-2"
INSTANCE_TYPE="t2.micro"
AMI_ID="ami-0abcdef1234567890" # Reemplazar con el ID de la AMI adecuada
KEY_NAME="my-key-pair"
SECURITY_GROUP_NAME="my-security-group"
BUCKET_NAME="my-secure-bucket-$(date +%s)"
DB_INSTANCE_ID="mydbinstance"
DB_USERNAME="admin"
DB_PASSWORD="YourSecurePassword"
WEB_ACL_NAME="my-web-acl"
PROTECTION_NAME="my-protection"
INSPECTOR_TARGET_NAME="my-assessment-target"
INSPECTOR_TEMPLATE_NAME="my-assessment-template"
IP_SET_NAME="my-ip-set"

# Crear una nueva instancia EC2
INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --count 1 --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --security-groups $SECURITY_GROUP_NAME --region $REGION --query 'Instances[0].InstanceId' --output text)
echo "Instancia EC2 creada: $INSTANCE_ID"

# Obtener la ID del grupo de seguridad
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values=$SECURITY_GROUP_NAME --query 'SecurityGroups[0].GroupId' --output text)
echo "ID del grupo de seguridad: $SECURITY_GROUP_ID"

# Configurar el grupo de seguridad
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 443 --cidr 0.0.0.0/0

# Crear un bucket S3 con cifrado
aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION
aws s3api put-bucket-encryption --bucket $BUCKET_NAME --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
echo "Bucket S3 creado y cifrado: $BUCKET_NAME"

# Configurar RDS con backups automáticos
aws rds create-db-instance --db-instance-identifier $DB_INSTANCE_ID --db-instance-class db.t2.micro --engine mysql --master-username $DB_USERNAME --master-user-password $DB_PASSWORD --allocated-storage 20 --backup-retention-period 7 --region $REGION
echo "Instancia RDS creada: $DB_INSTANCE_ID"

# Crear y configurar AWS CloudTrail
CLOUDTRAIL_BUCKET_NAME="my-cloudtrail-bucket-$(date +%s)"
aws s3api create-bucket --bucket $CLOUDTRAIL_BUCKET_NAME --region $REGION
aws cloudtrail create-trail --name my-trail --s3-bucket-name $CLOUDTRAIL_BUCKET_NAME --is-multi-region-trail
aws cloudtrail start-logging --name my-trail
echo "AWS CloudTrail configurado."

# Crear una alarma en CloudWatch
aws cloudwatch put-metric-alarm --alarm-name HighCPUAlarm --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 300 --threshold 80 --comparison-operator GreaterThanOrEqualToThreshold --evaluation-periods 2 --alarm-actions arn:aws:sns:$REGION:<account-id>:my-sns-topic --dimensions Name=InstanceId,Value=$INSTANCE_ID
echo "Alarma de CloudWatch configurada."

# Configurar AWS Shield y WAF
aws wafv2 create-web-acl --name $WEB_ACL_NAME --scope REGIONAL --default-action Allow={} --rules '[{"Name":"Rule1","Priority":1,"Action":{"Allow":{}},{"Statement":{"IPSetReferenceStatement":{"ARN":"arn:aws:wafv2:$REGION:<account-id>:ipset/$IP_SET_NAME"}},"VisibilityConfig":{"SampledRequestsEnabled":true,"CloudWatchMetricsEnabled":true,"MetricName":"Rule1"}}]' --description "ACL para proteger contra DDoS"
aws shield create-protection --name $PROTECTION_NAME --resource-arn arn:aws:ec2:$REGION:<account-id>:instance/$INSTANCE_ID
echo "AWS Shield y WAF configurados."

# Configurar AWS Inspector
aws inspector create-assessment-target --assessment-target-name $INSPECTOR_TARGET_NAME --resource-group-arn arn:aws:inspector:$REGION:<account-id>:resource-group/my-resource-group
aws inspector create-assessment-template --assessment-target-arn arn:aws:inspector:$REGION:<account-id>:assessment-target/$INSPECTOR_TARGET_NAME --assessment-template-name $INSPECTOR_TEMPLATE_NAME --duration-in-seconds 3600 --rules-package-arns arn:aws:inspector:$REGION:<account-id>:rulespackage/my-rules-package
echo "AWS Inspector configurado."

# Crear IP Set para AWS WAF
aws wafv2 create-ip-set --name $IP_SET_NAME --scope REGIONAL --ip-address-version IPV4 --addresses '["203.0.113.0/24","198.51.100.0/24"]'
echo "IP Set creado para AWS WAF."

# Instalar AWS CLI y configurar credenciales
sudo apt-get update
sudo apt-get install -y awscli

# Crear un usuario IAM y configurar las claves
aws iam create-user --user-name admin
aws iam create-access-key --user-name admin --query 'AccessKey.[AccessKeyId,SecretAccessKey]' --output text > /tmp/admin-credentials.txt
ACCESS_KEY_ID=$(awk '{print $1}' /tmp/admin-credentials.txt)
SECRET_ACCESS_KEY=$(awk '{print $2}' /tmp/admin-credentials.txt)

# Configurar AWS CLI
aws configure set aws_access_key_id $ACCESS_KEY_ID
aws configure set aws_secret_access_key $SECRET_ACCESS_KEY
aws configure set region $REGION

echo "AWS CLI configurado."

echo "Configuración y seguridad completadas."
