#!/usr/bin/perl

# Title:       Quorum policy
# Description: Confirm the quorum policy based on nodes
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
	PROPERTY_NAME_CATEGORY."=Policies",
	PROPERTY_NAME_COMPONENT."=Quorum",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7012110"
);




##############################################################################
# Local Function Definitions
##############################################################################

sub nodeCount {
	SDP::Core::printDebug('> nodeCount', 'BEGIN');
	my $RCODE = 0;
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
			if ( /<node / ) {
				SDP::Core::printDebug("PROCESSING", $_);
				$RCODE++;
			} elsif ( /<\/nodes/ ) {
				last;
			}
		} elsif ( /\s*<nodes/ ) {
			SDP::Core::printDebug("PROCESSING", $_);
			$STATE = 1;
		}
	}
	SDP::Core::printDebug("< nodeCount", "Returns: $RCODE");
	return $RCODE;
}

sub getQuorumPolicy {
	my $COUNT = $1;
	SDP::Core::printDebug('> getQuorumPolicy', $COUNT);
	my @LINE_CONTENT = ();
	my $FILE_OPEN = 'ha.txt';
	my $SECTION = 'cibadmin -Q';
	my @CONTENT = ();
	my $POLICY = '';

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
		if ( /nvpair.*no-quorum-policy.*value="(.*)"/ ) {
			SDP::Core::printDebug("PROCESSING", $_);
			$POLICY = $1;
			last;
		}
	}
	SDP::Core::printDebug("< getQuorumPolicy", "Returns: $POLICY");
	return $POLICY;
}

sub ocfs2Volumes {
	SDP::Core::printDebug('> ocfs2Volumes', 'BEGIN');
	my $RCODE = 0; # assuming not ocfs2 volumes
	my $FILE_OPEN = 'ha.txt';
	my $SECTION = 'cibadmin -Q';
	my @CONTENT = ();

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
		if ( /^\s*<primitive.*provider="ocfs2".*type="o2cb"/i ) { # ocfs2 volumes found
			SDP::Core::printDebug("PROCESSING", $_);
			$RCODE++;
			last;
		}
	}

	SDP::Core::printDebug("< ocfs2Volumes", "Returns: $RCODE");
	return $RCODE;
}

##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();
	if ( SDP::SUSE::haeEnabled() ) {
		my $NODES = nodeCount();
		my $POLICY = getQuorumPolicy();

		SDP::Core::printDebug(" POLICY", "'$POLICY'");
		if ( $NODES > 2 ) {
			my $OCFS = ocfs2Volumes();
			my $OCFS_STR = 'without';
			if ( $OCFS ) {
				my $OCFS_STR = 'with';
				if ( $POLICY !~ m/freeze/i ) {
					SDP::Core::updateStatus(STATUS_CRITICAL, "$NODES node cluster $OCFS_STR ocfs2 requires 'freeze' policy");
				} else {
					if ( $POLICY =~ m/none/i ) {
						SDP::Core::updateStatus(STATUS_CRITICAL, "$NODES node cluster $OCFS_STR ocfs2 requires policy other than 'none'");
					} else {
						SDP::Core::updateStatus(STATUS_ERROR, "$NODES nodes $OCFS_STR ocfs2");
					}
				}
			}
		} elsif ( $NODES == 2 ) {
			if ( $POLICY !~ m/ignore/i ) {
				SDP::Core::updateStatus(STATUS_CRITICAL, "$NODES node cluster requires 'ignore' policy");
			} else {
				SDP::Core::updateStatus(STATUS_ERROR, "$NODES nodes");
			}
		} else {
			SDP::Core::updateStatus(STATUS_ERROR, "Skipping quorum check, only $NODES node(s)");
		}
	} else {
		SDP::Core::updateStatus(STATUS_ERROR, "HAE Disabled");
	}
SDP::Core::printPatternResults();

exit;


