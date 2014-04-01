#!/bin/bash

##### Variables de configuración
# cfg_tmp
# cfg_logFile
# cfg_echoMsg
# cfg_forceNoRoot
# cfg_forceRoot


##### Variables globales
# __ScriptPath
# __ScriptName
# __ScriptDir
# __ScriptInclude
# __ScriptEtc
# __ScriptShare
# __BackupDst
# __StartTimestamp
# __Tmp
# __LogFile
# __Distrib_Id
# __Distrib_Release

function __defined() {
#	[ ${!1-X} == ${!1-Y} ]
	[ "${!1-X}" == "${!1-Y}" ]
}


__defined __ScriptPath || ( echo "Error: __ScriptPath variable is not set" && exit 2 )
__defined __ScriptName || __ScriptName=$(basename $__ScriptPath)
__defined __ScriptDir || __ScriptDir=$(dirname $__ScriptPath)
__defined __ScriptInclude || __ScriptInclude=$__ScriptDir/../includes
__defined __ScriptEtc || __ScriptEtc=$__ScriptDir/../etc
__defined __ScriptShare || __ScriptShare=$__ScriptDir/../share
__defined __ScriptLib || __ScriptLib=$__ScriptDir/../lib
__defined __ScriptVar || __ScriptVar=$__ScriptDir/../var
__defined __BackupDst || __BackupDst=/var/backups/lgbash

__defined __LgBashPath || ( echo "Error: __LgBashPath variable is not set" && exit 2 )
readonly __LgBashInclude=$__LgBashPath/includes
readonly __LgBashEtc=$__LgBashPath/etc
readonly __LgBashShare=$__LgBashPath/share


if __defined cfg_tmp; then
	readonly __Tmp=$cfg_tmp
else
	readonly __Tmp=/tmp/lgbash
fi
mkdir -p $__Tmp

mkdir -p $__BackupDst



# Inicializa valores por defecto del loging
if __defined cfg_logVerbosity; then
	__LogVerbosity=$cfg_logVerbosity
else
	__LogVerbosity=2
fi

if __defined cfg_logEcho; then
	__LogEcho=$cfg_logEcho
else
	# por defecto muestra la salida de log por stderr
	__LogEcho=0
fi

if __defined cfg_logFile; then
	readonly __LogFile=$cfg_logFile
else
	readonly __LogFile=""
#	readonly __LogFile=${__Tmp}/${__ScriptName}.log
fi



declare -ir __StartTimestamp=`date +%s`
readonly __Distrib_Id=`lsb_release -i | cut -f2`
readonly __Distrib_Release=`lsb_release -r | cut -f2`


if __defined cfg_forceNoRoot; then
	readonly __ForceNoRoot=$cfg_forceNoRoot
else
	readonly __ForceNoRoot=1
fi

if __defined cfg_forceRoot; then
	readonly __ForceRoot=$cfg_forceRoot
else
	readonly __ForceRoot=1
fi

if __defined cfg_ldapConnectionString; then
	readonly __LdapConnectionString="$cfg_ldapConnectionString"
else
	__LdapConnectionString="-Y EXTERNAL -H ldapi:///"
fi

if [ $__ForceRoot -eq 0 -a `whoami` != 'root' ]
then
	echo "This script must runs under root privilegies!"
	exit 2
fi

if [ $__ForceNoRoot -eq 0 -a `whoami` == 'root' ]
then
	echo "This script can't be executed as root!"
	exit 2
fi

. $__LgBashInclude/core.inc.sh

