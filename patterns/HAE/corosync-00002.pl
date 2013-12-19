#!/usr/bin/perl

# Title:       Invalid HAE SBD Partition
# Description: Detects invalid HAE SBD partitions
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
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

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
	PROPERTY_NAME_COMPONENT."=Health",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7010879"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub checkSBDPartition {
	SDP::Core::printDebug('> checkSBDPartition', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'ha.txt';
	my $SECTION = 'bin\/sbd -d .* dump';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /number of slots/i ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
				last;
			}
		}
		if ( $RCODE ) {
			SDP::Core::updateStatus(STATUS_ERROR, "Skipping, Valid SBD Partition");
		} else {
			my $SERVICE_NAME = 'openais';
			my %SERVICE_INFO = SDP::SUSE::getServiceInfo($SERVICE_NAME);
			if ( $SERVICE_INFO{'running'} > 0 ) {
				SDP::Core::updateStatus(STATUS_WARNING, "Invalid SBD Partition, cluster node may fail after reboot");
			} else {
				SDP::Core::updateStatus(STATUS_CRITICAL, "Invalid SBD Partition, recreate if using SBD");
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: checkSBDPartition(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< checkSBDPartition", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	checkSBDPartition();
SDP::Core::printPatternResults();

exit;


