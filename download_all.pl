#!/usr/bin/perl

use File::Basename;
use Bio::SeqIO;
use Bio::PrimarySeq;


for (my $argNum = 0; $argNum<$#ARGV+1; $argnum++) {

# Get the input 
	my $org = $ARGV[$argNum];

	print "Downloading $org\n";
# create a directory
	unless (-d $org) {
		mkdir $org;
	}
	chdir $org;
# Get the results from genbank and those from refseq
	for (my $round=0; $round < 2; $round++) {
# get the assembly file
		if (-e "assembly_summary.txt") {
			unlink("assembly_summary.txt");
		}
		if ($round == 0) {
			system("wget -q ftp://ftp.ncbi.nlm.nih.gov/genomes/genbank/$org/assembly_summary.txt") == 0
				or die "failed: $?";
		}
		else {
			system("wget -q ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/$org/assembly_summary.txt") == 0
				or die "failed: $?";
		}

		unless (-e "assembly_summary.txt") {
			warn "Unable to download assembly_summary.txt\n";
			exit;
		}

# parse the file
		open(IN, "assembly_summary.txt") || die "Unable to open file\n";

# skip the titles
		while (<IN>) {
			last;
		}

# parse the data
		while(<IN>) {
			chomp();

			my @d = split(/\t/);

			if ($d[11] eq "Complete Genome") {
				my $ftppath = $d[19];

# get the unique assembly name
				my $aname = basename $ftppath;

# construct the full path
				my $fullpath = "$ftppath" . "/" . $aname . "_genomic.fna.gz";

# download
				system("wget -q $fullpath") == 0
					or die "failed: $?";
				unless (-e "${aname}_genomic.fna.gz") {
					warn "We don't have ${aname}_genomic.fna.gz, did download fail?";
					next;
				}

# gunzip
				system("gunzip ${aname}_genomic.fna.gz") == 0
					or die "failed: $?";
				unless (-e "${aname}_genomic.fna") {
					warn "We don't have ${aname}_genomic.fna, did gunzip fail?";
					next;
				}

# get tax id
				my $taxid = $d[5];

# add tax id to header in Kraken format
				my $in = Bio::SeqIO->new(-file => "${aname}_genomic.fna", -format => 'fasta');
				my $out = Bio::SeqIO->new(-file => ">${aname}_genomic.tax.fna", -format => 'fasta');

# go through all sequences and add the tax id
				while(my $seq = $in->next_seq()) {

# add kraken:taxid to the unique ID
					my $id = $seq->primary_id;
					print "$id\n";
					$id = $id . '|' . "kraken:taxid" . '|' . $taxid;

# create new seq object with updated ID
					my $newseq = Bio::PrimarySeq->new(-id => $id, -seq => $seq->seq, -desc => $seq->description);

# write it out
					$out->write_seq($newseq);
				}

# remove original
				unlink("${aname}_genomic.fna");

			}
		}
	}

	close IN;
}
