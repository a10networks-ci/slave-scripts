#!/bin/bash -x

## A10 Software and config

if [ -n "$ACOS_CLIENT_GIT" ]; then
    sudo pip install -e "git+${ACOS_CLIENT_GIT}#egg=acos_client"
else
    sudo pip install -U acos-client
fi
if [ -n "$A10_NEUTRON_LBAAS_GIT" ]; then
    sudo pip install -e "git+${A10_NEUTRON_LBAAS_GIT}#egg=a10_neutron_lbaas"
else
    sudo pip install -U a10-neutron-lbaas
fi
set -e

# Make sure we have a configuration

AXAPI_VERSION=${AXAPI_VERSION:-2.1}

if [ "$AXAPI_VERSION" = "2.1" ]; then
  AXAPI_HOST=10.48.51.226
else
  AXAPI_HOST=10.48.51.227
fi

echo "Writing private config.py"
set +x
sudo mkdir -p /etc/a10
sudo chmod a+rwx /etc/a10
cat - > /etc/a10/config.py <<EOF
devices = {
    "ax1": {
        "host": "$AXAPI_HOST",
        "username": "admin",
        "password": "a10",
        "port": 443,
        "api_version": "$AXAPI_VERSION",
        "v_method": "adp",
    },
}
EOF
set -x

# python $WORKSPACE/neutron-thirdparty-ci/ax/ax_setup.py

