package Mojo::Command::Reversehttp;

use strict;
use warnings;

use base qw(Mojo::Command);
use Mojo::Server::Reversehttp;

__PACKAGE__->attr(description => <<'EOF');
Start application with reversehttp.
EOF
__PACKAGE__->attr(usage => <<"EOF");
usage: 
EOF

sub run {
    my $self = shift;

    my $server = Mojo::Server::Reversehttp->new(@_);
    $server->run;

    AnyEvent->condvar->recv;

    return shift;
}

1;
