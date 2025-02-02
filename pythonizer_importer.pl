#!/usr/bin/perl
# Importer for pythonizer: "require" the file given on the command line
# and write out the $VERSION, @EXPORT, @EXPORT_OK, %EXPORT_TAGS, and @EXPORT_FAIL information
use v5.10;
no warnings;
#use strict 'subs';
#use Data::Dumper;
use overload;           # issue s236: for overload::Method
use Sub::Util;          # issue s236: for Sub::Util::subname

package Symbol::Get;    # Not a std package, so we include a heavily modified version here

my %_sigil_to_type = qw(
    $   SCALAR
    @   ARRAY
    %   HASH
    &   CODE
);

my $sigils_re_txt = join('|', keys %_sigil_to_type);

sub get {
    my ($var) = @_;

    die 'Need a variable or constant name!' if !length $var;

    my $sigil = substr($var, 0, 1);


    if($sigil =~ /^[A-Za-z_]/) {
        my $table_hr = _get_table_hr( $var );
        #say STDERR "for $var, ref table_hr=".ref $table_hr;
        if('CODE' eq ref $table_hr || 'SCALAR' eq ref $table_hr || 'ARRAY' eq ref $table_hr) {
            return undef;       # Need '&' for subref
        }

        if($table_hr && ref $table_hr eq '' && *{$table_hr}{IO}) {
            return $table_hr && *{$table_hr}{IO};
        }

        goto \&_get_constant;
    }
    #goto \&_get_constant if $sigil =~ tr<A-Za-z_><>;

    my $type = $_sigil_to_type{$sigil} or die "Unrecognized sigil: '$sigil'";

    my $table_hr = _get_table_hr( substr($var, 1) );
    #say STDERR "for $var, ref table_hr=".ref $table_hr;
    if('CODE' eq ref $table_hr || 'SCALAR' eq ref $table_hr) {
        return $table_hr if $sigil eq '&';
        return undef;
    } elsif(ref $table_hr ne '') {
        return undef;
    }
    return $table_hr && *{$table_hr}{$type};
}

sub _get_constant {
    my ($var) = @_;

    my $ref = _get_table_hr($var);

    if ('SCALAR' ne ref($ref) && 'ARRAY' ne ref($ref)) {
        return undef;
    }

    return $ref;
}

sub get_names {
    my ($module) = @_;

    $module ||= (caller 0)[0];

    #Call::Context::must_be_list();

    my $table_hr = _get_module_table_hr($module);

    die "Unknown namespace: '$module'" if !$table_hr;

    return keys %$table_hr;
}

sub _get_module_table_hr {
    my ($module) = @_;

    my @nodes = split m<::>, $module;

    my $table_hr = \%main::;

    my $pkg = q<>;

    for my $n (@nodes) {
        $table_hr = $table_hr->{"$n\::"};
        $pkg .= "$n\::";
    }

    return $table_hr;
}

sub _get_table_hr {
    my ($name) = @_;

    $name =~ m<\A (?: (.+) ::)? ([^:]+ (?: ::)?) \z>x or do {
        #die "Invalid variable name: '$name'";
        return undef;
    };

    my $module = $1 || (caller 1)[0];

    my $table_hr = _get_module_table_hr($module);

    return $table_hr->{$2};
}

package _pythonizer_importer;   # something other than what we're importing

use File::Basename;
use File::Spec::Functions qw(file_name_is_absolute catfile);        # issue bootstrap
BEGIN {
    use Config;
    unshift @INC, dirname(__FILE__);
    if(exists $ENV{PERL5PATH}) {
        my $sep = $Config{path_sep};
        $ENV{PERL5PATH} .= $sep . dirname(__FILE__);
    } else {
        $ENV{PERL5PATH} = dirname(__FILE__);
    }
}
use Pyconfig;

my $fullfile = shift;

# issue bootstrap: we could be sent a relative path because the python version
# doesn't know the proper perl @INC, so check and make it absolute

if(file_name_is_absolute($fullfile)) {
    ;
} else {
    my $file = $fullfile;
    for my $place (@INC) {
        $fullfile = catfile($place, $file);
        if(-f $fullfile) {
            last;
        } else {
            $fullfile = $file;
        }
    }
}

