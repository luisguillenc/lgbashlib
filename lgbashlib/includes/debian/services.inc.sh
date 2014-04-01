#!/bin/bash

# Autor: Luis Guillen
# Fecha: 20121009

if [ $__ForceRoot -ne 0 ]; then
	__die "This module requires cfg_forceRoot=0"
fi

function __stopService() {
	test $# -ne 1 && __die "${FUNCNAME}(): invalid number of parameters"

	local exitstatus

	__dbg "${FUNCNAME}(): stopping service..."
	/etc/init.d/$1 stop
	exitstatus=$?

	if [ $exitstatus -ne 0 ]; then
		__warn "Error while stopping service.."
	fi

	return $exitstatus
}


function __startService() {
	test $# -ne 1 && __die "${FUNCNAME}(): invalid number of parameters"

	local exitstatus

	__dbg "${FUNCNAME}(): starting service..."
	/etc/init.d/$1 start
	exitstatus=$?

	if [ $exitstatus -ne 0 ]; then
		__warn "Error while starting service.."
	fi

	return $exitstatus
}


## TODO: implementar en ubuntu
function __checkService() {
	test $# -ne 1 && __die "${FUNCNAME}(): invalid number of parameters"

	local exitstatus

	__dbg "${FUNCNAME}(): checking service..."
	/etc/init.d/$1 status
	return $?
}
