#!/bin/bash

# Variables (replace REGION with your actual region)
REGION="us-west-2"  # Update this to your default region if necessary

# Helper function to print messages
function echo_message() {
    echo "===================="
    echo $1
    echo "===================="
}

# 1. List and delete all VPCs
echo_message "Fetching all VPCs in region $REGION..."
VPC_IDS=$(aws ec2 describe-vpcs --query 'Vpcs[*].VpcId' --output text --region $REGION)

if [ -z "$VPC_IDS" ]; then
    echo "No VPCs found in region $REGION."
else
    echo "VPCs found: $VPC_IDS"

    # Iterate through each VPC and delete related resources (Internet Gateway, Subnets, Route Tables) before deleting the VPC itself
    for VPC_ID in $VPC_IDS; do
        echo_message "Deleting resources associated with VPC: $VPC_ID"

        # Detach and delete Internet Gateways
        IGW_IDS=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[*].InternetGatewayId' --output text --region $REGION)
        if [ -n "$IGW_IDS" ]; then
            for IGW_ID in $IGW_IDS; do
                echo "Detaching and deleting Internet Gateway: $IGW_ID"
                aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $REGION
                aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region $REGION
            done
        fi

        # Delete NAT Gateways
        echo_message "Deleting NAT Gateways in VPC: $VPC_ID"
        NAT_GATEWAYS=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --query 'NatGateways[*].NatGatewayId' --output text --region $REGION)
        if [ -n "$NAT_GATEWAYS" ]; then
            for NAT_GW in $NAT_GATEWAYS; do
                echo "Deleting NAT Gateway: $NAT_GW"
                aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GW --region $REGION
            done
        fi

        # Delete Network Interfaces (ENIs)
        echo_message "Deleting Elastic Network Interfaces in VPC: $VPC_ID"
        ENI_IDS=$(aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=$VPC_ID" --query 'NetworkInterfaces[*].NetworkInterfaceId' --output text --region $REGION)
        if [ -n "$ENI_IDS" ]; then
            for ENI_ID in $ENI_IDS; do
                echo "Deleting Network Interface: $ENI_ID"
                aws ec2 delete-network-interface --network-interface-id $ENI_ID --region $REGION
            done
        fi

        # Delete Subnets
        SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].SubnetId' --output text --region $REGION)
        if [ -n "$SUBNET_IDS" ]; then
            for SUBNET_ID in $SUBNET_IDS; do
                echo "Deleting Subnet: $SUBNET_ID"

                # Check if there are EC2 instances running in the subnet
                INSTANCE_IDS=$(aws ec2 describe-instances --filters "Name=subnet-id,Values=$SUBNET_ID" --query 'Reservations[*].Instances[*].InstanceId' --output text --region $REGION)
                if [ -n "$INSTANCE_IDS" ]; then
                    echo "Terminating instances in Subnet: $INSTANCE_IDS"
                    aws ec2 terminate-instances --instance-ids $INSTANCE_IDS --region $REGION
                    aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS --region $REGION
                fi

                # Check for Elastic IPs associated with instances in the subnet
                ALLOC_IDS=$(aws ec2 describe-addresses --filters "Name=instance-id,Values=$INSTANCE_IDS" --query 'Addresses[*].AllocationId' --output text --region $REGION)
                if [ -n "$ALLOC_IDS" ]; then
                    for ALLOC_ID in $ALLOC_IDS; do
                        echo "Releasing Elastic IP: $ALLOC_ID"
                        aws ec2 release-address --allocation-id $ALLOC_ID --region $REGION
                    done
                fi

                # Finally, delete the subnet
                aws ec2 delete-subnet --subnet-id $SUBNET_ID --region $REGION
            done
        fi

        # Delete Route Tables (excluding the main route table)
        ROUTE_TABLE_IDS=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[?Associations[0].Main == `false`].RouteTableId' --output text --region $REGION)
        if [ -n "$ROUTE_TABLE_IDS" ]; then
            for RTB_ID in $ROUTE_TABLE_IDS; do
                echo "Deleting Route Table: $RTB_ID"
                aws ec2 delete-route-table --route-table-id $RTB_ID --region $REGION
            done
        fi

        # Delete Network ACLs (excluding default)
        NACL_IDS=$(aws ec2 describe-network-acls --filters "Name=vpc-id,Values=$VPC_ID" --query 'NetworkAcls[?IsDefault==`false`].NetworkAclId' --output text --region $REGION)
        if [ -n "$NACL_IDS" ]; then
            for NACL_ID in $NACL_IDS; do
                echo "Deleting Network ACL: $NACL_ID"
                aws ec2 delete-network-acl --network-acl-id $NACL_ID --region $REGION
            done
        fi

        # Delete VPC Peering Connections
        PEERING_CONNECTIONS=$(aws ec2 describe-vpc-peering-connections --filters "Name=requester-vpc-info.vpc-id,Values=$VPC_ID" --query 'VpcPeeringConnections[*].VpcPeeringConnectionId' --output text --region $REGION)
        if [ -n "$PEERING_CONNECTIONS" ]; then
            for PEERING_ID in $PEERING_CONNECTIONS; do
                echo "Deleting VPC Peering Connection: $PEERING_ID"
                aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id $PEERING_ID --region $REGION
            done
        fi

        # Finally, delete the VPC
        echo "Deleting VPC: $VPC_ID"
        aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION
    done
fi

# 2. List and delete all Route 53 hosted zones
echo_message "Fetching all Route 53 hosted zones..."
HOSTED_ZONES=$(aws route53 list-hosted-zones --query 'HostedZones[*].Id' --output text)

if [ -z "$HOSTED_ZONES" ]; then
    echo "No Route 53 hosted zones found."
else
    echo "Hosted zones found: $HOSTED_ZONES"

    for ZONE_ID in $HOSTED_ZONES; do
        ZONE_ID=$(echo $ZONE_ID | sed 's|/hostedzone/||') # Clean up the hosted zone ID format
        echo "Deleting Route 53 hosted zone: $ZONE_ID"

        # Fetch and delete all record sets (except NS and SOA)
        RECORD_SETS=$(aws route53 list-resource-record-sets --hosted-zone-id $ZONE_ID --query 'ResourceRecordSets[?Type != `NS` && Type != `SOA`]' --output json)
        echo $RECORD_SETS > change-batch.json

        if [ -s change-batch.json ]; then
            # Prepare a change batch to delete the record sets
            jq '{ "Changes": [ .[] | { "Action": "DELETE", "ResourceRecordSet": . } ] }' change-batch.json > final-change-batch.json

            # Execute the change batch to delete the record sets
            aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch file://final-change-batch.json
        fi

        # Finally, delete the hosted zone
        aws route53 delete-hosted-zone --id $ZONE_ID
        echo "Deleted Route 53 hosted zone: $ZONE_ID"
    done
fi

# Clean up
rm -f change-batch.json final-change-batch.json

echo_message "All VPCs and Route 53 hosted zones have been deleted."
