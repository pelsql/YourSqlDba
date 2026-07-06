---
layout: default
title: Référence des procédures de mirroring
parent: Maintenance
grand_parent: YourSqlDba documentation (fr)
nav_order: 12
---

# Référence des procédures de mirroring

Cette page documente les procédures publiques utilisées pour configurer,
exploiter, récupérer et retirer le mécanisme de mirroring par restauration de
YourSqlDba. Pour comprendre son architecture et le déroulement d’une migration,
commencez par [Miroir, standby et tests de migration](mirror-standby-migration.md).

{: .warning }
> Ces procédures configurent la sécurité des linked servers, récupèrent des
> bases de données ou mettent les bases sources hors ligne. Exécutez-les comme
> administrateur de YourSqlDba et validez les serveurs et les bases concernés
> avant leur exécution.

## Table des matières
{: .no_toc .text-delta }

1. TOC
{:toc}

## Mirroring.AddServer

Exécutez `Mirroring.AddServer` sur l’instance source pour enregistrer une
instance cible et créer la configuration du linked server utilisée par
YourSqlDba.

La procédure :

- exige que SQL Server Agent soit démarré afin de détecter son compte de
  service;
- crée le linked server avec le fournisseur `MSOLEDBSQL`;
- configure les correspondances de logins, RPC, RPC OUT et le délai maximal des
  requêtes distantes;
- enregistre la cible dans `Mirroring.TargetServer`;
- configure le login `YourSqlDba` utilisé pour les opérations distantes;
- vérifie que les deux instances utilisent la même version de YourSqlDba;
- synchronise les logins SQL admissibles vers la cible.

Si un linked server porte déjà le même nom logique, la procédure supprime sa
configuration existante avant de le recréer.

### Paramètres

| Paramètre | Type | Valeur par défaut | Rôle |
| --- | --- | --- | --- |
| `@MirrorServer` | `nvarchar(512)` | Obligatoire | Nom logique du linked server enregistré par YourSqlDba. |
| `@remoteLogin` | `nvarchar(512)` | Obligatoire | Login SQL sysadmin sur la cible, utilisé pour établir les correspondances distantes. |
| `@remotePassword` | `nvarchar(512)` | Obligatoire | Mot de passe de `@remoteLogin`. |
| `@ExcSysAdminLoginsInSync` | `int` | `0` | Réservé dans la signature actuelle; `Mirroring.AddServer` n’utilise pas cette valeur actuellement. |
| `@ExcLoginsFilter` | `nvarchar(max)` | Chaîne vide | Réservé dans la signature actuelle; `Mirroring.AddServer` n’utilise pas cette valeur actuellement. |
| `@MirrorServerDataSrc` | `nvarchar(512)` | Chaîne vide | Source de données réelle du fournisseur lorsqu’elle diffère du nom logique du linked server. |
| `@YourSqlDbaAccountForMirroringPwd` | `nvarchar(512)` | `NULL` | Mot de passe commun facultatif pour le login `YourSqlDba`, notamment lorsque plusieurs sources partagent une cible. |

### Prérequis

- Installez la même version de YourSqlDba sur les instances source et cible.
- Démarrez SQL Server Agent sur la source.
- Installez et configurez le fournisseur `MSOLEDBSQL`.
- Assurez-vous que les identifiants fournis à la procédure possèdent les droits
  sysadmin sur la cible.
- Rendez les fichiers de sauvegarde accessibles à la cible, directement ou par
  les substitutions de chemins configurées dans `Maint.YourSqlDba_DoMaint`.

### Exemple

```sql
EXEC YourSqlDba.Mirroring.AddServer
    @MirrorServer = N'SQLTARGET\SQL2025'
  , @remoteLogin = N'MirroringSetup'
  , @remotePassword = N'<mot-de-passe-sécurisé>';
```

