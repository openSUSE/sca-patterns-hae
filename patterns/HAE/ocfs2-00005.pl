#!/usr/bin/perl

# Title:       OCFS2 Cluster Node Crashes with an Inode Mismatch
# Description: The third node in an OCFS2 file system cluster crashes when the file system is mounted or brought online
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
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7008779",
	"META_LINK_BUG=https://bugzilla.novell.com/show_bug.cgi?id=698608"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub duplicateInodes {
	SDP::Core::printDebug('> duplicateInodes', 'BEGIN');
	my $RCODE = 0;
	my $ARRAY_REF = $_[0];
	my $FILE_OPEN = 'ocfs2.txt';
	my @CONTENT = ();
	my $DEV_CURRENT = '';
	my $DEV_PREVIOUS = '';
	my $STATE = 0;
	my %FILE_SYSTEMS = ();
	my %INODE_TABLE = ();
	my $INODE = '';
	my $OCFS2_FOUND = 0;

	if ( SDP::Core::loadFile($FILE_OPEN, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( $STATE ) {
				if ( /^#==\[/ ) {
					$STATE = 0;
				} elsif ( /^\s*Inode: (\d*)/ ) { # get the inode from the line that begins with Inode: and a number
					$INODE = $1;
					if ( $INODE_TABLE{$INODE} ) {
						$FILE_SYSTEMS{$DEV_CURRENT} = 1;
						SDP::Core::printDebug(" DUPLICATE", "Inode: $INODE, Push $DEV_CURRENT");					
					} else {
						$INODE_TABLE{$INODE} = 1;
						SDP::Core::printDebug(" New", "Inode: $INODE");					
					}
				}
			} elsif ( /^# debugfs.ocfs2.*(\/dev\/.*)/ ) { # found debugfs.ocfs2 command output
				$DEV_CURRENT = $1;
				$STATE = 1;
				$OCFS2_FOUND = 1;
				if ( $DEV_CURRENT ne $DEV_PREVIOUS ) { # begin processing a new ocfs2 device
					SDP::Core::printDebug("DEVICE", "$DEV_CURRENT");
					$DEV_PREVIOUS = $DEV_CURRENT;
					%INODE_TABLE = ();
				}
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: duplicateInodes(): Cannot load file: $FILE_OPEN");
	}
	if ( $OCFS2_FOUND ) {
		@$ARRAY_REF = keys %FILE_SYSTEMS;
		$RCODE = scalar keys %FILE_SYSTEMS;
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: duplicateInodes(): OCFS2 Required, skipping duplicate inode test");
	}
	SDP::Core::printDebug("< duplicateInodes", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	my @FSCK_NEEDED = ();
	if ( duplicateInodes(\@FSCK_NEEDED) ) {
		SDP::Core::updateStatus(STATUS_CRITICAL, "Detected Duplicate Inodes, Run fsck.ocfs2 on: @FSCK_NEEDED");
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "No Duplicate Inodes Detected");
	}
SDP::Core::printPatternResults();

exit;

