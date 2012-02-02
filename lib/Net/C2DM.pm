package Net::C2DM;

use strict;
use warnings;

use Any::Moose;
use Net::C2DM::Authenticate;
use Net::C2DM::Notification;

our $VERSION = '0.1';

sub notify {
    my ( $self, $args ) = @_;

    my $auth = Net::C2DM::Authenticate->new(
        'email'   => $args->{email},
        'passwd'  => $args->{passwd},
        'source'  => $args->{source}
    );
    $auth->login();

    return Net::C2DM::Notification->new(
        servertoken => $auth->auth
    );
}

__PACKAGE__->meta->make_immutable;
