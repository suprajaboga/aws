#!/bin/bash

CONFIG_FILE="$HOME/.aws/config"  # Update this if your config file is elsewhere
OUTPUT_FILE="ebs_gp2_volumes.csv"

# Headers for CSV file
echo "accountid,region,size,volume_type,volume_id,created_date,state" > "$OUTPUT_FILE"

# Extract AWS account IDs and profile names from the config file
ACCOUNTS=$(grep -oP '(?<=sso_account_id = )\d+' "$CONFIG_FILE" | sort -u)
PROFILES=$(grep -oP '(?<=\[profile ).*(?=\])' "$CONFIG_FILE")

# Define regions (Modify based on your AWS usage)
REGIONS=("us-east-1" "us-west-2" "eu-west-1")  # Add all required AWS regions

# Loop through each AWS account profile
for PROFILE in $PROFILES; do
    echo "Logging into AWS SSO for Profile: $PROFILE"
    
    # Attempt to log in only if the session is expired
    aws sts get-caller-identity --profile "$PROFILE" &>/dev/null
    if [[ $? -ne 0 ]]; then
        aws sso login --profile "$PROFILE"
    fi

    # Get the account ID linked to this profile
    ACCOUNT=$(grep -A 5 "\[profile $PROFILE\]" "$CONFIG_FILE" | grep -oP '(?<=sso_account_id = )\d+' | head -n 1)
    
    # Loop through each region
    for REGION in "${REGIONS[@]}"; do
        echo "  Checking EBS volumes in Region: $REGION for Account: $ACCOUNT"

        # Fetch all EBS volumes
        VOLUMES=$(aws ec2 describe-volumes --region "$REGION" --query 'Volumes[*].[VolumeId,Size,VolumeType,CreateTime,State]' --output text --profile "$PROFILE")

        # Process each volume
        echo "$VOLUMES" | while read -r VOLUME_ID SIZE TYPE CREATED STATE; do
            if [[ "$TYPE" == "gp2" ]]; then
                echo "$ACCOUNT,$REGION,$SIZE,$TYPE,$VOLUME_ID,$CREATED,$STATE" >> "$OUTPUT_FILE"
            fi
        done
    done
done

echo "Script execution complete. CSV file generated: $OUTPUT_FILE"