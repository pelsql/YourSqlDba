---
layout: default
title: Miroir, standby et tests de migration
parent: Maintenance
grand_parent: YourSqlDba documentation
nav_order: 11
---

# Miroir, standby et tests de migration

YourSqlDba utilise une approche de "standby server" même si cette documentation y réfère par le terme "miroir". Il maintient plutôt une copie restaurée mais non recouvrée de bases de données sélectionnées
sur une seconde instance SQL Server. Un cas d’usage principal est de préparer une montée de version
de SQL Server vers une nouvelle instance tout en gardant l’interruption finale de service aussi courte que possible.

> YourSqlDba utilise un flux de restauration séparé via linked server
> piloté par `Maint.YourSqlDba_DoMaint`.

Pour les signatures, paramètres, prérequis et exemples d’exécution, consultez
la [référence des procédures de mirroring](mirroring-reference.md).

## Préparer une mise à niveau de version SQL Server

Avant la migration, des sauvegardes régulières sont restaurées en continu sur l’instance cible. Le mécanisme évite les bases de données déjà recouvrées et donc en ligne, même si à la source elles sont ciblées.
Les sauvegardes complètes, différentielles et de journal de transactions maintiennent chaque base cible proche
de l’état de sa source. En mode de "mirroring" normal, la cible reste en état `RESTORING` pour que les sauvegardes
suivantes puissent être appliquées.

Cette approche apporte deux avantages importants avant la bascule :

- la plupart des données ont déjà été transférées et restaurées sur la cible ;
- l’activité de restauration régulière vérifie que la chaîne de sauvegarde peut être lue et appliquée sur la destination.

La version SQL Server cible doit être la même ou plus récente que la version source.
Ceci permet de préparer une migration côte à côte sans tenter une restauration non supportée vers une version antérieure.

## Comment cela fonctionne

Lorsque `Maint.YourSqlDba_DoMaint` s’exécute avec `@MirrorServer` défini, YourSqlDba peut mettre en file d’attente
des restaurations de sauvegarde sur le serveur distant après chaque sauvegarde éligible.

Le flux de restauration inclut :

- la tâche de maintenance qui produit les sauvegardes crée également une tâche de restauration miroir si elle n’existe pas déjà ;
- dans tous les cas, la tâche de restauration est ensuite démarrée pour traiter les opérations de restauration en file.

La tâche de restauration est créée automatiquement lorsque nécessaire. Son nom visible dans SQL Agent suit le modèle :

`Restores to <MirrorServer> For <SqlAgentJobName or MaintJobName>`

Par exemple, si la tâche de maintenance s’appelle `YourSQLDba_FullBackups_And_Maintenance`
et que le serveur miroir est `MauriceSql\Sql2k25`, la tâche de restauration sera nommée :

`Restores to MauriceSql\Sql2k25 For YourSQLDba_FullBackups_And_Maintenance`

L’instruction de la première étape est :

```sql
EXECUTE [Mirroring].[ProcessRestores]
```

## Bascule avec Mirroring.Failover

`Mirroring.Failover` effectue la synchronisation finale et bascule les bases sélectionnées de l’instance source
vers l’instance cible. Pour chaque base éligible, elle :

1. termine les connexions actives sur la source ;
2. crée et restaure la dernière sauvegarde de journal lorsque la base est en mode `FULL` ou `BULK_LOGGED`, ou une dernière sauvegarde différentielle lorsqu’elle est en mode `SIMPLE` ;
3. met la base source hors ligne pour empêcher tout accès ou modification supplémentaire ;
4. récupère la base cible et la remet en ligne ;
5. restaure le propriétaire de la base lorsqu’il est disponible ;
6. définit le niveau de compatibilité de la base pour la version SQL Server cible.

Les paramètres `@IncDb` et `@ExcDb` permettent au DBA de basculer un groupe de bases sélectionné indépendamment des filtres de bases utilisés par la tâche de maintenance régulière.
`@LastDataSync = 0` ignore la dernière sauvegarde et restauration YourSqlDba lorsque un autre produit de synchronisation des données a déjà effectué cette étape.

