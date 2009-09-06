package Mojo::Server::Reversehttp;

use strict;
use warnings;
our $VERSION = '0.01';

use base qw(Mojo::Server);
use AnyEvent::ReverseHTTP;
use HTTP::Response;
use URI;
use URI::WithBase;
use Data::Dumper;

__PACKAGE__->attr(label => '');
__PACKAGE__->attr(token => '');
__PACKAGE__->attr(endpoint => '');
__PACKAGE__->attr('app_uri');
__PACKAGE__->attr('guard');

sub run {
    my $self = shift;

    my $server = AnyEvent::ReverseHTTP->new(
        on_register => sub {
            my $app_uri = shift;
	    warn __PACKAGE__, ": reversehttp running at $app_uri\n";
            $self->app_uri(URI->new($app_uri));
        },
        on_request => sub {
            my $http_req = shift;
            $self->handle_request( $self->_make_request($http_req) );
        }
    );

    $server->label($self->label) if $self->label;
    $server->token($self->token) if $self->token;
    $server->endpoint($self->endpoint) if $self->endpoint;

    $self->guard($server->connect);
}

sub handle_request {
    my ($self, $req) = @_;

    my $cv = AnyEvent->condvar;

    my $cb = sub {
        my ( $res, $err ) = @_;

        unless ( Scalar::Util::blessed($res)
            && $res->isa('Mojo::Message::Response') )
        {
            $err = "You should return instance of Mojo::Message::Response.";
        }

        if ($err) {
            print STDERR $err;
            $res = Mojo::Message::Response->new;
            $res->code(500);
            $res->message('internal server error');
        }

        my $http_res = $self->_mmres2httpres($res);

        my $content;
        my $body = $http_res->content;
        if ((Scalar::Util::blessed($body) && $body->can('read')) || (ref($body) eq 'GLOB')) {
            while (!eof $body) {
                read $body, my ($buffer), 4096;
                $content .= $buffer;
            }
            close $body;
        }
        else {
            $content = $body;
        }

        $http_res->content($content);
        $cv->send($http_res);
    };

    my $tx = $self->build_tx_cb->($self);
    $tx->req($req);
    $self->handler_cb->($self, $tx);

    my $res = $tx->res;
    $cb->($res);

    return $cv;

}

sub _make_request {
    my($self, $request) = @_;

    my $req = Mojo::Message::Request->new;
    $req->method($request->method);
    my $base = $request->uri->clone;
    $base->path_query('/');
    my $url = Mojo::URL->new($base);
    $url->query(Mojo::Parameters->new($request->content));
    $req->url($url);

    return $req;

}


sub _mmres2httpres {
    my ($self, $mmres) = @_;
    HTTP::Response->new(
        $mmres->code,
	'',
	$mmres->headers->content_type,
	$mmres->body,
    );
}

1;
__END__

=head1 NAME

Mojo::Server::Reversehttp -

=head1 SYNOPSIS

  use Mojo::Server::Reversehttp;

=head1 DESCRIPTION

Mojo::Server::Reversehttp is

=head1 AUTHOR

Kazuhiro Shibuya E<lt>stevenlabs <lt>at<gt> gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
