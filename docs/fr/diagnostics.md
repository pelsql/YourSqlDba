---
layout: default
title: Diagnostics et rapports
nav_order: 50
---

# Diagnostics et rapports

Le reporting détaillé est l’une des forces de YourSqlDba. Il enregistre les commandes,
les messages, le statut d’exécution et les erreurs produites par ses tâches de maintenance.
`Maint.HistoryView` est l’outil principal pour examiner cet historique. Il peut isoler les erreurs
liées à une tâche spécifique ou présenter l’activité chronologique de plusieurs tâches dont les périodes
d’exécution se chevauchent, comme la maintenance complète et les sauvegardes de journal de transactions.

Lorsqu’un rapport de maintenance identifie une erreur, le courriel inclut une requête `Maint.HistoryView`
prête à exécuter dont l’intervalle de temps, le numéro de tâche et le filtre sont déjà réglés sur les erreurs
pertinentes. La fonction peut aussi être interrogée directement pour examiner l’activité complète d’une période donnée.

Les requêtes utilisent souvent `Maint.MaintenanceEnums`, qui fournit des constantes de filtre et des valeurs relatives
de date et heure précalculées. Ces valeurs rendent possible :

- la sélection d’une période récente sans calculer ou saisir explicitement son début et sa fin ;
- le retour soit des événements d’erreur, soit de l’activité complète pour cette période.

Parce que `Maint.HistoryView` est une fonction table-valeur en ligne, son résultat peut également être filtré sur n’importe quelle colonne retournée.
Les requêtes incluses dans les rapports de tâches ajoutent une clause `WHERE` sur `JobNo` pour isoler la tâche signalée.

Cette page couvre aussi le diagnostic Database Mail lorsque les rapports ne sont pas livrés
et les outils de statistiques d’attente SQL Server pour les investigations de performance.

## Table des matières
{: .no_toc .text-delta }

1. TOC
{:toc}

## Bases de données mises hors ligne par YourSqlDba

{: .warning }
> **YourSqlDba peut mettre une base de données hors ligne pour la protéger ou pour rendre une
> panne de sauvegarde prolongée impossible à ignorer.** Si le même problème sous-jacent affecte plusieurs bases,
> plusieurs ou même toutes les bases utilisateur éligibles peuvent être mises hors ligne pendant la même exécution de maintenance.

YourSqlDba met une base utilisateur éligible hors ligne dans l’une de ces situations :

- une vérification d’intégrité renvoie une erreur autre que l’erreur SQL Server 5128 ; mettre la base hors ligne empêche son utilisation continue pendant l’investigation de l’intégrité et de la récupération ;
- les sauvegardes complètes ont échoué le nombre de jours consécutifs configuré par `@ConsecutiveDaysOfFailedBackupsToPutDbOffline`. Sa valeur par défaut de `9999` désactive effectivement cette réponse de dernier recours, à moins qu’un DBA ne configure un seuil pratique.

Déterminez d’abord pourquoi les bases ont été mises hors ligne. Utilisez la requête d’erreur du rapport de maintenance ou interrogez `Maint.HistoryView`, puis corrigez le problème sous-jacent.
Les causes courantes d’échec de sauvegarde généralisé incluent une destination de sauvegarde indisponible ou pleine et un accès insuffisant pour le compte de service SQL Server.

Listez les bases actuellement hors ligne avant de changer leur état :

```sql
SELECT name, state_desc
FROM sys.databases
WHERE state_desc = N'OFFLINE'
ORDER BY name;
```

Après avoir examiné la liste, un sysadmin peut remettre en ligne toutes les bases hors ligne en une seule opération :

```sql
EXEC YourSqlDba.Maint.BringBackOnlineAllOfflineDb;
```

Cette procédure agit sur toutes les bases hors ligne de l’instance, y compris une base mise hors ligne manuellement ou par un autre processus.
Elle ne vérifie pas que le problème d’origine est résolu. Ne l’utilisez pas comme substitut à une investigation d’intégrité ou à une planification de restauration lorsque la corruption est suspectée.

