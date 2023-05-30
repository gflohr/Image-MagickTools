#! /bin/false

package Image::MagickTools::Command::Enhance;

use strict;

use base 'Image::MagickTools';

use Locale::TextDomain qw(image-magicktools);

sub _getDefaults {}

sub _getOptionSpecs {}

sub _run {
	my ($self, $args, $global_options, %options) = @_;

	$global_options->{quiet} = 1;
	delete $global_options->{verbose};
	$global_options->{log_stderr} = 1;

	# TODO

	return $self;
}

sub description {
	return __(<<'EOF');
enhance image or images
EOF
}

1;

=head1 NAME

magick-tools enhance - Enhance image or images

=head1 SYNOPSIS

	magick-tools [--quiet | -q] [--verbose | -v]
	[-h|--help] [-V | --version]
	IMAGE_FILES... enhance [OPTIONS]

Try 'magick-tools --help' for a description of global options.

=head1 DESCRIPTION

Enhance images by applying one or more filters.

=head1 OPTIONS

=over 4

=item -h, --help

Show this help page and exit.

=back

=head1 SEE ALSO

magick-tools(1), perl(1)

=head1 QGODA

Part of Image::MagickTools.
