#!/usr/bin/perl -w

## Create a XML file describing the header of a Mizar article.
## This is later used for inserting the header into the HTML file.

## SYNOPSIS:
## mkxmlhead.pl abcmiz_0.miz > abcmiz_0.hdr

## ###NOTE: This really sucks, but I have tried and failed many many times to 
##      convince Andrzej that we need keywords/pragmas for this in Mizar. So 
##      I am making shaky assumptions about where the info is in the .miz file.
##      If it fails, complain loudly to Andrzej.

use strict;

my ($title, $authors, $date, $copyright);
$title = "";

sub PrintIt
{
    $date = localtime unless (defined $date);
    if (!(defined $authors) or ($title=~ /^\s*$/))
    {
	$authors = "" unless (defined $authors);

	die "Incorrect article header - some fields missing: title: \"$title\", authors: \"$authors\"\nExpected article header form is at least:\n
:: Title
:: by Author

eg:

:: Tarski Grothendieck Set Theory
::  by Andrzej Trybulec
::
:: Received January 1, 1989
:: Copyright (c) 1990 Association of Mizar Users

"; 
    }
    $copyright = "Copyright (c) " . $authors unless (defined $copyright);
    print '<?xml version="1.0"?>', "\n", '<Header xmlns:dc="http://purl.org/dc/elements/1.1/">', "\n";
    print '<dc:title>', $title, '</dc:title>', "\n";
    print '<dc:creator>', $authors, '</dc:creator>', "\n";
    print '<dc:date>', $date, '</dc:date>', "\n";
    print '<dc:rights>', $copyright, '</dc:rights>', "\n";
    print '</Header>', "\n";
    exit;
}

while(<>)
{
  m/^::+ *(.*)$/ or PrintIt(); ## print and exit when the initial comment ends
  my $content = $1;
  if($content =~ m/^[bB]y +(.*)/) { $authors = $1; }
  elsif($content =~ m/^[rR]eceived +(.*)/) { $date = $1; }
  elsif($content =~ m/^[cC]opyright +(.*)/) { $copyright = $1; }
  elsif(!($content eq "")) { $title = $title . $content; }
}
