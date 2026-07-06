---
layout: default
title: Configuration
parent: YourSqlDba documentation (fr)
nav_order: 30
---

# Configuration

La configuration de YourSqlDba est principalement contrôlée par les étapes SQL Agent
qui appellent `Maint.YourSqlDba_DoMaint`.

Cette page explique comment la configuration est effectuée, quels paramètres sont les plus importants
et comment les DBA personnalisent généralement la maintenance.

## Où la configuration est effectuée

La configuration de YourSqlDba s’établit via quelques composants :

| Emplacement | Objectif |
| --- | --- |
| `Install.InitialSetupOfYourSqlDba` | Assistant qui crée les tâches SQL Agent par défaut, les planifications, les chemins de sauvegarde et le support Database Mail |
| planifications SQL Agent | Quand les tâches de maintenance s’exécutent |
| étapes SQL Agent | paramètres de maintenance actifs passés à `Maint.YourSqlDba_DoMaint` |
| Database Mail / profil de messagerie | configuration de l’envoi des rapports par courriel |
| `Maint.YourSqlDba_DoMaint` | définit les actions de maintenance, la sélection des bases, la rétention et le comportement miroir/standby |

`Install.InitialSetupOfYourSqlDba` ne contient pas lui-même les valeurs de configuration.
C’est un assistant qui construit la configuration par défaut en créant les tâches SQL Agent et leurs étapes,
puis en configurant Database Mail pour les rapports.

La configuration active vit dans les tâches SQL Agent et leurs étapes, ainsi que dans les paramètres Database Mail
utilisés par YourSqlDba. Les DBA peuvent ensuite personnaliser le comportement de maintenance en ajustant ces étapes
des tâches et les paramètres de messagerie associés.

## Paramètres clés de YourSqlDba_DoMaint

| Paramètre | Objectif |
| --- | --- |
| `@oper` | Opérateur SQL Agent pour les notifications |
| `@MaintJobName` | Nom de la tâche stocké dans l’historique et les rapports |
| `@DoInteg` | Exécute les vérifications d’intégrité des bases lorsque la valeur est `1` |
| `@DoUpdStats` | Met à jour les statistiques de l’optimiseur lorsque la valeur est `1` |
| `@DoReorg` | Réorganise ou reconstruit les index lorsque la valeur est `1` |
| `@DoBackup` | Mode de sauvegarde : `F`, `D`, `L`, ou vide pour aucune sauvegarde |
| `@FullBackupPath` | Répertoire des sauvegardes complètes et différentielles |
| `@LogBackupPath` | Répertoire des sauvegardes de journal de transactions |
| `@FullBkpRetDays` | Nombre de jours de conservation des anciens fichiers de sauvegarde complète |
| `@LogBkpRetDays` | Nombre de jours de conservation des anciens fichiers de sauvegarde de journal |
| `@BkpLogsOnSameFile` | Réutiliser le même fichier de journal ou créer un nouveau fichier à chaque exécution |
| `@SpreadUpdStatRun` | Étaler les mises à jour de statistiques sur plusieurs exécutions |
| `@SpreadCheckDb` | Étaler les vérifications complètes de base sur plusieurs exécutions |
| `@ConsecutiveDaysOfFailedBackupsToPutDbOffline` | Seuil de dernier recours pour mettre une base hors ligne après des sauvegardes complètes échouées sur des jours consécutifs |
| `@MirrorServer` | Instance optionnelle pour la validation de restauration ou les tests de standby/migration |

