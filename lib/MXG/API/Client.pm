package MXG::API::Client;
use strict;
use warnings FATAL => 'all';
use Net::SSL;
use LWP::UserAgent;
use JSON;
use MXG::API::Response;

sub new {
    my ($class,$endpoint,$api_key) = @_;
    $endpoint =~ s/\/$//; # remove trailing slash from endpoint
    bless {
        endpoint => $endpoint,
        api_key  => $api_key,
        ua       => LWP::UserAgent->new(
            ssl_opts => { verify_hostname => 0 },
            timeout => 10
        )
    }, $class;
}

sub request {
    my $self = shift;
    my %args = (
        method => 'GET',
        path => '',
        params => {},
        headers => {},
        data => '',
        @_
    );

    $args{path} =~ s/^\///;  # remove leading slash from path
    $args{data} = JSON::to_json($args{data}) if ref($args{data});

    my $uri = URI->new($self->{endpoint}.'/'.$args{path} );
    $uri->query_form($args{params});

    my %headers = %{$args{headers}};

    $headers{Authorization} = 'Bearer '.$self->{api_key};
    $headers{'Content-Type'} = 'application/json';
    $headers{'Accept'} = 'application/json';

    # print $args{method}.' '.$uri->as_string,"\n" if $verbose;
    # print $args{data},"\n" if $verbose and $args{data};
    my $request = HTTP::Request->new(
        $args{method},
        $uri->as_string,
        HTTP::Headers->new(%headers),
        $args{data}
    );

    #@type MXG::API::Response
    my $response = bless $self->{ua}->request($request), 'MXG::API::Response';

    return $response;
}

1;
