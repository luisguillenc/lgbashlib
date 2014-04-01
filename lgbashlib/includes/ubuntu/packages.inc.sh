#!/bin/bash

# Autor: Luis Guillen
# Fecha: 20121009

if [ $__ForceRoot -ne 0 ]; then
	__die "This module requires cfg_forceRoot=0"
fi


function __updatePackages() {
	__dbg "${FUNCNAME}(): updating packages..."
	# Actualizar repositorios
	apt-get update || __warn "${FUNCNAME}(): there are some errors while updating packages"
}

function __upgradePackages()
{
	__dbg "${FUNCNAME}(): upgrading packages previously installed..."
	OLD_DEBIAN_FRONTEND=$DEBIAN_FRONTEND
	export DEBIAN_FRONTEND=noninteractive

	apt-get upgrade -f -y || __warn "${FUNCNAME}(): there are some errors while upgrading distribution"

	DEBIAN_FRONTEND=$OLD_DEBIAN_FRONTEND
}


function __upgradeDist()
{
	__dbg "${FUNCNAME}(): upgrading distribution..."
	OLD_DEBIAN_FRONTEND=$DEBIAN_FRONTEND
	export DEBIAN_FRONTEND=noninteractive

	apt-get dist-upgrade -f -y || __warn "${FUNCNAME}(): there are some errors while upgrading distribution"

	DEBIAN_FRONTEND=$OLD_DEBIAN_FRONTEND
}


function __checkPackage()
{
	test $# -ne 1 && __die "${FUNCNAME}(): invalid number of parameters"
	package=$1

	__dbg "${FUNCNAME}(): checking if package $package exists"
	dpkg -s $package 2>/dev/null | grep ^Status | grep -qw install
	if [ $? -eq 0 ]; then
		__dbg "${FUNCNAME}(): package $package exists"
		return 0
	else
		__dbg "${FUNCNAME}(): package $package doesn't exists"
		return 1
	fi
}

# recibe array con los paquetes
# por referencia deja un array los paquetes no instalados
# retorna el número de paquetes no instalados
function __checkPackages()
{
	test $# -ne 2 && __die "${FUNCNAME}(): invalid number of parameters"

	__dbg "${FUNCNAME}(): checking packages"
	local uncompletedeps=0

	# copia local del array del parametro 1
	local deps
	eval "deps=( \"\${$1[@]}\" )"

	declare -a local_notinstalled

	for (( i = 0 ; i < ${#deps[@]} ; i++ ))
	do
		__checkPackage ${deps[$i]}
		if [ $? -ne 0 ]; then
			local_notinstalled[$uncompletedeps]=$package
			let uncompletedeps=uncompletedeps+1
		fi
	done

	# relleno el array especificado en $2 por referencia
	for (( i = 0 ; i < ${#local_notinstalled[@]} ; i++ ))
	do
		eval "${2}[$i]=${local_notinstalled[$i]}"
	done

	# retorna el numero de paquetes no resueltos
	__dbg "${FUNCNAME}(): not installed packages: $uncompletedeps"
	return $uncompletedeps
}

# Recibe un array con las dependencias y lo instala
function __installPackages()
{
	test $# -ne 1 && __die "${FUNCNAME}(): invalid number of parameters"

	__dbg "${FUNCNAME}(): installing packages"

	# copia local del array del parametro 1
	local deps
	eval "deps=( \"\${$1[@]}\" )"

	local string_deps=""
	for (( i = 0 ; i < ${#deps[@]} ; i++ ))
	do
		string_deps="$string_deps ${deps[$i]}"
	done

	if [ -z "${string_deps}" ]; then
		__die "${FUNCNAME}(): array of packages is empty"
	fi

	OLD_DEBIAN_FRONTEND=$DEBIAN_FRONTEND
	export DEBIAN_FRONTEND=noninteractive

	__dbg "${FUNCNAME}(): ${string_deps} will be installed now"
	apt-get -y install --force-yes ${string_deps}
	if [ $? -ne 0 ]; then
		__warn "${FUNCNAME}(): error installing packages"
		return 1
	fi

	DEBIAN_FRONTEND=$OLD_DEBIAN_FRONTEND
	__dbg "${FUNCNAME}(): packages installed"
}

function __installDependencies()
{
	test $# -lt 1 && __die "${FUNCNAME}(): invalid number of parameters"

	local dependencies=( $@ )

	local notinstalled=""
	declare -a notinstalled
	__checkPackages dependencies notinstalled
	if [ $? -ne 0 ]; then
		__installPackages notinstalled || __die "Error while installing ${1}"
	fi
	__dbg "${FUNCNAME}(): dependencies installed"
}

