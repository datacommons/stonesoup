#!/usr/bin/perl -w

use strict;

my $txt = "";
while (<>) {
    $txt = $txt . $_;
}

$txt =~ s/:[^:]*default:[^:]*flag:[^:]*translation:/:/g;
$txt =~ s/:[^:]*flag:[^:]*po-header:/:/g;

$txt =~ s/[\n\r][a-zA-Z0-9 _]+: \"\"//g;
$txt =~ s/[\n\ra-zA-Z0-9 _]+:\w*([\r\n])/$1/g;

print $txt;
