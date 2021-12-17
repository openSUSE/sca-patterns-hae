#!/usr/bin/perl

# Title:       Sysconfig SBD Format
# Description: The only supported /etc/sysconfig/sbd format is a device list separated by semicolons
# Modified:    2013 Jun 21

##############################################################################
#  Copyright (C) 2013 SUSE LLC
##############################################################################
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; version 2 of the License.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, see <http://www.gnu.org/licenses/>.

#  Authors/Contributors:
#   Jason Record (jrecord@suse.com)

##############################################################################

##############################################################################
# Module Definition
##############################################################################

use strict;
use warnings;
use SDP::Core;
use SDP::SUSE;

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

@PATTERN_RESULTS = (
	PROPERTY_NAME_CLASS."=HAE",
	PROPERTY_NAME_CATEGORY."=SBD",
	PROPERTY_NAME_COMPONENT."=Config",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7010931",
	"META_LINK_MISC=https://bugzilla.redhat.com/show_bug.cgi?id=736486"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub invalidSBDformat {
	SDP::Core::printDebug('> invalidSBDformat', 'BEGIN');
	my $RCODE = 0;
	my @DEVICE_LIST = ();
	my $DEVICE = '';
	my $FILE_OPEN = 'ha.txt';
	my $SECTION = '/etc/sysconfig/sbd';
	my @CONTENT = ();
	my $LINE = '';
	my $VALUE = '';

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $LINE (@CONTENT) {
			next if ( $LINE =~ m/^\s*$/ ); # Skip blank lines
			if ( $LINE =~ m/^SBD_DEVICE=(.*)/ ) {
				SDP::Core::printDebug("PROCESSING", $LINE);
				$VALUE = $1;
				$VALUE =~ s/"|'//g;
				SDP::Core::printDebug("CHECK", "\[$VALUE\]");
				@DEVICE_LIST = split(/;/, $VALUE);
				if ( $#DEVICE_LIST > 2 ) {
					$RCODE = 1;
					SDP::Core::updateStatus(STATUS_WARNING, "Too many SBD_DEVICE devices in /etc/sysconfig/sbd");
				}
				foreach $DEVICE (@DEVICE_LIST) {
					$DEVICE =~ s/^\s+|\s+$//g; # remove leading and trailing whitespace
					SDP::Core::printDebug(" DEVICE", "\[$DEVICE\]");
					if ( $DEVICE !~ m/^\// ) { # must begin with a / for a valid path
						$RCODE = 2;
						SDP::Core::printDebug("  Failed", "No leading / - $RCODE");
						SDP::Core::updateStatus(STATUS_CRITICAL, "Invalid SBD_DEVICE format in /etc/sysconfig/sbd");
						last;
					}
					if ( $DEVICE =~ m/\s+/ ) { # no spaces allowed in the device path
						$RCODE = 3;
						SDP::Core::printDebug("  Failed", "Space in device path - $RCODE");
						SDP::Core::updateStatus(STATUS_CRITICAL, "Invalid SBD_DEVICE format in /etc/sysconfig/sbd");
						last;
					}
					if ( $DEVICE =~ m/\/$/ ) { # path cannot end with a /
						$RCODE = 4;
						SDP::Core::printDebug("  Failed", "Trailing / in device path - $RCODE");
						SDP::Core::updateStatus(STATUS_CRITICAL, "Invalid SBD_DEVICE format in /etc/sysconfig/sbd");
						last;
					}
					if ( $DEVICE =~ m/[,]/ ) { # invalid seperator characters
						$RCODE = 5;
						SDP::Core::updateStatus(STATUS_CRITICAL, "Invalid SBD_DEVICE seperator in /etc/sysconfig/sbd, use semi-colons");
						last;
					}
					if ( $DEVICE =~ m/[\\]/ ) { # encoding present https://bugzilla.redhat.com/show_bug.cgi?id=736486
						$RCODE = 7;
						SDP::Core::updateStatus(STATUS_WARNING, "Verify SBD_DEVICE blacklist encoding in /etc/sysconfig/sbd");
					}
					if ( $DEVICE =~ m/^[\/a-z0-9#+-.:=\@_.]+$/i ) { ; } else { # invalid path characters 
						$RCODE = 6;
						SDP::Core::updateStatus(STATUS_WARNING, "Possible Invalid SBD_DEVICE characters in /etc/sysconfig/sbd");
					}
				}
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: invalidSBDformat(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< invalidSBDformat", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( ! invalidSBDformat() ) {
		SDP::Core::updateStatus(STATUS_ERROR, "Valid SBD_DEVICE format in /etc/sysconfig/sbd");
	}
SDP::Core::printPatternResults();

exit;


