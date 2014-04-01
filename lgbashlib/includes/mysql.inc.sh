#!/bin/bash

# Autor: Luis Guillen
# Fecha: 20121126

if [ $__ForceRoot -ne 0 ]; then
	__die "This module requires cfg_forceRoot=0"
fi


# This function set password to root
function __mysqlSetRootPassword()
{
	__dbg "${FUNCNAME}(): setting mysql root password..."
	test $# -ne 1 && __die "${FUNCNAME}(): invalid number of parameters"

	local root_mysql=$1
	__dbg "${FUNCNAME}(): setting root password in MySQL server"
	/usr/bin/mysqladmin -u root password ${root_mysql}
	if [ $? -ne 0 ]; then
		__warn "${FUNCNAME}: error while setting root password in MySQL server"
		return 1
	fi
	__dbg "${FUNCNAME}(): root password saved!"
	return 0
}


# Crea un usuario administrativo para la base de datos
# recibe host desde el que se puede conectar
function __mysqlCreateRemoteRoot()
{
	[ $# -eq 2 ] || __die "${FUNCNAME}(): invalid number of parameters"

	local root_password=$1
	local fromHost=$2

	__dbg "${FUNCNAME}(): creating root user for host $fromHost"

	cat > $__Tmp/create_remote_root.sql <<EOF
GRANT ALL PRIVILEGES ON *.* TO 'root'@'${fromHost}' IDENTIFIED BY '${root_password}' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
	mysql -u root --password=${root_password} < $__Tmp/create_remote_root.sql
	if [ $? -ne 0 ]; then
		__warn "${FUNCNAME}(): error while creating remote root"
		return 1
	else
		__dbg "${FUNCNAME}(): remote root user created ok"
		rm -f $__Tmp/create_remote_root.sql
		return 0
	fi
}


# comprueba si puede conectar con mysql con el usuario root
function __mysqlTestConnection()
{
	test $# -ne 1 && __die "${FUNCNAME}(): invalid number of parameters"

	local root_password="${1}"
	__dbg "${FUNCNAME}(): checking connection to mysql..."
	echo "" | mysql -uroot -p"${root_password}"
	if [ $? -ne 0 ]; then
		__dbg "${FUNCNAME}(): connection to mysql failed, check root password and if daemon is running!"
		return 1
	else
		__dbg "${FUNCNAME}(): connection success"
		return 0
	fi
}

# comprueba si la base de datos existe
function __mysqlDbExists()
{
	test $# -ne 2 && __die "${FUNCNAME}(): invalid number of parameters"

	local root_password="${1}"
	local database=$2
	__dbg "${FUNCNAME}(): checking if $database exists..."
	echo "show databases" | mysql -uroot -p"${root_password}" | grep "^${database}$"
	if [ $? -ne 0 ]; then
		__dbg "${FUNCNAME}():database $database doesn't exists"
		return 1
	else
		__dbg "${FUNCNAME}():database $database exists"
		return 0
	fi
}

function __mysqlCheckDbIsEmpty()
{
	test $# -ne 2 && __die "${FUNCNAME}(): invalid number of parameters"

	local root_password="${1}"
	local database=$2
	__dbg "${FUNCNAME}(): checking if $database is empty..."
	num_tablas=`echo "show tables" | mysql -uroot -p"${root_password}" "${database}" | wc -l`
	if [ $? -ne 0 ]; then
		__die "${FUNCNAME}(): error executing query, check database and root password"
		exit 1
	fi

	if [ $num_tablas -eq 0 ]; then
		__dbg "${FUNCNAME}():database $database is empty"
		return 0
	else
		__dbg "${FUNCNAME}():database $database has tables"
		return 1
	fi
}


function __mysqlImportSqlFileToDb()
{
	test $# -ne 3 && __die "${FUNCNAME}(): invalid number of parameters"

	local root_password="${1}"
	local database=$2
	local sqlfile=$3

	if [ ! -f $sqlfile ]; then
		__die "${FUNCNAME}(): Unable to locate $sqlfile!!"
		return 1
	fi

	__dbg "${FUNCNAME}(): importing sql file to ${database}..."
	mysql -uroot -p"${root_password}" --default-character-set=utf8 "${database}" < $sqlfile
	if [ $? -ne 0 ]; then
		__warn "${FUNCNAME}(): error while importing $sqlfile in database $database"
		return 1
	fi
	__dbg "${FUNCNAME}(): file imported to database $database"
	return 0
}


# Crea la base de datos
function __mysqlCreateDb()
{
	test $# -ne 2 && __die "${FUNCNAME}(): invalid number of parameters"

	local root_password="${1}"
	local database=$2

	__dbg "${FUNCNAME}(): creating database..."
	mysqladmin -u root --password="${root_password}" create $database
	if [ $? -ne 0 ]; then
		__warn "${FUNCNAME}(): error while creating database $database"
		return 1
	fi
	__dbg "${FUNCNAME}(): database $database created"
	return 0
}


function __mysqlCheckUserExists()
{
	test $# -ne 2 && __die "${FUNCNAME}(): invalid number of parameters"

	local root_password="${1}"
	local userdb=$2

	__dbg "${FUNCNAME}(): checking if $userdb exists..."
	echo "select user from user where user='${userdb}'\\G" |mysql -uroot -p"${root_password}" mysql | grep user
	if [ $? -ne 0 ]; then
		__dbg "${FUNCNAME}(): user doesn't exists"
		return 1
	else
		__dbg "${FUNCNAME}(): user already exists"
		return 0
	fi

}

# Crea un usuario administrativo para la base de datos
function __mysqlCreateAdminUserToDb()
{
	[ $# -ge 4 ] || __die "${FUNCNAME}(): invalid number of parameters"

	local root_password=$1
	local database=$2
	local userdb=$3
	local passdb=$4
	if [ $# -eq 5 ]; then
		local fromHost=$5
	else
		local fromHost="localhost"
	fi

	__dbg "${FUNCNAME}(): creating admin user ${userdb} to database ${database}"

	cat > $__Tmp/create_${database}.sql <<EOF
GRANT USAGE ON *.* TO '${userdb}'@'localhost' IDENTIFIED BY '${passdb}' ;
GRANT ALL PRIVILEGES ON ${database}.* TO '${userdb}'@'${fromHost}' WITH GRANT OPTION ;
FLUSH PRIVILEGES ;
EOF
	mysql -u root --password=${root_password} < $__Tmp/create_${database}.sql
	if [ $? -ne 0 ]; then
		__warn "${FUNCNAME}(): error while creating user in mysql"
		rm -f $__Tmp/create_${database}.sql
		return 1
	else
		__dbg "${FUNCNAME}(): user created ok"
		rm -f $__Tmp/create_${database}.sql
		return 0
	fi
}

