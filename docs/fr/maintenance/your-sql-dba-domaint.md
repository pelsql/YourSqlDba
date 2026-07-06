---
layout: default
title: Maint.YourSqlDba_DoMaint
parent: Maintenance
grand_parent: YourSqlDba documentation (fr)
nav_order: 10
---

# Maint.YourSqlDba_DoMaint

`Maint.YourSqlDba_DoMaint` est la procédure stockée principale utilisée pour la maintenance régulière de YourSqlDba.
Elle est normalement appelée depuis les étapes SQL Agent ; l’exécution manuelle est réservée aux tests,
au dépannage ou aux opérations ponctuelles.

Utilisez cette procédure pour définir :

- quelles actions de maintenance sont effectuées ;
- quelles bases de données sont incluses ou exclues ;
- où les fichiers de sauvegarde sont écrits ;
- combien de temps les fichiers de sauvegarde sont conservés ;
- si des sauvegardes sont restaurées sur un miroir ou un serveur de standby ;
- comment les résultats de maintenance sont rapportés.

## Table des matières
{: .no_toc .text-delta }

1. TOC
{:toc}

## Modèle d’exécution

`Maint.YourSqlDba_DoMaint` est conçu pour être le point d’entrée principal des opérations de maintenance automatique.
Au début d’une exécution, YourSqlDba crée un contexte de maintenance et enregistre les paramètres de la procédure dans ses tables d’historique.
Ce contexte est utilisé par les procédures appelées plus tard dans l’exécution, et par les outils de rapport une fois l’exécution terminée.

La procédure effectue ensuite les actions sélectionnées, telles que :

- suppression des anciens fichiers de sauvegarde ;
- exécution des vérifications d’intégrité ;
- mise à jour des statistiques ;
- réorganisation ou reconstruction des index ;
- création de sauvegardes complètes, différentielles ou de journal de transactions ;
- restauration optionnelle des sauvegardes sur un serveur miroir ou de standby.

La procédure coordonne également l’exécution de la maintenance avec un verrou d’application afin que d’autres processus intégrés à YourSqlDba puissent se synchroniser avec la maintenance régulière.

## Appels typiques

La maintenance complète quotidienne active généralement les vérifications d’intégrité, les mises à jour des statistiques,
la maintenance des index et les sauvegardes complètes. Ces exemples reflètent les tâches initiales par défaut pour la maintenance complète et les sauvegardes de journal :

```sql
EXEC Maint.YourSqlDba_DoMaint
    @oper = N'YourSQLDba_Operator',
    @MaintJobName = N'YourSQLDba: DoInteg,DoUpdateStats,DoReorg,Full backups',
    @DoInteg = 1,
    @DoUpdStats = 1,
    @DoReorg = 1,
    @DoBackup = N'F',
    @FullBackupPath = N'D:\SQLBackups',
    @LogBackupPath = N'D:\SQLBackups',
    @FullBkpRetDays = 1,
    @LogBkpRetDays = 8;
```

Les sauvegardes fréquentes du journal utilisent généralement le même appel de procédure avec
`@DoBackup = N'L'` :

```sql
EXEC Maint.YourSqlDba_DoMaint
    @oper = N'YourSQLDba_Operator',
    @MaintJobName = N'YourSQLDba: Log backups',
    @DoBackup = N'L';
```

## Paramètres principaux

