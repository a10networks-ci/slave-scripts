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

# Migrate DB
echo "Migrating neutron database with A10 tables"

set +e
which a10-neutron-lbaas-db-manage > /dev/null
r=$?
set -e

if [ $r -eq 0 ]; then
    a10-neutron-lbaas-db-manage install
fi

# Run tests
echo "Running neutron lbaas $testenv test suite"
set +e

if [ "$ZUUL_BRANCH" != "stable/kilo" ]; then
    sudo -H -u $owner $sudo_env tox -e $testenv -- $test_subset
else
    # Pull a version of standalone tempest that still had the old tests
    cd /tmp
    git clone https://github.com/openstack/tempest.git
    cd tempest
    git reset --hard 4209ecfa60b96b35c8c1c74fcf4e0b34d96ae4cb
    cd ..
    mkdir v
    virtualenv v
    . v/bin/activate
    pip install -e tempest/

    TEMPEST_CONFIG_DIR=/opt/stack/tempest/etc
    TEMPEST_REGEX='(?!.*\[.*\bslow\b.*\])(tempest.api.network|tempest.cli.simple_read_only.test_neutron)(?!.*(lbaas_agent))'
    cd tempest
    testr init
    testr run "$TEMPEST_REGEX"
fi

testr_exit_code=$?
set -e

# Collect and parse results
generate_testr_results
exit $testr_exit_code
