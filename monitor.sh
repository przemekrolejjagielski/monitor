#/bin/bash
#Codzienny raport pracy serwera
#Autor: Przemyslaw Jagielski
#Wersja 1.0
#Funkcje:
#*Badanie kondycji dysku SMART
#*Zbiorcza informacja o zużytej pojemności dysku


#Zmienne
DATA=`date +%F`
RAPORT=/root/raporty/raport-{$DATA}.txt
DYSKTMP=/tmp/dysk-{$DATA}.txt
HOSTNAME=/bin/hostname
REPORTER=postmaster@jagielski.ovh
ADMIN=przemek@jagielski.ovh
#Oprogramowanie
smart=/usr/sbin/smartctl

###################
#Rozpoczęcie pracy#
###################
touch $RAPORT
echo  "Dzienny raport z pracy serwera.
Dzień: $DATA" > $RAPORT
$HOSTNAME >> $RAPORT
######################
#Tablica danych SMART#
######################

touch $DYSKTMP
echo "Podsumowanie statystyk pracy dysku /dev/sda" >> $RAPORT
$smart -a /dev/sda > $DYSKTMP
grep ID $DYSKTMP >> $RAPORT
grep Raw_Read_Error_Rate $DYSKTMP >> $RAPORT
grep Throughput_Performance $DYSKTMP >> $RAPORT
grep Reallocated_Sector_Ct $DYSKTMP >> $RAPORT
grep Power_On_Hours $DYSKTMP >> $RAPORT
grep Spin_Retry_Count $DYSKTMP >> $RAPORT
grep Reallocated_Event_Count $DYSKTMP >> $RAPORT
grep Current_Pending_Sector $DYSKTMP >> $RAPORT
grep Offline_Uncorrectable $DYSKTMP >> $RAPORT
######################
#Analiza danych SMART#
######################
grep Power_On_Hours $RAPORT | cut -d ' ' -f10 $RAPORT
 if  [ $(grep Throughput_Performance $RAPORT | cut -d ' ' -f34) -gt 90 ]
        then echo "Wydajność dysku jest prawidłowa" >> $RAPORT
        else echo "Wydajność dysku spada. Podejmij szczegółową analizę SMART" >> $RAPORT
 fi
 if  [ $(grep Reallocated_Sector_Ct $RAPORT | cut -d ' ' -f36) -ge 0 ]
	then echo "W ciągu ostatniego czasu nie było operacji na sektorach" >> $RAPORT
	else echo "W ciągu ostatniego czasu dysk przeprowadzał interwencje na badsectorach!" >> $RAPORT
 fi
 if  [ $(grep Power_On_Hours $RAPORT | cut -d ' ' -f44) -le 1200000 ]
	then echo "Dysk nie przekracza czasu międzyawarayjnego" >> $RAPORT
	else echo "Dysk w niedługim czasie zostanie uszkodzony. Rozważ wymianę" >> $RAPORT
 fi
 if  [ $(grep Spin_Retry_Count test.txt | cut -d ' ' -f40) -ge 0 ]
	then echo "W ostatnim czasie nie podejmowano prób rozpędzania talerzy po niepowodzeniu" >> $RAPORT
	else echo "Niebezpieczeństwo uszkodzenia mechanicznego dysku wzrasta! Rozważ interwencje!" >> $RAPORT
 fi
 if [ $(grep Reallocated_Event_Count test.txt | cut -d ' ' -f33) -ge 0 ]
	then echo "W ostatnim czasie nie remapowano danych z badsectorów" >> $RAPORT
	else echo "UWAGA! Dokonywano remapowanie danych z badsectoru! Przeprowadź analizę dysku!"
 fi
 if [ $(grep Current_Pending_Sector test.txt | cut -d ' ' -f34) -ge 0 ]
	then echo "Obecnie żaden sektor nie oczekuje na zremapowanie" >> $RAPORT
	else echo "Istnieją badsectory, które oczekują na remaping! Podejmij interwencje w serwerowni!" >> $RPAORT
 fi
 if [ $(grep Offline_Uncorrectable test.txt | cut -d ' ' -f34) -ge 0 ]
	then echo "Na dysku obecnie nie ma uszkodzeń mechanicznych, które wymagałyby interwencji" >> $RAPORT
	else echo "Dysk wymaga interwencji! Podejmij odpowiednie działania!" >> $RAPORT
 fi

##################################
#Wysyłka rapotu do administratora#
##################################

(cat - $RAPORT)<<EoF | sendmail -f $REPORTER -i $ADMIN 
Subject: Raport dzienny $DATA
From: $REPORTER
To: $ADMIN

EoF