{: .warning }
> Avant de diminuer `@ConsecutiveDaysOfFailedBackupsToPutDbOffline` depuis sa valeur par défaut de `9999`, passez en revue [pourquoi YourSqlDba peut mettre des bases hors ligne et comment les récupérer](diagnostics.md#databases-taken-offline-by-yoursqldba).

## Mode de sauvegarde

`@DoBackup` contrôle le comportement de sauvegarde :

| Valeur | Opération |
| --- | --- |
| `F` | Sauvegardes complètes et une première sauvegarde consécutive du journal de transaction. |
| `D` | Sauvegardes différentielles |
| `L` | Sauvegardes de journal de transactions |
| Chaîne vide | Aucune sauvegarde |

Pour les tâches de sauvegarde du journal, YourSqlDba utilise généralement le chemin de sauvegarde de journal enregistré
par le dernier ensemble de fichiers de sauvegarde complète ou différentielle. Cela signifie que les sauvegardes de journal fréquentes
n’ont pas besoin de chemins de sauvegarde complets explicites.

## Sélection des bases de données

La sélection des bases de données est contrôlée le plus souvent par `@IncDb` et `@ExcDb`.

- `@IncDb` limite la maintenance aux bases correspondantes.
- `@ExcDb` exclut les bases correspondantes de l’ensemble sélectionné.

Lorsque les noms de bases suivent une convention utilisable, la stratégie préférée consiste souvent à maintenir la plupart
des bases et à n’exclure qu’un nombre réduit de cas exceptionnels. Cela garde la tâche par défaut large tout en permettant
des exclusions ciblées.

Si `@IncDb` est vide, YourSqlDba commence par toutes les bases éligibles puis enlève celles listées dans `@ExcDb`.

### Motifs d’inclusion / d’exclusion

Ces paramètres acceptent des motifs SQL `LIKE`.

Exemples :

```sql
@IncDb = N'Payroll%,Accounting%'
@ExcDb = N'%Archive%,%Test%'
```

Stratégies courantes :

| Stratégie | Paramètres |
| --- | --- |
| Maintenir la plupart des bases, sauf quelques-unes | `@ExcDb` uniquement |
| Maintenir un groupe d’applications spécifique | `@IncDb` uniquement |
| Séparer un groupe de bases avec un horaire différent | exclure du travail par défaut, puis ajouter une autre tâche ou étape avec `@IncDb` |

## Modèles de personnalisation courants

### Exclure une ou plus souvent des bases de données de la tâche par défaut

Utilisez `@ExcDb` dans l’étape SQL Agent de la tâche de maintenance par défaut.

Ceci est utile lorsqu’une base doit utiliser une planification, une politique de sauvegarde ou un comportement de maintenance différents.

### Ajouter une deuxième étape de maintenance

Si un groupe de bases de données doit s’exécuter avec des paramètres différents mais peut utiliser la même planification,
ajoutez une autre étape SQL Agent avec une valeur `@IncDb` spécifique.

**NOTE IMPORTANTE**

YourSqlDba publie, dans son rapport de maintenance, les bases de données ciblées par la combinaison de `@IncDb` et `@ExcDb`. Il est important de vérifier cette liste pour s'assurer que toutes les bases de données que vous souhaitez maintenir et celles que vous souhaitez exclure ont été traitées correctement.

### Utiliser une tâche SQL Agent séparée

Si le groupe de bases nécessite une planification différente, créez une tâche SQL Agent séparée.

Lorsque des tâches séparées s’exécutent sur la même instance, évitez les chevauchements inutiles entre des opérations lourdes telles que
les sauvegardes complètes, les vérifications DBCC et la maintenance des index.

## Rétention des sauvegardes

Le nettoyage des sauvegardes est contrôlé par :

- `@FullBkpRetDays`
- `@LogBkpRetDays`

Une valeur `NULL` désactive le nettoyage pour ce type de sauvegarde.

La rétention s’applique uniquement aux fichiers que YourSqlDba peut reconnaître comme faisant partie de ses règles de nommage de sauvegarde.

## Répartir le travail de maintenance

Utilisez ces paramètres pour réduire la charge par exécution :

| Paramètre | Objectif |
| --- | --- |
| `@SpreadUpdStatRun` | Étaler les mises à jour de statistiques sur plusieurs exécutions |
| `@SpreadCheckDb` | Étaler les vérifications DBCC complètes sur plusieurs exécutions |

Ceci est utile lorsque votre fenêtre de maintenance ne peut pas contenir tout le travail en une seule exécution.

## Rapport et dépannage

`Maint.HistoryView` est l’outil de diagnostic principal de la maintenance.
Les rapports de maintenance envoyés par courriel incluent une requête prête à exécuter pour cet outil.
Lorsque le rapport identifie une erreur, la requête est déjà paramétrée pour filtrer les opérations qui ont échoué pour cette tâche.

Voir [Diagnostics et rapports](diagnostics.md#maintenance-diagnostics-with-mainthistoryview)
pour des exemples d’historique complet et d’investigation des erreurs.

Pour la référence de la procédure de maintenance principale, voir
[Maint.YourSqlDba_DoMaint](maintenance/your-sql-dba-domaint.md).
