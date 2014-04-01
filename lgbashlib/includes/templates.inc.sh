#!/bin/bash


function __tplReplaceVars() {
	local cadena_sed=""
	local param; for param in $@
	do
		local nom="${param%%=*}"
		local val="${param#*=}"

		cadena_sed="${cadena_sed}s|%%$nom%|${val}|g;"
	done

	sed "$cadena_sed"
}

function __tplProcessDefined() {
	local dentro=1
	local buffer=""
	local nomDefined=""
	while IFS= read line; do
		if [[ ! $line =~ ^# ]] && [[ $line =~ %=.*% ]]; then
			dentro=0
			nomDefined=`echo "$line" | sed 's/.*%@\(.*\)%.*/\1/'`
			buffer=""
		else

			if [[ ! $line =~ ^# ]] && [[ $line =~ %/=${nomDefined}% ]]; then
				dentro=1

				local param; local nom
				for param in $@; do
					nom="${param%%=*}"
					if [ "$nom" == "$nomDefined" ]; then
						echo "$buffer"
					fi
				done
		elif [ $dentro -eq 0 ]; then
			if [ -z ${buffer} ]; then 
				buffer="${line}"
			else
				buffer=`echo "${buffer}"; echo "${line}"`
			fi
		else
			echo "${line}"
		fi
		fi
	done
}

function __tplProcessForEach() {
	local dentro=1
	local buffer=""
	local nomForEach=""
	while IFS= read line; do
		if [[ ! $line =~ ^# ]] && [[ $line =~ %@.*% ]]; then
			dentro=0
			nomForEach=`echo "$line" | sed 's/.*%@\(.*\)%.*/\1/'`
			buffer=""
		else

			if [[ ! $line =~ ^# ]] && [[ $line =~ %/@${nomForEach}% ]]; then
				dentro=1

				local cadena_param=""
				local param; local nom; local val; local mostrado=1
				for param in $@; do
					nom="${param%%=*}"
					if [ "$nom" == "$nomForEach" ]; then
						valForEach=`__processParams "${param#*=}"`
						local v; for v in $valForEach; do
							echo "$buffer" | __tplReplaceVars "$nomForEach"="$v"
						done
						mostrado=0
					fi
				done
				# si no lo hemos mostrado escupimos el buffer sin modificar
				if [ $mostrado -ne 0 ]; then
					echo "$buffer"
				fi
		elif [ $dentro -eq 0 ]; then
			if [ -z "${buffer}" ]; then 
				buffer="${line}"
			else
				buffer=`echo "${buffer}"; echo "${line}"`
			fi
		else
			echo "${line}"
		fi
		fi
	done
}

function __tplProcessDefined() {
	local dentro=1
	local buffer=""
	local nomDefined=""
	while IFS= read line; do
		if [[ ! $line =~ ^# ]] && [[ $line =~ %=.*% ]]; then
			dentro=0
			nomDefined=`echo "$line" | sed 's/.*%=\(.*\)%.*/\1/'`

			buffer=""
		else

			if [[ ! $line =~ ^# ]] && [[ $line =~ %/=${nomDefined}% ]]; then
				dentro=1

				local param; local nom
				for param in $@; do
					nom="${param%%=*}"
					if [ "$nom" == "$nomDefined" ]; then
						echo "$buffer"
					fi
				done
			elif [ $dentro -eq 0 ]; then
				if [ -z "${buffer}" ]; then 
					buffer="${line}"
				else
					buffer=`echo "${buffer}"; echo "${line}"`
				fi
			else
				echo "${line}"
			fi
		fi
	done
}

function __tplProcessUndefined() {
	local dentro=1
	local buffer=""
	local nomDefined=""
	while IFS= read line; do
		if [[ ! $line =~ ^# ]] && [[ $line =~ %\!.*% ]]; then
			dentro=0
			nomDefined=`echo "$line" | sed 's/.*%\!\(.*\)%.*/\1/'`

			buffer=""
		else

			if [[ ! $line =~ ^# ]] && [[ $line =~ %/\!${nomDefined}% ]]; then
				dentro=1

				local param; local nom; local esta=1
				for param in $@; do
					nom="${param%%=*}"
					if [ "$nom" == "$nomDefined" ]; then
						esta=0
					fi
				done
				if [ $esta -ne 0 ]; then
					echo "$buffer"
				fi
			elif [ $dentro -eq 0 ]; then
				if [ -z "${buffer}" ]; then 
					buffer="${line}"
				else
					buffer=`echo "${buffer}"; echo "${line}"`
				fi
			else
				echo "${line}"
			fi
		fi
	done
}


function __tplProcessSourceCode() {
	local dentro=1
	local buffer=""
	local nomDefined=""
	while IFS= read line; do
		if [[ ! $line =~ ^# ]] && [[ $line =~ %X% ]]; then
			dentro=0
			buffer=""
		else
			if [[ ! $line =~ ^# ]] && [[ $line =~ %/X% ]]; then
				tmpFile=`mktemp`
				dentro=1
				echo "$buffer" >> $tmpFile
				source $tmpFile
				rm $tmpFile
			elif [ $dentro -eq 0 ]; then
				if [ -z "${buffer}" ]; then 
					buffer="${line}"
				else
					buffer=`echo "${buffer}"; echo "${line}"`
				fi
			else
				echo "${line}"
			fi
		fi
	done
}

function __processTemplate() {
    __dbg "${FUNCNAME}($@)"
	__tplProcessForEach $@ | __tplProcessDefined $@ | \
	__tplProcessUndefined $@ | __tplReplaceVars $@ | \
	__tplProcessSourceCode
}

