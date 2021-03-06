use strict;
use Getopt::Long;
use IO::Uncompress::Bunzip2 qw(bunzip2 $Bunzip2Error);
use IO::File;

my $infile = "";
my $outfile = "";
my $reffile = "";
my $normalfile = "";
my $result = GetOptions ( 	"infile=s" => \$infile,    # string
                       		"outfile=s" => \$outfile,
                       		"normalfile=s" => \$reffile );

print "Reading normal file: $normalfile\n";
my %snvTable = ();

my($chrInd, $startInd, $endInd, $allele1SeqInd, $allele2SeqInd, $allele1VarQualInd, $allele2VarQualInd, $refAlleleReadCountInd, $totalReadCountInd, $vartypeInd );
my($normal_refAlleleReadCount, $normal_totalReadCount);

my $INFILEHANDLE;
if ( $reffile =~ /.bz2/ ) {
	print "Found bzip2 file ... decompressing ...\n";
	$INFILEHANDLE = new IO::Uncompress::Bunzip2 $reffile or die "Cannot read $infile\n";
} else {
	$INFILEHANDLE = new IO::File "< $reffile" or die "Cannot read $infile\n";	
}

my $lineCount = 0;
my $snpCount = 0;

<$INFILEHANDLE>;

while ( my $line = <$INFILEHANDLE> ) {

	chomp($line);
	$line =~ s/\r|\n//;

	$lineCount++;			
	if ( $lineCount%100000 == 1 ) {
		print "Lines processed: $lineCount. SNPs found: $snpCount\n";
	}

	if ( $line =~ /#/ ) {
		next;
	}
	if ( $line =~ />/ ) {
		print "Found header line. Reading headers ...\n";
		my @linedat = split(/\t/, $line);
		my $indexCount = 0;
		foreach my $cell ( @linedat ) {
			if ( $cell =~ /chromosome/ ) {
				$chrInd = $indexCount;
			}
			if ( $cell =~ /begin/ ) {
				$startInd = $indexCount;
			}
			if ( $cell =~ /end/ ) {
				$endInd = $indexCount;	
			}
			if ( $cell =~ /varType/ ) {
				$vartypeInd = $indexCount;	
			}										
			if ( $cell =~ /allele1Seq/ ) {
				$allele1SeqInd = $indexCount;
			}
			if ( $cell =~ /allele2Seq/ ) {
				$allele2SeqInd = $indexCount;
			}						
			if ( $cell =~ /allele1VarFilter/ ) {
				$allele1VarQualInd = $indexCount;
			}
			if ( $cell =~ /allele2VarFilter/ ) {
				$allele2VarQualInd = $indexCount;
			}					
			if ( $cell =~ /^referenceAlleleReadCount$/ ) {
				$refAlleleReadCountInd = $indexCount;
			}
			if ( $cell =~ /^totalReadCount$/ ) {
				$totalReadCountInd = $indexCount;
			}
											
			$indexCount++;
		}	
		
		next;
		
	}
	if ( $line !~ /dbsnp/ ) {
		next;
	} 		


	my @linedat = split(/\t/, $line);

	my $chr = $linedat[$chrInd];
	my $startPos = $linedat[$startInd];
	my $endPos = $linedat[$endInd];
	my $vartype = $linedat[$vartypeInd];			
	my $allele1Seq = $linedat[$allele1SeqInd];
	my $allele2Seq = $linedat[$allele2SeqInd];		
	my $allele1VarQual = $linedat[$allele1VarQualInd];
	my $allele2VarQual = $linedat[$allele2VarQualInd];					
	my $refAlleleReadCount = $linedat[$refAlleleReadCountInd];				
	my $totalReadCount = $linedat[$totalReadCountInd];
			
	$chr =~ s/chr//;
	$chr =~ s/X/23/;
	$chr =~ s/Y/24/;
	$chr =~ s/M/25/;

	$allele1VarQual =~ s/PASS/1/;
	$allele1VarQual =~ s/VQLOW/0/;
	$allele1VarQual =~ s/AMBIGUOUS/0/;
						
	$allele2VarQual =~ s/PASS/1/;
	$allele2VarQual =~ s/VQLOW/0/;
	$allele2VarQual =~ s/AMBIGUOUS/0/;			

	if ( $allele1VarQual != 1 ) {
		next;
	}

	if ( $allele2VarQual != 1 ) {
		next;
	}

	my $id = "$chr:$startPos";
	$snvTable{$id} = {
		"CHROMOSOME" => $chr,
		"POS" => $startPos,
		"NORMALALLELECOUNT" => $refAlleleReadCount,
		"NORMALTOTALCOUNT" => $totalReadCount,
	};
	
	$snpCount++;

}

