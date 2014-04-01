#!/bin/bash

# Autor: Luis Guillen
# Fecha: 20130425


__dieNotDef __LdapConnectionString

function __ldapExistsObject() {
	__dbg "${FUNCNAME}($@)"
	[ $# -eq 2 ] || __die "${FUNCNAME}(): invalid number of parameters"

	local baseDn=$1
	local rdn=$2

	ldapsearch $__LdapConnectionString -b "$rdn,$baseDn" \
		> /dev/null 2>&1
	if [ $? -eq 0 ]; then
		__dbg "Existe objeto"
		return 0
	else
		__dbg "No existe"
		return 1
	fi
}

function __ldapAddLdiff() {
	__dbg "${FUNCNAME}($@)"
	[ $# -eq 1 ] || __die "${FUNCNAME}(): invalid number of parameters"
	local ldifFile=$1
	[ -f $ldifFile ] || __die "${FUNCNAME}(): no se encuentra ldif"

	ldapadd $__LdapConnectionString -f $ldifFile
	if [ $? -ne 0 ]; then
		__error "${FUNCNAME}(): Error ldapadd $ldifFile"
		return 1
	fi

	return 0
}

function __ldapModifyLdiff() {
	__dbg "${FUNCNAME}($@)"
	[ $# -eq 1 ] || __die "${FUNCNAME}(): invalid number of parameters"
	local ldifFile=$1
	[ -f $ldifFile ] || __die "${FUNCNAME}(): no se encuentra ldif"

	ldapmodify $__LdapConnectionString -f $ldifFile
	if [ $? -ne 0 ]; then
		__error "${FUNCNAME}(): Error ldapmodify $ldifFile"
		return 1
	fi

	return 0
}

function __ldapAddLdiffFromTemplate() {
	__dbg "${FUNCNAME}($@)"
	[ $# -ge 1 ] || __die "${FUNCNAME}(): invalid number of parameters"	
	local templateFile="$1"
	[ -f $templateFile ] || __die "${FUNCNAME}(): no se encuentra ldif"
	local ldifFile=`basename $templateFile`
	shift

	cat $templateFile | __processTemplate \
		$@ > $__Tmp/$ldifFile

	if [ \( $? -ne 0 \) -o \( ! -f $__Tmp/$ldifFile \) ]; then
		__error "${FUNCNAME}(): procesando plantilla $templateFile"
		return 1
	fi

	__ldapAddLdiff $__Tmp/$ldifFile
	if [ $? -ne 0 ]; then
		__error "${FUNCNAME}(): error"
		return 1
	fi

	rm -f $__Tmp/$ldifFile
	return 0
}

function __ldapModifyLdiffFromTemplate() {
	__dbg "${FUNCNAME}($@)"
	[ $# -ge 1 ] || __die "${FUNCNAME}(): invalid number of parameters"	
	local templateFile="$1"
	[ -f $templateFile ] || __die "${FUNCNAME}(): no se encuentra ldif"
	local ldifFile=`basename $templateFile`
	shift

	cat $templateFile | __processTemplate \
		$@ > $__Tmp/$ldifFile

	if [ \( $? -ne 0 \) -o \( ! -f $__Tmp/$ldifFile \) ]; then
		__error "${FUNCNAME}(): procesando plantilla $templateFile"
		return 1
	fi

	__ldapModifyLdiff $__Tmp/$ldifFile
	if [ $? -ne 0 ]; then
		__error "${FUNCNAME}(): error"
		return 1
	fi

	rm -f $__Tmp/$ldifFile
	return 0
}

