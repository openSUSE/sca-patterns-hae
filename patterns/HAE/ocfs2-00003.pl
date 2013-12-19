#!/usr/bin/perl

# Title:       OCFS2 File System Damage
# Description: OCFS2 hangs or gets ocfs2/heartbeat.c:67 kernel bug error
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
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7008776"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub failedCheckSums {
	SDP::Core::printDebug('> failedCheckSums', 'BEGIN');
	my $RCODE = 0;
	my $ARRAY_REF = $_[0];
	my @LINE_CONTENT = ();
	my $FILE_OPEN = 'ocfs2.txt';
	my @CONTENT = ();
	my $OCFS_DEV = '';
	my $STATE = 0;
	my %FILE_SYSTEMS = ();
	my $OCFS_FOUND = 0;

	if ( SDP::Core::loadFile($FILE_OPEN, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( $STATE ) {
				if ( /^#==\[/ ) {
					SDP::Core::printDebug(" OFF", "End Section");
					$STATE = 0;
					$OCFS_DEV = '';
				} elsif ( /FAILED CHECKSUM/ ) {
					SDP::Core::printDebug(" Found", "FAILED CHECKSUM");					
					$FILE_SYSTEMS{$OCFS_DEV} = 1;
				}
			} elsif ( /^# debugfs.ocfs2.*(\/dev\/.*)/ ) {
				$STATE = 1;
				$OCFS_DEV = $1;
				$OCFS_FOUND = 1;
				SDP::Core::printDebug("ON", "Dev: $OCFS_DEV");
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: failedCheckSums(): Cannot load file: $FILE_OPEN");
	}
	if ( $OCFS_FOUND ) {
		@$ARRAY_REF = keys %FILE_SYSTEMS;
		$RCODE = scalar keys %FILE_SYSTEMS;
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: failedCheckSums(): OCFS2 Required, skipping checksum test");
	}
	SDP::Core::printDebug("< failedCheckSums", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my @FSCK_NEEDED = ();
	if ( failedCheckSums(\@FSCK_NEEDED) ) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "OCFS2 Check Sum Errors, run fsck.ocfs2 on: @FSCK_NEEDED");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "No OCFS2 Check Sum Errors Found");
	}
SDP::Core::printPatternResults();

exit;

