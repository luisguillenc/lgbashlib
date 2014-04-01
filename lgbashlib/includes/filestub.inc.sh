#!/bin/bash

which wget > /dev/null || __die "No se encuentra wget!"

# comprueba si existe un fichero con el nombre pasado nombrefichero.stub
# y descarga desde la ubicación contenida en el contenido del ficheor
function __getFileStub() {
	__dbg "${FUNCNAME}($@)"
	[ $# -eq 1 ] || __die "${FUNCNAME}(): invalid number of parameters"
	local fileorig=$1

	if [ -f $fileorig ]; then
		# si existe ya el fichero, lo copia
		cp -a $fileorig .
		return $?
	fi

	local stubfile="${fileorig}.stub"
	if [ ! -f $stubfile ]; then
		__error "${FUNCNAME}(): no se encuentra $stubfile!"
		return 2
	fi

	local stubcontent=`cat $stubfile`
	##TODO: implementar multiprotocolo
	wget $stubcontent
}