| Paramètre | Type | Valeur par défaut | Description |
| --- | --- | --- | --- |
| `@oper` | `nvarchar(200)` | Requis | Opérateur SQL Agent utilisé pour les notifications de maintenance. |
| `@MaintJobName` | `nvarchar(200)` | `Ad-Hoc Job` | Nom de la tâche stocké dans l’historique et les rapports de maintenance. |
| `@DoInteg` | `int` | `0` | Exécute les vérifications d’intégrité lorsqu’il vaut `1`. |
| `@DoUpdStats` | `int` | `0` | Met à jour les statistiques de l’optimiseur lorsqu’il vaut `1`. |
| `@DoReorg` | `int` | `0` | Réorganise ou reconstruit sélectivement les index lorsqu’il vaut `1`. |
| `@DoBackup` | `nvarchar(5)` | Chaîne vide | Mode de sauvegarde : `F`, `D`, `L`, ou vide pour aucune sauvegarde. |
| `@FullBackupPath` | `nvarchar(512)` | `NULL` | Répertoire utilisé pour les fichiers de sauvegarde complète et différentielle. |
| `@LogBackupPath` | `nvarchar(512)` | `NULL` | Répertoire utilisé pour les fichiers de sauvegarde de journal de transactions. |
| `@TimeStampNamingForBackups` | `int` | `1` | Ajoute un horodatage aux noms de fichiers de sauvegarde lorsqu’il vaut `1`. |
| `@FullBkExt` | `nvarchar(7)` | `BAK` | Extension de fichier utilisée pour les sauvegardes complètes et différentielles. |
| `@LogBkExt` | `nvarchar(7)` | `TRN` | Extension de fichier utilisée pour les sauvegardes de journal. |
| `@FullBkpRetDays` | `int` | `NULL` | Nombre de jours de conservation des anciens fichiers de sauvegarde complète. `NULL` désactive le nettoyage. |
| `@LogBkpRetDays` | `int` | `NULL` | Nombre de jours de conservation des anciens fichiers de sauvegarde de journal. `NULL` désactive le nettoyage. |
| `@NotifyMandatoryFullDbBkpBeforeLogBkp` | `int` | `1` | Signale une erreur lorsqu’une sauvegarde de journal ne peut pas s’exécuter faute de sauvegarde complète. |
| `@BkpLogsOnSameFile` | `int` | `1` | Utilise le même fichier de sauvegarde de journal après une sauvegarde complète lorsqu’il vaut `1`; crée un nouveau fichier à chaque exécution lorsqu’il vaut `0`. |
| `@SpreadUpdStatRun` | `int` | `7` | Étale les mises à jour des statistiques sur plusieurs exécutions de maintenance. |
| `@SpreadCheckDb` | `int` | `7` | Étale les vérifications DBCC complètes sur plusieurs exécutions. |
| `@ConsecutiveDaysOfFailedBackupsToPutDbOffline` | `int` | `9999` | Seuil de dernier recours pour mettre une base hors ligne après des sauvegardes complètes échouées sur des jours consécutifs. Voir [l’avertissement sur les bases hors ligne et la procédure de récupération](../diagnostics.md#databases-taken-offline-by-yoursqldba) avant de diminuer cette valeur. |
| `@MirrorServer` | `sysname` | Chaîne vide | Instance SQL optionnelle pour la restauration automatique des sauvegardes. |
| `@MigrationTestMode` | `int` | `0` | Modifie le comportement du miroir pour supporter les tests de migration. |
| `@ReplaceSrcBkpPathToMatchingMirrorPath` | `nvarchar(max)` | Chaîne vide | Réécrit les chemins de sauvegarde vus depuis le serveur miroir. |
| `@ReplacePathsInDbFilenames` | `nvarchar(max)` | Chaîne vide | Réécrit les chemins de fichiers de base de données lors de la restauration sur le serveur miroir. |
| `@IncDb` | `nvarchar(max)` | Chaîne vide | Inclut les bases de données correspondant aux motifs fournis. |
| `@ExcDb` | `nvarchar(max)` | Chaîne vide | Exclut les bases de données correspondant aux motifs fournis. |
| `@ExcDbFromPolicy_CheckFullRecoveryModel` | `nvarchar(max)` | Chaîne vide | Exclut les bases de données de la règle de vérification du mode de récupération complète. |
| `@EncryptionAlgorithm` | `nvarchar(10)` | Chaîne vide | Algorithme de chiffrement de sauvegarde. |
| `@EncryptionCertificate` | `nvarchar(100)` | Chaîne vide | Certificat utilisé pour les sauvegardes chiffrées. |

## Actions de maintenance

Les actions de maintenance sont contrôlées par des paramètres indépendants. Cela rend possible l’utilisation d’une seule procédure pour plusieurs tâches SQL Agent ou étapes de tâche.

| Paramètre | Action lorsqu’il est activé |
| --- | --- |
| `@DoInteg = 1` | Exécute des vérifications d’intégrité de base de données. |
| `@DoUpdStats = 1` | Met à jour les statistiques de l’optimiseur. |
| `@DoReorg = 1` | Optimise les index nécessitant une maintenance. |
| `@DoBackup = N'F'` | Exécute des sauvegardes complètes et une première sauvegarde consécutive du journal de transaction. |
| `@DoBackup = N'D'` | Exécute des sauvegardes différentielles. |
| `@DoBackup = N'L'` | Exécute des sauvegardes de journal de transactions. |

Ces actions peuvent être combinées. La tâche de maintenance complète par défaut combine généralement
les vérifications d’intégrité, les mises à jour des statistiques, la maintenance des index et les sauvegardes complètes.

Si la fenêtre de maintenance est trop courte pour toutes les actions, séparez le travail en étapes de tâche distinctes ou en tâches distinctes.

{: .warning }
> Les erreurs d’intégrité et un nombre de jours consécutifs de sauvegardes complètes échouées peuvent amener YourSqlDba à mettre des bases concernées hors ligne.
> Si un problème commun affecte plusieurs bases, cela peut les rendre indisponibles ensemble.
> Voir [Bases de données mises hors ligne par YourSqlDba](../diagnostics.md#databases-taken-offline-by-yoursqldba) avant de configurer le seuil d’échec de sauvegarde.

## Mode de sauvegarde

`@DoBackup` contrôle l’opération de sauvegarde :

| Valeur | Opération |
| --- | --- |
| `F` | Sauvegardes complètes. YourSqlDba effectue également une sauvegarde de journal initiale lorsque cela est applicable. |
| `D` | Sauvegardes différentielles. |
| `L` | Sauvegardes de journal de transactions. |
| Chaîne vide | Aucune opération de sauvegarde. |

Pour les sauvegardes de journal, `@FullBackupPath` et `@LogBackupPath` ne sont généralement pas nécessaires.
YourSqlDba dérive en général l’emplacement des sauvegardes de journal à partir du dernier ensemble de fichiers de sauvegarde complète ou différentielle.

### Sauvegardes complètes et différentielles

Les sauvegardes complètes et différentielles utilisent `@FullBackupPath` et l’extension définie par `@FullBkExt`.

Lorsque `@TimeStampNamingForBackups = 1`, les fichiers de sauvegarde incluent un horodatage dans leur nom.
Cela permet au nettoyage de rétention de supprimer les fichiers plus anciens tout en préservant les jeux de sauvegarde récents.

Lorsque `@TimeStampNamingForBackups = 0`, les noms de fichiers de sauvegarde sont réutilisés.
Cela peut être utile avec des outils de déduplication, mais cela change le sens pratique de la rétention de la sauvegarde, car les fichiers plus anciens sont écrasés au lieu de s’accumuler.

### Sauvegardes de journal de transactions

Les sauvegardes de journal de transactions utilisent l’emplacement de sauvegarde de journal enregistré par la dernière sauvegarde complète ou différentielle.

`@BkpLogsOnSameFile` contrôle la façon dont les fichiers de sauvegarde de journal sont écrits :

| Valeur | Comportement |
| --- | --- |
| `1` | Les sauvegardes de journal sont ajoutées au même fichier de sauvegarde de journal associé à l’ensemble de sauvegarde en cours. |
| `0` | Chaque sauvegarde de journal crée un fichier distinct. |

`@NotifyMandatoryFullDbBkpBeforeLogBkp` contrôle si YourSqlDba signale une erreur lorsqu’une sauvegarde de journal ne peut pas s’exécuter faute de sauvegarde complète.

## Sélection des bases de données

`@IncDb` et `@ExcDb` définissent la portée des bases de données.

- `@IncDb` limite la maintenance aux bases correspondant à la liste d’inclusion.
- `@ExcDb` retire les bases de données de l’ensemble sélectionné.
- Laisser `@IncDb` vide est la stratégie habituelle « toutes les bases éligibles, sauf les exclusions ». 

Ces paramètres sont particulièrement utiles sur les instances qui hébergent de nombreuses bases de données.
Lorsque les noms de bases suivent des conventions exploitables, les DBA préfèrent souvent maintenir la plupart des bases en laissant `@IncDb` vide et en utilisant `@ExcDb` pour quelques exceptions.
Cela évite des listes explicites longues et garde la maintenance par défaut large.

Utilisez des étapes SQL Agent distinctes ou des tâches séparées lorsque des groupes de bases de données différents nécessitent des actions ou des planifications différentes.

### Motifs d’inclusion et d’exclusion

Les paramètres d’inclusion et d’exclusion sont des listes de motifs SQL `LIKE`.

Exemples :

```sql
@IncDb = N'Payroll%,Accounting%'
```

```sql
@ExcDb = N'%Archive%,%Test%'
```

Stratégies typiques :

| Stratégie | Paramètres |
| --- | --- |
| Maintenir la plupart des bases, sauf quelques-unes | Laisser `@IncDb` vide et définir `@ExcDb`. |
| Maintenir uniquement un groupe d’applications | Définir `@IncDb` sur le motif de la base applicative. |
| Donner à un groupe un horaire différent | l’exclure de la tâche par défaut, puis créer une autre tâche ou étape avec `@IncDb`. |

### Étape de tâche ou tâche séparée

Utilisez une autre étape SQL Agent lorsque la maintenance peut s’exécuter sur la même planification que la tâche par défaut.

Utilisez une autre tâche SQL Agent lorsque le groupe de bases de données nécessite une planification différente.

Lorsque des tâches séparées s’exécutent sur la même instance, évitez le chevauchement inutile entre des opérations lourdes comme les sauvegardes complètes, les vérifications DBCC et la maintenance des index.

## Rétention des sauvegardes

Le nettoyage des sauvegardes est contrôlé par :

- `@FullBkpRetDays`
- `@LogBkpRetDays`

`NULL` signifie que le nettoyage est désactivé pour ce type de sauvegarde.

Les valeurs faibles sont courantes lorsque le dossier de sauvegarde est dédié au jeu de sauvegarde le plus récent.
Des valeurs plus élevées sont utiles lorsque le dossier doit conserver plusieurs points de récupération. Évidemment, on retient plus de fichiers de log, si on n'est pas assuré d'une sauvegarde fiable sur support externe ou si leur récupération de ce support est lent.

La rétention s’applique aux fichiers que YourSqlDba peut identifier comme faisant partie de ses règles de nommage de sauvegarde. Les fichiers qui n'obéissent pas à ces règles sont ignorés. Il incombe au DBA de les gérer.

## Répartir le travail de maintenance

Deux paramètres réduisent la quantité de travail effectuée dans une seule exécution :

| Paramètre | Objectif |
| --- | --- |
| `@SpreadUpdStatRun` | Étaler les mises à jour des statistiques sur plusieurs exécutions. |
| `@SpreadCheckDb` | Étaler les vérifications DBCC complètes sur plusieurs exécutions, sinon une vérification plus sommaire est faire sur la base de données avec l'option Physical_only |

Par exemple, avec la valeur par défaut `7`, le travail est réparti sur un cycle de sept exécutions.
Cela réduit la fenêtre de maintenance tout en garantissant que toutes les bases sont vérifiées à intervalles réguliers.
