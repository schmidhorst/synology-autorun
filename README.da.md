# autorun-pakke til Synology NAS
Udfører scripts, når der tilsluttes eksterne lagre (USB / eSATA) på en Synology NAS med DSM 7.x. Typisk brug er at kopiere eller sikkerhedskopiere nogle filer.
I Synologies Task Scheduler er der mulighed for at oprette udløste opgaver. Men for den udløsende begivenhed er der kun Boot-up og Shutdown tilgængelige. Der er ingen USB-hændelser tilgængelige. Denne mangel kompenseres af dette værktøj.

## [Licens](https://htmlpreview.github.io/?https://github.com/schmidhorst/synology-autorun/blob/main/package/ui/licence_dan.html)

## Ansvarsfraskrivelse og problemtracker
Du bruger alt her på egen risiko.
For problemer bedes du bruge [issue tracker](https://github.com/schmidhorst/synology-autorun/issues) med tysk eller engelsk sprog

# Installation
* Hent *.spk-filen fra ["Releases"](https://github.com/schmidhorst/synology-autorun/releases), "Assets" til din computer og brug "Manual Install" i pakkecenteret.

Tredjepartspakker er begrænset af Synology i DSM 7. Da autorun kræver root
tilladelse for at udføre sit arbejde, er et yderligere manuelt trin nødvendigt efter installationen.

SSH til din NAS (som en administratorbruger) og udfør følgende kommando:
````shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
Alternativ til SSH:
Gå til Kontrolpanel => Opgavestyring => Opret => Planlagt opgave => Brugerdefineret script. I fanen "General" indstiller du et vilkårligt opgavenavn, og vælger "root" som bruger. I fanen "Task Settings" (Indstillinger for opgaver) indtastes
````shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
som "Kør kommando". Afslut den med OK. Når du bliver bedt om at udføre denne kommando nu under pakkeinstallationen, skal du gå til opgaveplanlæggeren, vælge denne opgave og "Kør" den.

Under https://www.cphub.net/ i pakkecenteret er der [ældre versioner](https://github.com/reidemei/synology-autorun) for ældre DSM-versioner til rådighed:
* DSM 7: faktisk stadig kun 1.8
* DSM 6: 1.7
* DSM 5: 1.6
* elder: 1.3

## Credits og referencer
- Tak til [Jan Reidemeister](https://github.com/reidemei) for hans [Version 1.8](https://github.com/reidemei/synology-autorun) og hans [Licens](https://github.com/reidemei/synology-autorun/blob/main/LICENSE)
- Tak til [Synology-forumtråden om denne autorun-pakke](https://www.synology-forum.de/threads/autorun-fuer-ext-datentraeger.18360/)
- Tak til [toafez Tommes](https://github.com/toafez) og hans [Demopakke](https://github.com/toafez/DSM7DemoSPK)
- Tak til [geimist Stephan Geisler](https://github.com/geimist) og hit tip til at bruge [DeepL API](https://www.deepl.com/docs-api) for oversættelser til andre sprog.



Translated with www.DeepL.com/Translator (free version)