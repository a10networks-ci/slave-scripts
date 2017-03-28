#!/bin/bash -x

GATE_DEST=$BASE/new
DEVSTACK_PATH=$GATE_DEST/devstack
testenv=${2:-"apiv2"}
if [ "$1" = "lbaasv1" ]; then
    testenv="apiv1"
elif [ "$1" = "lbaasv2" ]; then
    testenv="apiv2"
fi

install_python_pkg() {
    if [ -n "$2" ]; then
        set -e
        cd /tmp
        git clone "$2"
        cd $1
        set +e

        if [ -n "$ghprbPullLink" ]; then
            src_repo=$(echo "$2" | perl -ne '/([^\/]+)$/ && print "$1";' | sed -e 's/\.git//')
            pull_repo=$(echo $ghprbAuthorRepoGitUrl | perl -ne '/([^\/]+)$/ && print "$1";' | sed -e 's/\.git//')
            if [ "$src_repo" = "$pull_repo" ]; then
                set -e
                if [ "$ghprbSourceBranch" != "master" ]; then
                    git checkout -b "$ghprbSourceBranch" master
                fi
                git pull "$ghprbAuthorRepoGitUrl" "$ghprbSourceBranch"
                set +e
            fi
        # elif [ "$ZUUL_BRANCH" != "master" ]; then
        #     # ignore errors here -- no stable branch means use master
        #     git checkout "$ZUUL_BRANCH"
        fi
        set -e
        sudo -H pip install .
    else
        set -e
        sudo -H pip install -U $1
    fi
}

## A10 Software and config

install_python_pkg acos-client "$ACOS_CLIENT_GIT"
install_python_pkg a10-openstack-lib "$A10_OPENSTACK_LIB_GIT"
install_python_pkg a10-neutron-lbaas "$A10_NEUTRON_LBAAS_GIT"
set -e

# Make sure we have a configuration

AXAPI_VERSION=${AXAPI_VERSION:-2.1}
AXAPI_ID=$(cat ~/.a10-instance-id)
AXAPI_HOST=$(curl "http://10.48.1.51/cgi-bin/a10-vm?ipaddress&id=$AXAPI_ID")
export A10_DEVICE_HOST=${AXAPI_HOST:-needstobeset}
# echo "Writing private config.py"
# sudo mkdir -p /etc/a10
# sudo chmod a+rwx /etc/a10
# cat - > /etc/a10/config.py <<EOF
# devices = {
#     "ax1": {
#         "host": "$AXAPI_HOST",
#         "username": "admin",
#         "password": "a10",
#         "port": 443,
#         "api_version": "$AXAPI_VERSION",
#         "v_method": "adp",
#     },
# }
# EOF
# 
# if [ -n "$A10_USE_DATABASE" ]; then
#     echo "use_database = True" >> /etc/a10/config.py
# fi
