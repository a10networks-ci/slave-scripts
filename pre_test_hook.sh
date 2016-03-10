#!/bin/bash -x

GATE_DEST=$BASE/new
DEVSTACK_PATH=$GATE_DEST/devstack

testenv=${2:-"apiv2"}
if [ "$1" = "lbaasv1" ]; then
    testenv="apiv1"
elif [ "$1" = "lbaasv2" ]; then
    testenv="apiv2"
fi

## A10 Software and config

CONTINUE=false

if [ -n "$ACOS_CLIENT_GIT" ]; then
    if [ -n "$ghprbPullLink" ]; then
        cd /tmp && \
        git clone "$ACOS_CLIENT_GIT" && \
        cd acos-client && \
        git checkout -b "$ghprbSourceBranch" master && \
        git pull "$ghprbAuthorRepoGitUrl" "$ghprbSourceBranch" && \
        pip install .
        if [ $? -eq 0 ]; then
            CONTINUE=true
        fi
    else
        sudo -H pip install -e "git+${ACOS_CLIENT_GIT}#egg=acos_client"
        if [ $? -eq 0 ]; then
            CONTINUE=true
        fi
    fi
else
    sudo -H pip install -U acos-client
    if [ $? -eq 0 ]; then
        CONTINUE=true
    fi
fi
if [ -n "$A10_NEUTRON_LBAAS_GIT" ]; then
    if [ -n "$ghprbPullLink" ]; then
        cd /tmp && \
        git clone "$A10_NEUTRON_LBAAS_GIT" && \
        cd a10-neutron-lbaas && \
        git checkout -b "$ghprbSourceBranch" master && \
        git pull "$ghprbAuthorRepoGitUrl" "$ghprbSourceBranch" && \
        pip install .
        if [ $? -ne 0 ]; then
            CONTINUE=false
        fi
    else
        sudo -H pip install -e "git+${A10_NEUTRON_LBAAS_GIT}#egg=a10_neutron_lbaas"
        if [ $? -ne 0 ]; then
            CONTINUE=false
        fi
    fi
else
    sudo -H pip install -U a10-neutron-lbaas
    if [ $? -ne 0 ]; then
        CONTINUE=false
    fi
fi

if [ "$CONTINUE" != "true" ]; then
    echo "ERROR: a10 package install failed"
    exit 1
fi
set -e

if [ "$testenv" != "apiv1" ]; then
    cat > $DEVSTACK_PATH/local.conf <<EOF
[[post-config|\$NEUTRON_LBAAS_CONF]]

[service_providers]
service_provider=LOADBALANCERV2:A10Networks:neutron_lbaas.drivers.a10networks.driver_v2.ThunderDriver:default
EOF
else
    cat > $DEVSTACK_PATH/local.conf <<EOF
[[post-config|\$NEUTRON_LBAAS_CONF]]

[service_providers]
service_provider=LOADBALANCER:A10Networks:neutron_lbaas.services.loadbalancer.drivers.a10networks.driver_v1.ThunderDriver:default
EOF
fi

# Make sure we have a configuration

AXAPI_VERSION=${AXAPI_VERSION:-2.1}
AXAPI_ID=$(cat ~/.a10-instance-id)
AXAPI_HOST=$(curl "http://10.48.1.51/cgi-bin/a10-vm?ipaddress&id=$AXAPI_ID")

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