Si les rapports de maintenance n’ont pas été reçus, enquêtez aussi sur leur absence avec [`Maint.DiagDbMail`](#database-mail-diagnostics).

## Conditions courantes après l’installation

Deux conditions signalées sont fréquentes immédiatement après l’installation de YourSqlDba.

### Une sauvegarde de journal nécessite une sauvegarde complète

SQL Server ne peut pas démarrer une chaîne valide de sauvegarde de journal tant qu’une sauvegarde complète appropriée n’existe pas.
Ce message est attendu pour une nouvelle base ou après une restauration qui n’a pas encore été suivie d’une sauvegarde complète.

Exécutez la tâche de maintenance complète ou appelez `Maint.YourSqlDba_DoMaint` avec une configuration adaptée pour créer la sauvegarde complète requise.
Pour les paramètres de sauvegarde connexes, voir [`Maint.YourSqlDba_DoMaint`](maintenance/your-sql-dba-domaint.md#backup-mode).

### Une base de données n’est pas en mode de récupération FULL

Par défaut, YourSqlDba signale les bases qui ne sont pas en mode de récupération `FULL`.
Cette politique prend en charge les sauvegardes régulières du journal de transactions et la récupération point-in-time pour les bases de production.

Les bases dont le mode de récupération est intentionnellement différent, comme les bases de test jetables,
peuvent être exclues avec `@ExcDbFromPolicy_CheckFullRecoveryModel`.
Examinez la [politique de mode de récupération de `Maint.YourSqlDba_DoMaint`](maintenance/your-sql-dba-domaint.md#recovery-model-policy)
avant de modifier la liste d’exclusion.

## Diagnostics de maintenance avec Maint.HistoryView

`Maint.HistoryView` est l’outil de diagnostic et de reporting principal pour la maintenance YourSqlDba.
Il renvoie les événements de tâche par ordre chronologique, y compris le SQL généré, les messages d’information,
les messages SQL Server, le statut de fin et les erreurs.

Les données sous-jacentes sont stockées dans ces tables :

- `Maint.JobHistory`, qui identifie et décrit chaque exécution de maintenance ;
- `Maint.JobHistoryDetails`, qui enregistre les détails d’exécution originaux ;
- `Maint.JobHistoryLineDetails`, qui stocke les lignes reportables consommées par `Maint.HistoryView`.

Interrogez `Maint.HistoryView` au lieu de lire directement ces tables.
La fonction organise leurs données en un résultat pratique et peut montrer les tâches concurrentes dans la plage temporelle choisie. Le rapport cible sa tâche et sa plage temporelle grâce à la requête qu'il fournit pour interroger `Maint.HistoryView`.

### Paramètres

| Paramètre | Objectif |
| --- | --- |
| `@StartDateTime` | Début de l’intervalle de rapport, fourni sous forme de chaîne canonique de date-heure au format SQL 121. |
| `@EndDateTime` | Fin de l’intervalle, fournie sous forme de chaîne canonique de date-heure au format SQL 121. |
| `@FilterOption` | Sélectionne tous les événements ou uniquement les événements d’erreur. Utilisez une constante de `Maint.MaintenanceEnums`. |

La représentation de date prise en charge est :

```text
YYYY-MM-DD hh:mm:ss.mmm
```

`Maint.MaintenanceEnums` retourne déjà des valeurs de date-heure canoniques, donc aucun appel explicite à `CONVERT()` n’est nécessaire lors de leur passage à `Maint.HistoryView`.

L’utilisation de ce format non ambigu évite que la langue de session n’échange le mois et le jour lors de la conversion.

### Constantes de filtres et de temps

`Maint.MaintenanceEnums` fournit des valeurs nommées pour les appels courants :

| Constante | Signification |
| --- | --- |
| `HV$ShowAll` | Retourne tous les événements de l’intervalle. |
| `HV$ShowErrOnly` | Retourne uniquement les événements d’erreur de l’intervalle. |
| `HV$Now` | Date et heure actuelles. |
| `HV$FromMidnight` | Début du jour en cours. |
| `HV$FromYesterdayMidnight` | Début du jour précédent. |
| `HV$Since12Hours` | Douze heures avant l’heure actuelle. |
| `HV$Since1Hour` | Une heure avant l’heure actuelle. |
| `HV$Since10Min` | Dix minutes avant l’heure actuelle. |

### Examiner l’activité récente

La requête suivante affiche toute l’activité YourSqlDba des dix dernières minutes :

```sql
SELECT
  H.cmdStartTime, H.JobNo, H.seq, H.Typ, H.line, H.Txt,
  H.MaintJobName, H.MainSqlCmd, H.Who, H.Prog, H.Host,
  H.SqlAgentJobName, H.JobId, H.JobStart, H.JobEnd
FROM
  Maint.MaintenanceEnums AS E
  CROSS APPLY
  Maint.HistoryView(E.HV$Since10Min, E.HV$Now, E.HV$ShowAll) AS H
ORDER BY
  H.cmdStartTime, H.Seq, H.TypSeq, H.Typ, H.Line;
```

Ceci est également utile pendant qu’une tâche de maintenance s’exécute. Parce que l’intervalle peut contenir des tâches concurrentes,
utilisez `JobNo` et les colonnes de contexte de tâche pour distinguer leurs événements.

### Enquêter sur une erreur signalée par une tâche

Lorsqu’une tâche de maintenance signale une erreur, son rapport par courriel fournit une requête contre `Maint.HistoryView`.
Cette requête contient déjà la plage de temps, utilise `HV$ShowErrOnly` et restreint la sortie au `JobNo` pertinent.
Copiez-la dans une fenêtre de requête connectée à l’instance SQL Server qui a exécuté la tâche.

Une requête typique a cette forme :

```sql
SELECT
  H.cmdStartTime, H.JobNo, H.seq, H.Typ, H.line, H.Txt,
  H.MaintJobName, H.MainSqlCmd, H.Who, H.Prog, H.Host,
  H.SqlAgentJobName, H.JobId, H.JobStart, H.JobEnd
FROM
  Maint.MaintenanceEnums AS E
  CROSS APPLY
  Maint.HistoryView
  (
    N'2026-06-30 00:40:00.750'
  , N'2026-06-30 00:40:02.520'
  , E.HV$ShowErrOnly
  ) AS H
WHERE
  H.JobNo = 10942
ORDER BY
  H.cmdStartTime, H.JobNo, H.Seq, H.TypSeq, H.Typ, H.Line;
```

Utilisez la requête fournie par le rapport plutôt que de copier ces dates et ce numéro de tâche d’exemple.

### Colonnes principales de sortie

| Colonne | Signification |
| --- | --- |
| `cmdStartTime` | Heure associée à l’événement. |
| `JobNo` | Exécution de tâche YourSqlDba qui a produit l’événement. |
| `Seq` | Séquence de l’événement dans l’activité enregistrée. |
| `Secs` | Durée en secondes lorsqu’une durée s’applique. |
| `Typ` | Type d’événement, tel que contexte de tâche, SQL, message, statut ou erreur. |
| `Line` | Numéro de ligne dans un événement multiligne. |
| `Txt` | Texte SQL, message, statut ou erreur. |

Lorsque la sortie passe d’une tâche à une autre, `Maint.HistoryView` remplit également des colonnes de contexte telles que
`MaintJobName`, `MainSqlCmd`, `Who`, `Prog`, `Host`, `SqlAgentJobName`, `JobId`, `JobStart` et `JobEnd`.
Leur affichage intermittent facilite l’identification des transitions de tâches concurrentes.

Puisque `Maint.HistoryView` est une fonction table-valeur en ligne, son résultat peut être filtré comme n’importe quelle autre requête.
Appliquez des prédicats supplémentaires sur `JobNo`, `Typ`, `Txt` ou d’autres colonnes lors de l’investigation d’une opération spécifique.

## Diagnostic Database Mail

Exécutez `Maint.DiagDbMail` lorsque la maintenance se termine mais que son rapport ou son alerte par courriel ne parvient pas :

```sql
EXEC Maint.DiagDbMail;
```

