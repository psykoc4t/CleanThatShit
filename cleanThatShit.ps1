# ----------------------------------------------------------------------------------
# NOM: cleanThatShit.ps1
# AUTEUR: Antonio de Almeida
# Version: 1.5

#
# COMMENTAIRES:
# Permet de purger les répertoires définis dans le fichier db ou passes en argument
# ----------------------------------------------------------------------------------



function Remove([parameter(Mandatory)][string] $server, [parameter(Mandatory)][string] $Path, [parameter(Mandatory)][DateTime] $DeadLine, [switch] $WhatIf)
{
        #formatage du nom du dossier (si local c: si distant c$)
        if($path -match ".:"){ #si la variable contient : en 2eme caractere
        $connectionString = $path
        }else{$connectionString = "\\$server\$Path"}
    
        write-host Serveur : $server
        write-host Dossier a purger : $Path
        write-host Supprimer tout avant le : $DeadLine

            #Le select last 10 permet de ne travailler que sur les 10 dernier fichier, afin d'éviter de supprimer le seul contenu restant si il n'ya plus d'archive depuis
            #un certain temps.
            #Le sort descending permet de trier les fichiers les plus vieux en premier, ceci pour un souci de performance lors du traitement
            
            
            Get-ChildItem -Path $connectionString -Recurse -Force -File | select -last 10 | sort -descending | Where-Object { $_.CreationTime -lt $DeadLine } | 
                ForEach-Object {  
                    Remove-Item -Path $_.FullName -Force -WhatIf:$WhatIf
                    if ($? -eq $True) {Write-Output $_.FullName}
					report -PathToLog $path -Server $server

                }

           
			stop-transcript
			exit 0
            
}

function about()
{
    write-host 'CleanThatShit starting...'
}

#Permet de recupérer tout le contenu du fichier de conf
function getConfigCleanThatShit([parameter(Mandatory)][string] $dbFileName)
{
	
	$filepath = ".\database\$dbFileName"
	#Test si notre premier argument passe au script est un fichier, puis retour...
	if (Test-Path -Path $filepath)
	{
		$dbConfigFileContent = Import-CSV $filepath
		return $dbConfigFileContent
	}
	else { return "NotAFile" }
	
	
}

function processing([object]$confFileContent, [string]$argServerName, [string]$argDirToPurge, [string]$argKeep)
{
	#Test quel type de parametre est recu a la fonction (est-ce un fichier ou des infos passees en argument)
	if ($confFileContent)
	{
		#Instantiation de variables
		$MesServeurs = @()
		
		
		
		#On recupère la liste de tous les serveurs a traiter               
		$confFileContent | ForEach-Object {
			$MesServeurs += $_.nomDuServeur
		}
		
		ForEach ($MonServeur in $MesServeurs)
		{
			#Recupération des infos d'un serveurs précis
			$MonServeurInfo = $confFileContent | Where-Object { $_.nomDuServeur -eq $MonServeur } |
			#Recupération des champs précis pour un serveur donné
			ForEach-Object{
				$MonDossier += $_.repertoireAvider
				$MaRetention += $_.NbJourRetention
				#write-host 'Dossier pour ' $MonServeur $MonDossier
				#write-host 'Exclusions pour ' $MonServeur $MesExclusions.split('|')
				#write-host 'Retention pour ' $MonServeur $MaRetention
				
				
				Remove -server $MonServeur -Path $MonDossier -DeadLine (get-date).AddDays(- $MaRetention) #-WhatIf
				
				clear-variable MonDossier
				clear-variable MaRetention
			}
			
		}
	}
	else
	{	
		Remove -server $argServerName -Path $argDirToPurge -DeadLine (get-date).AddDays(- $argKeep) #-WhatIf
	}
	
	
	
	
}

