package MXG::API::Response;
use strict;
use warnings FATAL => 'all';
use JSON;

use parent 'HTTP::Response';

sub json {
    JSON::from_json(shift->content());
}

sub status {
    shift->status_line()."\n";
}

1;
