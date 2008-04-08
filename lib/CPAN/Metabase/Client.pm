use strict;
use warnings;
package CPAN::Metabase::Client;

our $VERSION = '0.001';

use HTTP::Request;
use JSON::XS;
use Params::Validate;
use LWP::UserAgent;
use URI;

my @valid_args;
BEGIN { @valid_args = qw(user key url) };
use Object::Tiny @valid_args;

sub new {
  my ($class, @args) = @_;

  my %args = Params::Validate::validate(
    @args,
    { map { $_ => 1 } @valid_args }
  );

  my $self = bless \%args, $class;

  return $self;
}   

sub http_request {
  my ($self, $request) = @_;
  LWP::UserAgent->new->request($request);
}

sub submit_fact {
  my ($self, $fact) = @_;

  my $path = sprintf 'submit/dist/%s/%s/%s',
    $fact->dist_author,
    $fact->dist_file,
    $fact->type;

  my $req_url = $self->abs_url($path);

  my $req = HTTP::Request->new(
    PUT => $req_url,
    [
      'Content-type' => 'text/x-json',
      'Accept'       => 'text/x-json',
    ],
    JSON::XS->new->encode({
      version => $fact->schema_version,
      content => $fact->content_as_string,
    }),
  );

  # Is it reasonable to return an HTTP::Response?  I don't know.  For now,
  # let's say yes.
  my $response = $self->http_request($req);
}

sub retrieve_fact {
  my ($self, $guid) = @_;

  my $req_url = $self->abs_url("guid/$guid");

  my $req = HTTP::Request->new(
    GET => $req_url,
    [
      'Content-type' => 'text/x-json',
      'Accept'       => 'text/x-json',
    ]
  );

  $self->http_request($req);
}

sub search_stuff {
  my ($self, @args) = @_;

  my $req_url = $self->abs_url("search/" . join '/', @args);

  my $req = HTTP::Request->new(
    GET => $req_url,
    [
      'Content-type' => 'text/x-json',
      'Accept'       => 'text/x-json',
    ]
  );

  $self->http_request($req);
}

sub abs_url {
  my ($self, $str) = @_;
  my $req_url = URI->new($str)->abs($self->url);
}

1;
