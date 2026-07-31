---
layout: default
title: Qu'est-ce que YourSqlDba ?
parent: YourSqlDba documentation (fr)
nav_order: 1
has_children: false
---

# Qu'est-ce que YourSqlDba ?

> **English version: [What is YourSqlDba?](../what-is-yoursqldba.md)**

YourSqlDba est un outil open source de maintenance et d’automatisation pour
Microsoft SQL Server, développé par Maurice Pelchat. Entièrement écrit en
T-SQL, il est distribué sous la forme d’un script unique qui crée une base de
données nommée `YourSqlDba` sur l’instance SQL Server. Il automatise notamment
les sauvegardes, les contrôles d’intégrité, l’entretien des index et des
statistiques, le nettoyage, les diagnostics et la production de rapports. Il
permet aussi de déléguer de manière contrôlée certaines opérations de gestion
de bases de données à des utilisateurs non `sysadmin`.

Son objectif est d’automatiser les tâches de maintenance récurrentes et de
fournir un cadre cohérent aux DBA professionnels, occasionnels ou accidentels.
La configuration initiale est directement exploitable, tandis que les horaires,
les filtres de bases, les règles de rétention et les opérations exécutées
demeurent visibles et configurables.

## Que fait YourSqlDba ?

YourSqlDba automatise notamment :

- les sauvegardes complètes, différentielles et des journaux de transactions ;
- les vérifications d’intégrité avec `DBCC CHECKDB` ;
- la mise à jour des statistiques ;
- la réorganisation ou la reconstruction des index selon leur état et les
  seuils configurés ;
- le nettoyage des anciens fichiers de sauvegarde ;
- la collecte d’informations de diagnostic et la production de rapports par
  courriel.

## Comment fonctionne-t-il ?

YourSqlDba repose sur des composants natifs de SQL Server :

- T-SQL ;
- SQL Server Agent ;
- Database Mail.

Le script d’installation crée la base `YourSqlDba` et y déploie ses procédures
stockées, fonctions, vues, tables et autres objets de soutien. L’exécution de
`Install.InitialSetupOfYourSqlDba` réalise la configuration initiale et crée
deux travaux SQL Server Agent par défaut. Ces travaux appellent la procédure de
maintenance principale :

```sql
Maint.YourSqlDba_DoMaint
```

Cette procédure coordonne les opérations courantes de maintenance. Consultez
les [Premiers pas](getting-started.md) et la référence de
[`Maint.YourSqlDba_DoMaint`](maintenance/your-sql-dba-domaint.md).

## Comment peut-il être personnalisé ?

Les administrateurs peuvent :

- sélectionner les bases au moyen de filtres d’inclusion et d’exclusion ;
- créer des travaux SQL Server Agent ayant différents horaires et différentes
  actions ;
- répartir les contrôles d’intégrité, les mises à jour des statistiques et les
  travaux d’indexation coûteux entre plusieurs exécutions ;
- configurer des stratégies de sauvegarde et de rétention adaptées à chaque
  environnement.

Consultez la page [Configuration](configuration.md) pour connaître les contrôles
disponibles.

## Comment fonctionne la gestion déléguée ?

YourSqlDba permet aux administrateurs d’autoriser certains utilisateurs non
`sysadmin`, comme les responsables d’applications ou le personnel de soutien
avancé, à effectuer des opérations précises sur une liste déterminée de bases.
Ces opérations comprennent la sauvegarde, la restauration, la duplication, le
rafraîchissement, le nettoyage des sauvegardes, le mode maintenance et les flux
de mise à niveau applicative.

Les autorisations sont configurées centralement dans
`Maint.DelegatedDbManagement`. Des protections supplémentaires, notamment les
règles de nommage des cibles de restauration, empêchent un utilisateur délégué
d’écraser la base source ou une base non liée. Ce modèle permet d’appliquer le
principe du moindre privilège sans accorder le rôle `sysadmin`. Consultez la
[documentation sur la gestion déléguée](maintenance/delegated-database-management.md).

## Comment les problèmes sont-ils diagnostiqués ?

La fonction table en ligne `Maint.HistoryView` centralise les commandes, les
messages, les erreurs, le contexte d’exécution, l’état et la durée enregistrés
pendant la maintenance. Les rapports par courriel fournissent une requête prête
à exécuter pour examiner rapidement l’exécution concernée. Consultez la page
[Diagnostics et rapports](diagnostics.md).

## À qui s’adresse YourSqlDba ?

Le projet est particulièrement adapté :

- aux organisations qui ne disposent pas d’un DBA à temps plein ;
- aux éditeurs de logiciels qui livrent des solutions reposant sur SQL Server ;
- aux instances SQL Server qui hébergent de nombreuses bases de données ;
- aux DBA professionnels qui recherchent un cadre de maintenance transparent,
  configurable et entièrement en T-SQL ;
- aux équipes qui doivent déléguer des opérations contrôlées sans accorder les
  privilèges `sysadmin`.

Pour en savoir plus, consultez
[À qui s’adresse YourSqlDba](Who-YourSqlDba-is-for.md).

## Philosophie et historique du projet

YourSqlDba est conçu pour être installé à l’aide d’un seul script, puis mis à
jour en réexécutant la version courante de ce script. Sa logique de maintenance
demeure visible dans SQL Server. Il évite les travaux inutiles en choisissant
les opérations selon l’état des bases et des index plutôt qu’en exécutant
systématiquement toutes les tâches à chaque passage.

Le projet existe depuis 2007. Son approche d’auto-maintenance des bases de
données a valu à Maurice Pelchat le
[SQL Server Magazine 2007 Innovator Award](https://www.linkedin.com/in/maurice-pelchat-9891495/).
Il continue d’être maintenu et documenté en ligne.

Pour les environnements SQL Server, YourSqlDba constitue une solution ouverte
et hautement configurable par rapport aux plans de maintenance intégrés, avec
des diagnostics détaillés et sans environnement logiciel supplémentaire.
