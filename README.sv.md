# Autostartpaket för Synology NAS
Exekverar skript när externa lagringsenheter (USB/eSATA) ansluts till en Synology NAS med DSM 7.x. Typiskt användningsområde är att kopiera eller säkerhetskopiera vissa filer.
I Synologies Task Scheduler finns det möjlighet att skapa utlösta uppgifter. Men för den utlösande händelsen finns det bara Boot-up och Shutdown tillgängliga. Det finns inga USB-händelser tillgängliga. Denna brist kompenseras av det här verktyget.

## Ansvarsfriskrivning och problemspårare
Du använder allt här på egen risk.
För problem vänligen använd [issue tracker] (https://github.com/schmidhorst/synology-autorun/issues) på tyska eller engelska.

# Installation
* Hämta *.spk-filen från ["Releases"](https://github.com/schmidhorst/synology-autorun/releases), "Assets" till din dator och använd "Manual Install" i Package Center.

Tredjepartspaket är begränsade av Synology i DSM 7. Eftersom autorun kräver root
behörighet för att utföra sitt arbete krävs ytterligare ett manuellt steg efter installationen.

SSH till din NAS (som adminanvändare) och utför följande kommando:
````shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
Alternativ till SSH:
Gå till Kontrollpanelen => Aktivitetsschemaläggare => Skapa => Schemalagd aktivitet => Användardefinierat skript. På fliken "General" anger du ett namn på uppgiften och väljer "root" som användare. På fliken "Task Settings" (Uppgiftsinställningar) anger du
````shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
som "Körkommando". Avsluta det med OK. När du ombeds att utföra det kommandot nu under paketinstallationen går du till schemaläggaren, väljer den uppgiften och "Kör" den.

Under https://www.cphub.net/ i Package Center finns [elder versions](https://github.com/reidemei/synology-autorun) för äldre DSM-versioner tillgängliga:
* DSM 7: faktiskt fortfarande bara 1.8.
* DSM 6: 1.7
* DSM 5: 1.6
* elder: 1.3

## Krediter och referenser
- Tack till [Jan Reidemeister](https://github.com/reidemei) för hans [Version 1.8](https://github.com/reidemei/synology-autorun) och hans [Licens](https://github.com/reidemei/synology-autorun/blob/main/LICENSE).
- Tack till [Synology Forum Thread om det där autorun-paketet](https://www.synology-forum.de/threads/autorun-fuer-ext-datentraeger.18360/)
- Tack till [toafez Tommes](https://github.com/toafez) och hans [Demopaket](https://github.com/toafez/DSM7DemoSPK)
- Tack till [geimist Stephan Geisler](https://github.com/geimist) och träffade tipset att använda [DeepL API](https://www.deepl.com/docs-api) för översättningar till andra språk.


