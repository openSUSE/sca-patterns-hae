#!/usr/bin/perl

# Title:       OCFS2 File System Performance Issue
# Description: OCFS2: dump messages after update regarding __remove_from_page_cache_nocheck
# Modified:    2022 Oct 25

##############################################################################
#  Copyright (C) 2013, 2022 SUSE LLC
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
#   Jason Record <jason.record@suse.com>

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
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7000562",
	"META_LINK_BUG=https://bugzilla.suse.com/show_bug.cgi?id=478140"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub ocfs2_mounted {
	SDP::Core::printDebug('>', 'ocfs2_mounted');
	use constant HEADER_LINES   => 0;
	my $RCODE                    = 0;
	my $FILE_OPEN                = 'ocfs2.txt';
	my $SECTION                  = '/bin/mount';
	my @CONTENT                  = ();
	my @LINE_CONTENT             = ();
	my $LINE                     = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( $LINE++ < HEADER_LINES ); # Skip header lines
			next if ( /^\s*$/ );                   # Skip blank lines
			if ( /type\s+ocfs/i ) {
				SDP::Core::printDebug("LINE $LINE", $_);
				@LINE_CONTENT = split(/\s+/, $_);
				if ( $LINE_CONTENT[4] eq 'ocfs2' ) {
					$RCODE++;
					last;
				}
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< Returns: $RCODE", 'ocfs2_mounted');
	return $RCODE;
}

sub ocfs2_dumped_page_cache {
	SDP::Core::printDebug('>', 'ocfs2_dumped_page_cache');
	use constant HEADER_LINES   => 0;
	my $RCODE                    = 0;
	my $FILE_OPEN                = 'messages.txt';
	my $SECTION                  = '/var/log/messages';
	my @CONTENT                  = ();
	my @LINE_CONTENT             = ();
	my $LINE                     = 0;

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( $LINE++ < HEADER_LINES ); # Skip header lines
			next if ( /^\s*$/ );                   # Skip blank lines
			if ( /__remove_from_page_cache_nocheck/i ) {
				SDP::Core::printDebug("LINE $LINE", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< Returns: $RCODE", 'ocfs2_dumped_page_cache');
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();

	if  ( SDP::SUSE::compareKernel(SLE10SP2) > 0 && SDP::SUSE::compareKernel('2.6.16.60-0.34') <= 0 ) {
		if ( ocfs2_mounted() ) {
			if ( ocfs2_dumped_page_cache() ) {
				SDP::Core::updateStatus(STATUS_CRITICAL, "OCFS2 performance issue detected, Update Needed: kernel-2.6.16.60-0.37 or higher");
			} else {
				SDP::Core::updateStatus(STATUS_WARNING, "OCFS2 slow performance potential, Update Recommended: kernel-2.6.16.60-0.37 or higher");
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "No OCFS2 mounted file systems");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "Outside the kernel scope");
	}

SDP::Core::printPatternResults();

exit;



