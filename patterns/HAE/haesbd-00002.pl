#!/usr/bin/perl

# Title:       Matching Node Lists
# Description: The HAE SBD and CIB node lists must match
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
	PROPERTY_NAME_CATEGORY."=SBD",
	PROPERTY_NAME_COMPONENT."=Attributes",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7010932"
);




my @CIB_NODES = ();
my @SBD_NODES = ();

##############################################################################
# Local Function Definitions
##############################################################################

sub getCIBnodes {
	SDP::Core::printDebug('> getCIBnodes', 'BEGIN');
	my $RCODE = 0;
	my @LINE_CONTENT = ();
	my $FILE_OPEN = 'ha.txt';
	my $SECTION = 'cibadmin -Q';
	my @CONTENT = ();
	my $STATE = 0;
	my $NODE;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		if ( $#CONTENT < 3 ) {
			$SECTION = 'cib.xml';
			if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
				SDP::Core::printDebug("CIB Database", "$SECTION");
			} else {
				SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Cannot find \"$SECTION\" section in $FILE_OPEN");
			}
		} else {
			SDP::Core::printDebug("CIB Database", "$SECTION");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Cannot find \"$SECTION\" section in $FILE_OPEN");
	}

	foreach $_ (@CONTENT) {
		next if ( m/^\s*$/ ); # Skip blank lines
		if ( $STATE ) {
			SDP::Core::printDebug("CHECK", $_);
			if ( /\<node .* uname=".*/ ) {
				@LINE_CONTENT = split(/\s+|\/|>|</, $_);
				for my $NCHECK (@LINE_CONTENT) {
					if ( $NCHECK =~ m/^uname/ ) {
						$NCHECK =~ s/"//g;
						(undef, $NODE) = split(/=/, $NCHECK);
					}
				}
				$NODE = lc $NODE;
				SDP::Core::printDebug("Node Identified", "$NODE");
				push(@CIB_NODES, $NODE);
			} elsif ( /<\/nodes>/ ) {
				last;
			}
		} elsif ( /\<nodes\>/ ) {
			SDP::Core::printDebug("IN STATE", "Found: $_");
			$STATE = 1;
		}
	}
	SDP::Core::printDebug("CIB NODES", "@CIB_NODES");
	$RCODE = scalar @CIB_NODES;
	SDP::Core::printDebug("< getCIBnodes", "Returns: $RCODE");
	return $RCODE;
}

sub compareSBDnodes {
	SDP::Core::printDebug('> compareSBDnodes', 'BEGIN');
	my $RCODE = 0;
	my @LINE_CONTENT = ();
	my $FILE_OPEN = 'ha.txt';
	my @CONTENT = ();
	my $STATE = 0;
	my $NOT_FOUND = 1;
	my ($LINE, $CN, $SN) = (0, 0, 0);
	if ( SDP::Core::loadFile($FILE_OPEN, \@CONTENT) ) {
		foreach $LINE (@CONTENT) {
			next if ( $LINE =~ m/^\s*$/ ); # Skip blank lines
			if ( $STATE ) {
				if ( $LINE =~ /^#==\[/ ) { # finished building the SDB section of nodes, now compare them to the CIB node list
					my $CIB_COUNT = scalar @CIB_NODES;
					my $SBD_COUNT = scalar @SBD_NODES;
					SDP::Core::printDebug("CIB", "@CIB_NODES");
					SDP::Core::printDebug("SBD", "@SBD_NODES");
					if ( $SBD_COUNT = $CIB_COUNT ) {
						my $VALID_NODES = 0;
						foreach my $CN (@CIB_NODES) {
							foreach my $SN (@SBD_NODES) {
								SDP::Core::printDebug("CIB - SBD", "$CN - $SN");
								$VALID_NODES++ if ( "$SN" eq "$CN" );
							}
						}
						if ( $VALID_NODES != $CIB_COUNT) {
							SDP::Core::updateStatus(STATUS_CRITICAL, "HAE CIB Nodes Don't Match SBD Node List");
						} else {
							SDP::Core::updateStatus(STATUS_PARTIAL, "HAE CIB Nodes Match SBD Node List");
						}
					} else {
						SDP::Core::updateStatus(STATUS_CRITICAL, "HAE CIB Nodes Don't Match SBD Node List");
					}
					$STATE = 0;
					SDP::Core::printDebug(" DONE", "State Off");
				} elsif ( $LINE =~ /^\d/ ) { # Section content needed
					@LINE_CONTENT = split(/\s+/, $LINE);
					my $NODE = $LINE_CONTENT[1];
					$NODE = lc $NODE;
					push(@SBD_NODES, $NODE); # build the section SDB array of nodes
				}
			} elsif ( $LINE =~ /^# .*\/sbd -d .* list/ ) { # Section
				$STATE = 1;
				$NOT_FOUND = 0;
				@SBD_NODES = (); # reinitialize for new section
				SDP::Core::printDebug("CHECK", "Section: $LINE");
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: compareSBDnodes(): Cannot load file: $FILE_OPEN");
	}
	if ( $NOT_FOUND ) {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: compareSBDnodes(): Unused SBD Partitions");
	}
	SDP::Core::printDebug("< compareSBDnodes", "Exit");
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	getCIBnodes();
	compareSBDnodes();
	SDP::Core::updateStatus(STATUS_ERROR, "HAE CIB Nodes Match SBD Node List") if ( $GSTATUS < 1 );
SDP::Core::printPatternResults();

exit;


