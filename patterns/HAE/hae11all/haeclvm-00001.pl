#!/usr/bin/perl

# Title:       Cluster wide locking for LVM
# Description: Confirm locking_type is 3 if LVM resources found
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
	PROPERTY_NAME_CATEGORY."=cLVM",
	PROPERTY_NAME_COMPONENT."=Locking",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7012115"
);

##############################################################################
# Local Function Definitions
##############################################################################

sub invalidLockingType {
	SDP::Core::printDebug('> invalidLockingType', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'lvm.txt';
	my $SECTION = 'lvm.conf';
	my @CONTENT = ();
	my @LINE_CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /^\s*locking_type\s*=/ ) {
				SDP::Core::printDebug("PROCESSING", $_);
				s/\s*//g; # remove white space
				@LINE_CONTENT = split(/=/, $_);
				my $LOCK_TYPE = $LINE_CONTENT[$#LINE_CONTENT];
				SDP::Core::printDebug("LOCK_TYPE", $LOCK_TYPE);
				if ( $LOCK_TYPE != 3 ) {
					$RCODE++;
				}
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: invalidLockingType(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< invalidLockingType", "Returns: $RCODE");
	return $RCODE;
}

sub lvmResourcesFound {
	SDP::Core::printDebug('> lvmResourcesFound', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'ha.txt';
	my $SECTION = 'cibadmin -Q';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		if ( $#CONTENT < 3 ) {
			$SECTION = 'cib.xml';
			if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
				SDP::Core::printDebug("CIB Database", "$SECTION");
			} else {
				SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Cannot find \"$SECTION\" section in $FILE_OPEN");
			}
		} else {
			SDP::Core::printDebug("CIB Database", "$SECTION");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Cannot find \"$SECTION\" section in $FILE_OPEN");
	}

	foreach $_ (@CONTENT) {
		next if ( m/^\s*$/ ); # Skip blank lines
		if ( /<primitive.*provider="lvm2/i ) {
			SDP::Core::printDebug("PROCESSING", $_);
			$RCODE++;
			last;
		} elsif ( /<primitive.*provider="heartbeat".*type="LVM/i ) {
			SDP::Core::printDebug("PROCESSING", $_);
			$RCODE++;
			last;
		}
	}
	SDP::Core::printDebug("< lvmResourcesFound", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( SDP::SUSE::haeEnabled() ) {
		if ( lvmResourcesFound() ) {
			if ( invalidLockingType() ) {
				SDP::Core::updateStatus(STATUS_CRITICAL, "Invalid LVM locking type, set locking_type to 3 in lvm.conf");
			} else {
				SDP::Core::updateStatus(STATUS_ERROR, "Valid LVM locking type");
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "No LVM Resources found");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "HAE Disabled");
	}
SDP::Core::printPatternResults();

exit;


