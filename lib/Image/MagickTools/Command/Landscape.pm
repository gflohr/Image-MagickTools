#! /bin/false

package Image::MagickTools::Command::Landscape;

use strict;

use base 'Image::MagickTools';

use Locale::TextDomain qw(image-magicktools);

sub _getDefaults {
	return background => 'white';
}

sub _getOptionSpecs {
	return background => 'b|background=s';
}

sub _run {
	my ($self, $args, $global_options, %options) = @_;

	my $wrappers = $options{_images};

	foreach my $wrapper (@$wrappers) {
		my $image = $wrapper->image;
		my $width = $image->Get('width');
		my $height = $image->Get('height');
		if ($height > $width) {
			my $border_width = $height * $height / $width / 2;
			my $error = $image->Border(
				width => $border_width,
				height => 0,
				bordercolor => $options{background},
			);
			die "$error\n" if length $error;
		}
	}

	return $wrappers;
}

sub description {
	return __(<<'EOF');
force landscape format on an image
EOF
}

1;

=head1 NAME

magick-tools landscape - Force landscape mode on an image

=head1 SYNOPSIS

	magick-tools [--quiet | -q] [--verbose | -v]
	[-h|--help] [-V | --version]
	IMAGE_FILES... landscape [OPTIONS]

Try 'magick-tools --help' for a description of global options.

=head1 DESCRIPTION

Force landscape mode on an image.

If the image is currently in portrait mode, a frame is added left and right so
that the aspect ratio of the image remains the same only in landscape mode.

=head1 OPTIONS

=over 4

=item -b, --background

The background color as a L<color name|https://imagemagick.org/script/color.php>.

=item -h, --help

Show this help page and exit.

=back

=head1 SEE ALSO

magick-tools(1), perl(1)
