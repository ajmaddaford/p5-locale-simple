use strict;
use warnings;
use Test::More;

use Test::InDistDir;
use Capture::Tiny 'capture';
use Locale::Simple::Scraper 'scrape';
use Cwd 'getcwd';
use Test::Regression;
use Try::Tiny;

run();
done_testing;

sub run {
    $ENV{TEST_REGRESSION_GEN}++;

    my @groups = (
        { desc => "base test",                  argv => [qw()], },
        { desc => "force error on wrong quote", argv => [qw(--pl 1pl --only 1pl)], },
        { desc => "force error on wrong comma", argv => [qw(--pl 2pl --only 2pl)], },
    );
    $groups[$_]->{id} = $_ for 0 .. $#groups;

    test_group( $_, getcwd ) for @groups;

    return;
}

sub test_group {
    my ( $group, $basedir ) = @_;

    my %res;
    @res{qw( out err return )} = capture {
        try {
            scrape( @{ $group->{argv} } );
            return "success";
        }
        catch {
            chdir $basedir;
            warn $_;
            return "died";
        };
    };
    $res{$_} =~ s/\Q$basedir\E//g for qw(out err);
    $res{err} =~ s/at [^\s]+Locale\/Simple\/Scraper.pm line \d+/at Scraper.pm/;

    ok_regression(
        sub { $res{$_} },    #
        sprintf( "t/out/scrape_%02d_$_",                  $group->{id} ),
        sprintf( "%02d - $_ matches for: $group->{desc}", $group->{id} )
    ) for qw(out err return);

    return;
}