Ne conservez pas un véritable mot de passe dans un script enregistré ou un
dépôt de code source. Après l’enregistrement, exécutez une sauvegarde complète
de maintenance ou `Maint.SaveDbOnNewFileSet` afin d’initialiser chaque base
cible sélectionnée avant la restauration des journaux.

## Mirroring.DropServer

Exécutez `Mirroring.DropServer` sur l’instance source pour retirer une cible de
YourSqlDba. La procédure supprime l’entrée de `Mirroring.TargetServer`, les
correspondances de logins du linked server, puis le linked server lui-même.

Elle ne supprime ni les bases de données ni les fichiers de sauvegarde sur
l’instance cible.

### Paramètres

| Paramètre | Type | Valeur par défaut | Rôle |
| --- | --- | --- | --- |
| `@MirrorServer` | `sysname` | Chaîne vide | Nom logique du linked server à supprimer. |
| `@silent` | `int` | `0` | Supprime certains messages sur la version de la cible lorsque sa valeur est `1`; ne modifie pas la portée de la suppression. |

### Exemple

```sql
EXEC YourSqlDba.Mirroring.DropServer
    @MirrorServer = N'SQLTARGET\SQL2025';
```

## Mirroring.DoRecovery

Exécutez `Mirroring.DoRecovery` sur l’instance qui héberge actuellement les
bases en état `RESTORING`. La procédure exécute
`RESTORE DATABASE ... WITH RECOVERY` pour chaque base admissible sélectionnée
par `@IncDb` et `@ExcDb`, puis indique si chacune est passée à l’état `ONLINE`.

La récupération d’une base met fin à sa séquence de restauration actuelle. Les
sauvegardes différentielles ou de journal suivantes ne peuvent plus être
appliquées à cette copie. Utilisez cette procédure pour rendre volontairement
la copie disponible, et non comme test de diagnostic pendant le mirroring
continu.

### Paramètres

| Paramètre | Type | Valeur par défaut | Rôle |
| --- | --- | --- | --- |
| `@IncDb` | `nvarchar(max)` | Chaîne vide | Inclut les bases dont le nom correspond aux motifs SQL `LIKE`. Une valeur vide sélectionne toutes les bases admissibles. |
| `@ExcDb` | `nvarchar(max)` | Chaîne vide | Exclut les bases correspondantes de l’ensemble inclus. |

### Exemple

```sql
EXEC YourSqlDba.Mirroring.DoRecovery
    @IncDb = N'Payroll,Accounting'
  , @ExcDb = N'%Archive%';
```

Cette procédure ne modifie pas les chaînes de connexion des applications et ne
met pas hors ligne les bases correspondantes sur une autre instance.

## Mirroring.Failover

Exécutez `Mirroring.Failover` sur l’instance source pour effectuer la dernière
synchronisation et rendre disponibles les bases cibles sélectionnées. Il s’agit
de la méthode normale de bascule pour une migration préparée avec le mirroring
YourSqlDba.

Pour chaque base admissible, la procédure valide la source et la cible,
déconnecte les utilisateurs de la source, crée et restaure facultativement une
dernière sauvegarde, met la base source hors ligne, récupère la base cible,
restaure son propriétaire et ajuste son niveau de compatibilité à la version SQL
Server cible.

La dernière synchronisation utilise :

- une sauvegarde du journal pour les bases en mode `FULL` ou `BULK_LOGGED`;
- une sauvegarde différentielle pour les bases en mode `SIMPLE`.

### Paramètres

| Paramètre | Type | Valeur par défaut | Rôle |
| --- | --- | --- | --- |
| `@IncDb` | `nvarchar(max)` | Chaîne vide | Inclut les bases sources dont le nom correspond aux motifs fournis. Une valeur vide sélectionne toutes les bases admissibles. |
| `@ExcDb` | `nvarchar(max)` | Chaîne vide | Exclut les bases correspondantes de l’ensemble inclus. |
| `@Simulation` | `int` | `0` | Lorsque sa valeur est `1`, n’effectue pas la bascule. L’implémentation actuelle ne doit pas être considérée comme une validation complète de l’état de préparation. |
| `@LastDataSync` | `int` | `1` | Crée et restaure la dernière sauvegarde YourSqlDba. Utilisez `0` lorsqu’un produit externe a déjà effectué la synchronisation finale des données. |

