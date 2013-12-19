#!/usr/bin/perl

# Title:       pingd constraint sporadically ignored
# Description: Cluster pingd Resource may not adhere to constraints as documented
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
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7008656",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=695456",
	"META_LINK_MISC=http://developerbugs.linux-foundation.org/show_bug.cgi?id=2528"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub checkDampenAffect {
	SDP::Core::printDebug('> checkDampenAffect', 'BEGIN');
	my $RCODE = 1; # assume no pingd resources
	my @LINE_CONTENT = ();
	my $FILE_OPEN = 'ha.txt';
	my $SECTION = 'cibadmin -Q';
	my @CONTENT = ();
	my ($PRIMATIVE, $DAMPEN_VALUE, $MONITOR_INTERVAL) = (0,0,0);
	my $PRIMATIVE_ID = '';

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( $PRIMATIVE ) {
				if ( /<\/primitive>/ ) {
					SDP::Core::printDebug(" COMPARE", "DAMPEN_VALUE=$DAMPEN_VALUE, MONITOR_INTERVAL=$MONITOR_INTERVAL");
					$RCODE = 0;
					if ( $DAMPEN_VALUE > $MONITOR_INTERVAL ) {
						SDP::Core::updateStatus(STATUS_WARNING, "Resource ID '$PRIMATIVE_ID' susceptible to constraint issues.");
					} else {
						SDP::Core::updateStatus(STATUS_ERROR, "Resource ID '$PRIMATIVE_ID' is valid, but may become susceptible to constraint issues.");
					}
					$PRIMATIVE = 0;
					$PRIMATIVE_ID = '';
				} elsif ( /<nvpair.*name="dampen" value="(.*)"/ ) {
					$DAMPEN_VALUE = $1;
					$DAMPEN_VALUE =~ s/\D//;
					SDP::Core::printDebug(" FOUND DAMPEN", "DAMPEN_VALUE=$DAMPEN_VALUE");
				} elsif ( /<op.*interval="(.*)".*name.*monitor/ ) {
					$MONITOR_INTERVAL = $1;
					$MONITOR_INTERVAL =~ s/\D//;
					SDP::Core::printDebug(" FOUND MONITOR", "MONITOR_INTERVAL=$MONITOR_INTERVAL");
				}
			} elsif ( /<primitive class.*ocf.*id="(.*)".*provider.*pacemaker.*type.*ping/ ) {
				SDP::Core::printDebug("PINGD", $_);
				$PRIMATIVE = 1;
				$PRIMATIVE_ID = $1;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: checkDampenAffect(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< checkDampenAffect", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my $RPM_NAME = 'pacemaker';
	my $VERSION_TO_COMPARE = '1.1.5-5.5.5';
	my $RPM_COMPARISON = SDP::SUSE::compareRpm($RPM_NAME, $VERSION_TO_COMPARE);
	if ( $RPM_COMPARISON == 2 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: RPM $RPM_NAME Not Installed, skipping pingd test");
	} elsif ( $RPM_COMPARISON > 2 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Multiple Versions of $RPM_NAME RPM are Installed, skipping pingd test");
	} else {
		if ( $RPM_COMPARISON <= 0 ) {
			if ( checkDampenAffect() ) {
				SDP::Core::updateStatus(STATUS_ERROR, "ERROR: No pingd resources found");
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "IGNORED: Pacemaker newer than affected package, skipping pingd test");
		}			
	}
SDP::Core::printPatternResults();

exit;

