#!/usr/bin/perl -w

# stolen from mizp.pl

use XML::LibXML;

my $article_name = $ARGV[0];
my $article_miz = $article_name . '.miz';
my $article_xml = $article_name . '.xml';

unless (-e "$article_name.miz") {
  die "Mizar source $article_miz does not exist in the current directory";
}

unless (-e "$article_name.xml") {
  die "Article XML file $article_xml does not exist in the current directory.";
}

# the XPath expression for proofs that are not inside other proof
my $top_proof_xpath = '//Proof[not((name(..)="Proof") 
          or (name(..)="Now") or (name(..)="Hereby")
          or (name(..)="CaseBlock") or (name(..)="SupposeBlock"))]';

# read the whole mizar file as a sequence of strings
my @mizfile_lines = ();
open (MIZFILE, q{<}, $article_miz)
  or die ("Unable to open file $article_miz for reading.");
my $miz_line;
while (defined ($miz_line = <MIZFILE>)) {
  chomp $miz_line;
  push (@mizfile_lines, $miz_line);
}
close (MIZFILE)
  or die ("Unable to close the input filehandle for $article_miz!");

my $parser = XML::LibXML->new();
my $doc = $parser->parse_file($article_xml);

## get the top proof nodes (those whose parent is not another proof block)
my @tpnodes = $doc->findnodes($top_proof_xpath);
my @tppos = (); # each entry is a list of [begline,begcol,endline,endcol,nr_of_lines]
my $plinesnr = 0; # total nr of proof lines in the .miz
if($#tpnodes >= 0)
  {
    foreach my $node (@tpnodes)
      {
	# find the end position of the proof
	my ($endpos) = $node->findnodes('EndPosition[position()=last()]');
	my ($bl,$bc,$el,$ec) = ($node->findvalue('@line'),$node->findvalue('@col'),
				$endpos->findvalue('@line'),$endpos->findvalue('@col'));
	push(@tppos, [$bl,$bc,$el,$ec,$el-$bl]);
	$plinesnr += $el-$bl;
      }
  }

# DEBUG: foreach my $ln (@tppos) {print join(',',@$ln),"\n";} print $plinesnr;

# try to reconstruct the whole toplevel proofs
foreach my $pos_ref (@tppos) {
  my ($bl_num,$bc_num,$el_num,$ec_num,$len) = @$pos_ref;
  print "$bl_num,$bc_num,$el_num,$ec_num\n";
  print "======================================================================\n";
  print "proof ";
  my $miz_line = $mizfile_lines[$bl_num-1];
  if ($bl_num == $el_num) { # weird but possible: proof begins and ends on same line
    print substr ($miz_line, $bc_num, $ec_num-$bc_num);
  } else { # more typical: the proof does not begin and end on the same line
    print substr($miz_line, $bc_num);
    print "\n";
    for (my $line = $bl_num; $line < $el_num; $line++) {
      print $mizfile_lines[$line];
      print "\n";
    }
    print substr ($mizfile_lines[$el_num],0,$ec_num);
  }
  print "======================================================================\n";
}


