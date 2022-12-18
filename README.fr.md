# Paquet autorun pour Synology NAS
Exécute des scripts lors de la connexion de stockages externes (USB / eSATA) sur un Synology NAS avec DSM 7.x. L'utilisation typique est de copier ou de sauvegarder certains fichiers.
Dans le planificateur de tâches de Synology, il y a la possibilité de créer des tâches déclenchées. Mais pour l'événement déclencheur, seuls les événements Boot-up et Shutdown sont disponibles. Il n'y a pas d'événements USB disponibles. Ce déficit est compensé par cet outil.

### Disclaimer et Issue Tracker
Vous utilisez tout ici à vos propres risques.
Pour les problèmes, veuillez utiliser le [Issue Tracker] (https://github.com/schmidhorst/synology-autorun/issues) en allemand ou en anglais.

# Installation
* Téléchargez le fichier *.spk depuis ["Releases"](https://github.com/schmidhorst/synology-autorun/releases), "Assets" sur votre ordinateur et utilisez "Manual Install" dans le Package Center.

Les paquets tiers sont limités par Synology dans DSM 7. Puisque l'exécution automatique nécessite l'autorisation
pour effectuer son travail, une étape manuelle supplémentaire est nécessaire après l'installation.

SSH à votre NAS (en tant qu'utilisateur administrateur) et exécutez la commande suivante :
```shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
Alternative à SSH :
Allez dans Panneau de configuration => Planificateur de tâches => Créer => Tâche planifiée => Script défini par l'utilisateur. Dans l'onglet "Général", donnez un nom à la tâche, sélectionnez "root" comme utilisateur. Dans l'onglet "Paramètres de la tâche" entrez
```shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
comme "Exécuter la commande". Terminez en cliquant sur OK. Lorsque l'on vous demande d'exécuter cette commande maintenant pendant l'installation du paquet, allez dans le planificateur de tâches, sélectionnez cette tâche et "Exécutez-la".

Sous https://www.cphub.net/ dans le centre de paquets, il y a [elder versions] (https://github.com/reidemei/synology-autorun) pour les anciennes versions de DSM disponibles :
* DSM 7 : en fait toujours seulement 1.8
* DSM 6 : 1.7
* DSM 5 : 1.6
* elder : 1.3

## Crédits et références
- Merci à [Jan Reidemeister](https://github.com/reidemei) pour sa [Version 1.8](https://github.com/reidemei/synology-autorun) et sa [Licence](https://github.com/reidemei/synology-autorun/blob/main/LICENSE)
- Merci à [Synology Forum Thread about that autorun package](https://www.synology-forum.de/threads/autorun-fuer-ext-datentraeger.18360/)
- Merci à [toafez Tommes](https://github.com/toafez) et à son [Demo Package](https://github.com/toafez/DSM7DemoSPK)
- Merci à [geimist Stephan Geisler](https://github.com/geimist) et à son conseil d'utiliser l'[API DeepL](https://www.deepl.com/docs-api) pour les traductions dans d'autres langues.



Traduit avec www.DeepL.com/Translator (version gratuite)