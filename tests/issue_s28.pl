# -*- coding: utf-8 -*-
# vim: set fileencoding=utf-8 :
# The following escape sequences are available in constructs that interpolate, but not in transliterations.
# 
# \l          lowercase next character only
# \u          titlecase (not uppercase!) next character only
# \L          lowercase all characters till \E or end of string
# \U          uppercase all characters till \E or end of string
# \F          foldcase all characters till \E or end of string
# \Q          quote (disable) pattern metacharacters till \E or
#             end of string
# \E          end either case modification or quoted section
#             (whichever was last seen)
# 
# See "quotemeta" in perlfunc for the exact definition of characters that are quoted by \Q.
# 
# \L, \U, \F, and \Q can stack, in which case you need one \E for each. For example:
use feature 'unicode_strings';
use utf8;
use Carp::Assert;

assert(lcfirst "ABC" eq 'aBC');
# 
my $s = "This \Qquoting \ubusiness \Uhere isn't quite\E done yet,\E is it?";
assert($s eq q/This quoting\\ Business\\ HERE\\ ISN\\'T\\ QUITE\\ done\\ yet\\, is it?/);
my $q = 'quoting';
my $u = 'business';
my $U = q/here isn't quite/;
my $d = "done yet";
$s = "This \Q$q \u$u \U$U\E $d,\E is it?";
assert($s eq q/This quoting\\ Business\\ HERE\\ ISN\\'T\\ QUITE\\ done\\ yet\\, is it?/);

my $Uf = "UpperFirst";
assert("\l$Uf Test" eq 'upperFirst Test');

assert("\ucheck" eq 'Check');
my $c = 'check';
assert("\u$c" eq 'Check');

assert("\u\LCHECK" eq 'Check');		# ucfirst(lc("CHECK"))
assert("\L\uCHECK" eq 'Check');		# ucfirst(lc("CHECK"))
assert("\l\Ucheck" eq 'cHECK');		# lcfirst(uc("CHECK"))
assert("\U\lcheck" eq 'cHECK');		# lcfirst(uc("CHECK"))
$c = 'CHECK';
assert("\u\L$c" eq 'Check');
assert("\L\u$c" eq 'Check');

# Try adding some chars not allowed in f strings
my $Test = 'Test';
assert(qq/\U$Test \\ and ' and " with upper\E applied/ eq qq/TEST \\ AND ' AND " WITH UPPER applied/);
assert(qq/\Q$Test \\ and ' and " with quotemeta\E applied/ eq q/Test\\ \\\\\\ and\\ \\'\\ and\\ \\"\\ with\\ quotemeta applied/);

# Try with some special escapes

assert(qq/\L$Test \101/ eq q/test a/);
assert(qq/\L$Test \c@/ eq qq/test \c@/);

# The next line contains a tab char after "Test"
assert(qq/\L$Test	\N{LATIN CAPITAL LETTER A}/ eq q/test	a/);

# Try some special chars

my $blank = '';
my $emoji = '😎🥁🎹🎤🎸💜🕛🎅🏻❌⭕️💯🇺🇸';
my $emoji1 = "\U$blank😎🥁🎹🎤🎸💜🕛🎅🏻❌⭕️💯🇺🇸\E";
assert($emoji eq $emoji1);
my $emoji2 = "\L$blank\x{1f60e}\x{1f941}\x{1f3b9}\x{1f3a4}\x{1f3b8}\x{1f49c}\x{1f55b}\x{1f385}\x{1f3fb}\x{274c}\x{2b55}\x{fe0f}\x{1f4af}\x{1f1fa}\x{1f1f8}";
assert($emoji eq $emoji2);

my $non_printables=' 	
';
my $non_printables1="\l$blank 	
";
assert($non_printables eq $non_printables1);

# Try in a regex

assert($Test =~ /^\Q$Test\E$/);
assert($Test !~ /^\L$Test\E$/);
assert($Test !~ /^\U$Test\E$/);
assert("\\" =~ /^\U\\$/);
assert("\\" =~ /^\U\\$blank$/);
assert("\\" =~ /^\L$blank\\$/);
assert("\\" =~ /^\u$blank\\$blank$/);

print "\L$0 - TeSt PaSsEd!\E\n";

