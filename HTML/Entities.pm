package HTML::Entities;

=encoding utf8

=head1 NAME

HTML::Entities - Encode or decode strings with HTML entities

=head1 SYNOPSIS

 use HTML::Entities;

 $a = "V&aring;re norske tegn b&oslash;r &#230res";
 decode_entities($a);
 encode_entities($a, "\200-\377");

For example, this:

 $input = "vis-à-vis Beyoncé's naïve\npapier-mâché résumé";
 print encode_entities($input), "\n"

Prints this out:

 vis-&agrave;-vis Beyonc&eacute;'s na&iuml;ve
 papier-m&acirc;ch&eacute; r&eacute;sum&eacute;

=head1 DESCRIPTION

This module deals with encoding and decoding of strings with HTML
character entities.  The module provides the following functions:

=over 4

=item decode_entities( $string, ... )

This routine replaces HTML entities found in the $string with the
corresponding Unicode character.  Unrecognized entities are left alone.

If multiple strings are provided as argument they are each decoded
separately and the same number of strings are returned.

If called in void context the arguments are decoded in-place.

This routine is exported by default.

=item _decode_entities( $string, \%entity2char )

=item _decode_entities( $string, \%entity2char, $expand_prefix )

This will in-place replace HTML entities in $string.  The %entity2char
hash must be provided.  Named entities not found in the %entity2char
hash are left alone.  Numeric entities are expanded unless their value
overflow.

The keys in %entity2char are the entity names to be expanded and their
values are what they should expand into.  The values do not have to be
single character strings.  If a key has ";" as suffix,
then occurrences in $string are only expanded if properly terminated
with ";".  Entities without ";" will be expanded regardless of how
they are terminated for compatibility with how common browsers treat
entities in the Latin-1 range.

If $expand_prefix is TRUE then entities without trailing ";" in
%entity2char will even be expanded as a prefix of a longer
unrecognized name.  The longest matching name in %entity2char will be
used. This is mainly present for compatibility with an MSIE
misfeature.

   $string = "foo&nbspbar";
   _decode_entities($string, { nb => "@", nbsp => "\xA0" }, 1);
   print $string;  # will print "foo bar"

This routine is exported by default.

=item encode_entities( $string )

=item encode_entities( $string, $unsafe_chars )

This routine replaces unsafe characters in $string with their entity
representation. A second argument can be given to specify which characters to
consider unsafe.  The unsafe characters is specified using the regular
expression character class syntax (what you find within brackets in regular
expressions).

The default set of characters to encode are control chars, high-bit chars, and
the C<< < >>, C<< & >>, C<< > >>, C<< ' >> and C<< " >> characters.  But this,
for example, would encode I<just> the C<< < >>, C<< & >>, C<< > >>, and C<< "
>> characters:

  $encoded = encode_entities($input, '<>&"');

and this would only encode non-plain ASCII:

  $encoded = encode_entities($input, '^\n\x20-\x25\x27-\x7e');

This routine is exported by default.

=item encode_entities_numeric( $string )

=item encode_entities_numeric( $string, $unsafe_chars )

This routine works just like encode_entities, except that the replacement
entities are always C<&#xI<hexnum>;> and never C<&I<entname>;>.  For
example, C<encode_entities("r\xF4le")> returns "r&ocirc;le", but
C<encode_entities_numeric("r\xF4le")> returns "r&#xF4;le".

This routine is I<not> exported by default.  But you can always
export it with C<use HTML::Entities qw(encode_entities_numeric);>
or even C<use HTML::Entities qw(:DEFAULT encode_entities_numeric);>

=back

All these routines modify the string passed as the first argument, if
called in a void context.  In scalar and array contexts, the encoded or
decoded string is returned (without changing the input string).

If you prefer not to import these routines into your namespace, you can
call them as:

  use HTML::Entities ();
  $decoded = HTML::Entities::decode($a);
  $encoded = HTML::Entities::encode($a);
  $encoded = HTML::Entities::encode_numeric($a);

