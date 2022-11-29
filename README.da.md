# autorun
Udfører scripts, når der tilsluttes ekstern lagring (USB / eSATA) på en Synology NAS. Typisk brug er at kopiere eller sikkerhedskopiere nogle filer. 
I Synologies Task Scheduler er der mulighed for at oprette udløste opgaver, men for den udløsende begivenhed er kun opstart og nedlukning tilgængelige. Der er ingen USB-hændelser tilgængelige. Denne mangel kompenseres af dette værktøj.  

# install
* Download *.spk-filen fra "Releases", "Assets" i Github og brug "Manual Install" i Package Center.

Under https://www.cphub.net/ i Package Center er der ældre versioner for ældre DSM-versioner tilgængelige:
* DSM 7: faktisk stadig kun 1.8
* DSM 6: 1.7
* DSM 5: 1.6
* elder: 1.3

Tredjepartspakker er begrænset af Synology i DSM 7. Da autorun kræver root 
tilladelse for at udføre sit arbejde, er der behov for et ekstra manuelt trin efter installationen.

SSH til din NAS (som en admin-bruger) og udfør følgende kommando:

````shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
Alternativ til SSH: 
Gå til Kontrolpanel => Opgaveskemalægger => Opret => Planlagt opgave => Brugerdefineret script. I fanen "General" indstiller du et vilkårligt opgavenavn, og vælger "root" som bruger. I fanen "Task Settings" (Indstillinger for opgaver) indtastes  
```shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
som "Kør kommando". Afslut den med OK. Når du bliver bedt om at udføre denne kommando nu under pckage-installationen, skal du gå til opgaveplanlæggeren, vælge denne opgave og "Kør" den. 