my $dir = dirname($fullfile);
my $has_std = 0;
for my $d (@STANDARD_LIBRARY_DIRS) {
    if($dir =~ /$d/) {
        $has_std = 1;
        last;
    }
}
# don't add things like perl5/site_perl/Net/ to the path for Net::FTP
unshift @INC, $dir unless($has_std);

sub _gen_tags
{
        my $tag_ref = shift;
        my %tags = %$tag_ref;
        return '()' if(!%tags);

        my $result = '(';
        for my $key (keys %tags) {
            my $nkey = $key;                    # issue s164
            if(substr($key,0,1) eq ':') {       # issue s164
                $nkey = substr($key,1);         # issue s164
            }
            # issue s164 $result .= "$key => [qw/";
            if($nkey =~ /^[A-Za-z_][A-Za-z0-9_]*$/) {   # issue s164
                $result .= "$nkey => [qw/";         # issue s164
            } else {                                # issue s164
                $result .= "'$nkey' => [qw/";       # issue s164
            }                                       # issue s164
            $value = $tags{$key};
            $result .= "@$value";
            $result .= '/], ';
        }
        $result = substr($result,0,length($result)-2) . ')';
        return $result;
}

sub _gen_outs
{
        my $outs_ref = shift;
        my %outs = %$outs_ref;
        return '()' if(!%outs);

        my $result = '(';
        for my $key (keys %outs) {
            $result .= "$key => [qw/";
            $value = $outs{$key};
            my @args = (sort keys %$value);
            $result .= "@args";
            $result .= '/], ';
        }
        $result = substr($result,0,length($result)-2) . ')';
        return $result;
}