### Exemple

```sql
EXEC YourSqlDba.Mirroring.Failover
    @IncDb = N'Payroll,Accounting'
  , @ExcDb = N'%Archive%'
  , @Simulation = 0
  , @LastDataSync = 1;
```

{: .warning }
> Une bascule réussie laisse les bases sources `OFFLINE` et les bases cibles
> `ONLINE`. Elle ne redirige pas les clients vers l’instance cible. Coordonnez
> l’arrêt des applications, les changements de chaînes de connexion ou de DNS,
> la validation et le plan de retour en arrière en dehors de YourSqlDba.

Après la bascule, établissez une nouvelle sauvegarde complète de référence sur
la cible pour les bases qui y utiliseront des sauvegardes de journal.

## Mirroring.SetYourSqlDbaAccountForMirroring

Exécutez `Mirroring.SetYourSqlDbaAccountForMirroring` sur une instance source
pour reconstruire les correspondances du login `YourSqlDba` pour toutes les
cibles enregistrées dans `Mirroring.TargetServer`.

Cette procédure est particulièrement utile lorsque plusieurs instances sources
partagent une cible et doivent utiliser un mot de passe `YourSqlDba` commun.
Lorsqu’un mot de passe est fourni, elle l’applique aux logins `YourSqlDba`
locaux et distants, puis recrée les correspondances. Lorsqu’il est omis, elle
génère les identifiants nécessaires tout en conservant le hachage du mot de
passe local d’origine.

### Paramètres

| Paramètre | Type | Valeur par défaut | Rôle |
| --- | --- | --- | --- |
| `@YourSqlDbaAccountForMirroringPwd` | `nvarchar(max)` | `NULL` | Mot de passe commun facultatif utilisé pour reconstruire les correspondances de logins du mirroring. |

### Exemple

```sql
EXEC YourSqlDba.Mirroring.SetYourSqlDbaAccountForMirroring
    @YourSqlDbaAccountForMirroringPwd = N'<mot-de-passe-sécurisé>';
```

Ne conservez pas ce mot de passe dans le texte d’une tâche, la documentation ou
un dépôt de code source.

## Upgrade.MakeDbCompatibleToTarget

`Mirroring.Failover` appelle `Upgrade.MakeDbCompatibleToTarget` sur l’instance
cible après avoir récupéré une base migrée. La procédure place la base en mode
`MULTI_USER` et règle son niveau de compatibilité selon la version SQL Server
de la cible.

### Paramètres

| Paramètre | Type | Valeur par défaut | Rôle |
| --- | --- | --- | --- |
| `@DbName` | `sysname` | Obligatoire | Base à rendre compatible avec l’instance cible. |

### Exemple

Cette procédure est normalement appelée par `Mirroring.Failover`. Pour une base
migrée manuellement, elle peut être exécutée directement sur la cible :

```sql
EXEC YourSqlDba.Upgrade.MakeDbCompatibleToTarget
    @DbName = N'Payroll';
```

Un changement de niveau de compatibilité peut modifier l’optimisation des
requêtes et le comportement de l’application. Testez l’application et ses
charges de travail importantes au niveau cible.

## Mirroring.ProcessRestores

`Mirroring.ProcessRestores` est la procédure de travail exécutée par les tâches
SQL Agent de restauration que YourSqlDba crée et démarre automatiquement. Elle
consomme la file de restauration dans l’ordre et consigne son activité dans
l’historique de la tâche de maintenance d’origine.

Normalement, le DBA surveille la tâche SQL Agent générée et diagnostique ses
échecs avec `Maint.HistoryView`; il ne doit pas planifier ou appeler cette
procédure comme un flux de restauration indépendant.
