#!/usr/bin/perl

# Title:       Cannot Perform a File System Check on OCFS2
# Description: DLM errors reported when attempting an OCFS2 file system check
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
	PROPERTY_NAME_COMPONENT."=Resource",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7005238"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub checkFsckOcfsErrors {
	SDP::Core::printDebug('> checkFsckOcfsErrors', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'ocfs2.txt';
	my $SECTION = '/var/log/messages';
	my @CONTENT = ();
	my @LINE_CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( /^\s*$/ ); # Skip blank lines
			if ( /ocfs2_controld: complete_mount: uuid.*errcode.*-1485330943.*service.*fsck.ocfs2/i ) {
				SDP::Core::printDebug("FOUND", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< checkFsckOcfsErrors", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( SDP::SUSE::compareKernel(SLE11GA) >= 0 && SDP::SUSE::compareKernel(SLE11SP1) < 0 ) {
		if ( SDP::SUSE::packageInstalled('openais') && SDP::SUSE::packageInstalled('ocfs2-tools') ) {
			my $RPM_NAME = 'libdlm-devel';
			my $VERSION_TO_COMPARE = '2.99.08-8.4';
			my $RPM_COMPARISON = SDP::SUSE::compareRpm($RPM_NAME, $VERSION_TO_COMPARE);
			if ( $RPM_COMPARISON == 2 ) { # libdlm-devel is not installed
				my $RPM_NAME = 'libdlm';
				my $LIBDLM = SDP::SUSE::compareRpm($RPM_NAME, $VERSION_TO_COMPARE);
				if ( $LIBDLM < 2 ) {
					if ( $LIBDLM > 0 ) {
						SDP::Core::updateStatus(STATUS_ERROR, "OCFS2 File system Check: Available (libdlm)");
					} else {
						if ( checkFsckOcfsErrors() ) {
							SDP::Core::updateStatus(STATUS_CRITICAL, "OCFS2 File system Check: fsck.ocfs2 ERRORS Found, try libdlm-devel");
						} else {
							SDP::Core::updateStatus(STATUS_WARNING, "OCFS2 File system Check: fsck.ocfs2 may fail");
						}
					}                       
				} else {
					SDP::Core::updateStatus(STATUS_ERROR, "ERROR: $RPM_NAME RPM is not installed properly");
				}
			} elsif ( $RPM_COMPARISON > 2 ) {
				SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Multiple Versions of $RPM_NAME RPM are Installed");
			} else {
				if ( $RPM_COMPARISON >= 0 ) {
					SDP::Core::updateStatus(STATUS_ERROR, "OCFS2 File system Check: Available (libldm-devel)");
				} else {
					if ( checkFsckOcfsErrors() ) {
						SDP::Core::updateStatus(STATUS_CRITICAL, "OCFS2 File system Check: fsck.ocfs2 ERRORS Found");
					} else {
						SDP::Core::updateStatus(STATUS_ERROR, "OCFS2 File system Check: No errors fsck.ocfs2");
					}
				}                       
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Missing SLE11 HAE OCFS2, Skipping fsck.ocfs2 test");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Outside kernel scope, skipping fsck.ocfs2 test");
	}
SDP::Core::printPatternResults();

exit;

