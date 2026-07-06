---
layout: default
title: Installation et mise à niveau
parent: YourSqlDba documentation (fr)
nav_order: 20
---

# Installation et mise à niveau

Installez YourSqlDba en exécutant le script d’installation principal T-SQL. Cela crée
ou met à jour la base de données `YourSqlDba` et déploie les objets utilisés par la maintenance.

## Prérequis

- Instance SQL Server avec SQL Agent activé
- autorisations pour créer ou modifier la base de données `YourSqlDba`
- accès aux répertoires de sauvegarde utilisés par SQL Server
- Database Mail disponible pour l’envoi des rapports par courriel
- compte Windows ou compte de service capable d’écrire dans les chemins de sauvegarde

## Première installation

Pour une première installation :

1. Ouvrez `YourSQLDba_InstallOrUpdateScript.sql` dans SQL Server Management Studio.
2. Exécutez le script sur l’instance SQL Server cible.
3. Exécutez `Install.InitialSetupOfYourSqlDba` avec des valeurs adaptées à votre environnement.
4. Vérifiez les tâches SQL Agent créées et leurs planifications.
5. Confirmez que Database Mail et les notifications SQL Agent fonctionnent.

Exemple :

```sql
EXEC Install.InitialSetupOfYourSqlDba
    @FullBackupPath = N'D:\SQLBackups',
    @LogBackupPath = N'D:\SQLBackups',
    @email = N'dba-team@example.com',
    @SmtpMailServer = N'smtp.example.com';
```

## Configuration initiale

La configuration initiale crée les tâches de maintenance SQL Agent par défaut et configure :

- le chemin des sauvegardes complètes
- le chemin des sauvegardes du journal de transactions
- le profil Database Mail
- le serveur SMTP
- les destinataires de notifications
- les planifications SQL Agent

Cette étape est requise après une première installation.

## Tâches SQL Agent créées

La configuration initiale crée deux tâches par défaut.

| Tâche | Procédure appelée | Objectif |
| --- | --- | --- |
| Maintenance complète | `Maint.YourSqlDba_DoMaint` | Maintenance quotidienne et sauvegardes complètes |
| Sauvegardes de journal | `Maint.YourSqlDba_DoMaint` | Sauvegardes fréquentes du journal de transactions |

Chaque tâche contient une étape SQL Agent qui appelle `Maint.YourSqlDba_DoMaint`
avec des paramètres différents.

## Mise à niveau

Pour mettre à niveau YourSqlDba, exécutez à nouveau le dernier
`YourSQLDba_InstallOrUpdateScript.sql`.

Le processus de mise à niveau préserve la configuration et l’historique de YourSqlDba
tout en mettant à jour les objets de la base de données.

Après une mise à niveau :

1. Passez en revue l’historique de version.
2. Vérifiez les étapes des tâches SQL Agent pour détecter des changements.
3. Exécutez une tâche de maintenance manuellement si vous souhaitez une validation immédiate.
4. Confirmez que le rapport de maintenance par courriel est reçu.

## Quand relancer la configuration initiale

Relancez `Install.InitialSetupOfYourSqlDba` uniquement lorsque vous devez recréer
les définitions par défaut des tâches, les chemins de sauvegarde, le profil de messagerie ou les paramètres de notification.

> **Attention :** `Install.InitialSetupOfYourSqlDba` recrée la définition par défaut
> des tâches de maintenance quotidienne et de sauvegarde du journal. Vérifiez toute
> étape SQL Agent personnalisée avant de la relancer.
