#!/bin/bash

# Autor: Luis Guillen
# Fecha: 20121009

if [ $__ForceRoot -ne 0 ]; then
	__die "This module requires cfg_forceRoot=0"
fi


function __checkUpstart() {
	test $# -ne 1 && __die "${FUNCNAME}(): invalid number of parameters"

	__msg "Checking if service $1 is under Upstart"
	local i
	for i in /etc/init/*
	do
		if [ `basename $i .conf` == "${1}" ]; then
			__msg "$1 is under Upstart"
			return 0
		fi
	done
	__msg "$1 isn't under Upstart"
	return 1
}

function __stopService() {
	test $# -ne 1 && __die "${FUNCNAME}(): invalid number of parameters"

	local exitstatus

	__msg "${FUNCNAME}(): stopping service..."
	__checkUpstart $1
	if [ $? -eq 0 ]; then
		service $1 stop
		exitstatus=$?
	else
		/etc/init.d/$1 stop
		exitstatus=$?
	fi

	if [ $exitstatus -ne 0 ]; then
		__warn "Error while stopping service.."
	fi

	return $exitstatus
}


function __startService() {
	test $# -ne 1 && __die "${FUNCNAME}(): invalid number of parameters"

	local exitstatus

	__msg "${FUNCNAME}(): starting service..."
	__checkUpstart $1
	if [ $? -eq 0 ]; then
		service $1 start
		exitstatus=$?
	else
		/etc/init.d/$1 start
		exitstatus=$?
	fi

	if [ $exitstatus -ne 0 ]; then
		__warn "Error while starting service.."
	fi

	return $exitstatus
}

