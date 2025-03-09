#!/bin/bash

output_file="ebs_gp2_volumes.csv"
regions=("ap-south-1")  # Modify as needed

# CSV Header
echo "account_id,region,size,volume_type,volume_id,created_date,state" > $output_file

# Fetch all AWS accounts dynamically from SSO config
accounts=$(aws sso list-accounts --profile sso-session --query "accountList[*].accountId" --output text)

# Loop through each AWS account
for account_id in $accounts; do
    admin_profile="privileged-${account_id}"  # Construct admin profile dynamically

    echo "Logging into AWS SSO for Profile: $admin_profile"
    aws sso login --profile "$admin_profile"

    # Loop through each region
    for region in "${regions[@]}"; do
        echo "Checking EBS volumes in Region: $region for Account: $account_id"

        # Fetch EBS volumes for the account
        aws ec2 describe-volumes --profile "$admin_profile" --region "$region" \
            --filters Name=volume-type,Values=gp2 \
            --query "Volumes[*].[Attachments[0].InstanceId,Region,Size,VolumeType,VolumeId,CreateTime,State]" \
            --output text | while read -r instance_id region size volume_type volume_id created_date state; do
            echo "$account_id,$region,$size,$volume_type,$volume_id,$created_date,$state" >> $output_file
        done
    done
done

echo "Script execution complete. CSV file generated: $output_file"