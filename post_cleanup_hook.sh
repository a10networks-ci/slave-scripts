#!/bin/bash -xe

# set +e
# python $WORKSPACE/neutron-thirdparty-ci/ax/ax_dump.py
# set -e

# aws ec2 terminate-instances --instance-ids `cat ~/.a10-instance-id`

AXAPI_ID=$(cat ~/.a10-instance-id)
AXAPI_HOST=$(curl "http://10.48.1.51/cgi-bin/a10-vm?delete&id=$AXAPI_ID")
