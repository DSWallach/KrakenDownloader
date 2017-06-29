#!/bin/bash

# Copyright 2013-2015, Derrick Wood <dwood@cs.jhu.edu>
#
# This file is part of the Kraken taxonomic sequence classification system.
#
# Kraken is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Kraken is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Kraken.  If not, see <http://www.gnu.org/licenses/>.

# Download specific genomic libraries for use with Kraken.
# Supported choices are:
#   bacteria - NCBI RefSeq complete bacterial/archaeal genomes
#   plasmids - NCBI RefSeq plasmid sequences
#   viruses - NCBI RefSeq complete viral DNA and RNA genomes
#   human - NCBI RefSeq GRCh38 human reference genome

set -u  # Protect against uninitialized vars.
set -e  # Stop on error

LIBRARY_DIR="$KRAKEN_DB_NAME/library/GCA"
NCBI_SERVER="ftp.ncbi.nlm.nih.gov"
FTP_SERVER="ftp://$NCBI_SERVER"
RSYNC_SERVER="rsync://$NCBI_SERVER"
THIS_DIR=$PWD

perl download_all.pl "$1"

find "$1" -name '*.fna' -print0 | \
    xargs -0 -I{} -n1 kraken-build \
    --add-to-library {} --ab $DB_NAME

kraken-build --build --db $DB_name