function report([parameter(Mandatory)][string] $PathToLog, [parameter(Mandatory)][string] $server)
{
       #formatage du nom du dossier (si local c: si distant c$)
        if($PathToLog -match ".:"){ #si la variable contient : en 2eme caractere
        $connectionString = $PathToLog
        }else{$connectionString = "\\$server\$PathToLog"}

    #$connectionString = "\\$server\$PathToLog"

    $rootPath = (get-item $connectionString ).parent.FullName

    $timestamp = Get-Date -f dd-MM-yyyy_HH_mm_ss

    $LogsPath = ".\logs"

    If(!(test-path $LogsPath))
    {
    New-Item -ItemType Directory -Force -Path $LogsPath
    }

    [System.Collections.ArrayList]$ArrayList = Get-ChildItem $rootPath | 
       Where-Object {$_.PSIsContainer} | 
       Foreach-Object {$_.Name}

  
    #Creation du tableau
    $a = "<style>"
    $a = $a + "BODY{background-color:LightGoldenRodYellow;}"
    $a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
    $a = $a + "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;}"
    $a = $a + "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;}"
    $a = $a + "</style>"


   #A cause de l'erreur: "La collection a été modifiée ; l'opération d'énumération peut ne pas s'exécuter"
   #Qui veux dire que la seléction d'un item pose problème car nous supprimons par la suite certain items
   #de l'arraylist. Nous allons donc recupérer le contenu et le stocker dans un autre arraylist pour effectuer
   #notre comparaison.

   [System.Collections.ArrayList]$ArrayListToDelete = @()

   #if arraylist est vide...
   if(!$ArrayList)
   {
    exit
   }else{


           foreach($element in $ArrayList)
           {

                $formatedElement = $rootPath+'\'+$element

                if($formatedElement -eq $connectionString)
                {
                    $ArrayListToDelete += $ArrayList.IndexOf($element)
                }
           }
   
           ForEach($IndexToDelete in $ArrayListToDelete)
           {
                $ArrayList.removeAt($IndexToDelete)
           }


   #LOGS sont forme de fichier plat
   #$output = $server +" " +$PathToLog + " was purged." + " Folders not purged: " + $ArrayList
   #[System.Collections.ArrayList]$outputArrayList = @($server,$PathToLog,$ArrayList,"--------------------------------------------------")
   #$outputArrayList | Add-Content .\logs\rapportCleanThatShit_$timestamp.log

   #Manipulation d'objet
   #Création d'un objet pour la génération du rapport
            [string]$FoldersNotPurged = $ArrayList           
            $myServerObject = New-Object System.Object
            $myServerObject | Add-Member -type NoteProperty -name Name -Value $server
            $myServerObject | Add-Member -type NoteProperty -name PurgedFolder -Value $Path
            $myServerObject | Add-Member -type NoteProperty -name NotPurgedFolders -value $FoldersNotPurged.Replace(' ', ";")#`r`n

    #Création du dossier individuel de log
    $ServerLogFolder = Get-Date -f dd-MM-yyyy_HH_mm
    $Date = Get-Date -format 'd  MMM yyyy a HH:mm'
    If(!(test-path ".\logs\$server\$ServerLogFolder"))
    {
    New-Item -ItemType Directory -Force -Path ".\logs\$server\$ServerLogFolder\"
    }
    $myServerObject | Select-Object Name, PurgedFolder, NotPurgedFolders | ConvertTo-HTML -head $a -body "<H2>Rapport de purge CleanThatShit pour le serveur $server - Le $Date </H2>"| Out-File .\logs\$server\$ServerLogFolder\rapportCleanThatShit_$timestamp.html
		
		Write-Host fin
		stop-transcript
		exit 0
    }

}

################################
# DEBUT DES APPELS DE FONCTION #
################################
cls
$trscptTmstp = Get-Date -f dd-MM-yyyy_HH_mm_ss
start-transcript -path .\transcripts\Transcript_$trscptTmstp.txt -noclobber
about

#Recuperation du parametre passe en appel de script
$dbFile = $args[0]

#Test d'au moins 1 agument passe au script
if($args.Count -lt 1)
{
		Get-Date -uformat "%Hh%M(%S) : ERR. : Argument manquant'"
	stop-transcript
	exit 1
}

#Lecture du fichier de conf
$confFileContent = getConfigCleanThatShit($dbFile)

#Test si args[0] n'est PAS un fichier, recuperation des arguments si non utilisation d'un fichier DB: nom du serveur, repertoire a purger et retention
if ($confFileContent -eq "NotAFile")
{
		if ($args.Count -lt 3)
		{
			Get-Date -uformat "%Hh%M(%S) : ERR. : Argument manquant'"

		stop-transcript
			exit 1
		}
	
	#Donc, gerer les arguments serveur, repertoire et retention
	$serverName = $dbFile
	$dirToPurge = $args[1]
	$keep = $args[2]
	
	#Appel de la fonction processing avec passage en parametre les arguments recus
	processing -argServerName $serverName -argDirToPurge $dirToPurge -argKeep $keep
}
else
{
	processing($confFileContent)
}