print "Reading tumour file ...\n";

my $INFILEHANDLE;
if ( $infile =~ /.bz2/ ) {
	$INFILEHANDLE = new IO::Uncompress::Bunzip2 $infile;
} else {
	$INFILEHANDLE = new IO::File "< $infile";	
}

open(OUTFILE, ">", $outfile) or die "Cannot write to: $outfile\n";

	print OUTFILE "Chr\tPosition\tAllele1VarQual\tAllele2VarQual\tTumourRefAlleleCount\tTumourTotalCount\tNormalRefAlleleCount\tNormalTotalCount\n";

	my $lineCount = 0;
	my $snpCount = 0;
	while ( my $line = <$INFILEHANDLE> ) {

		$lineCount++;			
		if ( $lineCount%100000 == 1 ) {
			print "Lines processed: $lineCount. SNPs found: $snpCount\n";
		}

		chomp($line);
		$line =~ s/\r|\n//;

		if ( $line =~ /#/ ) {
			next;
		}
		if ( $line =~ />/ ) {
			print "Found header line. Reading headers ...\n";
			my @linedat = split(/\t/, $line);
			my $indexCount = 0;
			foreach my $cell ( @linedat ) {
				if ( $cell =~ /chromosome/ ) {
					$chrInd = $indexCount;
				}
				if ( $cell =~ /begin/ ) {
					$startInd = $indexCount;
				}
				if ( $cell =~ /end/ ) {
					$endInd = $indexCount;	
				}
				if ( $cell =~ /varType/ ) {
					$vartypeInd = $indexCount;	
				}										
				if ( $cell =~ /allele1Seq/ ) {
					$allele1SeqInd = $indexCount;
				}
				if ( $cell =~ /allele2Seq/ ) {
					$allele2SeqInd = $indexCount;
				}						
				if ( $cell =~ /allele1VarFilter/ ) {
					$allele1VarQualInd = $indexCount;
				}
				if ( $cell =~ /allele2VarFilter/ ) {
					$allele2VarQualInd = $indexCount;
				}					
				if ( $cell =~ /^referenceAlleleReadCount$/ ) {
					$refAlleleReadCountInd = $indexCount;
				}
				if ( $cell =~ /^totalReadCount$/ ) {
					$totalReadCountInd = $indexCount;
				}
												
				$indexCount++;
			}	
			
			next;
			
		}
		if ( $line !~ /dbsnp/ ) {
			next;
		} 	

		my @linedat = split(/\t/, $line);
	
		my $chr = $linedat[$chrInd];
		my $startPos = $linedat[$startInd];
		my $endPos = $linedat[$endInd];
		my $vartype = $linedat[$vartypeInd];			
		my $allele1Seq = $linedat[$allele1SeqInd];
		my $allele2Seq = $linedat[$allele2SeqInd];		
		my $allele1VarQual = $linedat[$allele1VarQualInd];
		my $allele2VarQual = $linedat[$allele2VarQualInd];					
		my $refAlleleReadCount = $linedat[$refAlleleReadCountInd];				
		my $totalReadCount = $linedat[$totalReadCountInd];	
				
		$chr =~ s/chr//;
		$chr =~ s/X/23/;
		$chr =~ s/Y/24/;
		$chr =~ s/M/25/;

		$allele1VarQual =~ s/PASS/1/;
		$allele1VarQual =~ s/VQLOW/0/;
		$allele1VarQual =~ s/AMBIGUOUS/0/;
							
		$allele2VarQual =~ s/PASS/1/;
		$allele2VarQual =~ s/VQLOW/0/;
		$allele2VarQual =~ s/AMBIGUOUS/0/;			
	
		if ( $allele1VarQual != 1 ) {
			next;
		}

		if ( $allele2VarQual != 1 ) {
			next;
		}
		

		my $id = "$chr:$startPos";
		if ( !defined( $snvTable{$id} ) ) {
			next;
		} else {
			$normal_refAlleleReadCount = $snvTable{$id}->{NORMALALLELECOUNT};
			$normal_totalReadCount = $snvTable{$id}->{NORMALTOTALCOUNT};
		}
	
		print OUTFILE "$chr\t$startPos\t1\t1\t$refAlleleReadCount\t$totalReadCount\t$normal_refAlleleReadCount\t$normal_totalReadCount\n";
	
		$snpCount++;

	}

close(OUTFILE);


