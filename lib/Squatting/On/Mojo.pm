package Squatting::On::Mojo;
use strict;
use warnings;
use Data::Dump 'pp';

our $VERSION = '0.01';
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

__END__

=head1 NAME

Squatting::On::Mojo - squat on top of Mojo

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

=head1 AUTHOR

John Beppu E<lt>john.beppu@gmail.comE<gt>

=cut

# Local Variables: ***
# mode: cperl ***
# indent-tabs-mode: nil ***
# cperl-close-paren-offset: -2 ***
# cperl-continued-statement-offset: 2 ***
# cperl-indent-level: 2 ***
# cperl-indent-parens-as-block: t ***
# cperl-tab-always-indent: nil ***
# End: ***
# vim:tabstop=2 softtabstop=2 shiftwidth=2 shiftround expandtab
