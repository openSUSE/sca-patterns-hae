#!/usr/bin/perl

# Title:       crm_mon failures
# Description: Detect crm_mon failures
# Modified:    2022 Oct 25

##############################################################################
#  Copyright (C) 2013,2022 SUSE LLC
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
#   Jason Record (jason.record@suse.com)

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
	PROPERTY_NAME_CATEGORY."=Monitor",
	PROPERTY_NAME_COMPONENT."=Failures",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7012145"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub getCrmMonFailures {
	SDP::Core::printDebug('> getCrmMonFailures', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'ha.txt';
	my $SECTION = 'crm_mon';
	my @CONTENT = ();
	my $STATE = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( $STATE ) {
				if ( /node=/ ) {
					SDP::Core::printDebug("PROCESSING", $_);
					$RCODE++;
				}
			} elsif ( /^Failed actions/i ) {
				$STATE = 1;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: getCrmMonFailures(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< getCrmMonFailures", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my $FAILURES = getCrmMonFailures();
	if ( $FAILURES > 0 ) {
		SDP::Core::updateStatus(STATUS_WARNING, "Detected $FAILURES cluster failure(s), review crm_mon in ha.txt");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "No crm_mon failures");
	}
SDP::Core::printPatternResults();

exit;


