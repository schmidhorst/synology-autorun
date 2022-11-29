# autorun
Scripts uitvoeren bij het aansluiten van externe opslag (USB / eSATA) op een Synology NAS. Typisch gebruik is het kopiëren of back-uppen van enkele bestanden. 
In Synologies Task Scheduler is er de mogelijkheid om getriggerde taken aan te maken, maar voor de trigger event is alleen Boot-up en Shutdown beschikbaar. Er zijn geen USB events beschikbaar. Dit tekort wordt gecompenseerd door deze tool.  

# installeer
* Download het *.spk-bestand van "Releases", "Assets" in Github en gebruik "Manual Install" in het Package Center.

Onder https://www.cphub.net/ in het Package Center zijn er versies voor oudere DSM-versies beschikbaar:
* DSM 7: eigenlijk nog steeds maar 1.8
* DSM 6: 1.7
* DSM 5: 1.6
* vlier: 1.3

Pakketten van derden worden beperkt door Synology in DSM 7. Aangezien autorun root-toestemming vereist 
toestemming nodig heeft om zijn werk te doen, is een extra handmatige stap vereist na de installatie.

SSH naar uw NAS (als admin gebruiker) en voer het volgende commando uit:

```shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
Alternatief voor SSH: 
Ga naar Control Panelel => Task Scheduler => Create => Scheduled Task => User-defined Script. In het tabblad "Algemeen" stelt u een willekeurige taaknaam in, selecteer 'root' als gebruiker. In het tabblad "Taakinstellingen" voert u in  
```shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
als "Opdracht uitvoeren". Sluit het af met OK. Als u nu tijdens de pckage-installatie wordt gevraagd om dat commando uit te voeren, ga dan naar de taakplanner, selecteer die taak en "Run" het. 

