#!/usr/bin/perl

# Title:       cluster update failed in cib checksum
# Description: Detect error for cluster update failed in cib checksum
# Modified:    2013 Jun 20

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
	PROPERTY_NAME_CATEGORY."=Database",
	PROPERTY_NAME_COMPONENT."=Checksum",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7012127",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=809635"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub cibChecksumFailures {
	SDP::Core::printDebug('> cibChecksumFailures', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'messages.txt';
	my $SECTION = '/var/log/messages';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /ERROR.*retrieveCib.*Checksum of.*cib.*failed.*Configuration contents ignored/i ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: cibChecksumFailures(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< cibChecksumFailures", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( SDP::SUSE::haeEnabled() ) {
		my $RPM_NAME = 'pacemaker';
		my $VERSION_TO_COMPARE = '1.1.7';
		my $RPM_COMPARISON = SDP::SUSE::compareRpm($RPM_NAME, $VERSION_TO_COMPARE);
		if ( $RPM_COMPARISON == 2 ) {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: RPM $RPM_NAME Not Installed");
		} elsif ( $RPM_COMPARISON > 2 ) {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Multiple Versions of $RPM_NAME RPM are Installed");
		} else {
			if ( $RPM_COMPARISON >= 0 ) {
				my $CIB_FAILURES = cibChecksumFailures();
				if ( $CIB_FAILURES > 0 ) {
					SDP::Core::updateStatus(STATUS_WARNING, "Detected $CIB_FAILURES CIB checksum failure(s)");
				} else {
					SDP::Core::updateStatus(STATUS_ERROR, "No CIB checksum failures found");
				}
			} else {
				SDP::Core::updateStatus(STATUS_ERROR, "The installed $RPM_NAME RPM version does not match requirements.");
			}			
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "HAE Disabled");
	}
SDP::Core::printPatternResults();
exit;


