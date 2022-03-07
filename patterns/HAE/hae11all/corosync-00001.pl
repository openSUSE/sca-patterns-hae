#!/usr/bin/perl

# Title:       Checking if more then one interface in the same bindnet.
# Description: Corosync crashed if more then one interface linked to the same bindnet.
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
#   Thomas Schlosser (schloss@suse.de)

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
	PROPERTY_NAME_CATEGORY."=Corosync",
	PROPERTY_NAME_COMPONENT."=Network",
	PROPERTY_NAME_PATTERN_ID."=$PATTERN_ID",
	PROPERTY_NAME_PRIMARY_LINK."=META_LINK_TID",
	PROPERTY_NAME_OVERALL."=$GSTATUS",
	PROPERTY_NAME_OVERALL_INFO."=None",
	"META_LINK_TID=http://www.suse.com/support/kb/doc.php?id=7008804"
);





##############################################################################
# Local Function Definitions
##############################################################################
sub get_bindnetaddr {
    SDP::Core::printDebug('> get_bindnetaddr', 'BEGIN');
    my $FILE_OPEN                = 'ha.txt';
    my $SECTION                  = 'corosync.conf';
    my @CONTENT                  = ();
    my @LINE_CONTENT             = ();
    my $LINE                     = 0;
    my @BindNetAddr              = ();

    if ( SDP::Core::getSection($FILE_OPEN, $SECTION, \@CONTENT) ) {
        foreach $_ (@CONTENT) {
            next if ( /^\s*$/ );                    # Skip blank lines
            if ( /bindnetaddr/i ) {
                @LINE_CONTENT = split(/:\s+/, $_);
                SDP::Core::printDebug('BNET',"Found: " . $LINE_CONTENT[0]. " -> " .  $LINE_CONTENT[1] );
                push(@BindNetAddr,$LINE_CONTENT[1]); 
            }
        }
    }
    return @BindNetAddr;
}





##############################################################################
# Main Program Execution
##############################################################################

SDP::Core::processOptions();

	if ( SDP::SUSE::compareKernel(SLE11GA) >= 0 ) {
		if ( SDP::SUSE::packageInstalled('corosync') ) {
            my $i                   = '';
            my @NETWORK_ROUTES      = ();
            my $tmp                 = "";
            my @BindNet             = get_bindnetaddr();
            my $hash_ref; 

            if ( SDP::SUSE::netRouteTable(\@NETWORK_ROUTES) ) {
                   for $i ( 0 .. $#NETWORK_ROUTES ) {
                            $tmp = $NETWORK_ROUTES[$i]{'destination'};
                            SDP::Core::printDebug('NET',"Destination: $tmp");
                            if($hash_ref->{$tmp}) {
                                foreach my $Addr (@BindNet) {
                                    SDP::Core::printDebug('NET',"Destiantion: $tmp linked to device: $hash_ref->{$tmp} and $NETWORK_ROUTES[$i]{'interface'}" );
                                    SDP::Core::printDebug('NET',"BindNet:     $Addr     Destination: $tmp");
                                    if($tmp eq $Addr) { 
                                        SDP::Core::updateStatus(STATUS_CRITICAL,'SCOPE',"More than one interface in the same subnet will be used for corosync bindnet address"); 
                                    } else {
                                        SDP::Core::updateStatus(STATUS_ERROR, 'SCOPE',"More than one interface in the same subnet, but it is not a bindnet address"); 
                                    }
                                }
                            }
                            $hash_ref->{$tmp} = $NETWORK_ROUTES[$i]{'interface'}; 
                    }   
                    SDP::Core::updateStatus(STATUS_ERROR,'SCOPE', "All interfaces for bindnet addresses are in different subnets");
            }
        } else {
            SDP::Core::updateStatus(STATUS_ERROR, "Corosync package required, skipping corosync test");
        } 
    } else {
        SDP::Core::updateStatus(STATUS_ERROR, "SLE11 or higher required, skipping corosync test"); 
    }

SDP::Core::printPatternResults();

exit;


