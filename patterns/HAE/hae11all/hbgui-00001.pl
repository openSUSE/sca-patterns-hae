#!/usr/bin/perl

# Title:       hb_gui does not show meta data
# Description: The hb_gui command of heartbeat may fail to show some data of the cluster cib.
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
#

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
	PROPERTY_NAME_COMPONENT."=Display",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7004450",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=539557"
);




##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my $RPM_NAME = 'heartbeat';
	my $VERSION_TO_COMPARE = '2.1.4-0.15.3';
	my $RPM_COMPARISON = SDP::SUSE::compareRpm($RPM_NAME, $VERSION_TO_COMPARE);
	if ( $RPM_COMPARISON == 2 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: RPM $RPM_NAME Not Installed");
	} elsif ( $RPM_COMPARISON > 2 ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Multiple Versions of $RPM_NAME RPM are Installed");
	} else {
		if ( $RPM_COMPARISON < 0 ) {
			SDP::Core::updateStatus(STATUS_WARNING, "Cluster CIB meta data may not display in hb_gui, Fix Needed: $RPM_NAME-$VERSION_TO_COMPARE");
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "All CIB meta data should display in hb_gui");
		}                       
	}
SDP::Core::printPatternResults();

exit;

