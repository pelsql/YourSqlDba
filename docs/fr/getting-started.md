---
layout: default
title: Premiers pas
nav_order: 10
---

# Premiers pas

YourSqlDba automatise la maintenance SQL Server en utilisant une base de données dédiée,
`YourSqlDba`, des tâches SQL Agent et des procédures stockées.

La procédure de maintenance centrale est :

```sql
Maint.YourSqlDba_DoMaint
```

Son principal compagnon diagnostic est
[`Maint.HistoryView`](diagnostics.md#maintenance-diagnostics-with-mainthistoryview).
Il présente les commandes, les messages, le statut et les erreurs enregistrés par les
tâches de maintenance et peut corréler les tâches exécutées durant la même période.

Cette page explique le flux de travail du DBA, les tâches par défaut et les premières vérifications après la configuration.

## Ce que fait YourSqlDba

YourSqlDba est conçu pour exécuter des tâches de maintenance standard sur plusieurs
bases de données sans nécessiter un plan de maintenance personnalisé pour chaque base.

Il peut :

- créer des sauvegardes complètes, différentielles et de journal de transactions
- nettoyer les anciens fichiers de sauvegarde
- exécuter des vérifications d’intégrité de base de données
- mettre à jour les statistiques de l’optimiseur
- réorganiser ou reconstruire les index lorsque c’est approprié
- nettoyer l’historique de SQL Server, SQL Agent, mail, sauvegarde et maintenance
- envoyer des rapports de maintenance par courriel
- enregistrer un historique d’exécution détaillé pour le dépannage

## Approche de conception

La configuration initiale est destinée à fournir une maintenance utile sans exiger
de plan de maintenance séparé pour chaque base. Pour de nombreuses instances de petite
ou moyenne taille, les tâches par défaut sont un point de départ pratique qui peut être
ajusté après examen des premières exécutions.

YourSqlDba limite également le travail qui n’a pas besoin d’être exécuté entièrement
à chaque fenêtre de maintenance. Les mises à jour de statistiques et les vérifications
complètes peuvent être étalées sur plusieurs exécutions, tandis que la maintenance des
index cible les index selon leur état. Ces comportements rendent le cycle de maintenance
plus facile à faire tenir dans la fenêtre disponible.

Le reporting détaillé fait partie du modèle de fonctionnement, pas d’une simple option.
Chaque exécution enregistre suffisamment de contexte pour identifier les commandes exécutées
et les erreurs survenues. Les rapports par courriel dirigent le DBA vers une requête sur `Maint.HistoryView`,
qui peut se concentrer sur les erreurs pertinentes ou montrer l’activité plus large autour de la tâche pour laquelle il fait un rapport.

## Démarrage rapide pour le DBA

1. Exécutez `YourSQLDba_InstallOrUpdateScript.sql` sur l’instance SQL Server cible.
2. Exécutez `Install.InitialSetupOfYourSqlDba` avec des valeurs adaptées à votre environnement.
3. Vérifiez les tâches SQL Agent et les étapes qui appellent `Maint.YourSqlDba_DoMaint`.
4. Vérifiez les chemins de sauvegarde, les paramètres de messagerie et la première exécution de maintenance.
5. Utilisez `Maint.HistoryView` pour examiner les erreurs signalées par cette exécution.
6. Ajustez les paramètres de `Maint.YourSqlDba_DoMaint` pour votre environnement.

## Tâches par défaut

La configuration initiale crée deux tâches SQL Agent :

| Tâche | Planification | Objectif |
| --- | --- | --- |
| Maintenance complète | Quotidienne, vers minuit | Sauvegardes complètes, vérifications d’intégrité, mises à jour statistiques et maintenance des index |
| Sauvegardes de journal | Toutes les 15 minutes | Sauvegardes du journal de transactions pour les bases en mode récupération complète |

Ces tâches appellent généralement la même procédure avec des paramètres différents.

## Du paramétrage par défaut aux configurations avancées

La configuration active de maintenance reste visible dans les planifications SQL Agent
et les étapes des tâches. Un DBA peut l’adapter progressivement en :

- modifiant la planification d’une tâche par défaut ;
- utilisant `@IncDb` et `@ExcDb` pour cibler des groupes de bases de données ;
- séparant les sauvegardes, les vérifications d’intégrité, les statistiques ou la maintenance des index dans des étapes différentes ;
- créant des tâches supplémentaires lorsqu’un groupe de bases de données nécessite sa propre planification ;
- utilisant le mirroring basé sur restauration pour maintenir une copie récupérable ou préparer une migration vers une autre instance SQL Server.

Si toutes les bases sélectionnées peuvent être maintenues séquentiellement dans la fenêtre disponible,
la structure par défaut peut suffire. Lorsque cette fenêtre devient trop longue, la même procédure peut être
divisée entre tâches ou étapes sans remplacer le cadre de maintenance.

## Ce qu’il faut vérifier après la configuration

Après l’installation et la configuration initiale, confirmez que :

- les tâches SQL Agent existent et sont activées
- les étapes appellent `Maint.YourSqlDba_DoMaint`
- `@FullBackupPath` et `@LogBackupPath` sont corrects
- le profil Database Mail et le serveur SMTP sont configurés
- les destinataires de notification sont définis
- la première exécution de maintenance se termine avec succès

## Où personnaliser la maintenance

Le point de configuration principal est l’étape SQL Agent qui appelle
`Maint.YourSqlDba_DoMaint`.

Les personnalisations courantes incluent :

- exclure des bases de données de la tâche par défaut
- maintenir un groupe de bases de données spécifique uniquement
- séparer les sauvegardes des vérifications d’intégrité
- ajuster la rétention des sauvegardes
- modifier le comportement des fichiers de sauvegarde de journal
- configurer le mirroring ou le comportement de restauration de secours

Voir [Configuration](configuration.md) et [Maint.YourSqlDba_DoMaint](maintenance/your-sql-dba-domaint.md) pour les paramètres détaillés.

