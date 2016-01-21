#!/bin/bash -xe

GATE_DEST=$BASE/new
DEVSTACK_PATH=$GATE_DEST/devstack

ls /opt/stack
ls /opt/stack/new

env

testenv=${2:-"apiv2"}
if [ "$1" = "lbaasv1" ]; then
    testenv="apiv1"
elif [ "$1" = "lbaasv2" ]; then
    testenv="apiv2"
fi

if [ "$testenv" = "apiv1" ]; then
    ENABLED_SERVICES="-c-api,-c-bak,-c-sch,-c-vol,-cinder"
    ENABLED_SERVICES+=",-s-account,-s-container,-s-object,-s-proxy"
    export ENABLED_SERVICES
fi

if [ "$testenv" = "apiv2" ]; then
    cat > $DEVSTACK_PATH/local.conf <<EOF
[[post-config|$NEUTRON_LBAAS_CONF]]

[service_providers]
service_provider=LOADBALANCERV2:A10Networks:neutron_lbaas.drivers.a10networks.driver_v2.ThunderDriver:default
EOF
else
    cat > $DEVSTACK_PATH/local.conf <<EOF
[[post-config|$NEUTRON_LBAAS_CONF]]

[service_providers]
service_provider=LOADBALANCER:A10Networks:neutron_lbaas.services.loadbalancer.drivers.a10networks.driver_v1.ThunderDriver:default
EOF
fi

$BASE/new/neutron-lbaas/neutron_lbaas/tests/contrib/gate_hook.sh "$1" "$2"
