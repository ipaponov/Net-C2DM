package Net::C2DM::Authenticate;

use strict;
use warnings;

use Any::Moose;
use LWP::UserAgent;

has email => (
    is      => 'rw',
    isa     => 'Str',
    default => ''
);

has passwd => (
    is      => 'rw',
    isa     => 'Str',
    default => ''
);

has source => (
    is      => 'rw',
    isa     => 'Str',
    default => ''
);

has auth => (
    is      => 'rw',
    isa     => 'Str',
    default => ''
);

has _ua => (
    is      => 'rw',
    isa     => 'LWP::UserAgent',
    lazy    => 1,
    default => sub {
        return LWP::UserAgent->new();
    }
);

sub ua {
    my $self = shift;

    my $ua = $self->_ua();
    $ua->agent($self->source);

    $self->auth
        ? $ua->default_header('Authorization' => 'GoogleLogin auth=' . $self->auth)
        : $ua->default_headers->remove_header('Authorization');

    return $ua;
}

sub login {
    my $self = shift;

    my $service = 'ac2dm';
    my $accountType = 'HOSTED_OR_GOOGLE';

    my %params = (
        accountType => 'HOSTED_OR_GOOGLE',
        service     => 'ac2dm',

        Email  => $self->email(),
        Passwd => $self->passwd(),
        source => $self->source()
    );

    my $r = $self->ua->post( 'https://www.google.com/accounts/ClientLogin', \%params );
    if ( $r->code == 403 ) {

        my ( $error ) = $r->content =~ m!Error=(.+)(\s+|$)!i;
        die "Invalid login: $error (" . $self->_error_code( $error ) . ')';

    } elsif ( $r->code == 200 ) {

        my ( $auth ) = $r->content =~ m!Auth=(.+)(\s+|$)!i;
        die "PANIC: Got a valid response from Google, but can't find Auth string"
            if $auth eq '';

        $self->auth( $auth );

    } else {

        # If we get here then something's up with Google's website
        # http://code.google.com/apis/accounts/AuthForInstalledApps.html#Response
        # or else with our connection.
        die 'PANIC: Got unexpected response (' . $r->code . ')';

    }
}

sub _error_code {
    my $self = shift;
    my $c = shift;

    return exists $self->codes->{ $c } ?
        $self->codes->{ $c } : $self->codes->{ 'Unknown' };
}

has codes => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
      return {
        'BadAuthentication'
            => 'The login request used a username or password that is not recognized.',

        'NotVerified'
            => 'The account email address has not been verified. The user will need to '
            .'access their Google account directly to resolve the issue before logging '
            .'in using a non-Google application.',

        'TermsNotAgreed'
            => 'The user has not agreed to terms. The user will need to access their '
            .'Google account directly to resolve the issue before logging in using a '
            .'non-Google application.',

        'CaptchaRequired'
            => 'A CAPTCHA is required. (A response with this error code will also contain '
            .'an image URL and a CAPTCHA token.)',

        'Unknown'
            => 'The error is unknown or unspecified; the request contained invalid input '
            .'or was malformed.',

        'AccountDeleted'
            => 'The user account has been deleted.',

        'AccountDisabled'
            => 'The user account has been disabled.',

        'ServiceDisabled'
            => 'The user\'s access to the specified service has been disabled. (The user '
            .'account may still be valid.)',

        'ServiceUnavailable'
            => 'The service is not available; try again later.'
      };
    }
);

__PACKAGE__->meta->make_immutable;
