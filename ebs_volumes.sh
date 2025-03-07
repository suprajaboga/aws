#!/bin/bash

# File paths
CONFIG_FILE="./accounts.txt" # AWS config file
ACCOUNTS_FILE="C:/Users/XG481/.aws/config" # List of account numbers
OUTPUT_CSV="./ebs_filtered_volumes.csv" # Output CSV file

# AWS regions to scan
AWS_REGIONS=("ap-south-1") # Modify as needed

# Extract AWS profiles matching account numbers
get_selected_profiles() {
    local selected_accounts=()
    local matched_profiles=()

    while IFS= read -r account_id; do
        selected_accounts+=("$account_id")
    done < "$ACCOUNTS_FILE"

    while IFS= read -r line; do
        if [[ "$line" =~ profile[[:space:]]+([^[:space:]]+) ]]; then
            profile_name="${BASH_REMATCH[1]}"
            for account_id in "${selected_accounts[@]}"; do
                if [[ "$profile_name" == *"$account_id"* ]]; then
                    matched_profiles+=("$account_id:$profile_name")
                    break # Avoid duplicate matches
                fi
            done
        fi
    done < "$CONFIG_FILE"

    echo "${matched_profiles[@]}"
}

# Get EBS volumes
get_ebs_volumes() {
    local account_id="$1"
    local profile_name="$2"

    for region in "${AWS_REGIONS[@]}"; do
        echo "Scanning region $region for account $account_id ($profile_name)..."

        aws ec2 describe-volumes --profile "$profile_name" --region "$region" --output text \
        --query "Volumes[*].[VolumeId, Size, VolumeType, CreateTime, State]" | while read -r volume_id size volume_type created_date state; do
           
            if ["$volume_type" == "gp2"]; then
                echo "$account_id,$region,$size,$volume_type,$volume_id,$created_date,$state" >> "$OUTPUT_CSV"
            fi
        done
    done
}

# Main execution
echo "Fetching selected AWS profiles..."
PROFILES=$(get_selected_profiles)

# Write CSV header
echo "Account Number,Region,Storage Size (GB),Volume Type,Volume ID,Created Date,Volume State" > "$OUTPUT_CSV"

for profile in $PROFILES; do
    IFS=":" read -r account_id profile_name <<< "$profile"
    get_ebs_volumes "$account_id" "$profile_name"
done

echo "✅ EBS report generated: $OUTPUT_CSV"
