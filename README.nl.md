# autorun pakket voor Synology NAS
Voert scripts uit bij het aansluiten van externe opslagmedia (USB / eSATA) op een Synology NAS met DSM 7.x. Typisch gebruik is het kopiëren of back-uppen van bepaalde bestanden.
In Synologies Task Scheduler is er de mogelijkheid om getriggerde taken aan te maken. Maar voor de trigger event zijn alleen Boot-up en Shutdown beschikbaar. Er zijn geen USB events beschikbaar. Deze tekortkoming wordt gecompenseerd door deze tool.

## [Licentie](https://htmlpreview.github.io/?https://github.com/schmidhorst/synology-autorun/blob/main/package/ui/licence_nld.html)

## Disclaimer en Issue Tracker
U gebruikt alles hier op eigen risico.
Gebruik voor problemen de [issue tracker](https://github.com/schmidhorst/synology-autorun/issues) met Duitse of Engelse taal.

# Installatie
* Download het *.spk bestand van ["Releases"](https://github.com/schmidhorst/synology-autorun/releases), "Assets" naar uw computer en gebruik "Manual Install" in het Package Center.

Pakketten van derden worden beperkt door Synology in DSM 7. Aangezien autorun root-toestemming vereist om
toestemming nodig heeft om zijn werk te doen, is een extra handmatige stap vereist na de installatie.

SSH naar uw NAS (als admin-gebruiker) en voer het volgende commando uit:
```shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
Alternatief voor SSH:
Ga naar Configuratiescherm => Taakplanner => Maken => Geplande taak => Door gebruiker gedefinieerd script. Stel in het tabblad "Algemeen" een willekeurige taaknaam in, selecteer 'root' als gebruiker. In het tabblad "Taakinstellingen" voert u in
```shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
als "Opdracht uitvoeren". Sluit het af met OK. Als u nu tijdens de pakketinstallatie gevraagd wordt om dat commando uit te voeren, ga dan naar de taakplanner, selecteer die taak en "Run" hem.

Onder https://www.cphub.net/ in het Package Center zijn [oudere versies](https://github.com/reidemei/synology-autorun) voor oudere DSM-versies beschikbaar:
* DSM 7: eigenlijk nog steeds maar 1.8
* DSM 6: 1.7
* DSM 5: 1.6
* vlier: 1.3

## Credits en Referenties
- Met dank aan [Jan Reidemeister](https://github.com/reidemei) voor zijn [Versie 1.8](https://github.com/reidemei/synology-autorun) en zijn [Licentie](https://github.com/reidemei/synology-autorun/blob/main/LICENSE)
- Met dank aan de [Synology Forum Thread over dat autorun pakket](https://www.synology-forum.de/threads/autorun-fuer-ext-datentraeger.18360/)
- Met dank aan [toafez Tommes](https://github.com/toafez) en zijn [Demopakket](https://github.com/toafez/DSM7DemoSPK)
- Met dank aan [geimist Stephan Geisler](https://github.com/geimist) en de tip om de [DeepL API](https://www.deepl.com/docs-api) te gebruiken voor vertalingen naar andere talen.

