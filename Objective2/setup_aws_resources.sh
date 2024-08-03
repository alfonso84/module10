#!/bin/bash

# Cargar variables de entorno
source /home/admin/aws_env_variables.sh

# Crear un bucket de S3
aws s3api create-bucket --bucket $S3_BUCKET_NAME --region $AWS_REGION --create-bucket-configuration LocationConstraint=$AWS_REGION

# Crear una política IAM
cat <<EOL > /home/admin/iam_policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::$S3_BUCKET_NAME/*"
    }
  ]
}
EOL

# Crear un rol IAM con la política
aws iam create-role --role-name $IAM_ROLE_NAME --assume-role-policy-document file:///home/admin/trust-policy.json
aws iam put-role-policy --role-name $IAM_ROLE_NAME --policy-name S3FullAccessPolicy --policy-document file:///home/admin/iam_policy.json

# Crear una política de trust
cat <<EOL > /home/admin/trust-policy.json
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

# Crear una instancia EC2 (ejemplo)
aws ec2 run-instances --image-id ami-0abcdef1234567890 --count 1 --instance-type t2.micro --key-name my-key-pair --role $IAM_ROLE_NAME --region $AWS_REGION

echo "Recursos de AWS configurados."