The module can also export the %char2entity and the %entity2char
hashes, which contain the mapping from all characters to the
corresponding entities (and vice versa, respectively).

=head1 COPYRIGHT

Copyright 1995-2006 Gisle Aas. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

use strict;
our $VERSION = '3.78';
our (%entity2char, %char2entity);

require 5.004;
require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(encode_entities decode_entities _decode_entities);
our @EXPORT_OK = qw(%entity2char %char2entity encode_entities_numeric);

sub Version { $VERSION; }

# SNOOPYJC require HTML::Parser;  # for fast XS implemented decode_entities
use Carp qw/croak/;     # SNOOPYJC


%entity2char = (
 # Some normal chars that have special meaning in SGML context
 amp    => '&',  # ampersand
'gt'    => '>',  # greater than
'lt'    => '<',  # less than
 quot   => '"',  # double quote
 apos   => "'",  # single quote

 # PUBLIC ISO 8879-1986//ENTITIES Added Latin 1//EN//HTML
 AElig	=> chr(198),  # capital AE diphthong (ligature)
 Aacute	=> chr(193),  # capital A, acute accent
 Acirc	=> chr(194),  # capital A, circumflex accent
 Agrave	=> chr(192),  # capital A, grave accent
 Aring	=> chr(197),  # capital A, ring
 Atilde	=> chr(195),  # capital A, tilde
 Auml	=> chr(196),  # capital A, dieresis or umlaut mark
 Ccedil	=> chr(199),  # capital C, cedilla
 ETH	=> chr(208),  # capital Eth, Icelandic
 Eacute	=> chr(201),  # capital E, acute accent
 Ecirc	=> chr(202),  # capital E, circumflex accent
 Egrave	=> chr(200),  # capital E, grave accent
 Euml	=> chr(203),  # capital E, dieresis or umlaut mark
 Iacute	=> chr(205),  # capital I, acute accent
 Icirc	=> chr(206),  # capital I, circumflex accent
 Igrave	=> chr(204),  # capital I, grave accent
 Iuml	=> chr(207),  # capital I, dieresis or umlaut mark
 Ntilde	=> chr(209),  # capital N, tilde
 Oacute	=> chr(211),  # capital O, acute accent
 Ocirc	=> chr(212),  # capital O, circumflex accent
 Ograve	=> chr(210),  # capital O, grave accent
 Oslash	=> chr(216),  # capital O, slash
 Otilde	=> chr(213),  # capital O, tilde
 Ouml	=> chr(214),  # capital O, dieresis or umlaut mark
 THORN	=> chr(222),  # capital THORN, Icelandic
 Uacute	=> chr(218),  # capital U, acute accent
 Ucirc	=> chr(219),  # capital U, circumflex accent
 Ugrave	=> chr(217),  # capital U, grave accent
 Uuml	=> chr(220),  # capital U, dieresis or umlaut mark
 Yacute	=> chr(221),  # capital Y, acute accent
 aacute	=> chr(225),  # small a, acute accent
 acirc	=> chr(226),  # small a, circumflex accent
 aelig	=> chr(230),  # small ae diphthong (ligature)
 agrave	=> chr(224),  # small a, grave accent
 aring	=> chr(229),  # small a, ring
 atilde	=> chr(227),  # small a, tilde
 auml	=> chr(228),  # small a, dieresis or umlaut mark
 ccedil	=> chr(231),  # small c, cedilla
 eacute	=> chr(233),  # small e, acute accent
 ecirc	=> chr(234),  # small e, circumflex accent
 egrave	=> chr(232),  # small e, grave accent
 eth	=> chr(240),  # small eth, Icelandic
 euml	=> chr(235),  # small e, dieresis or umlaut mark
 iacute	=> chr(237),  # small i, acute accent
 icirc	=> chr(238),  # small i, circumflex accent
 igrave	=> chr(236),  # small i, grave accent
 iuml	=> chr(239),  # small i, dieresis or umlaut mark
 ntilde	=> chr(241),  # small n, tilde
 oacute	=> chr(243),  # small o, acute accent
 ocirc	=> chr(244),  # small o, circumflex accent
 ograve	=> chr(242),  # small o, grave accent
 oslash	=> chr(248),  # small o, slash
 otilde	=> chr(245),  # small o, tilde
 ouml	=> chr(246),  # small o, dieresis or umlaut mark
 szlig	=> chr(223),  # small sharp s, German (sz ligature)
 thorn	=> chr(254),  # small thorn, Icelandic
 uacute	=> chr(250),  # small u, acute accent
 ucirc	=> chr(251),  # small u, circumflex accent
 ugrave	=> chr(249),  # small u, grave accent
 uuml	=> chr(252),  # small u, dieresis or umlaut mark
 yacute	=> chr(253),  # small y, acute accent
 yuml	=> chr(255),  # small y, dieresis or umlaut mark

 # Some extra Latin 1 chars that are listed in the HTML3.2 draft (21-May-96)
 copy   => chr(169),  # copyright sign
 reg    => chr(174),  # registered sign
 nbsp   => chr(160),  # non breaking space

 # Additional ISO-8859/1 entities listed in rfc1866 (section 14)
 iexcl  => chr(161),
 cent   => chr(162),
 pound  => chr(163),
 curren => chr(164),
 yen    => chr(165),
 brvbar => chr(166),
 sect   => chr(167),
 uml    => chr(168),
 ordf   => chr(170),
 laquo  => chr(171),
'not'   => chr(172),    # not is a keyword in perl
 shy    => chr(173),
 macr   => chr(175),
 deg    => chr(176),
 plusmn => chr(177),
 sup1   => chr(185),
 sup2   => chr(178),
 sup3   => chr(179),
 acute  => chr(180),
 micro  => chr(181),
 para   => chr(182),
 middot => chr(183),
 cedil  => chr(184),
 ordm   => chr(186),
 raquo  => chr(187),
 frac14 => chr(188),
 frac12 => chr(189),
 frac34 => chr(190),
 iquest => chr(191),
'times' => chr(215),    # times is a keyword in perl
 divide => chr(247),

 ( $] > 5.007 ? (
  'OElig;'    => chr(338),
  'oelig;'    => chr(339),
  'Scaron;'   => chr(352),
  'scaron;'   => chr(353),
  'Yuml;'     => chr(376),
  'fnof;'     => chr(402),
  'circ;'     => chr(710),
  'tilde;'    => chr(732),
  'Alpha;'    => chr(913),
  'Beta;'     => chr(914),
  'Gamma;'    => chr(915),
  'Delta;'    => chr(916),
  'Epsilon;'  => chr(917),
  'Zeta;'     => chr(918),
  'Eta;'      => chr(919),
  'Theta;'    => chr(920),
  'Iota;'     => chr(921),
  'Kappa;'    => chr(922),
  'Lambda;'   => chr(923),
  'Mu;'       => chr(924),
  'Nu;'       => chr(925),
  'Xi;'       => chr(926),
  'Omicron;'  => chr(927),
  'Pi;'       => chr(928),
  'Rho;'      => chr(929),
  'Sigma;'    => chr(931),
  'Tau;'      => chr(932),
  'Upsilon;'  => chr(933),
  'Phi;'      => chr(934),
  'Chi;'      => chr(935),
  'Psi;'      => chr(936),
  'Omega;'    => chr(937),
  'alpha;'    => chr(945),
  'beta;'     => chr(946),
  'gamma;'    => chr(947),
  'delta;'    => chr(948),
  'epsilon;'  => chr(949),
  'zeta;'     => chr(950),
  'eta;'      => chr(951),
  'theta;'    => chr(952),
  'iota;'     => chr(953),
  'kappa;'    => chr(954),
  'lambda;'   => chr(955),
  'mu;'       => chr(956),
  'nu;'       => chr(957),
  'xi;'       => chr(958),
  'omicron;'  => chr(959),
  'pi;'       => chr(960),
  'rho;'      => chr(961),
  'sigmaf;'   => chr(962),
  'sigma;'    => chr(963),
  'tau;'      => chr(964),
  'upsilon;'  => chr(965),
  'phi;'      => chr(966),
  'chi;'      => chr(967),
  'psi;'      => chr(968),
  'omega;'    => chr(969),
  'thetasym;' => chr(977),
  'upsih;'    => chr(978),
  'piv;'      => chr(982),
  'ensp;'     => chr(8194),
  'emsp;'     => chr(8195),
  'thinsp;'   => chr(8201),
  'zwnj;'     => chr(8204),
  'zwj;'      => chr(8205),
  'lrm;'      => chr(8206),
  'rlm;'      => chr(8207),
  'ndash;'    => chr(8211),
  'mdash;'    => chr(8212),
  'lsquo;'    => chr(8216),
  'rsquo;'    => chr(8217),
  'sbquo;'    => chr(8218),
  'ldquo;'    => chr(8220),
  'rdquo;'    => chr(8221),
  'bdquo;'    => chr(8222),
  'dagger;'   => chr(8224),
  'Dagger;'   => chr(8225),
  'bull;'     => chr(8226),
  'hellip;'   => chr(8230),
  'permil;'   => chr(8240),
  'prime;'    => chr(8242),
  'Prime;'    => chr(8243),
  'lsaquo;'   => chr(8249),
  'rsaquo;'   => chr(8250),
  'oline;'    => chr(8254),
  'frasl;'    => chr(8260),
  'euro;'     => chr(8364),
  'image;'    => chr(8465),
  'weierp;'   => chr(8472),
  'real;'     => chr(8476),
  'trade;'    => chr(8482),
  'alefsym;'  => chr(8501),
  'larr;'     => chr(8592),
  'uarr;'     => chr(8593),
  'rarr;'     => chr(8594),
  'darr;'     => chr(8595),
  'harr;'     => chr(8596),
  'crarr;'    => chr(8629),
  'lArr;'     => chr(8656),
  'uArr;'     => chr(8657),
  'rArr;'     => chr(8658),
  'dArr;'     => chr(8659),
  'hArr;'     => chr(8660),
  'forall;'   => chr(8704),
  'part;'     => chr(8706),
  'exist;'    => chr(8707),
  'empty;'    => chr(8709),
  'nabla;'    => chr(8711),
  'isin;'     => chr(8712),
  'notin;'    => chr(8713),
  'ni;'       => chr(8715),
  'prod;'     => chr(8719),
  'sum;'      => chr(8721),
  'minus;'    => chr(8722),
  'lowast;'   => chr(8727),
  'radic;'    => chr(8730),
  'prop;'     => chr(8733),
  'infin;'    => chr(8734),
  'ang;'      => chr(8736),
  'and;'      => chr(8743),
  'or;'       => chr(8744),
  'cap;'      => chr(8745),
  'cup;'      => chr(8746),
  'int;'      => chr(8747),
  'there4;'   => chr(8756),
  'sim;'      => chr(8764),
  'cong;'     => chr(8773),
  'asymp;'    => chr(8776),
  'ne;'       => chr(8800),
  'equiv;'    => chr(8801),
  'le;'       => chr(8804),
  'ge;'       => chr(8805),
  'sub;'      => chr(8834),
  'sup;'      => chr(8835),
  'nsub;'     => chr(8836),
  'sube;'     => chr(8838),
  'supe;'     => chr(8839),
  'oplus;'    => chr(8853),
  'otimes;'   => chr(8855),
  'perp;'     => chr(8869),
  'sdot;'     => chr(8901),
  'lceil;'    => chr(8968),
  'rceil;'    => chr(8969),
  'lfloor;'   => chr(8970),
  'rfloor;'   => chr(8971),
  'lang;'     => chr(9001),
  'rang;'     => chr(9002),
  'loz;'      => chr(9674),
  'spades;'   => chr(9824),
  'clubs;'    => chr(9827),
  'hearts;'   => chr(9829),
  'diams;'    => chr(9830),
 ) : ())
);


