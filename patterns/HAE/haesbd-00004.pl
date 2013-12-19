#!/usr/bin/perl

# Title:       SBD Partition Metadata Mismatch
# Description: All SBD partition dump metadata must match
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
	PROPERTY_NAME_COMPONENT."=Config",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7010933"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub sbdMetaMismatch {
	SDP::Core::printDebug('> sbdMetaMismatch', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'ha.txt';
	my @CONTENT = ();
	my @META = ();
	my $I = 0;
	my $STATE = 0;
	my $LOADED = 0;
	my $CONTENT_FOUND = 0;
	if ( SDP::Core::loadFile($FILE_OPEN, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$|^==/ ); # Skip blank lines
			if ( $STATE ) {
				if ( /^#==\[/ ) {
					$STATE = 0;
					$LOADED = 1;
					SDP::Core::printDebug(" DONE", "State Off");
				} else {
					if ( @META && $LOADED ) {
						SDP::Core::printDebug(" SRC", "$META[$I]");
						SDP::Core::printDebug(" CMP", "$_");
						if ( "$META[$I]" ne "$_") {
							SDP::Core::printDebug("  Failed", "Comparison");
							$RCODE++;
							last;
						}
						$I++;
					} else {
						SDP::Core::printDebug(" PUSH", "$_");
						push(@META, $_);
					}
				}
			} elsif ( /^#.*\/sbd -d .* dump/ ) { # Section
				$STATE = 1;
				$I = 0;
				SDP::Core::printDebug("CHECK", "Section: $_");
			}
		}
		if ( ! @META ) {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: sbdMetaMismatch(): No SBD Partitions Found");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: sbdMetaMismatch(): Cannot load file: $FILE_OPEN");
	}
	SDP::Core::printDebug("< sbdMetaMismatch", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( sbdMetaMismatch() ) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "Detected SBD Partition Metadata Mismatch");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "SBD Partition Metadata Matches");
	}
SDP::Core::printPatternResults();

exit;


