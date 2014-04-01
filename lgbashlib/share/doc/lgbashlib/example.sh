#!/bin/bash

__ScriptPath=$(readlink -f $0)
__LgBashPath=$(dirname $__ScriptPath)/../

cfg_forceRoot=0

. $__LgBashPath/includes/bootstrap.sh
__loadModule packages


__installDependencies vim
__dbg "Esto es una mensaje"

