---
layout: default
title: Délégation de la gestion de base de données
parent: Maintenance
grand_parent: YourSqlDba documentation (fr)
nav_order: 20
---

# Délégation de la gestion de base de données

La délégation est utile lorsque la responsabilité d’une application ou d’une
base précise est partagée avec quelqu’un qui n’est pas DBA. YourSqlDba permet
alors à un propriétaire d’application ou à un utilisateur de support senior
d’exécuter des opérations limitées sans recevoir de privilèges SQL Server
illimités.

Deux contextes reviennent souvent :

- créer une copie d’archive, de test ou de validation à partir d’une base
  existante ;
- gérer une mise à niveau de base de données liée à une mise à niveau
  applicative.

Pour les copies d’archive ou de test, la procédure
`Maint.DuplicateDbFromBackupHistory` est souvent le chemin le plus direct. Elle
restaure une base sous un autre nom à partir des sauvegardes déjà connues de
YourSqlDba. Par défaut, elle ajoute une dernière sauvegarde de journal,
habituellement rapide, afin de produire une copie aussi récente que possible
sans refaire une sauvegarde complète.

Les procédures plus spécialisées permettent aussi de créer une sauvegarde
copy-only, restaurer un fichier précis ou nettoyer les sauvegardes associées au
flux délégué. Dans tous les cas, YourSqlDba limite le login délégué aux bases
sources explicitement autorisées et, pour les restaurations, aux noms cibles
dérivés de ces sources.

Les mises à niveau applicatives posent un problème supplémentaire. La mise à niveau peut nécessiter un accès exclusif à la base
de données et un point de restauration fiable en cas d’échec de mise à niveau. Déconnecter les sessions en cours ne suffit pas toujours :
les services applicatifs, pools de connexions, outils de supervision ou processus planifiés peuvent se reconnecter immédiatement.

Le flux de travail en mode maintenance regroupe les étapes nécessaires :
déconnecter les utilisateurs, renommer temporairement la base avec le suffixe
`_MaintenanceMode`, établir un point de récupération, puis revenir au nom
normal après validation. Les clients configurés avec le nom d’origine ne
peuvent plus se reconnecter pendant l’intervention. Si la mise à niveau échoue,
la base peut être restaurée à son état initial ; si elle réussit, elle est
simplement remise en usage normal.

