# -*- coding: utf-8 -*-
# vim: set fileencoding=utf-8 :
# Test special chars in strings
# 
# Use /[^[:print:]]/ to detect them
#
use Carp::Assert;
use feature 'unicode_strings';
use utf8;

my $non_printables=' 	
';

for(my $i = 0; $i < length($non_printables); $i++) {
	assert(ord substr($non_printables,$i,1) == $i);
}

my $dnon_printables=" 	
";

for(my $i = 0; $i < length($dnon_printables); $i++) {
	assert(ord substr($dnon_printables,$i,1) == $i);
}
my $space = ' ';
my $fnon_printables=" 	
$space";

for(my $i = 0; $i < length($fnon_printables); $i++) {
	assert(ord substr($fnon_printables,$i,1) == $i);
}

assert($non_printables =~ /^ 	
$/);

my $emoji = '😎🥁🎹🎤🎸💜🕛🎅🏻❌⭕️💯🇺🇸';

my @ords = qw/128526 129345 127929 127908 127928 128156 128347 127877 127995 10060 11093 65039 128175 127482 127480/;
for(my $i = 0; $i < length($emoji); $i++) {
	assert(ord substr($emoji,$i,1) == $ords[$i]);
}
assert($emoji =~ /😎/);

# from eric/o_insert_row.pl:
#my $tms_msgs = "row1
#row2\n";
my $tms_msgs = "row1\r\nrow2\r\n";

my @rws = split(/\n/, $tms_msgs);
assert(@rws == 2 && $rws[0] eq 'row1' && $rws[1] eq 'row2');
local (@rows) = split(/\n/, $tms_msgs);
assert(@rows == 2 && $rows[0] eq 'row1' && $rows[1] eq 'row2');

print "$0 - test passed!\n";