# Make the opposite mapping
while (my($entity, $char) = each(%entity2char)) {
    $entity =~ s/;\z//;
    $char2entity{$char} = "&$entity;";
}
delete $char2entity{"'"};  # only one-way decoding

# Fill in missing entities
for (0 .. 255) {
    next if exists $char2entity{chr($_)};
    $char2entity{chr($_)} = "&#$_;";
}

my %subst;  # compiled encoding regexps

sub encode_entities
{
    return undef unless defined $_[0];
    # SNOOPYJC my $ref;
    # SNOOPYJC if (defined wantarray) {
    # SNOOPYJC my $x = $_[0];
    # SNOOPYJC $ref = \$x;     # copy
    # SNOOPYJC } else {
    # SNOOPYJC $ref = \$_[0];  # modify in-place
    # SNOOPYJC }
    my $arg = $_[0];        # SNOOPYJC
    my $result;             # SNOOPYJC
    if (defined $_[1] and length $_[1]) {
	  unless (exists $subst{$_[1]}) {
	    # Because we can't compile regex we fake it with a cached sub
	    my $chars = $_[1];
	    $chars =~ s,(?<!\\)([]/]),\\$1,g;
	    $chars =~ s,(?<!\\)\\\z,\\\\,;
        # SNOOPYJC my $code = "sub {\$_[0] =~ s/([$chars])/\$char2entity{\$1} || num_entity(\$1)/ge; }";
        # SNOOPYJC $subst{$_[1]} = eval $code;
        # SNOOPYJC die( $@ . " while trying to turn range: \"$_[1]\"\n "
        # SNOOPYJC   . "into code: $code\n "
        # SNOOPYJC ) if $@;
        $subst{$_[1]} = sub {
                                my $arg = $_[0];
                                $arg =~ s/([$chars])/$char2entity{$1} || num_entity($1)/ge; 
                                return $arg;
                            };   # SNOOPYJC
	  }
      # SNOOPYJC &{$subst{$_[1]}}($$ref);
	  $result = &{$subst{$_[1]}}($arg);
    } else {
	  # Encode control chars, high bit chars and '<', '&', '>', ''' and '"'
      # SNOOPYJC $$ref =~ s/([^\n\r\t !\#\$%\(-;=?-~])/$char2entity{$1} || num_entity($1)/ge;
      $result = $arg;           # SNOOPYJC
	  $result =~ s/([^\n\r\t !\#\$%\(-;=?-~])/$char2entity{$1} || num_entity($1)/ge;    # SNOOPYJC
    }
    #$$ref;
    if(!defined wantarray) {        # SNOOPYJC: Void context
        $_[0] = $result;            # SNOOPYJC: Change the argument
    }                               # SNOOPYJC
    return $result;                 # SNOOPYJC 
}

sub encode_entities_numeric {
    local %char2entity;
    return &encode_entities;   # a goto &encode_entities wouldn't work
}


sub num_entity {
    sprintf "&#x%X;", ord($_[0]);
}

sub decode_entities     # SNOOPYJC
# Based on code in https://github.com/libwww-perl/HTML-Parser/blob/master/Parser.xs#L507
{
    my $items = scalar(@_);
    $items = ($items >= 1 ? 1 : $items) if(defined wantarray and !wantarray);
    my @result = ();
    for(my $i = 0; $i < $items; $i++) {
        if(defined wantarray) {
            push @result, __decode_entities__($_[$i], \%entity2char, 0);
        } else {
            $_[$i] = __decode_entities__($_[$i], \%entity2char, 0);
        }
    }
    return @result if wantarray;
    return $result[0];
}

sub _decode_entities    # SNOOPYJC
# Based on code in https://github.com/libwww-perl/HTML-Parser/blob/master/Parser.xs#L529
{
    my ($string, $entities) = @_;
    my $items = scalar(@_);
    my $expand_prefix = ($items > 2) ? $_[2] : 0;
    croak('2nd argument must be hash reference') unless ref $entities eq 'HASH';
    $_[0] = __decode_entities__($string, $entities, $expand_prefix);
}

sub __decode_entities__     # SNOOPYJC
# Based on code in https://github.com/libwww-perl/HTML-Parser/blob/master/util.c#L65
{
    my ($sv, $entity2char, $expand_prefix) = @_;
    my $len = length($sv);
    my @result = ();
    my $s = 0;
    my $end = $len;
    my $ent_start;
    my $repl;
    while($s < $end) {
        my $p = index($sv, '&', $s);
        if($p < 0) {
            push @result, substr($sv, $s, $end-$s) if $end > $s;
            last;
        }
        push @result, substr($sv, $s, ($p-$s)) if $p > $s;
        $s = $p+1;
        $ent_start = $s;
        $repl = 0;
        if($s < $end && substr($sv, $s, 1) eq '#') {
            my $num = 0;
            my $ok = 0;
            $s++;
            if($s < $end && ((lc substr($sv, $s, 1)) eq 'x')) {
                $s++;
                while($s < $end) {
                    my $c = lc ord substr($sv, $s, 1);
                    my $tmp;
                    if($c >= ord('0') && $c <= ord('9')) {
                        $tmp = $c - ord('0');
                    } elsif($c >= ord('a') && $c <= ord('f')) {
                        $tmp = $c - ord('a') + 10;
                    } else {
                        last;
                    }
                    $num = ($num << 4) + $tmp;
                    if($num > 0x10FFFF) {
                        $ok = 0;    # overflow
                        last;
                    }
                    $s++;
                    $ok = 1;
                }
            } else {
                my $c;
                while($s < $end && ($c = ord substr($sv, $s, 1)) >= ord('0') && $c <= ord('9')) {
                    $num = $num * 10 + ($c - ord('0'));
                    if($num > 0x10FFFF) {
                        $ok = 0;    # overflow
                        last;
                    }
                    $s++;
                    $ok = 1;
                }
            }
            if($num && $ok) {
                $repl = chr($num);
            }
        } else {
            my $ent_name = $s;
            while($s < $end && substr($sv, $s, 1) =~ /^[\p{Alnum}]/) {
                $s++;
            }
            if($ent_name != $s && $entity2char) {
                my $svp;
                if(exists $entity2char->{substr($sv, $ent_name, $s-$ent_name)}) {
                    $repl = $entity2char->{substr($sv, $ent_name, $s-$ent_name)};
                } elsif(substr($sv, $s, 1) eq ';' && exists $entity2char->{substr($sv, $ent_name, $s-$ent_name+1)}) {
                    $repl = $entity2char->{substr($sv, $ent_name, $s-$ent_name+1)};
                } elsif($expand_prefix) {
                    my $ss = $s - 1;
                    while($ss > $ent_name) {
                        if(exists $entity2char->{substr($sv, $ent_name, $ss-$ent_name)}) {
                            $repl = $entity2char->{substr($sv, $ent_name, $ss-$ent_name)};
                            $s = $ss;
                            last;
                        }
                        $ss--;
                    }
                }
            }
        }
        if($repl) {
            if($s < $end && substr($sv, $s, 1) eq ';') {
                $s++;
            }
            push @result, $repl;
        } else {
            push @result, '&';
            if($ent_start < $s) {
                push @result, substr($sv, $ent_start, $s-$ent_start);
            }
        }
    }
    return join('', @result);
}

# Set up aliases
*encode = \&encode_entities;
*encode_numeric = \&encode_entities_numeric;
*encode_numerically = \&encode_entities_numeric;
*decode = \&decode_entities;

1;
