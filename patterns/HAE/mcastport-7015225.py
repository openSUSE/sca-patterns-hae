#!/usr/bin/python3

# Title:       Check for unique mcastports
# Description: Troubleshooting HAE Cluster Membership
# Modified:    2014 Jun 18
#
##############################################################################
# Copyright (C) 2014 SUSE LLC
##############################################################################
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, see <http://www.gnu.org/licenses/>.
#
#  Authors/Contributors:
#   Jason Record (jrecord@suse.com)
#
##############################################################################

##############################################################################
# Module Definition
##############################################################################

import os
import Core
import HAE

##############################################################################
# Overriden (eventually or in part) from SDP::Core Module
##############################################################################

META_CLASS = "HAE"
META_CATEGORY = "Configuration"
META_COMPONENT = "Corosync"
PATTERN_ID = os.path.basename(__file__)
PRIMARY_LINK = "META_LINK_TID"
OVERALL = Core.TEMP
OVERALL_INFO = "NOT SET"
OTHER_LINKS = "META_LINK_TID=https://www.suse.com/support/kb/doc.php?id=7015225|META_LINK_Man=http://linux.die.net/man/5/corosync.conf"

Core.init(META_CLASS, META_CATEGORY, META_COMPONENT, PATTERN_ID, PRIMARY_LINK, OVERALL, OVERALL_INFO, OTHER_LINKS)

##############################################################################
# Main Program Execution
##############################################################################

CS = HAE.getConfigCorosync()
MCASTPORT = {}
DUP_MCASTPORT = {}
try:
	for I in range(0, len(CS['totem']['interface'])):
		ADDR = CS['totem']['interface'][I]['mcastport']
		if ADDR in MCASTPORT:
			# There is a duplicate bind net address key, add the duplicate to the list
			DUP_MCASTPORT[ADDR] = True
		else:
			# The address is not a duplicate, add it to the list of bind net addresses to check
			MCASTPORT[ADDR] = True
	if( len(DUP_MCASTPORT) > 0 ):
		Core.updateStatus(Core.REC, "Detected Duplicate Corosync Multicast Port Addresses: " + " ".join(list(DUP_MCASTPORT.keys())))
	else:
		Core.updateStatus(Core.IGNORE, "All Corosync Multicast Port Addresses are Unique")
except Exception as error:
	Core.updateStatus(Core.ERROR, "Corosync configuration error: " + str(error))

Core.printPatternResults()

