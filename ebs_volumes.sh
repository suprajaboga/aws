#!/bin/bash

output_file="ebs_gp2_volumes.csv"
regions=("ap-south-1")  # Modify as needed

# CSV Header
echo "account_id,region,size,volume_type,volume_id,created_date,state" > "$output_file"

# Extract AWS account IDs from AWS SSO config
accounts=$(awk -F'=' '/sso_account_id/ {print $2}' ~/.aws/config | tr -d ' ' | sort -u)

# Loop through each AWS account
for account_id in $accounts; do
    admin_profile="privileged-${account_id}"  # Construct profile dynamically

    echo "Logging into AWS SSO for Profile: $admin_profile"
    aws sso login --profile "$admin_profile"

    # Loop through each AWS region
    for region in "${regions[@]}"; do
        echo "Checking EBS volumes in Region: $region for Account: $account_id"

        # Fetch EBS volumes for the account (only gp2)
        aws ec2 describe-volumes --profile "$admin_profile" --region "$region" \
            --filters Name=volume-type,Values=gp2 \
            --query "Volumes[*].[Size,VolumeType,VolumeId,CreateTime,State]" \
            --output text | while read -r size volume_type volume_id created_date state; do
            echo "$account_id,$region,$size,$volume_type,$volume_id,$created_date,$state" >> "$output_file"
        done
    done
done

echo "Script execution complete. CSV file generated: $output_file"