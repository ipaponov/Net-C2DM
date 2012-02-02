#!/usr/bin/env perl

use strict;
use warnings;

use Net::C2DM;
use Test::More tests => 6;

my $C2DM_EMAIL = 'xxx';
my $C2DM_PASSWD = 'xxx';
my $C2DM_PASSWD_WRONG = 'yyy';
my $devicetoken = '1234';
my $source = 'DEMO APP';

my $C2DM = Net::C2DM->new();


#
# trying login with wrong password
#

my $n0 = undef;
eval {
    $n0 = $C2DM->notify({
        email => $C2DM_EMAIL,
        passwd => $C2DM_PASSWD_WRONG,
        source => $source
    });
};
like($@, qr/Invalid\slogin/, 'google login failed successfully');


#
# trying login with good password
# but with fake device token
#

my $n1 = undef;
eval {
    $n1 = $C2DM->notify({
        email => $C2DM_EMAIL,
        passwd => $C2DM_PASSWD,
        source => $source
    });
};
is($@, '', 'google login seems to be finished without errors, as expected');
isnt($n1->servertoken, '', 'server token defined - google login completed successfully');

$n1->devicetoken($devicetoken);
is($n1->devicetoken, $devicetoken, 'device token set up successfully');

$n1->message('Test me');
is($n1->message, 'Test me', 'message set up successfully');

eval {
    $n1->write();
} or do {
    like($@, qr/Bad\sdevicetoken/, 'failed on sending message - wrong device token');
};
