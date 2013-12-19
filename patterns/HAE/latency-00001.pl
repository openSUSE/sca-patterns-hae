#!/usr/bin/perl

# Title:       Disk latency messages for HAE
# Description: High disk latency may cause unwanted node fening
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
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7011350"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub sbdDevices {
	SDP::Core::printDebug('> sbdDevices', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'ha.txt';
	my $SECTION = '/etc/sysconfig/sbd';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /SBD_DEVICE.*\/dev/i ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: sbdDevices(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< sbdDevices", "Returns: $RCODE");
	return $RCODE;
}

sub latencyDetected {
	SDP::Core::printDebug('> latencyDetected', 'BEGIN');
	my $RCODE = -1;
	my $FILE_OPEN = 'messages.txt';
	my $SECTION = '/var/log/messages';
	my @CONTENT = ();
	my $RESET = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (reverse(@CONTENT)) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /stonith-ng:.*st_device_action="reboot"|stonith-ng:.*st_device_action="poweroff"/i ) {
				SDP::Core::printDebug("STONITH", "Node Reset");
				$RESET = 1;
			} elsif ( /sbd:.*WARN.*Latency.*threshold/i ) {
				if ( ! $RESET ) {
					SDP::Core::printDebug(" LATENCY Dirty", $_);
					$RCODE = 1;
				} else {
					SDP::Core::printDebug(" LATENCY Clean", $_);
					$RCODE = 0;
				}
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: latencyDetected(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< latencyDetected", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( SDP::SUSE::compareKernel(SLE11GA) >= 0 ) { 
		if ( sbdDevices() ) {
			my $LATENCY = latencyDetected();
			if ( $LATENCY > 0 ) {
				SDP::Core::updateStatus(STATUS_WARNING, "SBD partition latency detected");
			} elsif ( $LATENCY < 0 ) {
				SDP::Core::updateStatus(STATUS_ERROR, "Error: No latency messages found");
			} else {
				SDP::Core::updateStatus(STATUS_ERROR, "Normal SBD partition latency messages found");
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: No SBD devices, skipping latency check");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Outside kernel scope, skipping latency check");
	}
SDP::Core::printPatternResults();

exit;


