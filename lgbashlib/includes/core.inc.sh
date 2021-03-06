#!/bin/bash

# Autor: Luis Guillen
# Fecha: 20121008


##### Variables globales
# __ScriptPath
# __ScriptName
# __ScriptDir
# __StartTimestamp
# __Tmp
# __LogFile
# __Distrib_Id
# __Distrib_Release


if ! type __defined > /dev/null 2>&1; then
	# Devuelve 0 si la variable pasada se encuentra definida
	function __defined() {
	#	[ ${!1-X} == ${!1-Y} ]
		[ "${!1-X}" == "${!1-Y}" ]
	}
fi

function __definedFunction() {
	type $1 > /dev/null
}


function __getDateTime() {
        echo `date +%Y%m%d-%H%M%S`
}

__LOG_SIL_LVL=0
__LOG_ERR_LVL=1
__LOG_WRN_LVL=2
__LOG_INF_LVL=3
__LOG_DBG_LVL=4

function __log() {
	if [ $# -lt 3 ]; then
		echo "${FUNCNAME}(): invalid number of parameters" 1>&2
		exit 2
	fi

	local verbosity=$1
	local header="$2"
	if [ $__LogVerbosity -ge $verbosity ]; then
		shift
		shift
		if [ -n "$__LogFile" ]; then

			local dateTime=`__getDateTime`
			echo -e "$dateTime;$header;$@" >> $__LogFile
		fi

		if [ $__LogEcho -eq 0 ]; then
			echo -e "$header: $@" 1>&2
		fi
	fi

}

function __msg() {
	__log $__LOG_SIL_LVL "MESSAGE" "$@"
#	test $__EchoMsg -eq 0 && echo "$@"
#	local dateTime=`__getDateTime`
#	echo "$dateTime;$SSH_CLIENT;INFO: $@" >> $__LogFile
}

function __error() {
	__log $__LOG_ERR_LVL "ERROR" "$@"
}

function __warn() {
	__log $__LOG_WRN_LVL "WARNING" "$@"
}

function __info() {
	__log $__LOG_INF_LVL "INFO" "$@"
}

function __dbg() {
	__log $__LOG_DBG_LVL "DEBUG" "$@"
}


function __die() {
	__error $@
	exit 2
}


# comprueba si el elemento pasado en $2 esta en el array $1
function __isInArray() {
	__dbg "${FUNCNAME}($@)"
	test $# -ne 2 && __die "${FUNCNAME}(): invalid number of parameters"
	__dbg "${FUNCNAME}(): checking if $2 is in $1"

	local deps
	eval "deps=( \"\${$1[@]}\" )"
	local elemento=$2

	local is_in_array=1
	# copia local del array del parametro 1
	for (( i = 0 ; i < ${#deps[@]} ; i++ ))
	do
		if [ "${deps[$i]}" = "${elemento}" ]; then
			__dbg "isInArray(): $elemento found in array"
			is_in_array=0
		fi
	done

	if [ $is_in_array -ne 0 ]; then
		__dbg "${FUNCNAME}(): $elemento NOT found in array"
	fi

	return $is_in_array
}


# Hace un backup del fichero pasado por parámetro
# deja un -last y uno para el día
# si recive un 1 por parámetro realiza el backup en el mismo directorio
function __backupFile() {
	__dbg "${FUNCNAME}($@)"
	test $# -ge 1 || __die "${FUNCNAME}(): invalid number of parameters"
	__defined __BackupDst || die "${FUNCNAME}(): global variable __BackupDst undefined"

	local fichero=$1
	if [ $# -eq 2 ]; then
		local opcion=$2
	else
		local opcion=0
	fi

	local nomfichero=`basename "$fichero"`
	local fecha=`date +%Y%m%d`

	if [ ! -f $fichero ]; then
		__warn "${FUNCNAME}(): file $fichero doesn't exists"
		return 1
	fi

	# realiza una copia de la última configuración como last
	if [ $opcion -eq 1 ]; then
		cp -p $fichero "${fichero}-LAST"
	else
		cp -p $fichero $__BackupDst/"${nomfichero}-LAST"
	fi

	# si para el día no hay backup lo hace, sino no
	if [ $opcion -eq 1 ]; then
		if [ ! -f "${fichero}-${fecha}" ]; then
			cp -p $fichero "${fichero}-${fecha}"
		fi
	else
		if [ ! -f $__BackupDst/"${nomfichero}-${fecha}" ]; then
			cp -p $fichero $__BackupDst/"${nomfichero}-${fecha}"
		fi
	fi

	__dbg "${FUNCNAME}(): backup done"
	return 0
}

function __restoreFile() {
	__dbg "${FUNCNAME}($@)"
	[ $# -ge 1 ] || __die "${FUNCNAME}(): invalid number of parameters"
	__defined __BackupDst || die "${FUNCNAME}(): global variable __BackupDst undefined"

	local fichero=$1
	if [ $# -eq 2 ]; then
		local opcion=$2
	else
		local opcion=0
	fi

	local nomfichero=`basename "$fichero"`

	if [ $opcion -eq 1 ]; then
		if [  -f "${fichero}-LAST" ]; then
			cp -p "$fichero-LAST" $fichero
		else
			__warn "${FUNCNAME}(): I can't restore file $fichero from LAST file"
		fi
	else
		if [  -f $__BackupDst/"${nomfichero}-LAST" ]; then
			cp -p $__BackupDst/"${nomfichero}-LAST" $fichero
		else
			__warn "${FUNCNAME}(): I can't restore file $fichero from LAST file"
		fi
	fi
}

function __isOS64bits()
{
	__dbg "${FUNCNAME}(): checking if kernel is 64 bits..."
	uname -m | grep x86_64 > /dev/null
	if [ $? -eq 0 ]; then
		__dbg "is 64bits"
		return 0
	else
		__dbg "is 32bits"
		return 1
	fi
}

# imprime el tiempo en segundos de ejecución del script
function __printExecTime()
{
	local now=`date +%s`
	echo "$((now-__StartTimestamp))"
}

function __loadConfig() {
	__dbg "${FUNCNAME}($@)"
	if [ $# -eq 0 ]; then
		local configFile=$__ScriptDir/../etc/`basename $__ScriptName .sh`.cfg
		. $configFile
	else
		if [ -f $1 ]; then
#			__dbg "${FUNCNAME}(): Cargando $1..."
			. $1
		elif [ -f $__ScriptEtc/$1.cfg ]; then
#			__dbg "${FUNCNAME}(): Cargando $__ScriptEtc/$1.cfg"
			. $__ScriptEtc/$1.cfg
		elif [ -f $__LgBashEtc/$1.cfg ]; then
#			__dbg "${FUNCNAME}(): Cargando $__LgBashEtc/$1.cfg"
			. $__LgBashEtc/$1.cfg
		else
			__die "${FUNCNAME}(): No puede cargar $1"
		fi
	fi
}

function __loadModule() {
	__dbg "${FUNCNAME}($@)"
	[ $# -eq 1 ] || __die "${FUNCNAME}(): invalid number of parameters"
	if [ -f $1 ]; then
#		__dbg "${FUNCNAME}(): Loading module $1..."
		. $1
	else
		if [ -f $__ScriptInclude/$1.inc.sh ]; then
#			__dbg "${FUNCNAME}(): Loading module $__ScriptInclude/$1.inc.sh..."
			. $__ScriptInclude/$1.inc.sh
		elif [ -f $__LgBashInclude/$1.inc.sh ]; then
#			__dbg "${FUNCNAME}(): Loading module $__LgBashInclude/$1.inc.sh..."
			. $__LgBashInclude/$1.inc.sh
		else
			__die "${FUNCNAME}(): Módulo $1 no encontrado!"
		fi
	fi
}

function __loadScriptModule() {
	__dbg "${FUNCNAME}($@)"
	[ $# -eq 1 ] || __die "${FUNCNAME}(): invalid number of parameters"
	if [ -f $__ScriptInclude/$1.inc.sh ]; then
#		__dbg "${FUNCNAME}(): Loading script module $__ScriptInclude/$1.inc.sh..."
		. $__ScriptInclude/$1.inc.sh
	else
		__die "${FUNCNAME}(): Módulo de script $1 no encontrado!"
	fi
}

# 0 -> si está vacío o no existe
# 1 -> si no está vacío
function __dirIsEmpty() {
	__dbg "${FUNCNAME}($@)"
	[ $# -eq 1 ] || __die "${FUNCNAME}(): invalid number of parameters"
	if [ ! -d $1 ]; then
		__dbg "${FUNCNAME}(): no existe"
		return 0
	fi
	ls -A $1 > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		__dbg "${FUNCNAME}(): no está vacío"
		return 1
	else
		__dbg "${FUNCNAME}(): vacío"
		return 0
	fi
}

# recive un parámetro en forma "servidor1,servidor2"
# devuelve una cadena en forma "servidor1 servidor"
function __processParams() {
	[ $# -eq 1 ] || __die "${FUNCNAME}(): invalid number of parameters"

	OLD_IFS=$IFS
	IFS=","
	local param
	local cadena=""
	for param in $1; do
		[ -z "$cadena" ] || cadena="${cadena} "
		cadena="${cadena}${param}"
	done
	IFS=$OLD_IFS
	echo -n "${cadena}"
}

# interrumpe si no está definido la variable pasada
function __dieNotDef() {
	__dbg "${FUNCNAME}($@)"
	[ $# -eq 1 ] || __die "${FUNCNAME}(): invalid number of parameters"
	__defined $1 || __die "${FUNCNAME}(): Falta definir $1"
#	__dbg "${FUNCNAME}(): ${1}=${!1}"
	return 0
}
