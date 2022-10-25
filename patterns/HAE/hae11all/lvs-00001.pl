#!/usr/bin/perl

# Title:       Recommnended Reading for LVS
# Description: Cool solution article for LVS example
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
	PROPERTY_NAME_CATEGORY."=Database",
	PROPERTY_NAME_COMPONENT."=Resource",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_Blog=https://www.suse.com/c/load-balancing-smt-servers-sles11-sp1-hae-cluster/"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub lvsFound {
	SDP::Core::printDebug('> lvsFound', 'BEGIN');
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
			if ( /primitive.*class="ocf".*type="ldirectord"/ ) {
				SDP::Core::printDebug("FROM DB", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: lvsFound(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	if ( $HA_DOWN ) {
		$SECTION = '/cib.xml';
		if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
			foreach $_ (@CONTENT) {
				next if ( m/^\s*$/ ); # Skip blank lines
				if ( /primitive.*class="ocf".*type="ldirectord"/ ) {
					SDP::Core::printDebug("FROM DB", $_);
					$RCODE++;
					last;
				}
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: lvsFound(): Cannot find \"$SECTION\" section in $FILE_OPEN");
		}
	}
	SDP::Core::printDebug("< lvsFound", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( SDP::SUSE::compareKernel(SLE11GA) >= 0 && SDP::SUSE::compareKernel(SLE12GA) < 0 ) { 
		if ( lvsFound() ) {
			SDP::Core::updateStatus(STATUS_RECOMMEND, "LVS Configuration Example");
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "Error: LVS not detected, skipping");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Error: Outside kernel scope, skipping");
	}
SDP::Core::printPatternResults();

exit;


