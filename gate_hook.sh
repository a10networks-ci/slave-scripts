#!/bin/bash -xe

GATE_DEST=$BASE/new
DEVSTACK_PATH=$GATE_DEST/devstack
ENABLED_SERVICES=""
testenv=${2:-"apiv2"}
if [ "$1" = "lbaasv1" ]; then
    testenv="apiv1"
    ENABLED_SERVICES+="a10-lbaasv1,"
    echo "enabled a10-lbaasv1"

elif [ "$1" = "lbaasv2" ]; then
    testenv="apiv2"
    ENABLED_SERVICES+="a10-lbaasv2,"
    echo "enabled a10-lbaasv2"
fi

ENABLED_SERVICES+="-c-api,-c-bak,-c-sch,-c-vol,-cinder"
ENABLED_SERVICES+=",-s-account,-s-container,-s-object,-s-proxy"
if [ "$testenv" != "apiv1" ]; then
  ENABLED_SERVICES+=",q-lbaasv2,-q-lbaas"
fi
export ENABLED_SERVICES

AXAPI_ID=$(cat ~/.a10-instance-id)
AXAPI_HOST=$(curl "http://10.48.1.51/cgi-bin/a10-vm?ipaddress&id=$AXAPI_ID")
export A10_DEVICE_HOST=$AXAPI_HOST

export DEVSTACK_LOCAL_CONFIG+="
FORCE=yes
"
export DEVSTACK_LOCAL_CONFIG+="
enable_plugin neutron-lbaas https://git.openstack.org/openstack/neutron-lbaas
"
export DEVSTACK_LOCAL_CONFIG+="
enable_plugin a10-neutron-lbaas https://github.com/a10networks/a10-neutron-lbaas master
"

export DEVSTACK_LOCAL_CONFIG+="
A10_DEVICE_HOST=$AXAPI_HOST
"

# bash -x $BASE/new/neutron-lbaas/neutron_lbaas/tests/contrib/gate_hook.sh "$1" "$2"
bash -x $GATE_DEST/devstack-gate/devstack-vm-gate.sh
