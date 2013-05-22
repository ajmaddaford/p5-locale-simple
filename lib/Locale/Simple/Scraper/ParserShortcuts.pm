use strict;
use warnings;

package Locale::Simple::Scraper::ParserShortcuts;

use Moo::Role;

has debug_sub => (
    is      => 'ro',
    default => sub {
        sub { shift, warn "- " . sprintf shift . "\n", @_ }
    }
);

sub debug { shift->debug_sub->( @_ ) }

sub expect_string { $_[0]->maybe_expect( "$_[1]" ) or $_[0]->fail( "Expected \"$_[1]\"" ) }

sub collect_from {
    my ( $self, @methods ) = @_;
    return map { $self->$_ } @methods;
}

sub named_token {
    my ( $self, $name, $type ) = @_;
    $type ||= "constant_string";
    my $token = $self->maybe( sub { $self->$type } ) or $self->fail( "Expected $name" );
    return $token;
}

sub expect_escaped { $_[0]->expect( qr/\\\Q$_[1]\E/ ); $_[1] }

sub warn_failure {
    my ( $self, $f ) = @_;
    my ( $linenum, $col, $text ) = $self->where( $f->{pos} || $self->pos );
    my $indent = substr( $text, 0, $col );
    $_ =~ s/\t/    /g for $text, $indent;
    $indent =~ s/./-/g;     # blank out all the non-whitespace
    $text   =~ s/\%/%%/g;
    $self->debug( "$f->{message}:\n |$text\n |$indent^" );
    return;
}

1;