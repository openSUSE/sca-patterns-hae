#!/usr/bin/perl

# Title:       Large files on ocfs2 fail
# Description: OCFS2 showing no space left on device regardless of the free space
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
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7008696",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=697513"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub ocfs2BlockSizes {
	SDP::Core::printDebug('> ocfs2BlockSizes', 'BEGIN');
	my $RCODE = 0;
	my $ARRAY_REF = $_[0];
	my $FILE_OPEN = 'ocfs2.txt';
	my @CONTENT = ();
	my $SECTION_FOUND = 0;
	my $STATE = 0;
	my $ODEV = '';

	if ( SDP::Core::loadFile($FILE_OPEN, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( $STATE ) {
				if ( /Block Size Bits.*Cluster Size Bits: (.*)/i ) {
					SDP::Core::printDebug(" CHECK", "$ODEV: $_");
					my $CSIZE = $1;
					push(@$ARRAY_REF, $ODEV) if ( $CSIZE < 16 );
				} elsif ( /^#==\[/ ) {
					$STATE = 0;
				}
			} elsif ( /^#.*debugfs.ocfs2 -n -R \"stats\" (.*)/ ) {
				SDP::Core::printDebug("STATE SET", $_);
				$ODEV = $1;
				$STATE = 1;
				$SECTION_FOUND++;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: ocfs2BlockSizes(): Cannot file $FILE_OPEN");
	}
	if ( $SECTION_FOUND ) {
		$RCODE = scalar @$ARRAY_REF;
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: ocfs2BlockSizes(): Cannot find debugfs.ocfs2 section(s) in $FILE_OPEN");
	}
	SDP::Core::printDebug("< ocfs2BlockSizes", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my @FLAGGED_OCFS2 = ();
	if ( ocfs2BlockSizes(\@FLAGGED_OCFS2) ) {
		SDP::Core::updateStatus(STATUS_WARNING, "Creating large files may fail on: @FLAGGED_OCFS2");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "OCFS2 filesystem(s) not susceptible to creating large files");
	}
SDP::Core::printPatternResults();

exit;


