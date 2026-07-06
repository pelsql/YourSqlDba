---
layout: default
title: Solutions de sauvegarde externes
parent: Maintenance
grand_parent: YourSqlDba documentation (fr)
nav_order: 30
---

# Solutions de sauvegarde externes

Un produit de sauvegarde externe peut remplacer la partie sauvegarde de YourSqlDba pendant que
YourSqlDba continue d’effectuer les vérifications d’intégrité, les mises à jour de statistiques et la maintenance des index.
Ceci est utile lorsque le produit externe fournit des fonctionnalités de stockage qui dépendent de l’émission
de ses propres commandes de sauvegarde SQL Server, comme la déduplication au niveau bloc.

CommVault est utilisé ici comme exemple concret. Les capacités du produit, les chemins de commande,
les planifications et les économies de stockage observées dépendent de la version installée et de l’environnement.

## Séparer la maintenance des sauvegardes

Configurez l’étape principale `Maint.YourSqlDba_DoMaint` sans mode de sauvegarde afin qu’elle continue d’effectuer
la maintenance non sauvegarde requise. Planifiez la sauvegarde complète externe après cette maintenance.

Les sauvegardes de journal de transactions doivent généralement continuer selon leur planification récurrente normale.
Laissez-les s’exécuter pendant la maintenance des index. Cela aide à contrôler la réutilisation du journal tandis que les
opérations de reconstruction et de réorganisation d’index génèrent des enregistrements de journal.

YourSqlDba ne réduit plus automatiquement les journaux après les sauvegardes de journal, et l’ancienne procédure
`Maint.ShrinkAllLogs` a été supprimée. Ne reproduisez pas l’étape de réduction obsolète post-sauvegarde de la documentation
ancienne. Les fichiers journaux doivent normalement être dimensionnés pour la charge prévue ; investiguez une croissance anormale
au lieu de planifier des réductions de routine.

## Synchroniser une sauvegarde complète externe avec la maintenance

`Maint.SetSyncWith_YourSqlDba_DoMaint` attend que l’opération principale de maintenance libère son verrou d’application.
Une pré-tâche de sauvegarde externe peut appeler cette procédure avant de démarrer une sauvegarde complète.

La commande suivante illustre une instance SQL Server locale par défaut utilisant l’authentification Windows :

```bat
"C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\Sqlcmd.exe" -E -S . -d YourSqlDba -Q "EXEC Maint.SetSyncWith_YourSqlDba_DoMaint;"
```

Ajustez le chemin `sqlcmd` et le nom de l’instance `-S` pour l’environnement. Le compte exécutant la commande externe doit pouvoir
se connecter à SQL Server et exécuter la procédure.

Si le produit de sauvegarde partage une pré-tâche entre les sauvegardes complètes et de journal, n’appliquez l’attente que
pour la fenêtre de temps réservée exclusivement à la sauvegarde complète. Gardez cette fenêtre séparée des heures de début
récurrentes des sauvegardes de journal. Planifiez la sauvegarde complète externe avec un délai suffisant pour que
`Maint.YourSqlDba_DoMaint` démarre et acquière son verrou d’application.

Exemple avec une sauvegarde complète planifiée à 00:15 et aucune sauvegarde de journal planifiée de 00:14 à 00:29 :

```bat
"C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\Sqlcmd.exe" -E -S . -d YourSqlDba -Q "IF CONVERT(char(8), GETDATE(), 108) BETWEEN '00:14:00' AND '00:29:00' EXEC Maint.SetSyncWith_YourSqlDba_DoMaint;"
```

Le test temporel est seulement une solution d’intégration pour les produits qui ne disent pas à une pré-tâche partagée quel type de sauvegarde commence.
Adaptez-le aux planifications réelles ; ne copiez pas ces heures telles quelles.

## Restaurer des fichiers de sauvegarde CommVault

CommVault peut matérialiser des sauvegardes SQL Server sous forme de fichiers `.bak` plutôt que de restaurer directement une base. C'est une sauvegarde répartie sur plusieurs fichiers.
Ce genre de sauvegarde produit normalement plusieurs fichiers de famille de médias pour chaque sauvegarde complète, différentielle ou de journal.
Restaurer plusieurs jours peut donc nécessiter de nombreuses instructions `RESTORE` ordonnées.

L’exemple optionnel suivant analyse un dossier contenant des fichiers au format de nommage CommVault et génère la séquence de restauration correspondante :

[Voir ou télécharger `BuildRestoreFromCommVaultBackupFiles.sql`](../assets/examples/BuildRestoreFromCommVaultBackupFiles.sql)

{: .warning }
> Ce script est un exemple de documentation. Il n’est pas installé par YourSqlDba et ne fait pas partie du code produit YourSqlDba.
> Il est fourni tel quel et n’est pas validé pour chaque configuration CommVault. L’utilisateur est responsable de le tester dans un environnement non production
> et de vérifier chaque instruction `RESTORE` générée avant exécution.

### Exigences et hypothèses

L’exemple :

- nécessite SQL Server 2019 ou ultérieur car il utilise `sys.dm_os_enumerate_filesystem` ;
- nécessite une installation YourSqlDba compatible avec l’exemple pour ses collecteurs `RESTORE HEADERONLY` et `RESTORE FILELISTONLY` ;
- attend que le compte du moteur de base de données SQL Server ait un accès en lecture au dossier source ;
- suppose deux fichiers de famille de médias identifiés par `_1_` et `_2_` dans chaque nom de sauvegarde CommVault ;
- dépend du modèle de nommage de fichier CommVault utilisé dans l’exemple documenté ;
- génère, mais n’exécute pas, la séquence de restauration ;
- prend en charge une cible facultative point-in-time via `@StopAt` ;
- prend en charge jusqu’à trois substitutions source-vers-destination de chemins.

### Générer une séquence de restauration

```sql
Exec dbo.BuildRestoreFromBackupFiles
  @SourceFolder=N'P:\CommVaultRestore\Payroll'
, @DestinationDatabase=N'Payroll_RecoveryTest'
, @SystemName=N'Payroll'
, @pathRepFrom1=N'F:\Data\'
, @pathRepTo1=N'F:\Data\RecoveryTest\'
, @pathRepFrom2=N'L:\Data\'
, @pathRepTo2=N'L:\Data\RecoveryTest\'
, @pathRepFrom3=NULL
, @pathRepTo3=NULL
, @StopAt=N'2026-06-30 12:00:30';
```

Exécutez la partie installation de l’exemple dans une base utilitaire DBA plutôt que de l’ajouter à la base `YourSqlDba`.
Le jeu de résultats contient les parties d’instruction `RESTORE` générées. Inspectez la sauvegarde complète sélectionnée,
les fichiers de média, les chemins cibles, l’ordre de restauration et le positionnement de `STOPAT` avant exécution.

Pour une restauration simple à partir d’un seul fichier de sauvegarde autonome, préférez
[`Maint.RestoreDb`](delegated-database-management.md#delegated-duplication-and-restore-procedures).
