package Squatting::On::Mojo;
use strict;
use warnings;
use Data::Dump 'pp';

our %p;

$p{e} = sub {
  my $tx  = shift;
  my $req = $tx->req;
  my $uri = $req->uri;
  my %env;
  $env{QUERY_STRING}   = $uri->query || '';
  $env{REQUEST_PATH}   = '/' . $req->path;
  $env{REQUEST_URI}    = "$env{REQUEST_PATH}?$env{QUERY_STRING}";
  $env{REQUEST_METHOD} = $req->method;
  my $h = $req->headers->{_headers};
  for (keys %$h) {
    my $header = "HTTP_" . uc($_);
    $header =~ s/-/_/g;
    $env{$header} = $h->{$header}[0]; # FIXME: I need to handle multiple occurrences of a header.
  }
  \%env;
};

$p{c} = sub {
  my $tx = shift;
  my $c  = $tx->req->cookies;
  my %k;
  warn pp($c);
};

$p{init_cc} = sub {
  my ($c, $tx) = @_;
  my $cc = $c->clone;
  $cc->env     = $p{e}->($tx);
  $cc->cookies = $p{c}->($tx);
  $cc->input   = $tx->req->parameters;
  $cc->headers = { 'Content-Type' => 'text/html' };
  $cc->v       = {};
  # $cc->state = ?
  # $cc->log   = $tx->log
  $cc->status = 200;
  $cc;
};

sub mojo {
  my ($app, $tx) = @_;
  my ($c,   $p)  = &{ $app . "::D" }('/' . $tx->req->path);
  my $cc = $p{init_cc}->($c, $tx);
  my $content = $app->service($cc, @$p);
  my $h       = $tx->res->headers;
  my $ch      = $cc->headers;
  for (keys %$ch) {
    $h->headers($_ => $ch->{$_});
  }
  $tx->res->status($cc->status);
  $tx->res->body($content);
  $tx;
}

1;


