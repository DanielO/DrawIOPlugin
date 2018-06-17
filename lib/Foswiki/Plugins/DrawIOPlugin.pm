
# See bottom of file for default license and copyright information

=begin TML

---+ package Foswiki::Plugins::DrawIOPlugin

https://github.com/DanielO/DrawIOPlugin

=cut
use MIME::Base64 ();
use Data::Dumper ();

package Foswiki::Plugins::DrawIOPlugin;

# Always use strict to enforce variable scoping
use strict;
use warnings;

use Foswiki::Func    ();    # The plugins API
use Foswiki::Plugins ();    # For the API version

our $VERSION = '1.00';
our $RELEASE = '13 Jun 2018';
our $SHORTDESCRIPTION = 'Draw.io diagram editing';
our $NO_PREFS_IN_TOPIC = 1;

=begin TML

=cut
sub initPlugin {
  my ( $topic, $web, $user, $installWeb ) = @_;
  # check for Plugins.pm versions
  if ($Foswiki::Plugins::VERSION < 2.3) {
    Foswiki::Func::writeWarning( 'Version mismatch between ',
				 __PACKAGE__, ' and Plugins.pm' );
    return 0;
  }
  unless ($Foswiki::cfg{Plugins}{JQueryPlugin}{Enabled}) {
    Foswiki::Func::writeWarning(
				"DrawIOPlugin is enabled but JQueryPlugin is not. Both must be installed and enabled for DrawIOPlugin."
			       );
    return 0;
  }
  Foswiki::Func::registerTagHandler('DRAWIO', \&_DRAWIO);
  Foswiki::Func::registerRESTHandler('upload',
				     \&_restUpload,
				     authenticate => 1,	# Set to 0 if handler should be useable by WikiGuest
				     validate     => 0,	# Set to 0 to disable StrikeOne CSRF protection
				     http_allow => 'POST', # Set to 'GET,POST' to allow use HTTP GET and POST
				     description => 'Upload handler for DrawIO'
				    );

  return 1;
}

sub _DRAWIO {
  my ($session, $attributes, $topic, $web) = @_;
  my $drawingName = $attributes->{_DEFAULT} || 'untitled';
  $drawingName = (Foswiki::Func::sanitizeAttachmentName($drawingName))[0];

  my $encdata = "";
  if (Foswiki::Func::attachmentExists($web, $topic, $drawingName)) {
    my $data = Foswiki::Func::readAttachment($web, $topic, $drawingName);
    $encdata = MIME::Base64::encode_base64($data);
    $encdata =~ s{\n}{}g; # delete new lines
  }
  # In theory we could use ATTACHURLPATH and have the JS fetch it and then pass it to Draw.IO,
  # however this fails due to CORS checks by the browser which require the server to add
  # CORS headers. Instead we use data URIs which bloat the HTML
  my $src = "data:image/svg+xml;base64," . $encdata;
  my $result = CGI::img({'src' => $src,
			 'class' => "drawio",
			 'filename' => $drawingName,
			 'validation-key' => "?%NONCE%>",
			});

    Foswiki::Func::addToZone('script', 'DrawIOPlugin/drawioplugin.js', <<JS, 'JQUERYPLUGIN::FOSWIKI');
<script type="text/javascript" src="%PUBURL%/%SYSTEMWEB%/DrawIOPlugin/scripts/drawioplugin.js"></script>
JS
  return $result;
}

sub begins_with {
    return substr($_[0], 0, length($_[1])) eq $_[1];
}

sub _restUpload {
  my ($session, $plugin, $verb, $response) = @_;
  my $query = Foswiki::Func::getCgiQuery();
  #print STDERR "_restUpload called - " . Data::Dumper->Dump([$query]) . "\n";

  if ($Foswiki::cfg{Validation}{Method} eq 'strikeone') {
    require Foswiki::Validation;
    my $nonce = $query->param('validation_key');
    if (!defined($nonce) ||
	!Foswiki::Validation::isValidNonce($session->getCGISession(), $nonce)) {
      print STDERR "incorrect validation key, continuing anyway\n";
      #returnRESTResult($response, 403, "Incorrect validation key");
      #return;
    }
  }

  my $web = $query->param('_web');
  unless ($web) {
    returnRESTResult($response, 400, 'no web');
    return;
  };
  my $topic = $query->param('_topic');
  unless ($topic) {
    returnRESTResult($response, 400, 'no topic');
    return;
  };
  my $fileName = $query->param('filename');
  unless ($fileName) {
    returnRESTResult($response, 400, 'no filename');
    return;
  };
  my $origName = $fileName;
  #print STDERR "fileName $fileName\n";

  # SMELL: call to unpublished function
  ($fileName, $origName) =
    Foswiki::Sandbox::sanitizeAttachmentName($fileName);
  #print STDERR "sanitised fileName $fileName\n";

  my $content = $query->param('data');
  unless ($content) {
    returnRESTResult($response, 400, 'no data');
    return;
  }

  my $prefix = "data:image/svg+xml;base64,";
  if (!begins_with($content, $prefix)) {
    returnRESTResult($response, 400, 'invalid data');
    return;
  }

  $content = MIME::Base64::decode_base64(substr($content, length($prefix)));
  if (!defined($content) || length($content) < 100) {
    returnRESTResult($response, 400, 'unable to decode data');
    return;
  }

  my $ft = new File::Temp();	# will be unlinked on destroy
  my $fn = $ft->filename();
  binmode($ft);
  print $ft $content;
  close($ft);
  #print STDERR "Writing to $web $topic $fileName\n";
  my $error = Foswiki::Func::saveAttachment(
					    $web, $topic,
					    $fileName,
					    {
					     dontlog  => !$Foswiki::cfg{Log}{upload},
					     hide     => 0,
					     filedate => time(),
					     file     => $fn,
					     filesize => length($content),
					    }
					   );
  if ($error) {
    #print STDERR "Unable to save - $error";
    returnRESTResult($response, 500, $error);
  }

  returnRESTResult($response, 200, 'OK');
}

sub returnRESTResult {
  my ($response, $status, $text) = @_;

  $response->header(
		    -status  => $status,
		    -type    => 'text/plain',
		    -charset => 'UTF-8'
		   );
  $response->print($text);

  print STDERR $text if ($status >= 400);
}

1;

__END__
This copyright information applies to the DrawIO plugin:

# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# WaveDrom is Copyright (C) 2018 Daniel O'Connor <doconnor@gsoft.com.au>. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
