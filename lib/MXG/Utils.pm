package MXG::Utils;
use strict;
use warnings FATAL => 'all';

sub getDomainFromEmail {
    my ($self,$email) = @_;
    my ($localpart,$domain) = split('@',$email);
    lc($domain);
}

sub validateEmail {
    my ($self,$email) = @_;
    $email =~ /^([a-zA-Z0-9\+\_\=\.\-])+@([a-zA-Z0-9\-])+(\.[a-zA-Z0-9\-]+)+$/;
}

1;
