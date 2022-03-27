#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use File::Basename;
use Getopt::Long;

my $prog = basename($0);
my $command = shift;
usage("the following arguments are required: command") unless defined($command);

my $client = MXG::API::Client->new(
    $ENV{MXG_API_ENDPOINT} || 'https://secure.mxguardian.net/api/v1',
    $ENV{MXG_API_KEY}
);

if ( $command eq 'search' ) {
    search();
}

sub usage {
    my $error = shift;
    my $msg = <<EOF;

usage: $prog [options] <command> <subcommand> [<subcommand> ...] [parameters]
To see help text, you can run:

  $prog help
  $prog <command> help
  $prog <command> <subcommand> help

EOF

    $msg .= "$prog: error: $error\n\n" if defined($error);
    die($msg);
}

sub search {
    my $columns = "mail_id,date,author,subject";
    my $pagesize = 100;
    my $page = 1;
    my $outbound = 0;
    my ($domain,$user);

    GetOptions (
        "pagesize=i" => \$pagesize,
        "columns=s"  => \$columns,
        "outbound"   => \$outbound,
        "domain=s"     => \$domain,
        "user=s"       => \$user
    ) or usage();

    my %params = (
        page     => $page,
        pagesize => $pagesize,
    );
    $params{q} = shift(@ARGV) if @ARGV;

    my $path;
    my $mode = $outbound ? 'outbound' : 'inbound';
    if ( defined($domain) ) {
        $path = "domains/$domain/$mode";
    } elsif ( defined($user) ) {
        $path = "users/$user/$mode";
    } else {
        usage("domain name or user email address is required");
    }

    #@type MXG::API::Response;
    my $response = $client->request(path => $path, params => \%params );
    print $response->status_line;
    die $response->status_line()."\n" unless $response->is_success();

    my @columns = split(',',$columns);
    for my $msg (@{$response->json()}) {
        for (@columns) {
            if ( $_ eq "mail_id" ) {
                printf '%s ',$msg->{mail_id};
            } elsif ( $_ eq "date" ) {
                printf '%s ',$msg->{date};
            } elsif ( $_ eq "author" ) {
                printf '%-40s ',$msg->{author};
            } elsif ( $_ eq "subject" ) {
                printf '%-50s ',$msg->{subject};
            } elsif ( $_ eq "ip" ) {
                printf '%-25s ',$msg->{ip};
            } elsif ( $_ eq "score" ) {
                printf '%7.3f ',$msg->{score};
            }
        }
        print "\n";
    }
}

package MXG::API::Client;
use strict;
use warnings FATAL => 'all';
use LWP;

sub new {
    my ($class,$endpoint,$api_key) = @_;
    $endpoint =~ s/\/$//; # remove trailing slash from endpoint
    bless {
        endpoint => $endpoint,
        api_key  => $api_key,
        ua       => LWP::UserAgent->new(
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

    my $uri = URI->new($self->{endpoint}.'/'.$args{path} );
    $uri->query_form($args{params});

    my %headers = %{$args{headers}};

    $headers{Authorization} = 'Bearer '.$self->{api_key};
    $headers{'Accept'} = 'application/json';

    print $uri->as_string,"\n";
    my $request = HTTP::Request->new(
        $args{method},
        $uri->as_string,
        HTTP::Headers->new(%headers),
        $args{data}
    );

    bless $self->{ua}->request($request), 'MXG::API::Response';

}

1;

package MXG::API::Response;
use strict;
use warnings FATAL => 'all';
use JSON;

use parent 'HTTP::Response';

sub json {
    JSON::from_json(shift->content());
}


1;
