---
layout: default
title: Suppression des anciennes sauvegardes
parent: Maintenance
grand_parent: YourSqlDba documentation (fr)
nav_order: 25
---

# Suppression des anciennes sauvegardes

`Maint.DeleteOldBackups` supprime les anciens fichiers de sauvegarde reconnus
par les règles de nommage de YourSqlDba. La procédure s’exécute habituellement
depuis `Maint.YourSqlDba_DoMaint`, mais peut aussi être appelée dans une tâche
SQL Server Agent distincte ou une fenêtre de requête SQL Server Management Studio.

[English version](../../maintenance/delete-old-backups.md)

## Sélection des fichiers et durée de conservation

La procédure examine uniquement les fichiers directement dans `@path`, sans
parcourir les sous-répertoires. Un chemin local ou un partage UNC est accepté.
Le compte de service SQL Server doit pouvoir énumérer le répertoire et supprimer
les fichiers sélectionnés.

Les fichiers doivent correspondre à l’extension demandée et contenir une date
reconnue et valide dans leur nom. Exemples de noms habituels :

```text
AdventureWorks_[2026-04-28_23h02m28_Mar]_Database.Bak
AdventureWorks_[2026-04-28_23h02m28_Mar]_Differential.Bak
AdventureWorks_[2026-04-28_23h02m28_Mar]_Logs.Trn
MSDB_[2026-04-28_Mar]_Database.Bak
```

L’âge est calculé à partir de la date inscrite dans le nom, et non des dates de
création ou de modification du système de fichiers. Pour les noms horodatés
ordinaires, le calcul utilise une précision à la minute ; pour le format court
de MSDB, il utilise minuit à la date indiquée. La date de référence est le début
de la tâche dans le contexte de maintenance. Un appel autonome crée son propre
contexte avec la date et l’heure courantes.

Un fichier devient admissible lorsque son âge en minutes est **strictement
supérieur au nombre de jours de conservation multiplié par 1440**. `NULL`
désactive la règle de nettoyage correspondante. `0` rend admissibles les fichiers
antérieurs à la minute de référence ; cela ne signifie pas « conserver les
sauvegardes d’aujourd’hui ». Les noms non reconnus et les dates invalides sont ignorés.

Les bases sélectionnées proviennent de la liste des bases en ligne admissibles
à la maintenance, filtrée par `@IncDb` et `@ExcDb`. Le filtre commun inclut
toujours les bases admissibles `master`, `model`, `msdb` et `YourSqlDba`, même
lorsque des filtres de bases utilisateur sont précisés. Une sauvegarde non
sélectionnée peut appartenir à une base supprimée, renommée, exclue ou autrement
absente de cette liste.

## Paramètres

| Paramètre | Type | Défaut | Rôle |
| --- | --- | --- | --- |
| `@oper` | `nvarchar(200)` | `'YourSQLDba_Operator'` | Opérateur SQL Server Agent activé, utilisé pour les rapports. |
| `@path` | `nvarchar(max)` | Obligatoire | Répertoire de sauvegarde. La barre oblique inverse finale est facultative. |
| `@BkpRetDays` | `int` | `NULL` | Jours de conservation des sauvegardes des bases sélectionnées ; sert aussi à la règle MSDB. |
| `@BkpRetDaysForUnSelectedDb` | `int` | `NULL` | Conservation des sauvegardes sans correspondance dans la liste des bases sélectionnées. Réservé aux sysadmins. |
| `@extension` | `sysname` | `''` | Filtre d’extension, par exemple `.bak`, `bak` ou `.trn`. Vide accepte toute extension, sous réserve des règles de nommage. |
| `@IncDb` | `nvarchar(max)` | `''` | Liste de motifs SQL `LIKE` à inclure. Vide sélectionne toutes les bases admissibles. |
| `@ExcDb` | `nvarchar(max)` | `''` | Liste de motifs SQL `LIKE` à exclure pour les bases utilisateur. |
| `@SendOnErrorOnly` | `int` | `1` | Envoyer le rapport d’un appel autonome seulement en cas d’erreur ; `0` rapporte aussi les réussites. |
| `@DeleteOnlyLogDiffBackups` | `int` | `0` | Avec `1`, limiter la règle des bases sélectionnées aux noms contenant `_Logs` ou `_Differential`. |

Placez chaque motif de base sur sa propre ligne. `%` correspond à une suite
de caractères, `_` à un caractère et `[5-9]` à un caractère dans une plage.
Utilisez `[_]` pour un soulignement littéral, comme dans `%[_]test`.

