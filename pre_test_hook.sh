#!/bin/bash -x

GATE_DEST=$BASE/new
DEVSTACK_PATH=$GATE_DEST/devstack

## A10 Software and config

if [ -n "$ACOS_CLIENT_GIT" ]; then
    sudo -H pip install -e "git+${ACOS_CLIENT_GIT}#egg=acos_client"
else
    sudo -H pip install -U acos-client
fi
if [ -n "$A10_NEUTRON_LBAAS_GIT" ]; then
    sudo -H pip install -e "git+${A10_NEUTRON_LBAAS_GIT}#egg=a10_neutron_lbaas"
else
    sudo -H pip install -U a10-neutron-lbaas
fi
set -e

cat > $DEVSTACK_PATH/local.conf <<EOF
[[post-config|\$NEUTRON_LBAAS_CONF]]

[service_providers]
service_provider=LOADBALANCER:A10Networks:neutron_lbaas.services.loadbalancer.drivers.a10networks.driver_v1.ThunderDriver:default
EOF

# Make sure we have a configuration

AXAPI_VERSION=${AXAPI_VERSION:-2.1}

if [ "$AXAPI_VERSION" = "2.1" ]; then
  AXAPI_HOST=10.48.51.226
else
  AXAPI_HOST=10.48.51.227
fi

echo "Writing private config.py"
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
sudo ln -s /etc/a10 /etc/neutron

# python $WORKSPACE/neutron-thirdparty-ci/ax/ax_setup.py

