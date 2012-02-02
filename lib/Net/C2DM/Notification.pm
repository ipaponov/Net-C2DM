package Net::C2DM::Notification;

use Any::Moose;
use Encode qw(decode encode);
use JSON::XS;
use LWP::UserAgent;

our $VERSION = '0.1';

has message => (
    is      => 'rw',
    isa     => 'Str',
    default => ''
);

has custom => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} }
);

has devicetoken => (
    is       => 'rw',
    isa      => 'Str',
    default  => ''
);

has servertoken => (
    is       => 'rw',
    isa      => 'Str',
    default  => ''
);

has host => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http://android.apis.google.com/c2dm/send'
);

sub write {
    my ( $self ) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->default_header( 'Authorization' => 'GoogleLogin auth=' . $self->servertoken );

    my $data = {
        message => $self->message
    };

    if (scalar keys %{$self->custom} > 0) {
        $data->{custom} = $self->custom;
    }

    my $jsonxs = JSON::XS->new->utf8(1)->encode($data);

    my %params = (
        'registration_id' => $self->devicetoken,
        'collapse_key' => 0,
        'data.message' => $jsonxs
    );

    my $r = $ua->post( $self->host, \%params );

    if ($r->content =~ /InvalidRegistration/) {
        die "Bad devicetoken. Sender should remove this devicetoken";
    }

    if ($r->content =~ /QuotaExceeded/) {
        die "Too many messages sent by the sender. Retry after a while.";
    }

    if ($r->content =~ /MissingRegistration/) {
        die "Missing devicetoken. Sender should always add the devicetoken to the request.";
    }

    if ($r->content =~ /MessageTooBig/) {
        die "The payload of the message is too big, see the limitations. Reduce the size of the message.";
    }

    if ($r->code != 200) {
        die 'Error code: '.$r->status_line;
    }

    return $r->code;
}

__PACKAGE__->meta->make_immutable;