{: .warning }
> `Mirroring.Failover` est une opération de bascule disruptive. Elle déconnecte les utilisateurs et laisse les bases source hors ligne avant de rendre les bases cibles disponibles sur l'instance de destination.
> Validez sur l'instance de destination, la connectivité, l’état de restauration, la configuration applicative, la sélection des bases et le plan de retour en arrière avant de l’exécuter. La plupart des utilisateurs trouvent plus facile de conserver des noms d'instance identiques sur des serveurs différents et d'ajuster la résolution de noms pour qu'elle pointe vers les nouveaux serveurs.

## Paramètres clés

Ce sont des paramètres de `Maint.YourSqlDba_DoMaint`.

| Paramètre | Objectif |
| --- | --- |
| `@MirrorServer` | Nom du linked server cible pour les opérations de restauration distante. |
| `@MigrationTestMode` | Active le mode de test de migration, où seules les sauvegardes complètes sont restaurées et les copies distantes ne sont pas rafraîchies à répétition. |
| `@ReplaceSrcBkpPathToMatchingMirrorPath` | Cartographie les chemins de sauvegarde source vers les chemins correspondants du serveur miroir. Cela n'est utile que lorsque les chemins sont pointés par disques ou des UNC différents. Le serveur qui restore doit faire cette substitution (par remplacement de chaîne dans les chemins) afin de trouver à l'endroit correspondant les fichiers de sauvegarde déposés |
| `@ReplacePathsInDbFilenames` | Réécrit les chemins des fichiers de base de données lors de la restauration sur le serveur miroir. C'est utile lorsqu'on change la structure de répertoire des données lorsqu'on change d'instance, le serveur qui restore adapte (par remplacement de chaîne dans les chemins) les anciens emplacements enregistrés dans les sauvegardes aux siens. |

## Exigences

- Utilisez `Mirroring.AddServer` pour créer et enregistrer le linked server utilisé par le mirroring YourSqlDba.
- Lorsque le serveur miroir n’est plus nécessaire, il peut être supprimé avec `Mirroring.DropServer`.
- Le nom du linked server doit correspondre à la valeur fournie dans `@MirrorServer`.
- YourSqlDba doit être installé sur le serveur cible, et les deux instances doivent utiliser la même version de YourSqlDba.
- L’accès distant doit fonctionner via la connexion `YourSqlDba` sur le serveur cible. Elle est automatiquement créée par `Mirroring.AddServer`. Typiquement, cela est transparent, car la plupart des utilisateurs ne font du mirroring que vers une seule instance.
- Si plusieurs serveurs source utilisent le même serveur miroir, ils doivent partager un mot de passe YourSqlDba commun pour la correspondance de connexion automatique. De manière inverse si le serveur source envoie des bases de données sur des serveurs différents, la même règle s'applique. La question se règle alors par `Mirroring.SetYourSqlDbaAccountForMirroring`.

## Gestion du linked server et de la sécurité

YourSqlDba valide le serveur miroir avant de lancer les opérations de restauration.
Si le serveur est manquant ou inaccessible, le processus peut envoyer une notification par courriel à l’opérateur configuré.

Une procédure stockée interne vérifie chaque serveur miroir configuré et peut aider à rétablir l’accès en appelant `Mirroring.SetYourSqlDbaAccountForMirroring`.

## Synchronisation des logins et des SID

À chaque restauration, YourSqlDba synchronise les logins SQL et leurs SID sur l’instance cible afin que les bases restaurées conservent les correspondances login/utilisateur correctes.
Il s’agit d’une mesure de sécurité au niveau base de données (login/user SIDs), pas d’un paramètre de sécurité du linked server, et cela évite les utilisateurs orphelins causés par des SID différents, lors d'une restauration sur un nouveau serveur.

Si SQL Agent ne fonctionne pas, le démarrage de la tâche de restauration échoue avec une erreur explicite.

