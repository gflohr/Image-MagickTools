#! /bin/false

package Image::MagickTools::Command::Srcset;

use strict;

use base 'Image::MagickTools';

use Locale::TextDomain qw(image-magicktools);

sub _getDefaults {
	return widths => '1920,1280,640,320,160';
}

sub _getOptionSpecs {
	return
		widths => 'w|width=s',
	;
}

sub _run {
	my ($self, $args, $global_options, %options) = @_;

	my $wrappers = $options{_images};
	my %optspec = $self->_getOptionSpecs;
	my @params = keys %optspec;
	my %params = $self->_cleanOptions(\%options, @params);

	my @widths = split /[ \t]*,[ \t]*/, $options{widths};
	die "no widths specified for srcset.\n" if !@widths;

	my @new_wrappers;
	foreach my $wrapper (@$wrappers) {
		my $image = $wrapper->image;
		my $width = $image->Get('width');
		my $height = $image->Get('height');
		my $ratio = $height / $width;

		my $default_width = $widths[0];
		my $error = $image->Scale(
			width => $default_width,
			height => $height * $default_width / $width,
		);
		die "$error\n" if length $error;
		push @new_wrappers, $wrapper;

		my $filename = $wrapper->filename;
		my $basename = $filename;
		my $extender = '';
		if ($basename =~ s/(\.[^.]+)$//) {
			$extender = $1;
		}

		foreach my $new_width (@widths) {
			my $new_wrapper = Image::MagickTools::ImageWrapper->new(
				$image->Clone,
				"$basename-${new_width}w$extender",
			);
			$error = $image->Scale(
				width => $new_width,
				height => $height * $new_width / $width,
			);
			die "$error\n" if length $error;
			push @new_wrappers, $new_wrapper;
		}
	}

	return [@new_wrappers];
}

sub description {
	return __(<<'EOF');
rotate an image
EOF
}

1;

=head1 NAME

magick-tools srcset - scale image to different widths

=head1 SYNOPSIS

	magick-tools [--quiet | -q] [--verbose | -v]
	[-h|--help] [-V | --version]
	IMAGE_FILES... srcset [OPTIONS]

Try 'magick-tools --help' for a description of global options.

=head1 DESCRIPTION

Scale an image to different widths so that you can use it as the attribute
to a C<srcset> attribute of an HTML C<img> tag.

If the output name of the image is F<photo.jpeg> it generates the following
images:

=over 4

=item F<photo.jpeg>

=item F<photo-1920w.jpeg>

=item F<photo-1280w.jpeg>

=item F<photo-640w.jpeg>

=item F<photo-320w.jpeg>

=item F<photo-160w.jpeg>

=back

=head1 OPTIONS

=over 4

=item -w, --widths DEFAULT_WIDTH,WIDTH1,WIDTH2,...

A comma separated list of widths to generate.  The first width is the default
width. Default: "1920, 1280, 640, 320, 160".

=item -b, --background

The background color as a L<color name|https://imagemagick.org/script/color.php>.

=item -h, --help

Show this help page and exit.

=back

=head1 SEE ALSO

magick-tools(1), perl(1)
