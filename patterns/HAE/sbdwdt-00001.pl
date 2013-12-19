#!/usr/bin/perl

# Title:       iTCO_wdt Watchdog Timeouts
# Description: iTCO_wdt does not accept Watchdog Timeout bigger 63 seconds
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
	PROPERTY_NAME_CATEGORY."=Database",
	PROPERTY_NAME_COMPONENT."=Resource",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7011426"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub getWatchDogTimer {
	SDP::Core::printDebug('> getWatchDogTimer', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'ha.txt';
	my $SECTION = 'sbd -d .* dump';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			s/\s+//g; # remove whitespace
			if ( /Timeout\(watchdog\):/i ) {
				SDP::Core::printDebug("PROCESSING", $_);
				(undef, $RCODE) = split(/:/, $_);
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: getWatchDogTimer(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< getWatchDogTimer", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my $WATCHDOG_TIMER_LIMIT = 63;
	my $DRIVER_NAME = 'iTCO_wdt';
	my %DRIVER_INFO = SDP::SUSE::getDriverInfo($DRIVER_NAME);
	if ( $DRIVER_INFO{'loaded'} ) {
		my $WATCHDOG_TIMER = getWatchDogTimer();
		if ( $WATCHDOG_TIMER > $WATCHDOG_TIMER_LIMIT ) {
			SDP::Core::updateStatus(STATUS_WARNING, "SBD Watchdog Timer $WATCHDOG_TIMER exceeds the iTCO_wdt limit of $WATCHDOG_TIMER_LIMIT");
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "SBD Watchdog Timer $WATCHDOG_TIMER within the iTCO_wdt limit of $WATCHDOG_TIMER_LIMIT");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Driver $DRIVER_NAME is NOT loaded, skipping");
	}
SDP::Core::printPatternResults();

exit;


