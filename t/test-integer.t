#!/usr/bin/perl -w

use strict;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck ();

my $FILE_CHECK;
$FILE_CHECK = $1 if $0 =~ qr{t/test-(\w).t$};

skip_all "This test is designed to be run from one of the symlink: t/test-s.t ..." unless $FILE_CHECK;

note "Testing -$FILE_CHECK";

my (%known_value);

# check some -X values before mocking
my @candidates = ( $^X, qw{/bin/true /bin/false / /home /root / /usr/local /root/.bashrc} );

foreach my $f (@candidates) {
    $known_value{$f} = do_dash_check($f);
}

# we are now mocking the function
ok Overload::FileCheck::mock_file_check( $FILE_CHECK, \&my_dash_check ), "mocking -$FILE_CHECK";

# mock some int values (should be positive)
my %mocked_value = (
    q[true]        => 42,
    q[false]       => 666,
    q[/mybin/true] => 1234,
    q[/usr/lib64]  => 9876,
    q[/usr/bin]    => 789,
    q[zero]        => 0,
);

sub my_dash_check {
    my $f = shift;

    note "mocked -$FILE_CHECK called for file: ", $f;

    if ( defined $mocked_value{$f} ) {
        return $mocked_value{$f};
    }

    # we have no idea about these files
    return -1;
}

foreach my $f ( sort keys %known_value ) {
    is( do_dash_check($f), $known_value{$f}, "-$FILE_CHECK '$f' known value" );
}

foreach my $f ( sort keys %mocked_value ) {
    is( do_dash_check($f), $mocked_value{$f}, "-$FILE_CHECK '$f' mocked value" );
}

ok Overload::FileCheck::unmock_file_check($FILE_CHECK);

done_testing;

sub do_dash_check {
    my ($what) = @_;
    return scalar eval qq[-$FILE_CHECK "$what"];
}