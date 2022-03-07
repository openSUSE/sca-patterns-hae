#!/usr/bin/perl

# Title:       Corosync Retransmit Lists
# Description: Checks for retransmit lists
# Modified:    2013 Aug 29

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
	PROPERTY_NAME_COMPONENT."=Resource",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_MISC",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_MISC=http://www.hastexo.com/resources/hints-and-kinks/whats-totem-retransmit-list-all-about-corosync"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub retransmitsFound {
	SDP::Core::printDebug('> retransmitsFound', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'messages.txt';
	my $SECTION = '/var/log/messages';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /corosync.*TOTEM.*Retransmit List:/i ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: retransmitsFound(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< retransmitsFound", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( SDP::SUSE::compareKernel(SLE11GA) >= 0 && SDP::SUSE::packageInstalled('corosync')) {
	 	if ( retransmitsFound() ) {
			SDP::Core::updateStatus(STATUS_WARNING, "Corosync retransmit detected, cluster performance may be affected");
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "Error: No corosync retransmits found");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Outside Kernel Scope or Corosync not installed");
	}
SDP::Core::printPatternResults();

exit;