Lorsqu’un contexte de maintenance existe déjà, son opérateur et ses filtres
remplacent les valeurs de `@oper`, `@IncDb` et `@ExcDb` fournies à cet appel.
Les anciens paramètres OneNote `@MaintJobName`, `@RefDate` et `@JobNo` ne font
plus partie de la signature ; l’historique et la date de référence sont gérés
par le contexte d’exécution.

## Droits et règles de nettoyage distinctes

Les sysadmins peuvent nettoyer les sauvegardes des bases sélectionnées, de MSDB
et des bases non sélectionnées selon les règles de conservation applicables.
Les utilisateurs délégués peuvent uniquement nettoyer les variantes nommées
pour l’utilisateur et autorisées à partir des bases sources configurées dans
`Maint.DelegatedDbManagement`. Voir [Délégation de la gestion de base de données](delegated-database-management.md).

Les règles MSDB et bases non sélectionnées sont évaluées séparément de celle
des bases sélectionnées. En particulier, `@DeleteOnlyLogDiffBackups = 1`
**ne limite pas** ces deux règles. Laissez
`@BkpRetDaysForUnSelectedDb = NULL` pour conserver les fichiers non sélectionnés.
Un fichier correspondant à plusieurs raisons de suppression n’est traité qu’une fois.

Les erreurs d’énumération de répertoire et de lecture des attributs provenant
des fonctions CLR sont consignées ; les fichiers concernés ne sont pas supprimés.
Les échecs de suppression sont aussi consignés. L’historique indique la raison
et le résultat de chaque tentative de suppression.

## Exemples

Ces appels suppriment immédiatement les fichiers ; la procédure n’a pas de
paramètre de prévisualisation. Choisissez les durées selon les points de
récupération et les copies externes à conserver.

### Nettoyer un répertoire après copie des sauvegardes ailleurs

Après vérification de la copie externe, un sysadmin peut retirer les sauvegardes
reconnues antérieures à la minute de référence, y compris celles de bases qui
n’existent plus. Les fichiers dans les sous-répertoires sont conservés.

```sql
Exec YourSqlDba.Maint.DeleteOldBackups
  @path = N'G:\Sql\Backups\ForXCOPY\'
, @BkpRetDays = 0
, @BkpRetDaysForUnSelectedDb = 0
, @extension = ''
```

### Nettoyer les sauvegardes de test en conservant les variantes d’archive

Cet exemple conserve sept jours de fichiers `.bak` pour les bases utilisateur
dont le nom se termine par `_test`, sauf celles contenant `Archive`. Les fichiers
non sélectionnés sont conservés. L’inclusion des bases système et les règles
MSDB décrites plus haut s’appliquent toujours. Le même appel convient à une tâche
SQL Agent ou à une fenêtre de requête SSMS.

```sql
Exec YourSqlDba.Maint.DeleteOldBackups
  @path = N'G:\Sql\Backups\ForXCOPY\'
, @BkpRetDays = 7
, @BkpRetDaysForUnSelectedDb = NULL
, @extension = '.bak'
, @IncDb = N'
%[_]test
'
, @ExcDb = N'
%Archive%
'
```

## Intégration et rapports

`Maint.YourSqlDba_DoMaint` transmet `@FullBkpRetDays` pour le répertoire des
sauvegardes complètes et différentielles, et `@LogBkpRetDays` pour celui des
journaux, avec les extensions configurées. Lors d’une maintenance différentielle,
elle utilise `@DeleteOnlyLogDiffBackups = 1` pour le répertoire des sauvegardes
complètes et différentielles. Ces appels précèdent les opérations de sauvegarde ;
le nettoyage ne vérifie ni la réussite d’une nouvelle sauvegarde ni la présence
d’une chaîne de restauration complète dans les fichiers restants.

Un appel autonome crée une entrée d’historique et envoie un rapport à `@oper`
selon `@SendOnErrorOnly`. Lors d’un appel depuis la maintenance principale,
les messages de nettoyage sont inclus dans son rapport. L’opérateur doit exister
et être activé dans `msdb.dbo.sysoperators`.

Voir [Maintenance principale et rétention](your-sql-dba-domaint.md#rétention-des-sauvegardes),
[Configuration](../configuration.md#rétention-des-sauvegardes) et
[Diagnostics et historique](../diagnostics.md).
