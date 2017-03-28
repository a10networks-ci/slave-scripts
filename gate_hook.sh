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

# if [ "$testenv" = "apiv2" ]; then
#     cat > $DEVSTACK_PATH/local.conf <<EOF
# [[post-config|\$NEUTRON_LBAAS_CONF]]

# [service_providers]
# service_provider=LOADBALANCERV2:A10Networks:neutron_lbaas.drivers.a10networks.driver_v2.ThunderDriver:default
# EOF
# else
#     cat > $DEVSTACK_PATH/local.conf <<EOF
# [[post-config|\$NEUTRON_LBAAS_CONF]]

# [service_providers]
# service_provider=LOADBALANCER:A10Networks:neutron_lbaas.services.loadbalancer.drivers.a10networks.driver_v1.ThunderDriver:default
# EOF
# fi

export DEVSTACK_LOCAL_CONFIG+="
FORCE=yes
"
export DEVSTACK_LOCAL_CONFIG+="
enable_plugin neutron-lbaas https://git.openstack.org/openstack/neutron-lbaas
"
export DEVSTACK_LOCAL_CONFIG+="
enable_plugin a10networks https://github.com/a10networks/a10-neutron-lbaas"

# bash -x $BASE/new/neutron-lbaas/neutron_lbaas/tests/contrib/gate_hook.sh "$1" "$2"
bash -x $GATE_DEST/devstack-gate/devstack-vm-gate.sh
