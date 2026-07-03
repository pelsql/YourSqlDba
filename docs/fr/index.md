---
layout: default
title: YourSqlDba documentation (Français)
nav_order: 1
has_children: true
---

# YourSqlDba (Français)

YourSqlDba est un script T-SQL libre qui automatise les tâches courantes de
maintenance des bases de données SQL Server. Il fournit une configuration par
défaut pratique pour la maintenance régulière, tout en restant adaptable aux
instances qui hébergent de nombreuses bases, utilisent différents horaires ou
ont des exigences opérationnelles plus spécialisées.

**Documentation anglaise : [YourSqlDba](../)**

Pour mieux comprendre les cas d’utilisation du produit, consultez
[Pour qui est YourSqlDba](Who-YourSqlDba-is-for.md).

Résumé
------

Le projet fournit un seul script d’installation qui crée une base nommée
`YourSqlDba` sur l’instance SQL Server cible. Cette base contient les procédures
stockées, fonctions et objets de soutien utilisés pour planifier et exécuter les
sauvegardes, contrôles d’intégrité, entretiens des index, collectes de métriques
et diagnostics.

YourSqlDba s’appuie sur des composants que les DBA utilisent déjà : T-SQL, SQL
Server Agent et Database Mail pour les rapports. Les tâches par défaut offrent
un point de départ direct, tandis que leurs horaires et leurs appels à
`Maint.YourSqlDba_DoMaint` demeurent visibles et configurables.

Pourquoi utiliser YourSqlDba
----------------------------

- Il regroupe les sauvegardes, contrôles d’intégrité, mises à jour des
  statistiques, entretiens sélectifs des index, nettoyages et rapports dans un
  même flux de maintenance.
- Il évite du travail inutile en répartissant certaines opérations entre les
  exécutions et en entretenant les index selon leur état.
- Il évolue depuis la configuration initiale de deux tâches vers des groupes de
  bases ayant des actions et horaires différents, au moyen des étapes SQL Agent
  et des filtres sur les noms de bases.
- Ses rapports détaillés et `Maint.HistoryView` exposent les commandes,
  messages, contextes d’exécution, états et erreurs produits par la maintenance.
- Son mirroring par restauration peut valider les chaînes de sauvegarde,
  maintenir des copies récupérables sur une autre instance et préparer une
  migration SQL Server côte à côte.

Liens rapides
-------------

- [Historique des versions et notes de version](releases.md)
- [Pour qui est YourSqlDba](Who-YourSqlDba-is-for.md)
- [Premiers pas](getting-started.md)
- [Installation et mise à niveau](installation.md)
- [Configuration](configuration.md)
- [`Maint.YourSqlDba_DoMaint`](maintenance/your-sql-dba-domaint.md), point d’entrée principal de la maintenance
- [Délégation de la gestion de base de données](maintenance/delegated-database-management.md)
- [Miroir, standby et tests de migration](maintenance/mirror-standby-migration.md)
- [Référence des procédures de mirroring](maintenance/mirroring-reference.md)
- [Solutions de sauvegarde externes](maintenance/external-backup-solutions.md)
- [Diagnostics et rapports](diagnostics.md), notamment `Maint.HistoryView`
- [README.md du projet](https://github.com/pelsql/YourSqlDba#readme)
- [Dernier script d’installation](https://raw.githubusercontent.com/pelsql/YourSqlDba/refs/heads/master/YourSQLDba_InstallOrUpdateScript.sql)

Comment démarrer
---------------

1. Lisez la page [Premiers pas](getting-started.md).
2. Suivez le guide [Installation et mise à niveau](installation.md).
3. Exécutez `YourSQLDba_InstallOrUpdateScript.sql` sur l’instance SQL Server où
   vous souhaitez installer YourSqlDba.
4. Complétez la configuration de SQL Server Agent et Database Mail décrite dans
   le guide d’installation.
