# autorun
Exécuter des scripts lors de la connexion d'un stockage externe (USB / eSATA) sur un Synology NAS. L'utilisation typique est la copie ou la sauvegarde de certains fichiers. 
Dans le planificateur de tâches de Synology, il y a la possibilité de créer des tâches déclenchées, mais pour l'événement déclencheur, seuls les Boot-up et Shutdown sont disponibles. Il n'y a pas d'événements USB disponibles. Ce déficit est compensé par cet outil.  

# Installation
* Téléchargez le fichier *.spk depuis "Releases", "Assets" sur Github et utilisez "Manual Install" dans le Package Center.

Sous https://www.cphub.net/ dans le Centre de Paquets, il y a des anciennes versions pour les anciennes versions de DSM disponibles :
* DSM 7 : en fait toujours seulement 1.8
* DSM 6 : 1.7
* DSM 5 : 1.6
* elder : 1.3

Les paquets tiers sont limités par Synology dans DSM 7. Puisque l'exécution automatique nécessite l'autorisation de root 
pour effectuer son travail, une étape manuelle supplémentaire est nécessaire après l'installation.

SSH à votre NAS (en tant qu'utilisateur administrateur) et exécutez la commande suivante :

``shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
Alternative à SSH : 
Allez dans le panneau de configuration => Planificateur de tâches => Créer => Tâche planifiée => Script défini par l'utilisateur. Dans l'onglet "Général", donnez un nom à la tâche, sélectionnez "root" comme utilisateur. Dans l'onglet "Task Settings" entrez  
``shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
comme "Exécuter la commande". Terminez en cliquant sur OK. Si l'on vous demande d'exécuter cette commande maintenant pendant l'installation du paquet, allez dans le planificateur de tâches, sélectionnez cette tâche et "Exécutez-la". 

