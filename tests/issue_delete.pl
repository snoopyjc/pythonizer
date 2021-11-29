# issue delete as hash key
use Carp::Assert;
%options = (delete=>1);
if($options{delete}) {
    $test = 'passed';
} else {
    $test = 'failed'; 
}
assert($test eq 'passed');
delete $options{delete};
assert(! exists $options{delete});
assert(scalar(%options) == 0);
$options{foo} = 1;
delete @options{qw/foo bar/};
assert(scalar(%options) == 0);
$options{faz} = 1;
delete @options{('bar', 'faz')};
assert(scalar(%options) == 0);
$options{this} = 1;
$options{that} = 1;
assert(scalar(%options) == 2);
delete @options{keys %options};
assert(scalar(%options) == 0);
$options{a} = 4;
$options{b} = 5;
@arr = ('a', 'b');
assert(scalar(%options) == 2);
delete @options{@arr};
assert(scalar(%options) == 0);


print "$0 - test passed!\n";
