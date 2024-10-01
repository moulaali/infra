# Replace these variables with your values
# 590183843967.dkr.ecr.us-west-2.amazonaws.com/akashx/infra-poc
aws_region="us-west-2"
aws_account_id="590183843967"
repository_name="akashx/portal"

# Authenticate Docker to AWS ECR
aws ecr get-login-password --region $aws_region | docker login --username AWS --password-stdin $aws_account_id.dkr.ecr.$aws_region.amazonaws.com

# Tag the image for AWS ECR
docker tag orderapp:latest $aws_account_id.dkr.ecr.$aws_region.amazonaws.com/$repository_name:latest

# Push the image to AWS ECR
docker push $aws_account_id.dkr.ecr.$aws_region.amazonaws.com/$repository_name:latest