## Traduction de chemin et configuration de fichier de restauration

Si vous ne souhaitez pas accorder au compte de démarrage distant l’accès au répertoire de sauvegarde source du serveur d’origine,
ces paramètres peuvent être utilisés comme solution de contournement.

Lorsque le serveur miroir utilise une structure de chemins différente de celle de la source — par exemple, des mappages de lecteurs différents vers les mêmes répertoires — utilisez ces paramètres :

`@ReplaceSrcBkpPathToMatchingMirrorPath` : une chaîne de recherche-et-remplacement de la forme `sourcePath>mirrorPath` pour traduire les chemins de sauvegarde pour le serveur miroir.
`@ReplacePathsInDbFilenames` : une chaîne de recherche-et-remplacement qui réécrit les chemins des fichiers de base de données lors de la restauration.

Ces valeurs de paramètre sont normalisées en supprimant les sauts de ligne et les espaces répétés avant utilisation.

### Exemple

```sql
@ReplaceSrcBkpPathToMatchingMirrorPath = N'D:\SQLBackups>E:\MirrorBackups'
@ReplacePathsInDbFilenames = N'D:\Data>E:\Db\Data'
```

## Mode de test de migration

`@MigrationTestMode = 1` modifie le comportement du miroir pour les scénarios de migration :

- seules les sauvegardes complètes sont restaurées sur le serveur miroir ;
- les bases restaurées sont mises en ligne sur le serveur cible ;
- tant que la copie cible existe et est en ligne, YourSqlDba n’essaie pas de restaurer à nouveau cette base. Cela peut aider à éviter des échecs dus à un espace insuffisant tout en permettant aux autres restaurations de se terminer,
  et cela donne une vision plus claire des réels besoins en espace disque.

Ce mode est utile lorsque vous migrez des bases de données vers une version SQL Server plus récente et que vous avez besoin d’une validation de restauration ponctuelle plutôt que d’un rafraîchissement continu de type miroir.

Pour revenir au comportement normal du miroir, supprimez `@MigrationTestMode = 1` et supprimez les bases de données testées sur le serveur cible pour recommencer leur mise à jour.

## Gestion des pannes et notifications

Si le flux de mirroring détecte un serveur linked absent ou inaccessible, YourSqlDba peut :

- désactiver la restauration miroir pour l’exécution en cours,
- consigner l’échec dans l’historique de la tâche,
- envoyer un courriel à l’opérateur configuré avec des instructions de remédiation.

Causes courantes d’échec de mirroring :

- linked server non créé ou inaccessible ;
- valeur `@MirrorServer` ne correspond pas à un linked server ;
- échec de la correspondance de connexion `YourSqlDba` distante ;
- serveur cible hors service ou inaccessible.
- Version de YourSqlDba différente sur les deux serveurs.

## Objets associés

- [`Mirroring.AddServer`](mirroring-reference.md#mirroringaddserver) — crée et enregistre le linked server utilisé par le mirroring YourSqlDba.
- [`Mirroring.DropServer`](mirroring-reference.md#mirroringdropserver) — supprime le linked server lorsqu’il n’est plus nécessaire.
- [`Mirroring.DoRecovery`](mirroring-reference.md#mirroringdorecovery) — récupère les bases locales sélectionnées qui sont en état `RESTORING`.
- [`Mirroring.Failover`](mirroring-reference.md#mirroringfailover) — effectue la synchronisation finale et la bascule de migration.
- [`Mirroring.SetYourSqlDbaAccountForMirroring`](mirroring-reference.md#mirroringsetyoursqldbaaccountformirroring) — reconstruit les correspondances de logins du mirroring.
- [`Upgrade.MakeDbCompatibleToTarget`](mirroring-reference.md#upgrademakedbcompatibletotarget) — applique le niveau de compatibilité cible après la migration.
- [`Mirroring.ProcessRestores`](mirroring-reference.md#mirroringprocessrestores) — procédure de travail interne exécutée par SQL Agent.
- `Maint.YourSqlDba_DoMaint`
