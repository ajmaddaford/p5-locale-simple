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

sub expect_op {
    my ( $self, $op ) = @_;
    return if $self->with_ws( maybe_expect => qr/\s*\Q$op\E/ );
    $self->fail( "Expected \"$op\"" );
}

sub collect_from {
    my ( $self, $methods ) = @_;
    return map { $self->$_ } @{$methods};
}

sub named_token {
    my ( $self, $name, $type ) = @_;
    $type ||= "constant_string";
    my $token = $self->maybe( sub { $self->$type } ) or $self->fail( "Expected $name" );
    return $token;
}

sub c_expect_escaped {
    my ( $self, $char ) = @_;
    return sub {
        $self->expect( qr/\\\Q$char\E/ );
        return $char;
    };
}

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

sub c_any_of {
    my ( $self, @args ) = @_;
    return sub {
        $self->any_of( @args );
    };
}

sub c_expect {
    my ( $self, @args ) = @_;
    return sub {
        $self->expect( @args );
    };
}

sub c_with_ws {
    my ( $self, $code, @args ) = @_;
    return sub {
        local $self->{patterns}{ws} = qr//;
        return $self->$code( @args );
    };
}

sub with_ws {
    my ( $self, $code, @args ) = @_;
    local $self->{patterns}{ws} = qr//;
    return $self->$code( @args );
}

1;
