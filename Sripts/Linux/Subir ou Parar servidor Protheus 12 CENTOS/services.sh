#!/bin/bash
#
#Descricao: 	| Script para inicializar serviço do Microsiga Protheus 12 -  Testado em CENTOS
#Versao: 	| 1.0
#Data Criacao:	| 30/12/2012
#Data Atualizac:| 
#Criado por:	| Charles Reitz - TSC 679

localinst="/totvs12/" #local da instalacao da pasta TOTVS
fdbaccess=$localinst"/microsiga/dbaccess/" #local de instalacao do dbaccess
fscripts=$localinst$"/scripts/" #local de instalacao dos scripts
fappserver=$localinst"/microsiga/protheus/bin//appserver_linux"
fctree="//"

#Faz a Verificao do Status do Servico
function status(){
local li=""
local msgOn=""
local msgOff=""

echo "Verificando Status de $1"

if [ "$1" == "ctree" ];then
	msgOn="Ctree ONLINE"
	msgOff="Ctree OFFLINE"
	li=`ps axu | grep ctsrvr | grep -v grep`;
	echo "$li"
	if [ "$li" ] && [ $2 == "stop" ];then
		echo $msgOn #online
		return 
	elif [ "$li" ] && [ $2 == "start" ];then
		echo $msgOn #online
		exit
	elif [ "$2" == "stop" ];then
		echo $msgOff #offline
		exit	
	elif [ "$2" == "start" ];then
		echo $msgOff #offline
		return
	fi
	
elif [ "$1" == "dbaccess" ];then 
	msgOn="DbAccess ONLINE"
	msgOff="DbAccess OFFLINE"
	li=`ps axu | grep dbaccess64opt | grep -v grep`;
	echo "$li"
	if [ "$li" ] && [ $2 == "stop" ];then
		echo $msgOn #online
		return 
	elif [ "$li" ] && [ $2 == "start" ];then
		echo $msgOn #online
		exit
	elif [ "$2" == "stop" ];then
		echo $msgOff #offline
		exit	
	elif [ "$2" == "start" ];then
		echo $msgOff #offline
		return
	fi
elif [ "$1" == "appserver" ];then 
	msgOn="Appserver ONLINE"
	msgOff="Appserver OFFLINE"
	li=`ps axu | grep appsrvlinux | grep -v grep`;
	echo "$li"
	if [ "$li" ] && [ $2 == "stop" ];then
		echo $msgOn #online
		return 
	elif [ "$li" ] && [ $2 == "start" ];then
		echo $msgOn #online
		exit
	elif [ "$2" == "stop" ];then
		echo $msgOff #offline
		exit	
	elif [ "$2" == "start" ];then
		echo $msgOff #offline
		return
	fi
elif [ "$1" == "totvs" ];then
	echo "totvs"
else
	echo "Necessario informar o programa para verificar o status"
fi

} 

function fCtree(){
	#Ctree Start
	if [ "$2" == "start" -o "$2" == "s" ]  ;then
		status $1 $2
		echo "Iniciando o CtreeServer..."
		export LD_LIBRARY_PATH=$localinst 
		ulimit -n 65535	
		aux=$localinst"ctreeserver/server/"
		cd $aux
		./ctsrvr &
		aux=$localinst"scripts"
		cd $aux
		sleep 1
		echo "Inicializado!"
		exit 
	#Ctree Stop
	elif [ "$2" == "stop" ] ;then
		status $1 $2 #chama funcao para verificar se esta online
		echo "Parando CtreeServer"
		killall ctsrvr
		sleep 2		
		echo "Finalizado!"
		exit
	else
		echo "Comando nao encontrado. Digite -h para ajuda"
		exit	
	fi
}

function fDbaccess(){
	#DbAccess Start
	if [ "$2" == "start" -o "$2" == "s" ]  ;then
		status $1 $2
		echo "Iniciando o DbAccess..."
		export LD_LIBRARY_PATH=$fdbaccess
		cd $fdbaccess
		nohup ./dbaccess64opt &
		cd $fscripts
		sleep 1
		echo "Inicializado!"
		exit 
	#DbAccess Stop
	elif [ "$2" == "stop" ] ;then
		status $1 $2 #chama funcao para verificar se esta online
		echo "Parando DbAccess"
		killall dbaccess64opt
		sleep 2		
		echo "Finalizado!"
		exit
	else
		echo "Comando nao encontrado. Digite -h para ajuda"
		exit	
	fi
}

function fAppserver(){
	#Appserver Start
	if [ "$2" == "start" -o "$2" == "s" ]  ;then
		status $1 $2
		echo "Iniciando o Appserver..."
		cd $fappserver
		declare -x LD_LIBRARY_PATH="/totvs12/microsiga/protheus/bin/appserver_linux;"$LD_LIBRARY_PATH
		# ulimits podem ser adicionados ao /etc/security/limits.con (ou equivalente)
		# e posteriormente adicionada chamada do pam_limits.so no arquivo/etc/pam.d/common-session
		# (realizar este procedimento com cautela pois pode danificar o login na maquina)
		ulimit -n 32768
		ulimit -s 1024
		ulimit -m 2048000
		ulimit -v 2048000
		#./appserver.sh
		nohup ./appsrvlinux &
		cd $fscripts
		sleep 1
		echo "Inicializado!"
		exit 
	#Appserver Stop
	elif [ "$2" == "stop" ] ;then
		status $1 $2 #chama funcao para verificar se esta online
		echo "Parando Appserver"
		killall appsrvlinux
		sleep 2		
		echo "Finalizado!"
		exit
	else
		echo "Comando nao encontrado. Digite -h para ajuda"
		exit	
	fi
}

#Help para ajudar o user
if [ "$1" == "--help" -o "$1" == "-h" -o "$1" == "" -o "$2" == "" ] ; then
	echo "<nome_do_script> <argumento1> <argumento2>"
	echo "exemplo ./totvs ctree start"
	echo "<argumento1> | programa"
	echo "<argumento2> | acao"
	echo ""
	echo "***************************************************************"
	echo "start	| inicia servico"
	echo "stop	| finaliza servico"
	echo "restart	| reinicia servico"
	echo "***************************************************************"
	echo ""
	echo "==============================================================="
	echo "obs:	| acima ade 65 usuario necessario entrar em contato"
	echo "		  com a TOTVS para solicitar licenca do ctreeserver"
	echo "==============================================================="
	exit
#Ctree
elif [ "$1" == "ctree" ];then
	fCtree $1 $2
elif [ "$1" == "dbaccess" ];then
	fDbaccess $1 $2
elif [ "$1" == "appserver" ];then
	fAppserver $1 $2
fi
	
