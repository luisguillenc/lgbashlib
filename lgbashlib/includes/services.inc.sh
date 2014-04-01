#!/bin/bash

# require bash 4!
if [ -f  $__LgBashInclude/${__Distrib_Id,,}/services.inc.sh ]; then
	. $__LgBashInclude/${__Distrib_Id,,}/services.inc.sh
else
	__die "services.inc.sh doesn't exist for yor distribution!"
fi