eval {
        local $SIG{__WARN__} = sub { };
        #say STDERR "fullfile=$fullfile, INC=@INC";
        package main;
        # NOTE: Be careful not to use any global variables in this code else they will appear to be
        # coming from the user's symbol table if they don't have a package declared.
        my $debug = 0;
        my @PREDEFS = qw/stdout STDOUT stderr STDERR stdin STDIN BEGIN INIT UNITCHECK CHECK END SIG ARGV INC _ ENV SRC/;
        my %PREDEFS = map { $_ => 1 } @PREDEFS;
        require $fullfile;
        open(SRC, '<', $fullfile);
        my $package = undef;
        my $in_pod = 0;
        my $CurSub = undef;
        my %wantarrays = ();
        my %out_parameters = ();            # issue s184
        my $CurShift = 0;                   # issue s184
        my %SpecialVarsUsed = ();           # issue s282
        my %ENGLISH_SCALAR = (ARG=>'_', LIST_SEPARATOR=>'"', PROCESS_ID=>'$', PID=>'$', PROGRAM_NAME=>'0',
                       REAL_GROUP_ID=>'(', GID=>'(', EFFECTIVE_GROUP_ID=>')', EGID=>')',
                       REAL_USER_ID=>'<', UID=>'<', EFFECTIVE_USER_ID=>'>', EUID=>'>',
                       SUBSCRIPT_SEPARATOR=>';', SUBSEP=>';', SYSTEM_FD_MAX=>'^F',
                       INPLACE_EDIT=>'^I', OSNAME=>'^O', BASETIME=>'^T', PERL_VERSION=>'^V',
                       EXECUTABLE_NAME=>'^X', MATCH=>'&', PREMATCH=>'`', POSTMATCH=>"'",
                       LAST_PAREN_MATCH=>'+', LAST_SUBMATCH_RESULT=>'^N', LAST_REGEXP_CODE_RESULT=>'^R',
                       LAST_MATCH_END=>'+', LAST_MATCH_START=>'-',  # in case of $LAST_MATCH_END[$ndx], etc
                       OUTPUT_FIELD_SEPARATOR=>',', OFS=>',', INPUT_LINE_NUMBER=>'.', NR=>'.',
                       INPUT_RECORD_SEPARATOR=>'/', RS=>'/', OUTPUT_RECORD_SEPARATOR=>'\\', ORS=>'\\',
                       OUTPUT_AUTOFLUSH=>'|', ACCUMULATOR=>'^A', FORMAT_FORMFEED=>'^L', FORMAT_PAGE_NUMBER=>'%',
                       FORMAT_LINES_LEFT=>'-', FORMAT_LINE_BREAK_CHARACTERS=>':', FORMAT_LINES_PER_PAGE=>'=',
                       FORMAT_TOP_NAME=>'^', FORMAT_NAME=>'~', EXTENDED_OS_ERROR=>'^E', EXCEPTIONS_BEING_CAUGHT=>'^S',
                       WARNING=>'^W', OS_ERROR=>'!', ERRNO=>'!', CHILD_ERROR=>'?', EVAL_ERROR=>'@');    # issue s282
        my %ENGLISH_ARRAY = (ARG=>'_', LAST_MATCH_END=>'+', LAST_MATCH_START=>'-'); # issue s282
        my %ENGLISH_HASH = (LAST_PAREN_MATCH=>'+', OS_ERROR=>'!', ERRNO=>'!');  # issue s282
        my $SPECIAL_VAR_PATTERN = '((?:\$(?:' . join('|', keys %ENGLISH_SCALAR) . '))|' .
                               '(?:\@(?:' . join('|', keys %ENGLISH_ARRAY) . '))|' .
                               '(?:\%(?:' . join('|', keys %ENGLISH_HASH) . '))|' .
                               '[$%@](?:(?:\^\w+\b)|[^\w\s#=]|[0-9_])' .
                              ')\b';            # issue s282
        my @specific_prop_patterns = (
            '(?:\\$_\\[(?<I>\\d+)\\]\\s*=[^~])',
            '(?:\\$_\\[(?<I>\\d+)\\]\\s*=~\\s*s\\b)',
            '(?:\\$_\\[(?<I>\\d+)\\]\\s*=~\\s*tr\\b)',
            '(?:\\$_\\[(?<I>\\d+)\\]\\s*=~\\s*y\\b)',
            '(?:\\+\\+\\$_\\[(?<I>\\d+)\\])',
            '(?:--\\$_\\[(?<I>\\d+)\\])',
            '(?:\\$_\\[(?<I>\\d+)\\]\\+\\+)',
            '(?:\\$_\\[(?<I>\\d+)\\]--)',
            '(?:\\bopen\\s*\\(\\s*\\$_\\[(?<I>\\d+)\\])',
            '(?:\\bbinmode\\s*\\(\\s*\\$_\\[(?<I>\\d+)\\])',
            '(?:\\bread\\s*\\([^,]+,\\s*\\$_\\[(?<I>\\d+)\\]\\s*,)',
            '(?:\\bchop\\s*\\(\\s*\\$_\\[(?<I>\\d+)\\])',
            '(?:\\bchomp\\s*\\(\\s*\\$_\\[(?<I>\\d+)\\])',
        );                                  # issue s184
        my @var_prop_patterns = (
            '(?:\\+\\+\\$_\\[)',
            '(?:--\\$_\\[)',
            '(?:\\bopen\\s*\\(\\s*\\$_\\[)',
            '(?:\\bbinmode\\s*\\(\\s*\\$_\\[)',
            '(?:\\bread\\s*\\([^,]+,\\s*\\$_\\[.*,)',
            '(?:\\bchop\\s*\\(\\s*\\$_\\[)',
            '(?:\\bchomp\\s*\\(\\s*\\$_\\[)'
        );                                  # issue s184
        my @reference_prop_patterns = (
            '(?:\\$\\{\\$_\\[(?<I>\\d+)\\]\\}\\s*=[^~])',
            '(?:\\$\\{\\$_\\[(?<I>\\d+)\\]\\}\\s*=~\\s*s\\b)',
            '(?:\\$\\{\\$_\\[(?<I>\\d+)\\]\\}\\s*=~\\s*tr\\b)',
            '(?:\\$\\{\\$_\\[(?<I>\\d+)\\]\\}\\s*=~\\s*y\\b)',
            '(?:\\+\\+\\$\\{\\$_\\[(?<I>\\d+)\\]\\})',
            '(?:--\\$\\{\\$_\\[(?<I>\\d+)\\]\\})',
            '(?:\\$\\{\\$_\\[(?<I>\\d+)\\]\\}\\+\\+)',
            '(?:\\$\\{\\$_\\[(?<I>\\d+)\\]\\}--)',
            '(?:\\bopen\\s*\\(\\s*\\$\\{\\$_\\[(?<I>\\d+)\\]\\})',
            '(?:\\bbinmode\\s*\\(\\s*\\$\\{\\$_\\[(?<I>\\d+)\\]\\})',
            '(?:\\bread\\s*\\([^,]+,\\s*\\$\\{\\$_\\[(?<I>\\d+)\\]\\}\\s*,)',
            '(?:\\bchop\\s*\\(\\s*\\$\\{\\$_\\[(?<I>\\d+)\\]\\})',
            '(?:\\bchomp\\s*\\(\\s*\\$\\{\\$_\\[(?<I>\\d+)\\]\\})',
        );                                  # issue s185
        my @reference_copy_patterns = (
            '(?:\\$\\{(?<V>\\$\w+)\\}\\s*=[^~])',
            '(?:\\$\\{(?<V>\\$\\w+)\\}\\s*=~\\s*s\\b)',
            '(?:\\$\\{(?<V>\\$\\w+)\\}\\s*=~\\s*tr\\b)',
            '(?:\\$\\{(?<V>\\$\\w+)\\}\\s*=~\\s*y\\b)',
            '(?:\\+\\+\\$\\{(?<V>\\$\\w+)\\})',
            '(?:--\\$\\{(?<V>\\$\\w+)\\})',
            '(?:\\$\\{(?<V>\\$\\w+)\\}\\+\\+)',
            '(?:\\$\\{(?<V>\\$\\w+)\\}--)',
            '(?:\\bopen\\s*\\(\\s*\\$\\{(?<V>\\$\\w+)\\})',
            '(?:\\bbinmode\\s*\\(\\s*\\$\\{(?<V>\\$\\w+)\\})',
            '(?:\\bread\\s*\\([^,]+,\\s*\\$\\{(?<V>\\$\\w+)\\}\\s*,)',
            '(?:\\bchop\\s*\\(\\s*\\$\\{(?<V>\\$\\w+)\\})',
            '(?:\\bchomp\\s*\\(\\s*\\$\\{(?<V>\\$\\w+)\\]\\})',
            '(?:\\$(?<V>\\$\w+)\\s*=[^~])',
            '(?:\\$(?<V>\\$\\w+)\\s*=~\\s*s\\b)',
            '(?:\\$(?<V>\\$\\w+)\\s*=~\\s*tr\\b)',
            '(?:\\$(?<V>\\$\\w+)\\s*=~\\s*y\\b)',
            '(?:\\+\\+\\$(?<V>\\$\\w+))',
            '(?:--\\$(?<V>\\$\\w+))',
            '(?:\\$(?<V>\\$\\w+)\\+\\+)',
            '(?:\\$(?<V>\\$\\w+)--)',
            '(?:\\bopen\\s*\\(\\s*\\$(?<V>\\$\\w+))',
            '(?:\\bbinmode\\s*\\(\\s*\\$(?<V>\\$\\w+))',
            '(?:\\bread\\s*\\([^,]+,\\s*\\$(?<V>\\$\\w+)\\s*,)',
            '(?:\\bchop\\s*\\(\\s*\\$(?<V>\\$\\w+))',
            '(?:\\bchomp\\s*\\(\\s*\\$(?<V>\\$\\w+))',
        );                                  # issue s185
        my %arg_copies = ();                # issue s185
        my $last_p = '';
        my $rpat = join('|', @reference_prop_patterns);
        say STDERR "rpat = $rpat" if $debug;
        my $cpat = join('|', @reference_copy_patterns);
        say STDERR "cpat = $cpat" if $debug;
        # issue s236: Need nore info!  my $blesses = 0;                       # issue s18
        my %blesses = ();                       # issue s18, issue s236: keep track of WHO blesses
        while(<SRC>) {
            if($in_pod) {                                   # issue s128: check this first!
                $in_pod = 0 if(substr($_,0,4) eq '=cut');
                    next;
            }
            if(substr($_,0,1) eq '=' && substr($_,1,1) =~ /\w/) {        # Skip POD
                $in_pod = 1;
                    next;
            }
            next if(/^\s*#/);                # skip comment lines
            s/\s+#.*$//;                # eat tail comments
            last if(/^__DATA__/ || /^__END__/);
            # FIXME: Eat strings, including '...', "...", q// s/// tr/// qw// qr// multi-line, etc
            # FIXME: Eat here documents
            if(/\bpackage\s+(.*);/) {
                $package = $1 unless defined $package;        # we just pick the first one
                #last;
            } elsif(/\bsub\s+(\w+)/) {
                $CurSub = $1;
                $CurShift = 0;              # issue s184
                %arg_copies = ();           # issue s185
            } elsif(/\bbless\b/) {          # issue s18
                # issue s236 $blesses = 1;               # issue s18
                $blesses{$CurSub} = 1 if defined $CurSub;   # issue s236: Keep track of who blesses
            } elsif(/\bwantarray\b/) {
                $wantarrays{$CurSub} = 1 if defined $CurSub;
            } elsif(/\breturn\s*\(\)/) {            # issue s254
                $wantarrays{$CurSub} = 1 if defined $CurSub;    # issue s254: Implicit wantarray
            } elsif(/^\s*\*(\w+)\s*=\s*\\\&(\w+);/) {     # issue s241 *alias = \&sub;
                $wantarrays{$1} = 1 if exists $wantarrays{$2};  # issue s241
                if(exists $out_parameters{$2}) {                # issue s241
                    $out_parameters{$1} = $out_parameters{$2};  # issue s241
                }                                               # issue s241
            } elsif($CurSub) {              # issue s184: Keep track of out parameters for each sub
                if(/\bgoto\s+\&(\w+);/ || /\breturn\s+\&(\w+);/) {      # issue s241
                    $wantarrays{$CurSub} = 1 if exists $wantarrays{$1}; # issue s241
                    if(exists $out_parameters{$1}) {                # issue s241
                        $out_parameters{$CurSub} = $out_parameters{$1};  # issue s241
                    }                                               # issue s241
                }
                if(m'^\s*my\s+(\$[A-Za-z_][A-Za-z0-9_]*)\s*=\s*shift\s*(?:\(?(?:@_)?\)?)\s*;') {      # Defining an arg copy
                    $arg_copies{$1} = $CurShift;
                    print STDERR "arg_copies{$1} = $CurShift in $CurSub on $_" if $debug;
                } elsif(m'^\s*my\s*\(([^)]*)\)\s*=\s*@_\s*;') {                 # Defining multiple arg copies
                    my @copies = split /,\s*/, $1;
                    for(my $i = 0; $i < @copies; $i++) {
                        $arg_copies{$copies[$i]} = $CurShift + $i;
                        print STDERR "arg_copies{$copies[$1]} = $CurShift + $i in $CurSub on $_" if $debug;
                    }
                } elsif(m'^\s*my\s+(\$[A-Za-z_][A-Za-z0-9_]*)\s*=\s*\$_\[(\d+)\]\s*;') {      # Defining an arg copy
                    $arg_copies{$1} = $CurShift + $2;
                    print STDERR "arg_copies{$1} = $CurShift + $2 in $CurSub on $_" if $debug;
                } elsif(m'[^$](\$[A-Za-z_][A-Za-z0-9_]*)\s*=[^~]') {             # Removes an arg copy
                    delete $arg_copies{$1};
                    print STDERR "delete arg_copies{$1} in $CurSub on $_" if $debug;
                }
                $CurShift++ if(/\bshift;/ || m'\bshift\(@_\)' || m'\bshift\s+@_' || m'\bshift\(\)');
                my $pat = join('|', @specific_prop_patterns);
                my $vpat = join('|', @var_prop_patterns);
                if($debug && $pat ne $last_p) {
                    say STDERR "pat = $pat";
                    say STDERR "vpat = $vpat";
                    $last_p = $pat;
                }

                if(m/$pat/) {
                    my $I = $+{I};
                    print STDERR "Matched pat with [$I]: $_" if($debug);
                    my $key = $I+$CurShift;
                    if(exists $out_parameters{$CurSub} && !exists $out_parameters{$CurSub}->{var}) {
                        $out_parameters{$CurSub}->{$key} = 1;
                    } else {
                        %{$out_parameters{$CurSub}} = ($key=>1);
                    }
                    my $spec_p = "(?:\\b$CurSub\\s*\\(\\s*";
                    for(my $i = 0; $i < $key; $i++) {
                        $spec_p .= '[^,]+,\\s*';
                    }
                    my $var_p = $spec_p;
                    $spec_p .= '\\$_\\[(?<I>\\d+)\\])';
                    $var_p .= '\\$_\\[)';
                    push @specific_prop_patterns, $spec_p;
                    push @var_prop_patterns, $var_p;
                    $spec_p = "(?:->\\s*$CurSub\\s*\\(\\s*";    # oo call
                    for(my $i = 0; $i < $key-1; $i++) {
                        $spec_p .= '[^,]+,\\s*';
                    }
                    $var_p = $spec_p;
                    $spec_p .= '\\$_\\[(\\d+)\\])';
                    $var_p .= '\\$_\\[)';
                    push @specific_prop_patterns, $spec_p;
                    push @var_prop_patterns, $var_p;
                } elsif(m/$cpat/) {
                    my $V = $+{V};
                    next if !exists $arg_copies{$V};
                    my $key = $arg_copies{$V};
                    print STDERR "Matched reference copy pat with [$V] (copy of $key): $_" if($debug);
                    $key .= 'r';
                    if(exists $out_parameters{$CurSub} && !exists $out_parameters{$CurSub}->{var}) {
                        $out_parameters{$CurSub}->{$key} = 1;
                    } else {
                        %{$out_parameters{$CurSub}} = ($key=>1);
                    }
                } elsif(m/$rpat/) {
                    my $I = $+{I};
                    print STDERR "Matched reference pat with [$I]: $_" if($debug);
                    my $key = $I+$CurShift;
                    $key .= 'r';
                    if(exists $out_parameters{$CurSub} && !exists $out_parameters{$CurSub}->{var}) {
                        $out_parameters{$CurSub}->{$key} = 1;
                    } else {
                        %{$out_parameters{$CurSub}} = ($key=>1);
                    }
                } elsif(m/$vpat/) {         # varargs
                    say STDERR "Matched vpat: $_" if($debug);
                    %{$out_parameters{$CurSub}} = (var=>1);
                    my $spec_p = "(?:\\b$CurSub\\s*\\(.*";
                    my $var_p = $spec_p;
                    $spec_p .= '\\$_\\[(?<I>\\d+)\\])';
                    $var_p .= '\\$_\\[)';
                    push @specific_prop_patterns, $spec_p;
                    push @var_prop_patterns, $var_p;
                } else {
                    my $p = 0;
                    while(($p = index($_, '$_[', $p)) != -1) {
                        # Find the matching ']'
                        my $balance = 0;
                        my $q;
                        for($q = $p+2; $q < length($_); $q++) {
                            my $c = substr($_, $q, 1);
                            if($c eq '[') {
                                $balance++;
                            } elsif($c eq ']') {
                                $balance--;
                            }
                            last if($balance == 0);
                        }
                        my $rest = substr($_, $q+1);
                        if($rest =~ m'^\s*=[^~]' || 
                           $rest =~ m'^\s*=~\s*s\b' ||
                           $rest =~ m'^\s*=~\s*tr\b' ||
                           $rest =~ m'^\s*=~\s*y\b' ||
                           $rest =~ m'^\+\+' || 
                           $rest =~ m'^--') {
                            say STDERR "Matched rest $_" if($debug);
                            %{$out_parameters{$CurSub}} = (var=>1);
                            my $spec_p = "(?:\\b$CurSub\\s*\\(.*";
                            my $var_p = $spec_p;
                            $spec_p .= '\\$_\\[(?<I>\\d+)\\])';
                            $var_p .= '\\$_\\[)';
                            push @specific_prop_patterns, $spec_p;
                            push @var_prop_patterns, $var_p;
                            last;
                        }
                    } continue {
                        $p++;
                    }
                }
            }
            while(/$SPECIAL_VAR_PATTERN/g) {
                my $var = $1;
                my $sigil = substr($var, 0, 1);
                my $rest = substr($var, 1);
                if($sigil eq '$' && exists $ENGLISH_SCALAR{$rest}) {
                    $var = '$' . $ENGLISH_SCALAR{$rest};
                } elsif($sigil eq '@' && exists $ENGLISH_ARRAY{$rest}) {
                    $var = '@' . $ENGLISH_ARRAY{$rest};
                } elsif($sigil eq '%' && exists $ENGLISH_HASH{$rest}) {
                    $var = '%' . $ENGLISH_HASH{$rest};
                }
                $SpecialVarsUsed{$var} = 1;
            }
        }
        close(SRC);
        if(!defined $package) {
            #say '$package=undef;';
            #return 
            $package='main';
        }
        my %pkh = %{"${package}::"};
        #say STDERR keys %pkh;
        #say STDERR "Symbol table for $package: " . Dumper(\%pkh);
        #require Symbol::Get;            # Remove this package ref and inline it here!
        my @global_vars = ();
        my @overloads = ();                # issue s3
        for my $k (keys %pkh) {
            next if $k =~ /::$/;
            if(substr($k,0,1) eq '(') {                # issue s3: key starting with '(' is an overload
                next if $k eq '((';                # not sure what this is
                push @overloads, substr($k,1);
                eval {      # issue s236: Try to get the name of the overloaded sub too
                    my $subname = Sub::Util::subname(overload::Method($package, substr($k, 1)));    # issue s236
                    push @overloads, $subname if($subname);         # issue s236
                };                                                  # issue s236
            }
            next if $k !~ /^[A-Za-z_]/;
            next if substr($k,0,2) eq '_<';        # issue s82
            next if $package eq 'main' && exists $PREDEFS{$k};
            #say STDERR "Checking $k";
            local *_tg = $pkh{$k};
            my $sc = Symbol::Get::get("\$${package}::$k");
            push @global_vars, "\$$k" if defined $_tg && defined $sc;
            my $ar = Symbol::Get::get("\@${package}::$k");
            push @global_vars, "\@$k" if defined $ar;
            my $ha = Symbol::Get::get("\%${package}::$k");
            push @global_vars, "\%$k" if defined $ha;
            my $co = Symbol::Get::get("\&${package}::$k");
            push @global_vars, "\&$k" if defined $co;
            my $fh = Symbol::Get::get("${package}::$k");
            push @global_vars, "$k" if defined $fh;
        }
        my @export = @{$pkh{EXPORT}} if exists($pkh{EXPORT});
        my @export_ok = @{$pkh{EXPORT_OK}} if exists($pkh{EXPORT_OK});
        my %export_tags = %{$pkh{EXPORT_TAGS}} if exists($pkh{EXPORT_TAGS});
        my $version = ${$pkh{VERSION}} if exists($pkh{VERSION});
        my @export_fail = @{$pkh{EXPORT_FAIL}} if exists($pkh{EXPORT_FAIL});
        my $has_export_fail_sub = (exists $pkh{export_fail}) ? 1 : 0;

        say '$package=' . "'$package';";
        say '$version=' . (defined $version ? "'$version';" : 'undef;');
        say '@export=' . (@export ? "qw/@export/;" : '();');
        say '@export_ok=' . (@export_ok ? "qw/@export_ok/;" : '();');
        say '%export_tags=' . &_pythonizer_importer::_gen_tags(\%export_tags) . ';';
        say '@export_fail=' . (@export_fail ? "qw/@export_fail/;" : '();');
        say "\$has_export_fail_sub=$has_export_fail_sub;";
        say '@global_vars=' . (@global_vars ? "qw/@global_vars/;" : '();');
        say '@overloads=' . (@overloads ? "qw'@overloads';" : '();');
        my @wantarrays = keys %wantarrays;
        say '@wantarrays=' . (@wantarrays ? "qw/@wantarrays/;" : '();');
        say '%out_parameters=' . &_pythonizer_importer::_gen_outs(\%out_parameters) . ';';
        # issue s236 say '$blesses=1' if($blesses);          # issue s18
        my @blesses = keys %blesses;                         # issue s236
        say '@blesses=' . (@blesses ? "qw/@blesses/;" : '();'); # issue s236
        my @specialvarsused = keys %SpecialVarsUsed;                         # issue s282
        say '@specialvarsused=' . (@specialvarsused ? "qw=@specialvarsused=;" : '();'); # issue s282

        #say STDERR "expand_extras: package=$package, version=$version, export=@export, export_ok=@export_ok, export_tags=@{[%export_tags]}" if($debug);
};
if($@) {
    $@ =~ s/[\r\n]/ /g;     # issue s325
    $@ =~ s/"/'/g;          # issue s325
    say '$errors=' . "\"Failed: $@\";";
    exit(1);
}
