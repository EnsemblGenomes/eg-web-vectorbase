#!/bin/bash

# Default setup of VB codebase
# exmaple:
#  eg-web-vectorbase/utils/install.sh release/87 release/eg/35
#
# This script requires Ensembl Git Tools to be installed
# see https://github.com/Ensembl/ensembl-git-tools/


ENSEMBL_BRANCH=$1
EG_BRANCH=$2

echo ">> Clone Ensembl repos on branch ${ENSEMBL_BRANCH}..."

git-ensembl --branch ${ENSEMBL_BRANCH} --clone web

echo ">> Clone eHive v2.2..."

git-ensembl --branch version/2.2 --clone ensembl-hive

echo ">> Cloning EG repos on branch ${EG_BRANCH}..."

git-ensembl --branch ${EG_BRANCH} --clone eg-web-common
git-ensembl --branch ${EG_BRANCH} --clone ensemblgenomes-api

echo ">> Copy configs..."

cp -v  eg-web-vectorbase/conf/httpd.conf ensembl-webcode/conf/
cp -v  eg-web-vectorbase/conf/Auto*      ensembl-webcode/conf/

echo ">> Make logs dir..."

mkdir -pv logs

if [[ "$HOSTNAME" =~ "ebi" ]]
  then
    echo ">> Clone EBI plugins..."
    git clone git@github.com:EnsemblGenomes/eg-web-ensembl-configs.git
    cp -rv eg-web-ensembl-configs/my-plugins .
fi 