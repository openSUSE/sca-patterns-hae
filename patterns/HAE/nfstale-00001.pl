#!/usr/bin/perl

# Title:       NFS resource with stale file handles
# Description: Getting stale NFS file handle errors after cluster fail over
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
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=3714483"
);




my @NFSHA_EXPORTS = ();

##############################################################################
# Local Function Definitions
##############################################################################

sub nfsHaResource {
	SDP::Core::printDebug('> nfsHaResource', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'ha.txt';
	my $SECTION = 'crm_mon';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /lsb:nfsserver/ ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: nfsHaResource(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< nfsHaResource", "Returns: $RCODE");
	return $RCODE;
}

sub missingFsid {
	SDP::Core::printDebug('> missingFsid', 'BEGIN');
	my $RCODE = 0;
	my @LINE_CONTENT = ();
	my $FILE_OPEN = 'nfs.txt';
	my $SECTION = '/etc/exports';
	my @CONTENT = ();
	my @TMP_EXPORTS = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( ! /fsid=/i ) {
				SDP::Core::printDebug("MISSING FSID", $_);
				@LINE_CONTENT = split(/\s+/, $_);
				push(@TMP_EXPORTS, $LINE_CONTENT[0]);
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: missingFsid(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}

	$FILE_OPEN = 'ha.txt';
	$SECTION = 'cib.xml';
	@CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach my $LINE (@CONTENT) {
			next if ( $LINE =~ m/^\s*$/ ); # Skip blank lines
			foreach my $EXPORT (@TMP_EXPORTS) {
				if ( $LINE =~ m/value="$EXPORT"/ ) {
					SDP::Core::printDebug("CLUSTERED", $EXPORT);
					push(@NFSHA_EXPORTS, $EXPORT);
				}
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: nfsHaResource(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}

	$RCODE = scalar @NFSHA_EXPORTS;
	SDP::Core::printDebug("< missingFsid", "Returns: $RCODE");
	return $RCODE;
}

sub staleFileHandleErrors {
	SDP::Core::printDebug('> staleFileHandleErrors', 'BEGIN');
	my $RCODE = 0;
	my $FILE_OPEN = 'messages.txt';
	my $SECTION = '/var/log/messages';
	my @CONTENT = ();

	if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
		foreach $_ (@CONTENT) {
			next if ( m/^\s*$/ ); # Skip blank lines
			if ( /Stale NFS file handle/i ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
				last;
			}
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: staleFileHandleErrors(): Cannot find \"$SECTION\" section in $FILE_OPEN");
	}
	SDP::Core::printDebug("< staleFileHandleErrors", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( nfsHaResource() ) {
		if ( missingFsid() ) {
			if ( staleFileHandleErrors() ) {
				SDP::Core::updateStatus(STATUS_CRITICAL, "Detected NFS stale file handles, use FSID for: @NFSHA_EXPORTS");
			} else { # no errors
				SDP::Core::updateStatus(STATUS_WARNING, "Susceptible to NFS stale file handles, consider FSID for: @NFSHA_EXPORTS");
			}
		} else { # found FSID
			SDP::Core::updateStatus(STATUS_ERROR, "NFS HA resource includes an FSID");
		}
	} else { # no NFS HA resource found
		SDP::Core::updateStatus(STATUS_ERROR, "ERROR: Missing NFS HA resource, skipping FSID test");
	}
SDP::Core::printPatternResults();

exit;

