#!/bin/bash

#Download the Analysis Summary Results
curl -X GET https://storage.googleapis.com/gtex_analysis_v7/single_tissue_eqtl_data/GTEx_Analysis_v7_eQTL.tar.gz > GTEx_Analysis_v7_eQTL.tar.gz
tar xf GTEx_Analysis_v7_eQTL.tar.gz

# Convert dbSNP variant id “rs1361754” to GTEx’s variant id “1_205801872_A_G_b37”
curl -k "https://gtexportal.org/rest/v1/reference/variant?format=tsv&snpId=rs1361754&datasetId=gtex_v7" > snp_reference.tsv
snp=`cat snp_reference.tsv | awk '{print $(NF-1)}' | tail -n 1`

# Shortcut for duration GTEx API is down
snp='1_205801872_A_G_b37'

# Grab all significant eQTLs from with variant id “1_205801872_A_G_b37”
rs="rs1361754"
zgrep $snp GTEx_Analysis_v7_eQTL/*.v7.signif_variant_gene_pairs.txt.gz > ${rs}_Sig_eQTLs.tsv
sh
rs="rs1361754"

# Convert Gencode id's in the grep results to HGNC gene symbols
zcat < GTEx_Analysis_v7_eQTL/Heart_Left_Ventricle.v7.signif_variant_gene_pairs.txt.gz | tail -n +2 | sed 's/^/tissue\t/'  > ${rs}_Sig_eQTLs_Standard_IDs.tsv
cat <<EOF | perl - ${rs}_Sig_eQTLs.tsv

use strict;
use warnings;

my %s = ();
my %g;

\$" = "\t";

while(<>) {
   chomp;
   s#GTEx_Analysis_v7_eQTL/([A-Za-z0-9-_]+)\.v7\.signif_variant_gene_pairs\.txt\.gz:#\$1\t#;
   
   my @a = split(/\t/, \$_);
   
   if(exists \$s{\$a[1]}) {
      \$a[1] = \$s{\$a[1]};
      } else {
                      
      \$a[1]     = \`curl -k "https://gtexportal.org/rest/v1/reference/variant?format=tsv&variantId=\$a[1]&datasetId=gtex_v7" 2>/dev/null | tail -n 1\`;
      my @b     = split(/\t/, \$a[1]);
      \$s{\$a[1]} = \$b[6];
      \$a[1]     = \$b[6];
   }

   if(exists \$g{\$a[2]}) {
      \$a[2] = \$g{\$a[2]};
      } else {
      \$a[2]     = \`curl -k "https://gtexportal.org/rest/v1/reference/gene?format=tsv&gencodeVersion=v19&genomeBuild=GRCh37/hg19&geneId=\$a[2]" 2>/dev/null | tail -n 1\`;
      my @b     = split(/\t/, \$a[2]);
      \$g{\$a[2]} = \$b[1];
      \$a[2]     = \$b[1];
   }

      print "@a\n";
}