Les utilisateurs non-sysadmin doivent être identifiés avec leurs limites d'accès dans la table `YourSqlDba.Maint.DelegatedDbManagement`. Voir le [Modèle d'autorisation](#modele-dautorisation) pour comprendre comment le faire et [Configurer un login délégué](#configurer-un-login-delegue). Après validation des flux délégués, retirez à ces utilisateurs les autorisations plus larges qui ne sont plus nécessaires,
comme l’adhésion au rôle fixe de serveur `dbcreator` ou au rôle fixe de base `db_backupoperator`.

Voir les procédures pour les [sauvegardes déléguées](#procedures-de-sauvegarde-deleguees),
[duplication et restauration](#procedures-de-duplication-et-de-restauration-deleguees),
[nettoyage des sauvegardes](#nettoyage-des-sauvegardes-deleguees) et le
[flux de travail de mise à niveau d’application](#flux-de-travail-de-mise-a-niveau-dapplication).

{: .warning }
> **Changement critique :** Les scripts existants non-sysadmin qui appellent des procédures déléguées
> peuvent cesser de fonctionner après la mise à niveau. Un sysadmin doit ajouter chaque login et ses bases
> sources autorisées à `Maint.DelegatedDbManagement` avant que ces scripts ne soient réexécutés.
> Les cibles de restauration doivent aussi respecter les règles de nommage ci-dessous.

## Modèle d’autorisation
{: #modele-dautorisation }

La délégation est configurée dans `YourSqlDba.Maint.DelegatedDbManagement`.
La table contient une ligne par login délégué.

| Colonne | Objectif |
| --- | --- |
| `LoginName` | Login retourné par `ORIGINAL_LOGIN()` pour l’utilisateur délégué. |
| `SourceDatabaseList` | Bases de données sources séparées par des virgules autorisées pour les opérations déléguées générales. |
| `MaintenanceModeDatabaseList` | Bases de données optionnelles séparées par des virgules autorisées pour le flux de travail de mise à niveau d’application. |
| `CreatedAt` | Date et heure de création de la ligne. |
| `CreatedBy` | Login qui a créé la ligne. |

`SourceDatabaseList` autorise les opérations de sauvegarde, duplication, restauration et nettoyage décrites sur cette page.
`MaintenanceModeDatabaseList` autorise le flux de travail plus spécifique en mode maintenance.
Une base listée dans `SourceDatabaseList` est déjà autorisée pour les deux catégories ;
la seconde liste est utile lorsqu’un login ne doit recevoir que l’autorisation de mode maintenance pour une base.

Les logins sysadmin ne sont pas restreints par cette table.

## Configurer un login délégué
{: #configurer-un-login-delegue }

Exécutez ces instructions en tant que sysadmin dans la base de données `YourSqlDba`.
Les noms de bases dans les deux listes sont séparés par des virgules.
Vous pouvez modifier directement la table dans SSMS en sélectionnant **Edit Top 200 Rows**
via le menu contextuel, ou adapter les exemples `INSERT`, `UPDATE` et `DELETE` ci-dessous.

### Ajouter un login

```sql
USE YourSqlDba;
GO

INSERT Maint.DelegatedDbManagement
       (LoginName, SourceDatabaseList, MaintenanceModeDatabaseList)
VALUES (N'DOMAIN\AppSupport',
        N'Payroll,Accounting',
        N'Payroll');
```

### Modifier son autorisation

La mise à jour remplace le contenu complet de chaque liste.

```sql
UPDATE Maint.DelegatedDbManagement
SET SourceDatabaseList = N'Payroll,Accounting,Reporting',
    MaintenanceModeDatabaseList = N'Payroll,Accounting'
WHERE LoginName = N'DOMAIN\AppSupport';
```

### Vérifier la configuration

```sql
SELECT LoginName,
       SourceDatabaseList,
       MaintenanceModeDatabaseList,
       CreatedAt,
       CreatedBy
FROM Maint.DelegatedDbManagement
ORDER BY LoginName;
```

### Révoquer la délégation

```sql
DELETE Maint.DelegatedDbManagement
WHERE LoginName = N'DOMAIN\AppSupport';
```

## Règles de nommage des cibles de restauration

Un login non-sysadmin délégué ne peut pas restaurer par-dessus la base source ni utiliser un nom cible non lié.
La cible doit commencer par le nom complet de la source, suivi d’un underscore et d’un suffixe.

Pour une base source nommée `Payroll`, les cibles valides incluent :

- `Payroll_AppSupport`
- `Payroll_UpgradeTest`
- `Payroll_2026Q3`

Les cibles invalides comprennent :

- `Payroll`, car un utilisateur délégué ne peut pas écraser la source ;
- `PayrollTest`, car l’underscore requis manque ;
- `ProductionPayroll`, car il ne dérive pas de la source autorisée.

Ne créez pas une base de production dont le nom ressemble à un dérivé délégué d’une autre base.
Par exemple, si `Payroll` est délégué, une base comme `Payroll_Production` semblerait être une dérivée autorisée alors que `PayrollProduction` ne le serait pas.

## Procédures de sauvegarde déléguées
{: #procedures-de-sauvegarde-deleguees }

Les procédures suivantes exigent que la base source soit présente dans `SourceDatabaseList` :

- `Maint.SaveDbOnNewFileSet` crée une sauvegarde en utilisant les règles de nommage et de sauvegarde de YourSqlDba.
- `Maint.SaveDbCopyOnly` crée une sauvegarde copy-only au chemin et nom de fichier spécifiés.

Exemple :

```sql
EXEC Maint.SaveDbCopyOnly
    @DbName = N'Payroll',
    @PathAndFilename = N'D:\SQLBackups\Payroll_AppSupport.bak';
```

## Procédures de duplication et de restauration déléguées
{: #procedures-de-duplication-et-de-restauration-deleguees }

Les procédures suivantes appliquent à la fois l’autorisation source et les règles de nommage de la cible :

- `Maint.DuplicateDb` crée une sauvegarde intermédiaire, la restaure sous le
  nom cible, puis supprime cette sauvegarde intermédiaire par défaut.
- `Maint.DuplicateDbFromBackupHistory` restaure à partir des sauvegardes déjà
  enregistrées par YourSqlDba et peut ajouter une dernière sauvegarde de
  journal avant la restauration.
- `Maint.RestoreDb` restaure un fichier de sauvegarde spécifié ; la base source est validée à partir des informations de sauvegarde.

`Maint.DuplicateDbFromBackupHistory` est généralement plus rapide lorsque la
chaîne de sauvegardes existe déjà : il évite de refaire une sauvegarde complète
et réutilise les sauvegardes de journal subséquentes déjà produites. La
dernière sauvegarde de journal qu’il ajoute est conservée dans le fichier de
journal existant ; elle reste ensuite soumise aux règles normales de rétention
des sauvegardes.

Exemples :

```sql
EXEC Maint.DuplicateDbFromBackupHistory
    @SourceDb = N'Payroll',
    @TargetDb = N'Payroll_UpgradeTest';

EXEC Maint.DuplicateDb
    @SourceDb = N'Payroll',
    @TargetDb = N'Payroll_AppSupport';
```

Avant de restaurer sur une cible déléguée existante, YourSqlDba termine ses sessions actives car un utilisateur non-sysadmin
ne peut normalement pas le faire. Ceci n’est pas effectué automatiquement pour les sysadmins : comme ils peuvent restaurer des bases non liées (ce qui est dangereux)
et doivent donc gérer explicitement les sessions actives si nécessaire. La procédure S#.KillDbUsers de YourSqlDba facilite cette tâche. RAPPEL (un script SQL ne peut demander de confirmation, alors veuillez les vérifier soigneusement).

## Nettoyage des sauvegardes déléguées
{: #nettoyage-des-sauvegardes-deleguees }

`Maint.DeleteOldBackups` permet à un login délégué de supprimer d’anciens fichiers de sauvegarde uniquement pour les variantes de bases qui dérivent
de ses sources autorisées. La même règle source_nom + underscore + suffixe s’applique.

Vérifiez attentivement `@Path`, la rétention, l’extension, `@IncDb` et `@ExcDb` avant d’exécuter le nettoyage.
Un sysadmin n’est pas restreint aux variantes déléguées.

## Flux de travail de mise à niveau d’application
{: #flux-de-travail-de-mise-a-niveau-dapplication }

Le flux de travail en mode maintenance introduit ci-dessus fournit les transitions de nommage et le point de récupération nécessaires pour contrôler
une mise à niveau d’application.

Le flux de travail propose les procédures suivantes. L’étape de restauration est optionnelle et n’est utilisée que lorsqu’un retour arrière est nécessaire.

1. `Maint.PrepDbForMaintenanceMode` déconnecte les utilisateurs, renomme la base avec le suffixe `_MaintenanceMode` et établit le point de récupération.
2. `Maint.RestoreDbAtStartOfMaintenanceMode` restaure la base de données à ce point de récupération (cela efface les effets de la mise à niveau ratée) tout en laissant la base sous son nom de mode maintenance.
3. `Maint.ReturnDbToNormalUseFromMaintenanceMode` ramène la base à son nom normal et en usage normal.

Exemple :

```sql
EXEC Maint.PrepDbForMaintenanceMode
    @DbList = N'Payroll';

-- Exécutez et validez la mise à niveau de l’application contre Payroll_MaintenanceMode.

-- Si la mise à niveau échoue, revenez au point de récupération.
-- Vous pouvez retenter la mise à niveau sans relancer Maint.PrepDbForMaintenanceMode ;
-- après chaque échec, restaurez de nouveau ce même point de récupération.
EXEC Maint.RestoreDbAtStartOfMaintenanceMode
    @DbList = N'Payroll';

-- Remettez en service la base mise à niveau ou restaurée au point de récupération :
EXEC Maint.ReturnDbToNormalUseFromMaintenanceMode
    @DbList = N'Payroll';
```

L’autorisation pour ce flux de travail peut provenir soit de `SourceDatabaseList`, soit de `MaintenanceModeDatabaseList`.

## Liste de vérification de mise à niveau

Avant de mettre à niveau une instance qui utilise déjà des scripts de gestion non-sysadmin :

1. Identifiez chaque login qui appelle l’une des procédures listées sur cette page.
2. Enregistrez les bases sources requises par chaque login.
3. Insérez ou mettez à jour la ligne correspondante dans `Maint.DelegatedDbManagement`.
4. Mettez à jour les noms de cibles de restauration pour qu’ils utilisent `SourceDatabase_suffix`.
5. Testez chaque flux délégué avec le vrai login non-sysadmin.
6. Vérifiez tout nom de base de production qui pourrait être confondu avec un dérivé délégué.
