#!/bin/sh -xe

# Start spinning up an appliance now; we'll check it in the pre-test-hook

# Override these in Jenkins for custom jobs

# A10_APPLIANCE_AMI=${A10_APPLIANCE_AMI:-ami-835c0fb3}
# A10_INSTANCE_TYPE=${A10_INSTANCE_TYPE:-m1.small}
# A10_KEY_NAME=${A10_KEY_NAME:-appliance-key}
# A10_SECURITY_GROUP=${A10_SECURITY_GROUP:-sg-c72563a2}
# A10_SUBNET_ID=${A10_SUBNET_ID:-subnet-7360dd16}

# t=/tmp/jenkins.a10.$$

# # $ aws ec2 run-instances --image-id ami-xxxxxxxx --count 1 --instance-type t1.micro --key-name MyKeyPair --security-group-ids sg-xxxxxxxx --subnet-id subnet-xxxxxxxx

# set -e
# aws ec2 run-instances \
#   --image-id $A10_APPLIANCE_AMI \
#   --count 1 \
#   --instance-type $A10_INSTANCE_TYPE \
#   --key-name $A10_KEY_NAME \
#   --security-group-ids $A10_SECURITY_GROUP \
#   --subnet-id $A10_SUBNET_ID > $t

# echo "Writing instance id to disk"
# set +x
# cat $t \
#     | perl -ne '/"InstanceId": "(.*?)"/ && print "$1\n";' \
#     > ~/.a10-instance-id
# grep PrivateIpAddress $t \
#     | head -1 \
#     | perl -ne '/"PrivateIpAddress": "(.*?)"/ && print "$1\n";' \
#     > ~/.a10-private-ip

## xxx: temporary

echo "10.48.1.51 area51.boi.a10networks.com area51" | sudo tee -a /etc/hosts

# Spawn an A10 appliance

if [ -z "$VTHUNDER_IMAGE_ID" ]; then
  if [ "$ACOS_VERSION" = "272" ]; then
    VTHUNDER_IMAGE_ID="0b960108-5244-47a4-9e0f-e342e802164b"
  elif [ "$ACOS_VERSION" = "401" ]; then
    VTHUNDER_IMAGE_ID="c6b522c4-e961-456c-885c-eb25f8b072fe"
  elif [ "$ACOS_VERSION" = "410" ]; then
    VTHUNDER_IMAGE_ID="28c9d2cb-2494-4fc9-95ec-5964cee373c0"
  fi
fi
id=$(curl "http://10.48.1.51/cgi-bin/a10-vm?create&image_id=$VTHUNDER_IMAGE_ID")
echo $id > ~/.a10-instance-id
