# autorun
Exekvera skript när du ansluter extern lagring (USB/eSATA) på en Synology NAS. Typisk användning är att kopiera eller säkerhetskopiera vissa filer. 
I Synologys Task Scheduler finns det möjlighet att skapa utlösta uppgifter, men för utlösande händelser finns endast Boot-up och Shutdown tillgängliga. Det finns inga USB-händelser tillgängliga. Denna brist kompenseras av det här verktyget.  

# installera
* Hämta *.spk-filen från "Releases", "Assets" i Github och använd "Manual Install" i Package Center.

Under https://www.cphub.net/ i Package Center finns äldre versioner för äldre DSM-versioner tillgängliga:
* DSM 7: faktiskt fortfarande bara 1.8
* DSM 6: 1.7
* DSM 5: 1.6
* elder: 1.3

Tredjepartspaket begränsas av Synology i DSM 7. Eftersom autorun kräver root 
för att utföra sitt arbete krävs ytterligare ett manuellt steg efter installationen.

SSH till din NAS (som adminanvändare) och utför följande kommando:

```shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
Alternativ till SSH: 
Alternativ till SSH: Gå till Kontrollpanelen => Aktivitetsschemaläggare => Skapa => Schemalagd aktivitet => Användardefinierat skript. På fliken "General" anger du ett valfritt uppgiftsnamn och väljer "root" som användare. På fliken "Task Settings" (Uppgiftsinställningar) anger du  
```shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
som "Körkommando". Avsluta det med OK. När du ombeds att utföra det kommandot nu under installationen av paketet går du till schemaläggaren, väljer den uppgiften och "kör" den. 

