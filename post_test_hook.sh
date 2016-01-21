#!/bin/sh -xe

env
ls $BASE
ls $BASE/new
ls $BASE/new/neutron-lbaas
ls $BASE/new/neutron-lbaas/neutron_lbaas
ls $BASE/new/neutron-lbaas/neutron_lbaas/tests
ls $BASE/new/neutron-lbaas/neutron_lbaas/tests/contrib

. $BASE/new/neutron-lbaas/neutron_lbaas/tests/contrib/post_test_hook.sh "$1" "$2"
