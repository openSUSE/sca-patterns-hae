#!/usr/bin/perl

# Title:       Check clone interleave for false
# Description: Generally clone resources should set interleave to true
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
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7011322"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub checkCloneInterleave {
	SDP::Core::printDebug('> checkCloneInterleave', 'BEGIN');
	my $RCODE = 0;
	my @LINE_CONTENT = ();
	my $FILE_OPEN = 'ha.txt';
	my $SECTION = 'cibadmin -Q';
	my @CONTENT = ();
	my $CLONE = 0;
	my $CLONE_ID = '';
	my $META = 0;
	my @CLONES_AT_RISK = ();
	my $HA_DOWN = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			if ( /CIB failed.*connection failed/ ) {
				SDP::Core::printDebug('WARNING', "CIB Connection Failed, Checking cib.xml");
				$HA_DOWN = 1;
				last;
			}
			next if ( m/^\s*$/ ); # Skip blank lines
			$_ =~ s/^\s*//g; # remove leading white space
			if ( $CLONE ) {
#				SDP::Core::printDebug(' >', $_);
				if ( /<\/clone>/ ) {
					SDP::Core::printDebug(' WARNING', $CLONE_ID);
					$CLONE = 0;
				} elsif ( /<nvpair.*name="interleave".*value="true"/i ) {
					SDP::Core::printDebug(" POP $CLONE_ID", "Interleave=True");
					pop(@CLONES_AT_RISK);
					$CLONE = 0;
				} elsif ( /<primitive.*/i ) {
					if ( $_ !~ m/type="Filesystem"/i ) {
						SDP::Core::printDebug(" POP $CLONE_ID", "Non-filesytem Primitive");
						pop(@CLONES_AT_RISK);
						$CLONE = 0;
					}
				}
			} elsif ( /<clone.*id="(.*)"/ ) {
				SDP::Core::printDebug('CLONE START', $_);
				$CLONE_ID = $1;
				push(@CLONES_AT_RISK, $CLONE_ID);
				$CLONE = 1;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: checkCloneInterleave(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	if ( $HA_DOWN ) {
		$SECTION = "/cib.xml";
		if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
			foreach $_ (@CONTENT) {
				next if ( m/^\s*$/ ); # Skip blank lines
				$_ =~ s/^\s*//g; # remove leading white space
				if ( $CLONE ) {
#					SDP::Core::printDebug(' >', $_);
					if ( /<\/clone>/ ) {
						SDP::Core::printDebug(' WARNING', $CLONE_ID);
						$CLONE = 0;
					} elsif ( /<nvpair.*name="interleave".*value="true"/i ) {
						SDP::Core::printDebug(" POP $CLONE_ID", "Interleave=True");
						pop(@CLONES_AT_RISK);
						$CLONE = 0;
					} elsif ( /<primitive.*/i ) {
						if ( $_ !~ m/type="Filesystem"/i ) {
							SDP::Core::printDebug(" POP $CLONE_ID", "Non-filesytem Primitive");
							pop(@CLONES_AT_RISK);
							$CLONE = 0;
						}
					}
				} elsif ( /<clone.*id="(.*)"/ ) {
					SDP::Core::printDebug('CLONE START', $_);
					$CLONE_ID = $1;
					push(@CLONES_AT_RISK, $CLONE_ID);
					$CLONE = 1;
				}
			}
			$RCODE = scalar @CLONES_AT_RISK;
			SDP::Core::printDebug('Interleave Clones', "@CLONES_AT_RISK");
			if ( $RCODE ) {
				SDP::Core::updateStatus(STATUS_WARNING, "Detected Filesystem Clones in cib.xml that Will Unmount When Any Node Reboots: @CLONES_AT_RISK");
			} else {
				SDP::Core::updateStatus(STATUS_ERROR, "No filesystem clones in cib.xml at risk with interleave");
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: checkCloneInterleave(): Cannot find \"$SECTION\" section in $FILE_OPEN");
		}
	} else {
		$RCODE = scalar @CLONES_AT_RISK;
		SDP::Core::printDebug('Interleave Clones', "@CLONES_AT_RISK");
		if ( $RCODE ) {
			SDP::Core::updateStatus(STATUS_WARNING, "Detected Filesystem Clones in CIB that Will Unmount When Any Node Reboots: @CLONES_AT_RISK");
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "No filesystem clones in CIB at risk with interleave");
		}
	}
	SDP::Core::printDebug("< checkCloneInterleave", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( SDP::SUSE::compareKernel(SLE11GA) >= 0 ) { 
		checkCloneInterleave();
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Error: Outside kernel scope, skipping interleave");
	}
SDP::Core::printPatternResults();
exit;


