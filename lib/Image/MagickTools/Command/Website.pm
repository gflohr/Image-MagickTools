#! /bin/false

package Image::MagickTools::Command::Website;

use strict;

use base 'Image::MagickTools';

use Locale::TextDomain qw(image-magicktools);

sub _getDefaults {
	return (
		thumbnail => '50x50',
		'thumbnail-offset' => 0,
		banner => '1947x843',
		'banner-offset' => 0,
	);
}

sub _getOptionSpecs {
	return (
		thumbnail => 't|thumbnail=s',
		thumbnail_offset => 'thumbnail-offset=i',
		banner => 'b|banner=s',
		banner_offset => 'banner-offset=i',
	);
}

sub _run {
	my ($self, $args, $global_options, %options) = @_;

	my $wrappers = $options{_images};
	my @new_wrappers;
	foreach my $wrapper (@$wrappers) {
		my $image = $wrapper->image;

		my $filename = $wrapper->filename;
		my $basename = $filename;
		my $extender = '';
		if ($basename =~ s/(\.[^.]+)$//) {
			$extender = $1;
		}

		my $banner_name = "$basename-banner$extender";
		$wrapper->filename($banner_name);
		push @new_wrappers, $wrapper;

		my $thumbnail_name = "$basename-thumbnail$extender";
		my $thumbnail_wrapper = Image::MagickTools::ImageWrapper->new(
			$image->Clone,
			$thumbnail_name,
		);
		push @new_wrappers, $thumbnail_wrapper;

		$self->info(__x("Cropping banner as '{filename}'.\n",
		                filename => $banner_name));
		$self->__crop($image, $options{banner}, $options{banner_offset});

		$self->info(__x("Cropping thumbnail as '{filename}'.\n",
		                filename => $thumbnail_name));
		$self->__crop(
			$thumbnail_wrapper->image, $options{thumbnail},
			$options{thumbnail_offset}
		);
	}

	return [@new_wrappers];
}

sub description {
	return __(<<'EOF');
create a thumbnail and a banner from image
force landscape format on an image
EOF
}

sub __crop {
	my ($self, $image, $dimensions, $offset) = @_;

	if ($dimensions !~ /^([1-9][0-9]*)x([1-9][0-9]*)$/i) {
		$self->fatal(
			__x("Invalid dimensions '{dimensions}', must be WxH!\n",
			    dimensions => $dimensions
		));
	}
	my ($crop_width, $crop_height) = ($1, $2);
	my $width = $image->Get('width');
	my $height = $image->Get('height');

	if ($crop_width > $width) {
		$self->fatal(
			__x(<<"EOF", width => $width, min => $crop_width)
Image is only {width} pixels wide and cannot be cropped to {min} pixels!
EOF
		);
	}

	if ($crop_height > $height) {
		$self->fatal(
			__x(<<"EOF", height => $height, min => $crop_width)
Image is only {height} pixels high and cannot be cropped to {min} pixels!
EOF
		);
	}

	my $ratio = $width / $height;
	my $crop_ratio = $crop_width / $crop_height;

	my $geometry;
	if ($crop_ratio < $ratio) {
		$self->debug("Must crop vertically.");
		my $tmp_width = $crop_ratio * $height;
		if (!defined $offset) {
			$offset = ($width - $tmp_width) / 2;
		}
		if ($offset > ($width - $tmp_width)) {
			$self->fatal(
				__x("Offset {offset} too high for dimensions {dims}, maximum is {max}.\n",
				    offset => $offset, dims => $dimensions,
				    max => $width - $tmp_width)
			);
		}
		$geometry = "${tmp_width}x${height}+$offset+0";
	} else {
		$self->debug("Must crop horizontally.");
		my $tmp_height = $width / $crop_ratio;
		if (!defined $offset) {
			$offset = ($height - $tmp_height) / 2;
		}
		if ($offset > ($height - $tmp_height)) {
			$self->fatal(
				__x("Offset {offset} too high for dimensions {dims}, maximum is {max}.\n",
				    offset => $offset, dims => $dimensions,
				    max => $height - $tmp_height)
			);
		}
		$geometry = "${width}x${tmp_height}+0+$offset";
	}

	$self->debug(__x("Crop from ${width}x${height} to $geometry."));
	my $error = $image->Crop($geometry);
	$self->fatal($error) if length $error;

	$self->debug(__x("Scale to ${crop_width}x${$crop_height}.\n"));
	$error = $image->Scale(width => $crop_width, height => $crop_height);
	$self->fatal($error) if length $error;

	return $self;
}

1;

=head1 NAME

magick-tools website - Create a thumbnail and a banner from an image

=head1 SYNOPSIS

	magick-tools [--quiet | -q] [--verbose | -v]
	[-h|--help] [-V | --version]
	IMAGE_FILES... website [OPTIONS]

Try 'magick-tools --help' for a description of global options.

=head1 DESCRIPTION

This is a helper specifically for my own website.  It creates a 50x50 thumbnail
and a 1947x843 banner from an image.

By default, the image is cropped to the centre part but you can specify an
explicit offset.

The output filename will not be used directly but "-banner" resp. "-thumbnail"
will get inserted.

=head1 OPTIONS

=over 4

=item -b, --banner=WxH

Make the banner WxH pixels instead of 1947x843.

=item --banner-offset=X

Crop the image X pixels from the edge instead of cutting out the centre of the
image.

=item -b, --thumbnail=WxH

Make the thumbnail WxH pixels instead of 1947x843.

=item --thumbnail-offset=X

Crop the image X pixels from the edge instead of cutting out the centre of the
image.

=item -h, --help

Show this help page and exit.

=back

=head1 SEE ALSO

magick-tools(1), perl(1)
