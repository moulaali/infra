#!/bin/bash

# Variables (replace REGION with your actual region)
REGION="us-west-2"  # Update this to your default region if necessary

# Automatically get AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

# Helper function to print messages
function echo_message() {
    echo "===================="
    echo $1
    echo "===================="
}

# 1. List all EKS clusters and ask the user which one to delete
echo_message "Listing all EKS clusters in region $REGION..."
CLUSTERS=$(aws eks list-clusters --region $REGION --query 'clusters' --output text)

if [ -z "$CLUSTERS" ]; then
    echo "No EKS clusters found in region $REGION."
    exit 1
fi

echo "Available EKS clusters:"
echo "$CLUSTERS"

read -p "Enter the name of the EKS cluster you want to delete: " CLUSTER_NAME

if [[ ! "$CLUSTERS" =~ "$CLUSTER_NAME" ]]; then
    echo "Cluster $CLUSTER_NAME not found. Exiting..."
    exit 1
fi

echo_message "You selected to delete: $CLUSTER_NAME"

# 2. Delete all Kubernetes resources in the cluster
echo_message "Deleting all Kubernetes resources from cluster $CLUSTER_NAME..."
kubectl config use-context arn:aws:eks:$REGION:$ACCOUNT_ID:cluster/$CLUSTER_NAME
kubectl delete all --all --context arn:aws:eks:$REGION:$ACCOUNT_ID:cluster/$CLUSTER_NAME

# 3. Delete node groups
echo_message "Deleting managed node groups for cluster $CLUSTER_NAME..."
NODE_GROUPS=$(aws eks list-nodegroups --cluster-name $CLUSTER_NAME --region $REGION --query 'nodegroups' --output text)

if [ -n "$NODE_GROUPS" ]; then
    for NODE_GROUP in $NODE_GROUPS; do
        aws eks delete-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $NODE_GROUP --region $REGION
        echo "Deleted node group: $NODE_GROUP"
    done
else
    echo "No managed node groups found."
fi

# 4. Terminate any EC2 instances (if using self-managed node groups)
echo_message "Terminating EC2 instances..."
INSTANCE_IDS=$(aws ec2 describe-instances --filters "Name=tag:eks:cluster-name,Values=$CLUSTER_NAME" --query 'Reservations[*].Instances[*].InstanceId' --output text --region $REGION)

if [ -n "$INSTANCE_IDS" ]; then
    aws ec2 terminate-instances --instance-ids $INSTANCE_IDS --region $REGION
    echo "Terminated instances: $INSTANCE_IDS"
else
    echo "No self-managed instances found."
fi

# 5. Delete the EKS cluster
echo_message "Deleting the EKS cluster $CLUSTER_NAME..."
aws eks delete-cluster --name $CLUSTER_NAME --region $REGION
echo "EKS cluster $CLUSTER_NAME deleted."

# 6. Delete CloudFormation stacks (for node groups or any related resources)
echo_message "Deleting CloudFormation stacks related to the EKS cluster..."
STACK_NAMES=$(aws cloudformation describe-stacks --query 'Stacks[?contains(StackName, `'$CLUSTER_NAME'`) == `true`].StackName' --output text --region $REGION)

if [ -n "$STACK_NAMES" ]; then
    for STACK_NAME in $STACK_NAMES; do
        aws cloudformation delete-stack --stack-name $STACK_NAME --region $REGION
        echo "Deleted CloudFormation stack: $STACK_NAME"
    done
else
    echo "No CloudFormation stacks found related to the EKS cluster."
fi

# 7. Delete Load Balancers created by the EKS cluster
echo_message "Deleting Load Balancers created by the EKS cluster..."
LB_ARNs=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `'$CLUSTER_NAME'`) == `true`].LoadBalancerArn' --output text --region $REGION)

if [ -n "$LB_ARNs" ]; then
    for LB_ARN in $LB_ARNs; do
        aws elbv2 delete-load-balancer --load-balancer-arn $LB_ARN --region $REGION
        echo "Deleted load balancer: $LB_ARN"
    done
else
    echo "No load balancers found."
fi

# 8. Delete security groups associated with the EKS cluster
echo_message "Deleting security groups associated with the EKS cluster..."
SECURITY_GROUPS=$(aws ec2 describe-security-groups --filters "Name=tag:eks:cluster-name,Values=$CLUSTER_NAME" --query 'SecurityGroups[*].GroupId' --output text --region $REGION)

if [ -n "$SECURITY_GROUPS" ]; then
    for SG in $SECURITY_GROUPS; do
        aws ec2 delete-security-group --group-id $SG --region $REGION
        echo "Deleted security group: $SG"
    done
else
    echo "No security groups found."
fi

# 9. Delete EBS volumes created by the EKS cluster
echo_message "Deleting EBS volumes associated with the EKS cluster..."
VOLUME_IDS=$(aws ec2 describe-volumes --filters "Name=tag:eks:cluster-name,Values=$CLUSTER_NAME" --query 'Volumes[*].VolumeId' --output text --region $REGION)

if [ -n "$VOLUME_IDS" ]; then
    for VOLUME_ID in $VOLUME_IDS; do
        aws ec2 delete-volume --volume-id $VOLUME_ID --region $REGION
        echo "Deleted EBS volume: $VOLUME_ID"
    done
else
    echo "No EBS volumes found."
fi

# 10. Delete Elastic IPs associated with the EKS cluster
echo_message "Deleting Elastic IPs..."
EIP_ALLOCATIONS=$(aws ec2 describe-addresses --filters "Name=tag:eks:cluster-name,Values=$CLUSTER_NAME" --query 'Addresses[*].AllocationId' --output text --region $REGION)

if [ -n "$EIP_ALLOCATIONS" ]; then
    for ALLOCATION_ID in $EIP_ALLOCATIONS; do
        aws ec2 release-address --allocation-id $ALLOCATION_ID --region $REGION
        echo "Released Elastic IP: $ALLOCATION_ID"
    done
else
    echo "No Elastic IPs found."
fi

echo_message "All resources related to the EKS cluster $CLUSTER_NAME have been deleted."
