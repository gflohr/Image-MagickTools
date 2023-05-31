#! /usr/bin/false

package Image::MagickTools;

use strict;

$Image::MagickTools::VERSION = 0.1;

use Locale::TextDomain qw(image-magicktools);

use Image::Magick;
use File::Spec;
use Getopt::Long 2.36 qw(GetOptionsFromArray);

sub new {
	my ($class, $args, $global_options) = @_;

	$args ||= [];

	my %options = $class->parseOptions($args);

	my $self = {
		__args => $args,
		__global_options => $global_options,
		__options => \%options,
	};

	bless $self, $class;
}

sub name {
	my ($self) = @_;

	my $class = ref $self ? ref $self : $self;
	$class =~ s/.*:://;

	return lc $class;
}

sub description {
	my ($self) = @_;

	my $class = ref $self ? ref $self : $self;
	die __x("'{class}' does not implement the method 'description'.\n");
}

sub run {
	my ($self, $images) = @_;

	$images = $self->_run(
		$self->{__args},
		$self->{__global_options},
		%{$self->{__options}},
		_images => $images,
	);

	return $images;
}

sub parseOptions {
	my ($self, $args) = @_;

	my %options = $self->_getDefaults;
	my %specs = $self->_getOptionSpecs;
	$specs{help} = 'h|help';

	my %optspec;
	foreach my $key (keys %specs) {
		$optspec{$specs{$key}} =
				ref $options{$key} ? $options{$key} : \$options{$key};
	}

	Getopt::Long::Configure('bundling');
	{
		local $SIG{__WARN__} = sub {
			$SIG{__WARN__} = 'DEFAULT';
			$self->__usageError(shift);
		};

		GetOptionsFromArray($args, %optspec);
	}

	# Exits.
	$self->_displayHelp if $options{help};

	return %options;
}

sub _getDefaults {}
sub _getOptionSpecs {};

sub __usageError {
	my ($self, @msg) = @_;

	my $class = ref $self;
	$class =~ s/^Image::MagickTools::Command:://;
	my $cmd = join '-', map { lcfirst $_ } split /::/, $class;

	return Image::MagickTools::CLI->commandUsageError($cmd, @msg);
}

sub _displayHelp {
	my ($class) = @_;

	my $module = Image::MagickTools::CLI::class2module($class);

	my $path = $INC{$module};
	$path = './' . $path if !File::Spec->file_name_is_absolute($path);

	$^W = 1 if $ENV{'PERLDOCDEBUG'};
	pop @INC if $INC[-1] eq '.';
	require Pod::Perldoc;
	local @ARGV = ($path);
	exit(Pod::Perldoc->run());
}

1;

=pod

=head1 NAME

Image::MagickTools - Some ImageMagick tools that I often use.

	magick-tools [--quiet | -q] [--verbose | -v]
	[--help | -h] [--version | -V]
	[--in | -i] [--out | -i] COMMANDS [OPTIONS]

	magick-tools --help

=head1 COPYRIGHT

Copyright (C) 2023, Guido Flohr <guido.flohr@cantanea.com>
