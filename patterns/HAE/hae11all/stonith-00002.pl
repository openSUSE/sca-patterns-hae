#!/usr/bin/perl

# Title:       Missing STONITH resource
# Description: Checks for missing STONITH resources
# Modified:    2019 Jun 25

##############################################################################
#  Copyright (C) 2013-2019 SUSE LLC
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
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7004817",
	"META_LINK_MISC=https://www.suse.com/documentation/sle_ha/book_sleha/data/sec_ha_fencing_recommend.html"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub checkStonithResource {
	SDP::Core::printDebug('> checkStonithResource', 'BEGIN');
	my $RCODE = 0;
	my @LINE_CONTENT = ();
	my $FILE_OPEN = 'ha.txt';
	my $SECTION = 'cibadmin -Q';
	my @CONTENT = ();
	my $HA_DOWN = 0;
	my $RESOURCES = 0;
	my $STONITH_RESOURCE = 0;
	my $STONITH_ENABLED = 1;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /CIB failed.*connection failed/ ) {
				SDP::Core::printDebug('WARNING', "CIB Connection Failed, Checking cib.xml");
				$HA_DOWN = 1;
				last;
			}
			SDP::Core::printDebug('Processing', $_);
			if ( /<\/primitive>/i ) {
				SDP::Core::printDebug('RESOURCE', "Found");
				$RESOURCES++;
			} elsif ( /<primitive.*class="stonith"/i ) {
				SDP::Core::printDebug('STONITH RESOURCE', "Found");
				$STONITH_RESOURCE = 1;
			} elsif ( /<nvpair.*name="stonith-enabled".*value="false"/i ) {
				SDP::Core::printDebug('STONITH', "Disabled");
				$STONITH_ENABLED = 0;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: checkStonithResource(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	if ( $HA_DOWN ) {
		$SECTION = '/cib.xml$';
		if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
			foreach $_ (@CONTENT) {
				next if ( m/^\s*$/ ); # Skip blank lines
				if ( /<\/primitive>/i ) {
					SDP::Core::printDebug('RESOURCE', "Found");
					$RESOURCES++;
				} elsif ( /<primitive class="stonith"/i ) {
					SDP::Core::printDebug('STONITH RESOURCE', "Found");
					$STONITH_RESOURCE = 1;
				} elsif ( /<nvpair.*name="stonith-enabled".*value="false"/i ) {
					SDP::Core::printDebug('STONITH', "Disabled");
					$STONITH_ENABLED = 0;
				}
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: checkStonithResource(): Cannot find \"$SECTION\" section in $FILE_OPEN");
		}
	}
	SDP::Core::printDebug('HA_DOWN', $HA_DOWN);
	SDP::Core::printDebug('RESOURCES', $RESOURCES);
	SDP::Core::printDebug('STONITH_RESOURCE', $STONITH_RESOURCE);
	SDP::Core::printDebug('STONITH_ENABLED', $STONITH_ENABLED);
	if ( $RESOURCES ) {
		if ( $STONITH_RESOURCE ) {
			if ( $STONITH_ENABLED ) {
				SDP::Core::updateStatus(STATUS_ERROR, "Ignore: STONITH Enabled and Resource found");
			} else {
				SDP::Core::updateStatus(STATUS_CRITICAL, "Unsupported cluster environment, enable STONITH");
			}
		} else {
			SDP::Core::updateStatus(STATUS_CRITICAL, "Unsupported cluster environment, missing a STONITH resource");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Error: No cluster resources found to worry about");
	}
	SDP::Core::printDebug("< checkStonithResource", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( SDP::SUSE::compareKernel(SLE11GA) >= 0 ) { 
		checkStonithResource();
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Error: Outside kernel scope, skipping");
	}
SDP::Core::printPatternResults();

exit;


