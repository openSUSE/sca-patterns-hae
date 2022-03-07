#!/usr/bin/perl

# Title:       OCFS2 Partition Fails to Mount with No Free Slots Error
# Description: Checks for errors relating to available slots
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
#

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
	PROPERTY_NAME_COMPONENT."=Resource",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7005236",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=570358"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub checkSlotErrors {
	SDP::Core::printDebug('> checkSlotErrors', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'ocfs2.txt';
	my $SECTION = '/var/log/messages';
	my @CONTENT = ();
	my @LINE_CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( /^\s*$/ ); # Skip blank lines
			if ( /ocfs2_find_slot:496 ERROR: no free slots available/i ) {
				SDP::Core::printDebug("FOUND", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	if ( $RCODE ) {
		SDP::Core::updateStatus(STATUS_WARNING, "No free OCFS2 slots error observed, consider fsck.ocfs2");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Free OCFS2 slots appear available");
	}
	SDP::Core::printDebug("< checkSlotErrors", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( SDP::SUSE::compareKernel(SLE11GA) >= 0 && SDP::SUSE::compareKernel(SLE11SP1) < 0 ) {
		if ( SDP::SUSE::packageInstalled('openais') && SDP::SUSE::packageInstalled('ocfs2-tools') ) {
			checkSlotErrors();
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Missing SLE11 HAE OCFS2, Skipping ocfs2 test");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Outside kernel scope, skipping ocfs2 test");
	}
SDP::Core::printPatternResults();

exit;

