# CleanThatShit

CleanThatShit est un script Powershell permettant de purger le contenu de répertoires sur des serveurs Windows distant.

##Appel du script

Le script accepte deux manières de lui préciser les infos dont il a besoin.

Appel du script avec des arguments:


.\cleanThatShit.ps1 nom_du_serveur dossier_a_purger retention
 

+nom_du_serveur = string

+dossier_a_purger = chemin du type c:\test (en local) ou e$\test (à distance)

+retention = integer

Appel du script avec un fichier database passé en argument:


.\cleanThatShit.ps1 fichier.db
 

##Le fichier DB

Les fichiers .db présents dans le dossier database doivent avoir le format suivant:
nomDuServeur;repertoireAVider;NbJourRetention

Le fichier db contiendra explicitement tous les dossiers et sous dossier a traiter.
/!\ IMPORTANT: Si un dossier n’est pas dans la liste de manière explicite il ne sera pas traité.
Voici un exemple de contenu


nomDuServeur,repertoireAvider,NbJourRetention
localhost,C:\test,0
Serveur01,e$\REP\archive\backup,60
 

Si le serveur à purger est distant, vous devez entrer le dossier « e$\votre_dossier ».
Pour vous aider, vous devez prendre le même format que son chemin réseau .(ex:\\Serveur01\e$\REP\archive\backup).
Si le chemin du dossier à purger est local au script, vous pouvez spécifier le chemin de cette façon « c:\votre_dossier »

##Les logs

Deux types de logs: Logs HTML présents dans le dossier LOGS à la racine du répertoire où se trouve le script récapitulant les dossiers purgés ainsi que les dossiers ne l’étant pas.

Les logs de types transcript, présents dans le dossier Transcripts à la racine du répertoire où se trouve le script, permettant de loguer TOUT ce qui se passe lors de l’exécution du script, ce qui est entré en commande, les sorties etc.
