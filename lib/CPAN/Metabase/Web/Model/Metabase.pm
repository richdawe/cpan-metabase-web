use strict;
use warnings;
package CPAN::Metabase::Web::Model::Metabase;
use base 'Catalyst::Model';

use Catalyst::Utils;
use Params::Util qw(_CLASS);

my $default_config = {
  archive   => { CLASS => 'CPAN::Metabase::Archive::Filesystem' },
  gateway   => { CLASS => 'CPAN::Metabase::Gateway'             },
  index     => { CLASS => 'CPAN::Metabase::Index::FlatFile'     },
  librarian => { CLASS => 'CPAN::Metabase::Librarian'           },
};

sub _initialize {
  my ($self, $entry, $extra) = @_;
  my $merged = Catalyst::Utils::merge_hashes($entry, $extra);

  my $class = delete $merged->{CLASS};
  eval "require $class; 1" or die "couldn't load Model::Metabase class: $@";
  my $obj = $class->new($merged);
}

sub COMPONENT {
  my ($class, $c, $user_config) = @_;

  my $config = Catalyst::Utils::merge_hashes($default_config, $user_config);

  my $self = bless {} => $class;
  
  my $fact_classes = $config->{fact_classes};
  Carp::croak "no fact_classes supplied to $class configuration"
    unless $fact_classes and @$fact_classes;

  for my $fact_class (@$fact_classes) {
    Carp::croak "invalid fact class: $fact_class" unless _CLASS($fact_class);
    eval "require $fact_class; 1" or die "couldn't load fact class: $@";
  }

  my ($archive, $index);

  if ($config->{database}) {
    # This branch is here mostly to remind me that something like this should
    # be possible. -- rjbs, 2008-04-14
    $archive = $index = $self->_initialize($config->{database});
  } else {
    $archive = $self->_initialize($config->{archive});
    $index   = $self->_initialize($config->{index});
  }

  my $librarian = $self->_initialize(
    $config->{librarian},
    {
      archive => $archive,
      index   => $index,
    },
  );

  my $gateway = $self->_initialize(
    $config->{gateway},
    {
      fact_classes => $fact_classes,
      librarian    => $librarian,
    },
  );

  $self->{gateway} = $gateway;
  return $self;
}

sub gateway   { $_[0]->{gateway} }
sub librarian { $_[0]->gateway->librarian }

1;
