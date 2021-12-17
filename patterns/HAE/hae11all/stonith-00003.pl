#!/usr/bin/perl

# Title:       Confirm primitive stonith resources
# Description: Checks for cloned stonith resources
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
	PROPERTY_NAME_CATEGORY."=Database",
	PROPERTY_NAME_COMPONENT."=Resource",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7012124"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub getClonedStonithResources {
	SDP::Core::printDebug('> getClonedStonithResources', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'ha.txt';
	my $SECTION = 'cibadmin -Q';
	my @CONTENT = ();
	my @NAMES = ();
	my $CLONE = 0;

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
		if ( /<\/configuration/ ) {
			last;
		} elsif ( $CLONE ) {
			if ( /<\/clone/ ) {
				$CLONE = 0;
			} elsif ( /<primitive.*id="(.*)".*type="external\/sbd">/ ) {
				my $ID = $1;
				push(@NAMES, $ID);
			}
		} elsif ( /^\s*<clone\s/ ) {
			$CLONE = 1;
		}
	}
	$RCODE = scalar @NAMES;
	SDP::Core::printDebug("< getClonedStonithResources", "Returns: $RCODE");
	return @NAMES;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( SDP::SUSE::haeEnabled() ) {
		my @CLONED_STONITHS = getClonedStonithResources();
		SDP::Core::printDebug("CLONED_STONITHS", "@CLONED_STONITHS");
		if ( $#CLONED_STONITHS == 0 ) {
			SDP::Core::updateStatus(STATUS_CRITICAL, "Detected cloned external/sbd stonith resource: @CLONED_STONITHS");
		} elsif ( $#CLONED_STONITHS > 0 ) {
			SDP::Core::updateStatus(STATUS_CRITICAL, "Detected cloned external/sbd stonith resources: @CLONED_STONITHS");
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "No cloned stonith resources");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "HAE Disabled");
	}
SDP::Core::printPatternResults();

exit;


