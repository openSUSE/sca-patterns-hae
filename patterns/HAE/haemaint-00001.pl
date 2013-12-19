#!/usr/bin/perl

# Title:       Maintenance Mode On
# Description: Checks if cluster is in maintenance mode
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
	PROPERTY_NAME_CATEGORY."=Resource",
	PROPERTY_NAME_COMPONENT."=Managed",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7012114"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub maintMode {
	SDP::Core::printDebug('> maintMode', 'BEGIN');
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
				SDP::Core::updateStatus(STATUS_ERROR, "ERROR: ocfs2Volumes(): Cannot find \"$SECTION\" section in $FILE_OPEN");
			}
		} else {
			SDP::Core::printDebug("CIB Database", "$SECTION");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: ocfs2Volumes(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}

	foreach $_ (@CONTENT) {
		next if ( m/^\s*$/ ); # Skip blank lines
		if ( /<nvpair.*name="maintenance-mode".*value.*true/ ) {
			SDP::Core::printDebug("PROCESSING", $_);
			$RCODE++;
			last;
		}
	}
	SDP::Core::printDebug("< maintMode", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( SDP::SUSE::haeEnabled() ) {
		if ( maintMode() ) {
			SDP::Core::updateStatus(STATUS_CRITICAL, "Detected cluster maintenance mode, resources are not being managed");
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "Cluster is not in maintenance mode");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "HAE Disabled");
	}
SDP::Core::printPatternResults();

exit;


