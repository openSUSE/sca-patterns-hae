#!/usr/bin/perl

# Title:       Resource fails to migrate or restart
# Description: Checks for missing monitor operations.
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
	PROPERTY_NAME_CATEGORY."=Resource",
	PROPERTY_NAME_COMPONENT."=Monitor",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7012073"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub getUnmonitoredResources {
	SDP::Core::printDebug('> getUnmonitoredResources', 'BEGIN');
	my $RCODE = 0;
	my @RESOURCES = ();
	my @LINE_CONTENT = ();
	my $FILE_OPEN = 'ha.txt';
	my $SECTION = 'cibadmin -Q';
	my @CONTENT = ();
	my $CHECKING = 0;
	my $NAME = '';
	my $MISSING = 1;

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
		s/^\s*//g; # Remove leading white space
		s/\s*$//g; # Remove trailing white space
		if ( /<\/configuration>/ ) {
			SDP::Core::printDebug("DONE", $_);
			last;
		} elsif ( $CHECKING ) {
			if ( /<\/primitive>/ ) {
				if ( $MISSING ) {
					SDP::Core::printDebug(" UNMONITORED", $NAME);
					push(@RESOURCES, $NAME);
				} else {
					SDP::Core::printDebug(" Monitored", $NAME);
				}
				$CHECKING = 0;
				$MISSING = 1;
				$NAME = '';
			} elsif ( /<op.*name=.*monitor/ ) {
				$MISSING = 0;
			}
		} elsif ( /<primitive/ ) {
			SDP::Core::printDebug("CHECKING", $_);
			$CHECKING = 1;
			@LINE_CONTENT = split(/\s/, $_);
			foreach my $ELEMENT (@LINE_CONTENT) {
				if ( $ELEMENT =~ m/^id=/ ) {
					$NAME = $ELEMENT;
					$NAME =~ s/id=//g;
					$NAME =~ s/"//g;
				}
			}
		}
	}
	$RCODE = scalar @RESOURCES;
	SDP::Core::printDebug("< getUnmonitoredResources", "Returns: $RCODE");
	return @RESOURCES;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my @UNMONITORED_RESOURCES = getUnmonitoredResources();
	my $COUNT = scalar @UNMONITORED_RESOURCES;
	if ( $COUNT > 2 ) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "Detected $COUNT unmonitored cluster resources: @UNMONITORED_RESOURCES");
	} elsif ( $COUNT > 1 ) {
		SDP::Core::updateStatus(STATUS_WARNING, "Detected $COUNT unmonitored cluster resources: @UNMONITORED_RESOURCES");
	} elsif ( $COUNT > 0 ) {
		SDP::Core::updateStatus(STATUS_WARNING, "Detected $COUNT unmonitored cluster resource: @UNMONITORED_RESOURCES");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "All resources are monitored");
	}
SDP::Core::printPatternResults();

exit;


