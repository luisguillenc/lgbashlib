#!/bin/bash

# require bash 4!
if [ -f  $__LgBashInclude/${__Distrib_Id,,}/packages.inc.sh ]; then
	. $__LgBashInclude/${__Distrib_Id,,}/packages.inc.sh
else
	__die "packages.inc.sh doesn't exist for yor distribution"
fi

