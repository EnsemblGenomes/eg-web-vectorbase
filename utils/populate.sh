#!/bin/bash

# Script to populate some data - run this post-install

echo ">> Populate gene autocomplete... "

perl ensembl-webcode/utils/make_gene_autocomplete.pl
 
echo ">> Populate vep examples... "

perl -I ensembl/modules -I ensembl-variation/modules eg-web-common/utils/populate_vep_examples_eg.pl --host localhost --port 3306 --user ensrw --pass ensrw --delete-existing