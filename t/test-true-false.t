#!/usr/bin/perl -w

use strict;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck ();

my $FILE_CHECK;
$FILE_CHECK = $1 if $0 =~ qr{t/test-(\w).t$};

skip_all "This test is designed to be run from one of the symlink: t/test-e.t ..." unless $FILE_CHECK;

note "Testing -$FILE_CHECK";

my ( @known_as_true, @known_as_false );

# list of candidates where we would use the umock file check
#	to know which state it is, and this should be preserved after the mock
my @candidates = ( $^X, qw{/bin/true /bin/false / /home /root / /usr/local} );

foreach my $f (@candidates) {
    if ( do_dash_check($f) ) {
        push @known_as_true, $f;
    }
    else {
        push @known_as_false, $f;
    }
}

# we are now mocking the function
ok Overload::FileCheck::mock_file_check( $FILE_CHECK, \&my_dash_check ), "mocking -$FILE_CHECK";

my @mocked_as_true  = qw{peace life love /bin/i-am-there /usr/local/a/b/c/d/e};
my @mocked_as_false = qw{war drug /not/there /usr/lib /usr/lib64};

sub my_dash_check {
    my $f = shift;

    note "mocked -$FILE_CHECK called for file: ", $f;

    return 1 if grep { $_ eq $f } @mocked_as_true;
    return 0 if grep { $_ eq $f } @mocked_as_false;

    # we have no idea about these files
    return -1;
}

foreach my $f ( @mocked_as_true, @known_as_true ) {
    ok( do_dash_check($f), "-$FILE_CHECK '$f' is true" );
}

foreach my $f ( @mocked_as_false, @known_as_false ) {
    ok( !do_dash_check($f), "-$FILE_CHECK '$f' is false" );
}

ok Overload::FileCheck::unmock_file_check($FILE_CHECK);

done_testing;

sub do_dash_check {
    my ($what) = @_;
    return scalar eval qq[-$FILE_CHECK "$what"];
}