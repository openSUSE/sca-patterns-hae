#!/usr/bin/perl

# Title:       OCFS2 File System Mounting Read Only
# Description: Checking for damaged file system
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
	PROPERTY_NAME_CATEGORY."=Database",
	PROPERTY_NAME_COMPONENT."=Resource",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7008776"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub readOnlyOCFS2 {
	SDP::Core::printDebug('> readOnlyOCFS2', 'BEGIN');
	my $RCODE = 0;
	my $ARRAY_REF = $_[0];
	my $FILE_OPEN = 'fs-diskio.txt';
	my $SECTION = '/bin/mount';
	my @CONTENT = ();
	my $OCFS = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /^(\S*) on .*type ocfs2 \((.*)\)/ ) {
				my $OCFS_DEV = $1;
				my @OCFS_PARAMS = split(',', $2);
				my $PARAM = '';
				$OCFS = 1;
				foreach $PARAM (@OCFS_PARAMS) {
					if ( "$PARAM" eq "ro" ) {
						SDP::Core::printDebug("PUSH", $OCFS_DEV);
						push(@$ARRAY_REF, $OCFS_DEV);
						last;
					}
				}
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: readOnlyOCFS2(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	if ( $OCFS ) {
		$RCODE = scalar @$ARRAY_REF;
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: readOnlyOCFS2(): No OCFS2 file systems mounted");
	}
	SDP::Core::printDebug("< readOnlyOCFS2", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my @OCFS2_RO = ();
	if ( readOnlyOCFS2(\@OCFS2_RO) ) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "Detected Read Only OCFS2 File Systems, Run fsck.ocfs2 on: @OCFS2_RO");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "No Read Only OCFS2 File Systems Found");
	}
SDP::Core::printPatternResults();

exit;

