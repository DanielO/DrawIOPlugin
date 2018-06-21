
# See bottom of file for default license and copyright information

=begin TML

---+ package Foswiki::Plugins::DrawIOPlugin

https://github.com/DanielO/DrawIOPlugin

=cut

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
  my ($topic, $web, $user, $installWeb) = @_;
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

  unless ($Foswiki::cfg{Plugins}{DrawIOPlugin}{EditURL}) {
    Foswiki::Func::writeWarning(
				"DrawIOPlugin is enabled but EditURL is undefined.");
    return 0;
  }

  Foswiki::Func::registerTagHandler('DRAWIO', \&_DRAWIO);

  return 1;
}

sub _DRAWIO {
  my ($session, $attributes, $topic, $web) = @_;
  my $drawingName = $attributes->{_DEFAULT} || 'untitled';
  $drawingName = (Foswiki::Func::sanitizeAttachmentName($drawingName))[0];

  my $result = CGI::img({'src' => "%ATTACHURLPATH%/$drawingName",
			 'class' => "drawio",
			 'filename' => $drawingName,
			 'drawio-url' => $Foswiki::cfg{Plugins}{DrawIOPlugin}{EditURL},
			 'data-validation-key' => "?%NONCE%",
			});

    Foswiki::Func::addToZone('script', 'DrawIOPlugin/drawioplugin.js', <<JS, 'JQUERYPLUGIN::FOSWIKI');
<script type="text/javascript" src="%PUBURL%/%SYSTEMWEB%/DrawIOPlugin/scripts/drawioplugin.js"></script>
JS
  return $result;
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
