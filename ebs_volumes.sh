#!/bin/bash

# File paths
ACCOUNTS_FILE="./accounts.txt"  # List of AWS account numbers
OUTPUT_CSV="./ebs_filtered_volumes.csv"  # Output CSV file

# AWS regions to scan
AWS_REGIONS=("ap-south-1")  # Modify as needed

# Function to fetch AWS profiles dynamically
get_selected_profiles() {
    local matched_profiles=()

    while IFS= read -r account_id; do
        profile_name="sso-${account_id}"  # Modify if your SSO profile naming is different
        matched_profiles+=("$account_id:$profile_name")
    done < "$ACCOUNTS_FILE"

    echo "${matched_profiles[@]}"
}

# Function to get EBS volumes of type gp2
get_ebs_volumes() {
    local account_id="$1"
    local profile_name="$2"

    for region in "${AWS_REGIONS[@]}"; do
        echo "🔍 Scanning region $region for account $account_id ($profile_name)..."

        aws ec2 describe-volumes --profile "$profile_name" --region "$region" --output text \
        --query "Volumes[*].[VolumeId, Size, VolumeType, CreateTime, State]" | while read -r volume_id size volume_type created_date state; do
           
            if [[ "$volume_type" == "gp2" ]]; then
                echo "$account_id,$region,$size,$volume_type,$volume_id,$created_date,$state" >> "$OUTPUT_CSV"
            fi
        done
    done
}

# Main execution
echo "Fetching AWS accounts and profiles..."
PROFILES=$(get_selected_profiles)

# Write CSV header
echo "Account Number,Region,Storage Size (GB),Volume Type,Volume ID,Created Date,Volume State" > "$OUTPUT_CSV"

# Process each AWS account
for profile in $PROFILES; do
    IFS=":" read -r account_id profile_name <<< "$profile"
    get_ebs_volumes "$account_id" "$profile_name"
done

echo "✅ EBS report generated: $OUTPUT_CSV"