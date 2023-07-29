#!/bin/bash



arrematar () {





cat << EOF > /opt/samba/etc/smb.conf



# Gerado pelo script samba4easy - astreinamentos.com.br/samba4easy



# Global parameters

[global]

workgroup = $DOMNETBIOS

realm = $DOMFQDN

netbios name = $NOMESRV

interfaces = lo $LAN

bind interfaces only = Yes

server role = active directory domain controller

idmap_ldb:use rfc2307 = yes

dns forwarder = $ENCDNS

[netlogon]

path = /opt/samba/var/locks/sysvol/$DOMFQDN/scripts

read only = No



[sysvol]

path = /opt/samba/var/locks/sysvol

read only = No



[$SHARE]

path = $PASTA

read only = No

browseable = yes



EOF





cat << EOF > /etc/resolv.conf



# Gerado pelo script samba4easy - astreinamentos.com.br/samba4easy



nameserver 127.0.0.1

nameserver 208.67.220.220

nameserver 8.8.8.8

search $DOMFQDN

domain $DOMFQDN



EOF

ln -s /opt/samba/lib/libnss_winbind.so.2 /lib/x86_64-linux-gnu/
ln -s /lib/x86_64-linux-gnu/libnss_winbind.so.2 /lib/x86_64-linux-gnu/libnss_winbind.so
ldconfig


cat << EOF > /etc/nsswitch.conf



# Gerado pelo script samba4easy - astreinamentos.com.br/samba4easy



passwd:         compat winbind
group:          compat winbind
shadow:         compat
gshadow:        files

hosts:          files dns
networks:       files

protocols:      db files
services:       db files
ethers:         db files
rpc:            db files

netgroup:       nis



EOF



chattr +i /etc/resolv.conf



cp /opt/samba/private/krb5.conf /etc


clear
figlet -c "Samba4Easy 6.0"
echo ""
echo ""

echo " IREI CONFIGURAR O SAMBA NO BOOT "
sleep 3

cat << EOF > /etc/systemd/system/samba-ad-dc.service



# Gerado pelo script samba4easy - astreinamentos.com.br/samba4easy

[Unit]
Description=Samba Active Directory Domain Controller
After=network.target remote-fs.target nss-lookup.target
[Service]
Type=forking
ExecStart=/opt/samba/sbin/samba -D
PIDFile=/opt/samba/var/run/samba.pid
[Install]
WantedBy=multi-user.target



EOF
/opt/samba/sbin/samba
systemctl daemon-reload
systemctl enable samba-ad-dc.service
systemctl start samba-ad-dc.service

clear
figlet -c "Samba4Easy 6.0"
echo ""
echo ""

echo " Agora irei instalar o servidor NTP "

sleep 3

chown root:ntp /opt/samba/var/lib/ntp_signd
chmod 750 /opt/samba/var/lib/ntp_signd
cd /etc
rm ntp.conf

cat << EOF > /etc/ntp.conf



# Gerado pelo script samba4easy - astreinamentos.com.br/samba4easy

# Relogio Local ( Nota: Este nAo e o endereco localhost !)
server 127.127.1.0
fudge  127.127.1.0 stratum 10

# A fonte , onde estamos recebendo o tempo.
server 0.pool.ntp.org     iburst prefer

driftfile       /var/lib/ntp/ntp.drift
logfile         /var/log/ntp
ntpsigndsocket  /opt/samba/var/lib/ntp_signd/

# Controle de acesso
#Restricao # PadrAo: So dar tempo consultando (incl ms-SNTP) a partir desta mAquina .
restrict default kod nomodify notrap nopeer mssntp

# Permitir tudo, de localhost
restrict 127.0.0.1

# Permita que a nossa fonte de tempo so pode fornecer tempo e nada
restrict 0.pool.ntp.org   mask 255.255.255.255    nomodify notrap nopeer noquery
restrict 1.pool.ntp.org   mask 255.255.255.255    nomodify notrap nopeer noquery
restrict 2.pool.ntp.org   mask 255.255.255.255    nomodify notrap nopeer noquery



EOF

/etc/init.d/ntp restart
clear
figlet -c "Samba4Easy 6.0"
echo ""
echo ""
echo -e " VOU CRIAR O DIRETORIO A SER COMPARTILHADO..."
if [ -d "$PASTA" ]
then

	clear
	figlet -c "Samba4Easy 6.0"
	echo ""
	echo ""
	echo -e "O DIRETORIO A SER COMPARTILHADO JA EXISTE"
	echo -e "ENTAO SO IREI AJUSTAR AS PERMISSOES"
	echo ""
	echo ""
	chown -Rv root:"Domain Admins" $PASTA
	chmod 0770 $PASTA
	/opt
	clear
else
	clear
	figlet -c "Samba4Easy 6.0"
	echo ""
	echo ""
	echo -e " VOU CRIAR O DIRETORIO A SER COMPARTILHADO..."
	sleep 3
	rm -rfv $PASTA
	mkdir $PASTA
	chown root:"Domain Admins" $PASTA
	chmod 0770 $PASTA
	sleep 3

fi

cd /usr/src
rm /usr/src/*.* 2> /dev/null
rm -rf /usr/src/*.* 2> /dev/null

rm /etc/mn.initial.sh 2> /dev/null
rm /sbin/menu 2> /dev/null
cd /usr/src
wget -q https://astreinamentos.com.br/scripts/mn.initial.zip /dev/null
unzip mn.initial.zip > /dev/null
chmod +x *.sh
mv mn.initial.sh /etc
ln -s /etc/mn.initial.sh /sbin/menu

clear
figlet -c "Samba4Easy 6.0"
echo ""
echo ""
echo -e " VOU INSTALAR OS ARQUIVOS ADMX PARA WINDOWS 11 NO SEU DC..."
echo ""

cd /opt/samba/var/locks/sysvol/$DOMFQDN/Policies/
wget https://astreinamentos.com.br/download/policy_definitions.zip 2> /dev/null
if [ "$?" = "0" ] ;

then

	unzip policy_definitions.zip
	rm *.zip

else

	clear
	figlet -c "Samba4Easy 6.0"
	echo ""
	echo ""

	echo -e " \e[1;31m OOPS !!!! NÃO CONSEGUI BAIXAR OS AQRUIVOS ADMX  \e[m ";
	   echo -e " \e[1;31m VOCE PODE TENTAR MAIS TARDE EXECUTANDO O COMANDO install_admx \e[m "; 
		echo ""
		echo ""
	
 cat << EOF > /sbin/install_admx
		
#!/bin/bash
		
cd /opt/samba/var/locks/sysvol/$DOMFQDN/Policies/
wget https://astreinamentos.com.br/download/policy_definitions.zip
unzip policy_definitions.zip
rm *.zip
		
EOF


	chmod +x /sbin/install_admx

fi


clear
figlet -c "Samba4Easy 6.0"

echo ""
echo ""

echo  -e "##############################################################################"
echo  -e ""
echo  -e ""
echo  -e ""
echo  -e ""
echo  -e ""
echo  -e "               ACABEI DE IMPLEMENTAR O SEU SERVIDOR SAMBA COM"
echo  -e "                         AS SEGUINTES INFORMACOES"
echo ""                                                      
echo ""
echo -e '\e[36;3m' " 			VERSAO DO SAMBA:  \e[m" $VERSAO
echo -e '\e[36;3m' " 			DIRETORIO DE INSTALACO:  \e[m" /opt/samba
echo -e '\e[36;3m' " 			CAMINHO DO smb.conf:  \e[m" /opt/samba/etc/smb.conf
echo -e '\e[36;3m' " 			IP DO SERVIDOR:  \e[m" $IP
echo -e '\e[36;3m' " 			MASCARA DE REDE:  \e[m" $MASCARA
echo -e '\e[36;3m' " 			DNS EXTERNO:  \e[m" $DNSEXTERNO
echo -e '\e[36;3m' " 			GATEWAY DA REDE:  \e[m" $GATEWAY
echo -e '\e[36;3m' " 			INTERFACE NA SWITCH:  \e[m" $LAN
echo -e '\e[36;3m' " 			NOME DO SERVIDOR:  \e[m" $NOMESRV
echo -e '\e[36;3m' " 			NOME DO DOMINIO:  \e[m" $DOMFQDN
echo -e '\e[36;3m' " 			NOME NETBIOS:  \e[m" $DOMNETBIOS
echo -e '\e[36;3m' " 			DNS DE ENCAMINHAMENTO:  \e[m" $ENCDNS
echo ""
echo ""


echo ""
echo -e "	VOCE PRECISA REINICIAR O SERVIDOR " 
echo -e "	E DEPOIS INSERIR AS MAQUINAS NO DOMINIO E CONFIGURAR GPO DE HORA"
echo -e "	DESEJA REINICIAR O SERVIDOR AGORA ? S/N"
echo ""
echo  -e "##############################################################################"
echo ""
read resposta

if [ $resposta = "s" ];
then
reboot
else
exit
fi
menu  


}










dcpromo () {

clear
figlet -c "Samba4Easy 6.0"
echo ""
echo "" 
echo -e " CONFIGURANDO VARIAVEL PATH ..."
export PATH=$PATH:'/opt/samba/bin:/opt/samba/sbin'

echo 'export PATH=$PATH:"/opt/samba/bin:/opt/samba/sbin' >> ~/.bashrc
echo 'export PATH=$PATH:"/opt/samba/bin:/opt/samba/bin' >> ~/.bashrc



cat << EOF > /etc/hosts


127.0.0.1   localhost localhost.localdomain
$IP    $NOMESRV.$DOMFQDN $NOMESRV


EOF

cat << EOF > /etc/hostname

$NOMESRV

EOF

hostname $NOMESRV.$DOMFQDN


clear
figlet -c "Samba4Easy 6.0"
echo ""
echo ""

echo " VOU AGORA SUBIR O AD E O SERVIDOR DE ARQUIVOS "

sleep 3

samba-tool domain provision --use-rfc2307 --realm=$DOMFQDN --domain=$DOMNETBIOS --dns-backend=SAMBA_INTERNAL --adminpass=$SENHA --server-role=dc --function-level=2008_R2 

if [ "$?" = "0" ] ;

then

arrematar

else

exit

fi

}


instalar () {

clear
figlet -c "Samba4Easy 6.0"
echo ""
echo ""
echo -e " VOU EXECUTAR  make install..."
sleep 3
make install -j 10

if [ "$?" = "0" ];
then

dcpromo

else

exit ;

fi  

}


compilar () {

clear

figlet -c "Samba4Easy 6.0"
echo ""
echo ""
echo -e " VOU EXECUTAR  make ..."
sleep 3  
make -j 10
if [ "$?" = "0" ];
then

instalar

else

exit ;

fi  

}


configurar () {
clear
figlet -c "Samba4Easy 6.0"
echo ""
echo ""
echo -e " VOU EXECUTAR  ./configure ..."
sleep 3
cd /usr/src/samba-$VERSAO
./configure --prefix=/opt/samba -j 10
if [ "$?" = "0" ];
then

compilar ;

else

exit ;

fi   



}



descompactar () {

clear
figlet -c "Samba4Easy 6.0"
echo ""
echo ""
apt-get autoremove -qq > /dev/null
apt-get clean -qq > /dev/null
apt-get update -qq > /dev/null
export DEBIAN_FRONTEND=noninteractive;apt-get update; apt-get install acl apt-utils attr autoconf bind9utils binutils bison build-essential ccache chrpath curl debhelper dnsutils docbook-xml docbook-xsl flex gcc gdb git glusterfs-common gzip heimdal-multidev hostname htop krb5-config krb5-user lcov libacl1-dev libarchive-dev libattr1-dev libavahi-common-dev libblkid-dev libbsd-dev libcap-dev libcephfs-dev libcups2-dev libdbus-1-dev libglib2.0-dev libgnutls28-dev libgpgme11-dev libicu-dev libjansson-dev libjs-jquery libjson-perl libkrb5-dev libldap2-dev liblmdb-dev libncurses5-dev libpam0g-dev libparse-yapp-perl libpcap-dev libpopt-dev libreadline-dev libsystemd-dev libtasn1-bin libtasn1-dev libunwind-dev lmdb-utils locales lsb-release make mawk mingw-w64 patch perl perl-modules pkg-config procps psmisc python3 python3-cryptography python3-dbg python3-dev python3-dnspython python3-gpg python3-iso8601 python3-markdown python3-matplotlib python3-pexpect python3-pyasn1 rsync sed  tar tree uuid-dev wget xfslibs-dev xsltproc zlib1g-dev -y

if [ "$?" = "0" ] ;

then

mount -o remount /

clear
figlet -c "Samba4Easy 6.0"
echo ""
echo""
echo -e " DESCOMPACTANDO ..."
sleep 3
cd /usr/src/
tar -xzvf samba-$VERSAO.tar.gz


clear
figlet -c "Samba4Easy 6.0"
echo ""
echo ""
echo -e " VOU COMECAR A COMPILACAO ..."
sleep 3

configurar 

else

exit ;

fi






}
baixarsamba () {

clear
figlet -c "Samba4Easy 6.0"
echo -e ""
echo -e ""
  cd /usr/src
  wget https://download.samba.org/pub/samba/stable/samba-$VERSAO.tar.gz
if [ "$?" = "0" ] ;

then

descompactar
   
else
   clear
figlet -c "Samba4Easy 6.0"
echo ""
   echo -e " \e[1;31m OOPS !!!! PARECE QUE ALGUMA COISA DEU ERRADO , TALVEZ VOCE ESTEJA SEM INTERNET OU ESCOLHEU VERSAO ERRADA \e[m ";
   echo -e " \e[1;31m OOPS !!!! EXECUTE O SCRIPT NOVAMETE  \e[m "; 
	echo ""
	echo ""
	echo -e "  SAINDO...";
   echo "";
   echo "";
   sleep 5;
  
   
fi




}




limpeza () {
clear
figlet -c "Samba4Easy 6.0"
echo -e " \e[1;31m ======================================================================== \e[m ";
echo ""
echo "LIMPANDO O SERVIDOR, AGUARDE ..."
echo ""
sleep 3
systemctl stop samba-ad-dc
apt-get remove winbind* -y 2> /dev/null
apt-get remove samba* -y 2> /dev/null
apt-get remove acl apt-utils attr autoconf bind9utils binutils bison build-essential ccache chrpath curl debhelper dnsutils docbook-xml docbook-xsl flex gcc gdb git glusterfs-common gzip heimdal-multidev hostname htop krb5-config krb5-user lcov libacl1-dev libarchive-dev libattr1-dev libavahi-common-dev libblkid-dev libbsd-dev libcap-dev libcephfs-dev libcups2-dev libdbus-1-dev libglib2.0-dev libgnutls28-dev libgpgme11-dev libicu-dev libjansson-dev libjs-jquery libjson-perl libkrb5-dev libldap2-dev liblmdb-dev libncurses5-dev libpam0g-dev libparse-yapp-perl libpcap-dev libpopt-dev libreadline-dev libsystemd-dev libtasn1-bin libtasn1-dev libunwind-dev lmdb-utils locales lsb-release make mawk mingw-w64 patch perl perl-modules pkg-config procps psmisc python3 python3-cryptography python3-dbg python3-dev python3-dnspython python3-gpg python3-iso8601 python3-markdown python3-matplotlib python3-pexpect python3-pyasn1 rsync sed  tar tree uuid-dev wget xfslibs-dev xsltproc zlib1g-dev -y
killall samba 2> /dev/null
systemctl stop "samba*"	 2> /dev/null
find /etc/systemd/system/ -type f -iname "samba-4*" -exec rm -v {} \; 2> /dev/null
find /etc -type f -iname krb5.conf -exec rm -v {} \; 2> /dev/null
find /etc/samba -type f -iname smb.conf -exec rm -v {} \; 2> /dev/null
find /opt -type f -iname smb.conf -exec rm -v {} \; 2> /dev/null
find / -type f -iname "*.ldb" -exec rm -v {} \; 2> /dev/null
find / -type f -iname "*.tdb" -exec rm -v {} \; 2> /dev/null
find / -type d -iname sysvol -exec rm -rfv {} \; 2> /dev/null
find /usr/src -type f -iname "samba-*" -exec rm -v {} \; 2> /dev/null
rm -rfv /opt/samba
clear
figlet -c "Samba4Easy 6.0"
echo ""
echo "CONCLUIDO !"
sleep 2
baixarsamba

}

teste2net() { 

ping -c 1 aws.amazon.com &> /dev/null

if [ "$?" = "0" ] ;

then
clear
echo ""
figlet -c "Samba4Easy 6.0"
echo -e '\E[32m' "	ESTAVA ENGANADO , INTERNET ... OK \e[m";
sleep 4
limpeza
return

else
clear
ping -c 4 astreinamentos.com.br 
echo ""
echo ""
ping -c 4 aws.amazon.com 
echo ""
echo ""
echo ""
clear
figlet -c "Samba4Easy 6.0"
echo ""
echo ""
echo -e "\e[1;31m REALMENTE SEU SERVIDOR NAO TEM INTERNET , NAO POSSO CONTINUAR \e[m"
echo -e "\e[1;31m EXECUTE O SCRIPT NOVAMENTE E PASSE AS INFORMACOES DE REDE CORRETAMENTE \e[m"
echo "";
echo "";
echo "SAINDO ...";
echo ""
echo ""
sleep 4;
exit;
fi
}


confrede() { 
clear
figlet -c "Samba4Easy 6.0"

echo ""
echo ""
echo -e "VERIFICANDO SE TEM INTERNET ..."
sleep 3
echo ""
cat << EOF > /etc/network/interfaces



# Gerado pelo script samba4easy - astreinamentos.com.br/samba4easy



# The loopback network interface

auto lo

iface lo inet loopback



allow-hotplug $LAN

iface $LAN inet static

address $IP

netmask $MASCARA

gateway $GATEWAY

EOF

ifdown $LAN

ifup $LAN

route add default gw $GATEWAY dev $LAN
hostname $NOMESRV

cat << EOF > /etc/hosts

127.0.0.1   localhost localhost.localdomain
$IP    $NOMESRV

EOF

cat << EOF > /etc/hostname


$NOMESRV

EOF

hostname $NOMESRV

chattr -i /etc/resolv.conf

cat << EOF > /etc/resolv.conf

nameserver $DNSEXTERNO
EOF

ping -c 1 google.com &> /dev/null

if [ "$?" = "0" ] ;

then


echo -e "\e[1;32m PARABENS !! SEU SERVIDOR ESTA CONECTADO A INTERNET PODEMOS CONTINUAR  \e[m";
sleep 5
limpeza

else
clear
figlet -c "Samba4Easy 6.0"
echo ""
echo ""
echo ""
echo -e " \e[1;31m Oooops !!!! PARECE QUE SEU SERVIDOR ESTA SEM INTERNET , MAS FAREI MAIS UMA VERIFICACAO PARA TER CERTERZA \e[m ";
echo "";
echo "";
sleep 10;
teste2net  

fi
}


obterinfo() {
clear
figlet -c "Samba4Easy 6.0"
echo ""
echo ""
echo  -e "##############################################################################"
echo  -e "#                                                                            #"
echo  -e "#                                                                            #"
echo  -e "#                                                                            #"
echo  -e "#                          	OLA ! VAMOS INICIAR                          #" 
echo  -e "#                                                                            #"
echo  -e "#             PARA INICIARMOS PRECISO DE ALGUMAS INFORMACOES                 #"
echo  -e "#                QUE SERAO SOLICITADAS NOS PASSOS SEGUINTES                  #"
echo  -e "#                DEPOIS TODO O PROCESSO SERA AUTOMATICO                       #"
echo  -e "#                                                                            #"
echo  -e "#                    PRESSIONE ENTER PARA CONTINUAR >>                       #"
echo  -e "#                                                                            #"
echo  -e "#                                                                            #"
echo  -e "#                                                                            #"
echo  -e "##############################################################################"
echo ""
echo ""
echo ""
echo ""
read
clear
figlet -c "Samba4Easy 6.0"
echo ""
echo ""
echo -e " \e[36;3mQUAL A VERSAO DO SAMBA 4 QUE VOCE QUER QUE EU INSTALE - EXEMPLO: 4.5.4 \e[m "
echo -e "\e[36;3mACESSE https://download.samba.org/pub/samba/stable/ E ESCOLHA A VERSAO \e[m"
echo "------------------------------------------------------------- "
read VERSAO
echo ""
echo -e '\e[36;3m' " QUAL IP PARA ESSE SERVIDOR ?   \e[m";
echo "------------------------------------------------------------- "
read IP
echo ""
echo -e '\e[36;3m' " QUAL MASCARA DE REDE ( EX. 255.255.255.0) ?   \e[m";
echo "------------------------------------------------------------- "
read MASCARA
echo ""
echo -e '\e[36;3m' " QUAL DNS EXTERNO (EX: 8.8.8.8) ?    \e[m";
echo "------------------------------------------------------------- "
read DNSEXTERNO
echo ""
echo -e '\e[36;3m' " QUAL e O SEU GATEWAY ?    \e[m";
echo "------------------------------------------------------------- "
read GATEWAY
echo ""
echo -e '\e[36;3m' "QUAL DESSAS INTEFACES ESTA CONECTADA NA SWITCH ?    \e[m";
ip -br link | awk '{print $1}' 
echo "------------------------------------------------------------- "
read LAN
echo ""
echo -e '\e[36;3m' "QUAL O NOME QUE VOCE QUER DAR A ESTE SERVIDOR ?  \e[m";
echo "------------------------------------------------------------- "
echo "( ex: SERVIDOR,SAMBA,SRVSAMBA,DC1,DCSAMBA)"
read NOMESRV
echo ""
echo -e '\e[36;3m' " Pasta a ser criada e compartilhada ?   \e[m";
echo -e '\e[36;3m' " Se nAo sabe responder digite /mnt/arquivos.   \e[m";
echo "------------------------------------------------------------- "
read PASTA
echo ""
echo -e '\e[36;3m' " Nome do compartilhamento? Ex: Dados  \e[m";
echo "------------------------------------------------------------- "
read SHARE
echo ""
echo -e " \e[36;3m QUAL E NOME FQDN DO DOMINIO ( EX: EXEMPLO.COM) \e[m "
echo "------------------------------------------------------------- "
read DOMFQDN
echo ""
echo -e " \e[36;3m QUAL E NOME NETBIOS DO DOMINIO ( EX: EXEMPLO) \e[m "
echo "------------------------------------------------------------- "
read DOMNETBIOS
echo ""
echo -e " \e[36;3m PARA QUAL DNS PUBLICO VOCE QUER ENCAMINHAR CONSULTA ? \e[m "
echo -e " \e[36;3m PARA DOMINIOS QUE NAO SEJA, O DOMINIO \e[m " $DOMFQDN
echo -e " \e[36;3m VOCE PODE USAR QUALQUER UM DESSES: \e[m "
echo ""
echo -e "  8.8.8.8"
echo -e "  208.67.220.220"
echo -e ""
echo -e " \e[36;3m AGORA DIGITE UM: \e[m "
echo "------------------------------------------------------------- "
read ENCDNS
echo ""
echo -e " \e[36;3m QUAL A SENHA DO ADMINISTRADOR" 
echo -e " \e[36;3m >>Voce nao vera nada enquanto digita<< \e[m "
echo -e " ( use letras, numeros e caracteres especiais - Ex:linux@2345) \e[m "
echo "------------------------------------------------------------- "
read -s SENHA
echo ""

clear
figlet -c "Samba4Easy 6.0"
echo ""
echo ""
echo -e "CONFIRA AS INFORMACOES POR FAVOR"
echo "------------------------------------------------------------- "
echo ""
echo ""
echo -e '\e[36;3m' " VERSAO DO SAMBA:  \e[m" $VERSAO
echo -e '\e[36;3m' " IP DO SERVIDOR:  \e[m" $IP
echo -e '\e[36;3m' " MASCARA DE REDE:  \e[m" $MASCARA
echo -e '\e[36;3m' " DNS EXTERNO:  \e[m" $DNSEXTERNO
echo -e '\e[36;3m' " GATEWAY DA REDE:  \e[m" $GATEWAY
echo -e '\e[36;3m' " INTERFACE NA SWITCH:  \e[m" $LAN
echo -e '\e[36;3m' " NOME DO SERVIDOR:  \e[m" $NOMESRV
echo -e '\e[36;3m' " PASTA COMPARTILHADA:  \e[m" $PASTA
echo -e '\e[36;3m' " NOME DO COMPARTILHAMENTO:  \e[m" $SHARE
echo -e '\e[36;3m' " NOME DO DOMINIO:  \e[m" $DOMFQDN
echo -e '\e[36;3m' " NOME NETBIOS:  \e[m" $DOMNETBIOS
echo -e '\e[36;3m' " DNS DE ENCAMINHAMENTO:  \e[m" $ENCDNS
echo -e '\e[36;3m' " SENHA DE ADMINISTRADOR:  \e[m" $SENHA
echo ""
echo ""
echo "------------------------------------------------------------- "
echo ""
echo -e "AS INFORMACOES ESTAO CORRETAS ? S/N" 
echo ""
read resposta

if [ $resposta = "s" ];
then
#!/bin/bash
clear
echo " "
echo "                          .MMMMMMM.        MMM                                 " 
echo "                          OMMMMMM,        =MMM=                                " 
echo "                         ~MMMMMMM         MMMM,                                " 
echo "                         MMMMMMM        .MMMMN                                 " 
echo "                        MMMMM        =MMM$                                     " 
echo "                        :MMMM        .MMM.                                     " 
echo "                           MM.        =MM                                      " 
echo "                                        ~~                                     " 
echo "   MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM~               "
echo "   MMMM                                                  MMMMMMMM              "  
echo "   MMMM                 PRONTO !!                        MMMMMMMM              " 
echo "   MMMM       AGORA DEIXA COMIGO E VA TOMAR UM CAFE      MMMMMMNN=      " 
echo "   MMMM      EM INSTANTES IREI IMPLANTAR O SEU SERVIDOR  MMMMMMMM      " 
echo "   MMMMMMM                                             MMMMMMMMMM      " 
echo "   MMMMMMMMMM?MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    " 
echo "   NMMMMMMMD   MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM=+8MMMMMMMMM:   " 
echo "   IMMMMMMMO   DMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.   .=MMMMMMM   " 
echo "   .MMMMMMMM   IMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM$.     ?MMMMMM   " 
echo "     .MMMMMMM    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM?     OMMMMMMMM    " 
echo "      :MMMMMMM.  .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    =MMMMMMMMD     " 
echo "       MMMMMMMZ..OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM..=MMMMMMMMMM~      " 
echo "        MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM        " 
echo "          .MMMMMMMM.    .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.              " 
echo "           ,MMMMMMMMM.  .NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMZ,                   " 
echo "                 IMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                              " 
echo "                  NMMMMMMMMMMMMMMMMMMMMMMMMMMM.                                "
echo "                    .MMMMMMMMMMMMMMMMMMMMMM8                                   "
echo "                                                                               "
sleep 6
confrede
else
clear
figlet -c "Ooops !!"
echo ""
echo ""
echo -e "\e[1;31m                        OK ! VAMOS COMECAR NOVAMENTE \e[m"
sleep 4
obterinfo
fi


}




clear
echo -e "carregando..."
DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND
apt-get install figlet -qq > /dev/null
clear
figlet -c "Samba4Easy 6.0"

echo ""
echo ""
echo -e " \e[1;31m ======================================================================== \e[m ";
echo "  =  ESSE SOFTWARE É DESENVOLVIDO E MANTIDO POR ALEXANDER SILVA          ="
echo "  =  VERSÕES ATUAIS DESSE SOFTWARE PODE SER OBTIDOS EM astreinamentos.com.br/samba4easy     ="
echo "  =  SE OBTEVE ESSE SOFTWARE DE ALGUMA OUTRA FORMA, E UMA COPIA ILEGAL   ="
echo -e " \e[1;31m ======================================================================== \e[m ";
echo ""
echo ""
echo "Direitos autorais (c) 2022, AP SILVA NEGOCIOS DIGITAIS - EIRELI "
echo "Todos os direitos reservados."
echo ""
echo ""
echo -e "VOCE ACEITA OS TERMOS ? s/n "
read resposta

if [ $resposta = "s" ];
then
clear
obterinfo		
else
exit
fi
