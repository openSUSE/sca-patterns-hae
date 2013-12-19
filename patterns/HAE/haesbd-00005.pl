#!/usr/bin/perl

# Title:       Matching CIB/SBD Values
# Description: Checks for matching sysconfig sbd and cib values
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
	PROPERTY_NAME_COMPONENT."=Attributes",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7011302"
);




my $CIBLIST = '';
my $SBDLIST = '';

##############################################################################
# Local Function Definitions
##############################################################################

sub cibSBDdevices {
	SDP::Core::printDebug('> cibSBDdevices', 'BEGIN');
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
			if ( /nvpair.*name="sbd_device".*value="(.*)"/i ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$CIBLIST = $1;
				$CIBLIST =~ s/\s+//g; # remove white space
				$RCODE++;
				SDP::Core::printDebug(" CIB LIST", "\[$CIBLIST\]");
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: cibSBDdevices(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	if ( $HA_DOWN ) {
		$SECTION = '/cib.xml$';
		if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
			foreach $_ (@CONTENT) {
				next if ( m/^\s*$/ ); # Skip blank lines
				if ( /CIB failed.*connection failed/ ) {
					SDP::Core::printDebug('WARNING', "CIB Connection Failed, Checking cib.xml");
					$HA_DOWN = 1;
					last;
				}
				if ( /nvpair.*name="sbd_device".*value="(.*)"/i ) {
					SDP::Core::printDebug("PROCESSING", $_);
					$CIBLIST = $1;
					$CIBLIST =~ s/\s+//g; # remove white space
					$RCODE++;
					SDP::Core::printDebug(" CIB LIST", "\[$CIBLIST\]");
					last;
				}
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: cibSBDdevices(): Cannot find \"$SECTION\" section in $FILE_OPEN");
		}
	}
	SDP::Core::printDebug("< cibSBDdevices", "Returns: $RCODE");
	return $RCODE;
}

sub sysconfigMismatch {
	SDP::Core::printDebug('> sysconfigMismatch', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'ha.txt';
	my $SECTION = '/etc/sysconfig/sbd';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /^SBD_DEVICE="(.*)"/ ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$SBDLIST = $1;
				$SBDLIST =~ s/\s+//g;
				SDP::Core::printDebug(" SBD LIST", "\[$SBDLIST\]");
				last;
			}
		}
		$RCODE++ if ( "$CIBLIST" ne "$SBDLIST" );
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: sysconfigMismatch(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< sysconfigMismatch", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( cibSBDdevices() ) {
		if ( sysconfigMismatch() ) {
			SDP::Core::updateStatus(STATUS_CRITICAL, "CIB SBD device list mismatch");
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "Valid CIB SBD device list");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "No CIB sbd_device list, skipping");
	}
SDP::Core::printPatternResults();

exit;


