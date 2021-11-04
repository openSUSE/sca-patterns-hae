#!/usr/bin/python3

# Title:       Invalid Corosync Consensus
# Description: Odd cluster membership changes in HAE cluster
# Modified:    2014 Jun 17
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
OTHER_LINKS = "META_LINK_TID=https://www.suse.com/support/kb/doc.php?id=7015215|META_LINK_Man=http://linux.die.net/man/5/corosync.conf"

Core.init(META_CLASS, META_CATEGORY, META_COMPONENT, PATTERN_ID, PRIMARY_LINK, OVERALL, OVERALL_INFO, OTHER_LINKS)

##############################################################################
# Main Program Execution
##############################################################################

if HAE.haeEnabled():
	CS = HAE.getConfigCorosync()
	if "totem" in CS:
		if "token" in CS['totem']:
			if "consensus" in CS['totem']:
				TOKEN = int(CS['totem']['token'])
				CONSENSUS = int(CS['totem']['consensus'])
				VALID = int(TOKEN * 1.2)
				if( CONSENSUS >= VALID ):
					Core.updateStatus(Core.IGNORE, "Valid corosysnc consensus value based on token")
				else:
					Core.updateStatus(Core.CRIT, "Invalid corosync consensus value; consensus=" + str(CONSENSUS) + ", should be >= " + str(VALID))
			else:
				Core.updateStatus(Core.IGNORE, "Corosysnc consensus automatically calculated based on token")
		else:
			Core.updateStatus(Core.ERROR, "token not defined in corosync configuration")
	else:
		Core.updateStatus(Core.ERROR, "totem not defined in corosync configuration")
else:
	Core.updateStatus(Core.ERROR, "HAE disabled, skipping test")

Core.printPatternResults()

