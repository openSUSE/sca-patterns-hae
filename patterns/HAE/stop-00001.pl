#!/usr/bin/perl

# Title:       Resource stop failure delay
# Description: Cluster resource failing on stop take too long to recover
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
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7012355"
);


my $MAX_TIMEOUT = 60;


##############################################################################
# Local Function Definitions
##############################################################################

sub getOperationDefTimeout {
	SDP::Core::printDebug('> getOperationDefTimeout', 'BEGIN');
	my $RCODE = -1;
	my @LINE_CONTENT = ();
	my $FILE_OPEN = 'ha.txt';
	my $SECTION = 'cibadmin -Q';
	my @CONTENT = ();
	my $STATE = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		if ( $#CONTENT < 3 ) {
			$SECTION = 'cib.xml';
			if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
				SDP::Core::printDebug("CIB Database", "$SECTION");
			} else {
				SDP::Core::updateStatus(STATUS_ERROR, "ERROR: getOperationDefTimeout(): Cannot find \"$SECTION\" section in $FILE_OPEN");
			}
		} else {
			SDP::Core::printDebug("CIB Database", "$SECTION");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: getOperationDefTimeout(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}

	foreach $_ (@CONTENT) {
		next if ( m/^\s*$/ ); # Skip blank lines
		if ( $STATE ) {
			SDP::Core::printDebug(" EVAL", "$_");
			if ( /<nvpair.*name=.*timeout.*value/ ) {
				@LINE_CONTENT = split(/\s+/, $_);
				foreach my $PART (@LINE_CONTENT) {
					SDP::Core::printDebug("   PARSE", "$PART");
					if ( $PART =~ m/^value/i ) {
						$PART =~ s/"|'|\s*|\/|<|>//g; # remove quotes and white space
						(undef, $RCODE) = split(/=/, $PART);
					}
				}
				last;
			} elsif ( /<\/op_defaults>/ ) {
				SDP::Core::printDebug("DONE", "$_");
				last;
			}
		} elsif ( /<op_defaults>/ ) {
			SDP::Core::printDebug("IN STATE", "$_");
			$STATE = 1;
		}
	}
	SDP::Core::printDebug("< getOperationDefTimeout", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my $TIMEOUT = getOperationDefTimeout();
	if ( $TIMEOUT > $MAX_TIMEOUT ) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "Detected excessive operation default timeout: $TIMEOUT exceeds $MAX_TIMEOUT");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Operation default time within limits");
	}
SDP::Core::printPatternResults();

exit;


