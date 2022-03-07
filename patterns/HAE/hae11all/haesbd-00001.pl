#!/usr/bin/perl

# Title:       Multiple sbd_device CIB nvpairs
# Description: Multiple sbd_device instance attributes are not supported
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
	PROPERTY_NAME_COMPONENT."=Attributes",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7010925"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub getSBDInstanceAttributes {
	SDP::Core::printDebug('> getSBDInstanceAttributes', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'ha.txt';
	my $SECTION = 'cibadmin -Q';
	my @CONTENT = ();
	my $HA_DOWN = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /CIB failed.*connection failed/ ) {
				SDP::Core::printDebug('WARNING', "CIB Connection Failed, Checking cib.xml");
				$HA_DOWN = 1;
				last;
			}
			if ( /<nvpair.*name="sbd_device"/i ) {
#				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: getSBDInstanceAttributes(): Cannot \"$SECTION\" section in $FILE_OPEN");
	}
	if ( $HA_DOWN ) {
		$SECTION = '/cib.xml$';
		if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
			foreach $_ (@CONTENT) {
				next if ( m/^\s*$/ ); # Skip blank lines
				if ( /<nvpair.*name="sbd_device"/i ) {
	#				SDP::Core::printDebug("PROCESSING", $_);
					$RCODE++;
				}
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: getSBDInstanceAttributes(): Cannot \"$SECTION\" section in $FILE_OPEN");
		}
	}
	SDP::Core::printDebug("< getSBDInstanceAttributes", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my $SBD_ATTRS = getSBDInstanceAttributes();
	if ( $SBD_ATTRS gt 1 ) {
		SDP::Core::updateStatus(STATUS_WARNING, "Detected multiple sbd_device instance attributes; reduce to zero or one.");
	} elsif ( $SBD_ATTRS lt 1 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "Success: No sbd_device instance attributes found");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Success: Only one sbd_device instance attribute found");
	}
SDP::Core::printPatternResults();

exit;


