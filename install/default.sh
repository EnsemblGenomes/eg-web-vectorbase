#!/bin/bash

## Default setup of VB codebase
## exmaple:
##  eg-web-vectorabase/install/default.sh release/87 release/eg/35

ENSEMBL_BRANCH=$1
EG_BRANCH=$2

echo ">> Clone Ensembl repos on branch ${ENSEMBL_BRANCH}..."

git-ensembl --branch ${ENSEMBL_BRANCH} --clone web

echo ">> Clone eHive v2.2..."

git-ensembl --clone --branch version/2.2 ensembl-hive

echo ">> Cloning EG repos on branch ${EG_BRANCH}..."

git-ensembl --branch ${EG_BRANCH} --clone eg-web-common
git-ensembl --branch ${EG_BRANCH} --clone ensemblgenomes-api

echo ">> Copy configs..."

cp -rv eg-web-vectorbase/install/default/my-plugins .
cp -v  eg-web-vectorbase/install/default/conf/* ensembl-webcode/conf/

echo ">> Make logs dir..."

mkdir -pv logs
