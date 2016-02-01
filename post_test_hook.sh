#!/bin/bash -xe

TEMPEST_CONFIG_DIR="$BASE/new/tempest/etc"

if [ "$1" = "lbaasv1" -o "$1" = "apiv1" ]; then
    f=$TEMPEST_CONFIG_DIR/tempest.conf
    sudo mv $f $f.old
    sudo touch $f
    sudo chmod a+rwx $f
    cat $f.old | sed -e 's/api_extensions = all/api_extensions = lbaas/g' > $f
fi

# $BASE/new/neutron-lbaas/neutron_lbaas/tests/contrib/post_test_hook.sh "$1" "$2"

NEUTRON_LBAAS_DIR="$BASE/new/neutron-lbaas"
TEMPEST_CONFIG_DIR="$BASE/new/tempest/etc"
SCRIPTS_DIR="/usr/os-testr-env/bin"

LBAAS_VERSION=$1
LBAAS_TEST=$2

if [ "$LBAAS_VERSION" = "lbaasv1" ]; then
    testenv="apiv1"
else
    testenv="apiv2"
fi

function generate_testr_results {
    # Give job user rights to access tox logs
    sudo -H -u $owner chmod o+rw .
    sudo -H -u $owner chmod o+rw -R .testrepository
    if [ -f ".testrepository/0" ] ; then
        subunit-1to2 < .testrepository/0 > ./testrepository.subunit
        $SCRIPTS_DIR/subunit2html ./testrepository.subunit testr_results.html
        gzip -9 ./testrepository.subunit
        gzip -9 ./testr_results.html
        sudo mv ./*.gz /opt/stack/logs/
    fi
}

owner=tempest

# Set owner permissions according to job's requirements.
cd $NEUTRON_LBAAS_DIR
sudo chown -R $owner:stack $NEUTRON_LBAAS_DIR

sudo_env=" OS_TESTR_CONCURRENCY=1"

# Configure the api and scenario tests to use the tempest.conf set by devstack
sudo_env+=" TEMPEST_CONFIG_DIR=$TEMPEST_CONFIG_DIR"

if [ "$testenv" = "apiv2" ]; then
    sudo_env+=" OS_TEST_PATH=$NEUTRON_LBAAS_DIR/neutron_lbaas/tests/tempest/v2/api"
elif [ "$testenv" = "apiv1" ]; then
    sudo_env+=" OS_TEST_PATH=$NEUTRON_LBAAS_DIR/neutron_lbaas/tests/tempest/v1/api"
elif [ "$testenv" = "scenario" ]; then
    sudo_env+=" OS_TEST_PATH=$NEUTRON_LBAAS_DIR/neutron_lbaas/tests/tempest/v2/scenario"
else
    echo "ERROR: unsupported testenv: $testenv"
    exit 1
fi

# Run tests
echo "Running neutron lbaas $testenv test suite"
set +e

sudo -H -u $owner $sudo_env tox -e $testenv -- $test_subset
# sudo -H -u $owner $sudo_env testr init
# sudo -H -u $owner $sudo_env testr run

testr_exit_code=$?
set -e

# Collect and parse results
generate_testr_results
exit $testr_exit_code
