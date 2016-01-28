#!/bin/sh -xe

TEMPEST_CONFIG_DIR="$BASE/new/tempest/etc"

if [ "$1" = "lbaasv1" -o "$1" = "apiv1" ]; then
    f=$TEMPEST_CONFIG_DIR/tempest.conf
    sudo mv $f $f.old
    sudo touch $f
    sudo chmod a+rwx $f
    cat $f.old | sed -e 's/\#api_extensions = all/api_extensions = lbaas/' > $f
fi

$BASE/new/neutron-lbaas/neutron_lbaas/tests/contrib/post_test_hook.sh "$1" "$2"
