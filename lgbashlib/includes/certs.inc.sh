#!/bin/bash

# Autor: Luis Guillen
# Fecha: 20121207
# requiere packages

if [ $__ForceRoot -ne 0 ]; then
	__die "This module requires cfg_forceRoot=0"
fi

readonly __CaCertsDir=/usr/share/ca-certificates
readonly __CertsDir=/etc/ssl/certs
readonly __KeysDir=/etc/ssl/private


# recibe
# 1 -> nombre de organización (sin espacios) ej: cefca.es, mozilla, etc
# 2 -> path completo al certificado
# devuelve
# 0 -> si ok
# 1 -> si el certificado no existe
function __installCaCert() {
	[ $# -eq 2 ] || __die "${FUNCNAME}(): invalid number of parameters"
	local organization=$1
	local caCert=$2
	local caCertName=`basename $caCert`

	if [ -f $__CaCertsDir/$organization/$caCertName ]; then
		__dbg "$__CaCertsDir/$organization/$caCertName already exists, omiting"
		return 0
	fi

	if [ ! -f $caCert ]; then
		__warn "${FUNCNAME}(): $caCert doesn't exists!"
		return 1
	fi

	mkdir -p $__CaCertsDir/$organization

	cat /etc/ca-certificates.conf | grep "$organization/$caCertName" > /dev/null
	if [ $? -ne 0 ]; then
		__backupFile /etc/ca-certificates.conf
		cp $caCert $__CaCertsDir/$organization
		echo "$organization/$caCertName" >> /etc/ca-certificates.conf
		update-ca-certificates
	fi
}

# recibe
# 1 -> path completo al certificado
# 2 -> path completo a la key (opcional)
function __installCert() {
	[ $# -ge 1 ] || __die "${FUNCNAME}(): invalid number of parameters"
	[ $# -le 2 ] || __die "${FUNCNAME}(): invalid number of parameters"

	local cert=$1
	local certName=`basename $cert`
	if [ $# -eq 2 ]; then
		local key=$2
		local keyName=`basename $key`
	fi

	if [ ! -f $__CertsDir/$certName ]; then
		__dbg "Installing cert $cert"

		if [ ! -f $cert ]; then
			__warn "${FUNCNAME}(): $cert doesn't exists!"
			return 1
		fi

		cp $cert $__CertsDir
		chown root:root $__CertsDir/$certName
		chmod 644 $__CertsDir/$certName
	else
		__dbg "$__CertsDir/$certName already exists, omiting"
	fi

	[ $# -eq 2 ] || return 0

	if [ ! -f $__KeysDir/$keyName ]; then
		__dbg "Installing key $key"

		if [ ! -f $key ]; then
			__warn "${FUNCNAME}(): $key doesn't exists!"
			return 1
		fi

		cp $key $__KeysDir
		chown root:ssl-cert $__KeysDir/$keyName
		chmod 640 $__KeysDir/$keyName
	else
		__dbg "$key already exists, omiting"
	fi
}

# recibe
# 1 -> nombre del certificado. ej: ldap1.pem
function __getCertPath() {
	[ $# -eq 1 ] || __die "${FUNCNAME}(): invalid number of parameters"
	echo "$__CertsDir/$1"
}

# recibe
# 1 -> nombre del key. ej: ldap.key
function __getKeyPath() {
	[ $# -eq 1 ] || __die "${FUNCNAME}(): invalid number of parameters"
	echo "$__KeysDir/$1"
}

# recibe
# 1 -> organizacion
# 2 -> nombre del certificado de la ca
function __getCaCertPath() {
	[ $# -eq 2 ] || __die "${FUNCNAME}(): invalid number of parameters"
	echo "$__CaCertsDir/$1/$2"
}


