---
layout: default
title: Pour qui est YourSqlDba
parent: YourSqlDba documentation (fr)
nav_order: 1
has_children: false
---

# Pour qui est YourSqlDba

YourSqlDba s’adresse d’abord aux DBA, accidentels ou professionnels. Les
premiers n’ont souvent qu’une connaissance élémentaire de ce rôle, contrairement
aux seconds, mais la solution peut répondre aux besoins des deux grâce à une
configuration initiale directement exploitable et à des possibilités de
personnalisation avancées.

Un autre public cible est constitué des responsables de solutions applicatives
spécialisées reposant sur une instance SQL Server dédiée à une seule base. Sans
être DBA, ils savent que les données doivent être sauvegardées et protégées, et
ont besoin d’une maintenance fiable nécessitant peu d’administration
quotidienne.

## Le défi

Les professionnels informatiques se voient souvent confier des responsabilités à temps partiel
pour lesquelles ils n’ont pas été suffisamment formés. L’administration de bases de données en fait partie.
Ils deviennent des DBA accidentels.

Après des années d’efforts pour former ces DBA accidentels, j’ai observé que leur manque de pratique régulière
entraîne des omissions graves et récurrentes.

Quelqu’un qui assume une responsabilité aussi importante, à temps partiel et parallèlement à des priorités
non liées, ne peut raisonnablement pas tout vérifier chaque jour. C’est une tâche ingrate, et une grande partie
peut être automatisée.

Pour un DBA professionnel, l’automatisation demeure tout aussi pertinente.
YourSqlDba peut fournir une solution complète, tout en offrant la flexibilité
nécessaire pour répartir ou paralléliser le travail lorsque le nombre de bases,
leur volume ou la fenêtre de maintenance imposent une organisation plus
élaborée.

À l’autre extrémité du spectre, YourSqlDba maintient un dialogue opérationnel
avec le responsable applicatif grâce à ses rapports. Celui-ci peut savoir si la
maintenance et les sauvegardes s’exécutent correctement, sans devoir maîtriser
leur fonctionnement interne.

Cette visibilité ne remplace toutefois pas une copie des sauvegardes à
l’extérieur du serveur. Selon l’environnement, il faut rappeler au responsable
d’échanger régulièrement les supports amovibles, ou configurer les sauvegardes
vers un serveur de fichiers lui-même protégé par un service de sauvegarde de
niveau supérieur.

## L’idée

SQL Server documente ce qu’il possède comme des données ordinaires : bases, tables, index, historique de sauvegarde,
tâches, etc. Il permet aussi de générer par script les mêmes opérations que SSMS exécute, car SSMS génère lui-même
des instructions T-SQL.

Le langage T-SQL permet de construire dynamiquement des instructions sous forme de chaînes de caractères, puis de les exécuter.
Dans ce contexte, les données variables sont essentiellement les noms des objets à gérer. En intégrant des métadonnées —
les noms de bases de données, de tables, d’index, etc. — dans des chaînes représentant des instructions de maintenance,
on peut construire une fonctionnalité d’administration de bases de données automatisée.

C’est là que l’idée a émergé : la maintenance de bases de données pouvait être automatisée en SQL pur,
de manière suffisamment dynamique pour s’adapter à de nouvelles bases, de nouvelles tables et de nouveaux index.
YourSqlDba est né de cette idée.

YourSqlDba est livré sous forme d’un script qui crée une base de données du même nom et déploie des modules SQL dans celle-ci.
Le point d’entrée de la maintenance est une procédure unique qui appelle d’autres procédures.

## Filtrage dynamique des bases de données

Les DBA à temps partiel ne veulent pas nommer chaque base de données manuellement.
YourSqlDba utilise des filtres qui ciblent les bases dynamiquement par motif :

- des motifs d’inclusion pour sélectionner des bases de manière générique,
- des motifs d’exclusion pour retirer les bases indésirables,
- plusieurs listes de motifs pour s’adapter automatiquement à l’évolution des bases.

La règle est simple :

- si le filtre d’inclusion n’est pas vide, il réduit l’ensemble des bases à gérer ;
- le filtre d’exclusion retire ensuite ce qui ne doit pas être géré de l’ensemble restant ;
- que le filtre d’inclusion ait réduit la liste ou non, le filtre d’exclusion s’applique toujours.

Une fois la sélection des bases déterminée, la procédure principale effectue le travail.

## Ce que la solution gère

YourSqlDba automatise les actions de maintenance de base essentielles :

- sauvegardes,
- vérifications d’intégrité,
- mises à jour des statistiques,
- optimisation des index (réorganisation ou reconstruction selon le cas).

La tâche d’optimisation est divisée en deux parties :

1. mise à jour des statistiques pour que SQL Server choisisse les meilleurs plans de requête,
2. réorganisation ou reconstruction des index qui deviennent fragmentés et surdimensionnés au fil du temps.

## Pourquoi l’automatisation est importante

Un DBA ne devrait pas avoir à surveiller et piloter tout manuellement si la solution peut s’exécuter selon un calendrier précis.
SQL Server Agent rend possible l’exécution récurrente et peut signaler les problèmes.

Les rapports sont essentiels. YourSqlDba les fournit avec :

- un résumé d’exécution,
- les commandes SQL émises,
- le statut de réussite/échec et les messages d’erreur,
- des requêtes de diagnostic prêtes à copier/coller.

## Qui devrait utiliser YourSqlDba

1. Propriétaires d’applications déployés sur un serveur unique: Le support applicatif déploie pour lui la maintenance pour la base de données applicative. En cas de problème, le propriétaire en informe le support applicatif. Les chances de problèmes sont faibles.
2. DBA accidentels : Pour éviter l'oubli de tâches, recevoir des alertes appropriées et permettre l’escalade vers des experts SQL lorsque nécessaire si les diagnostics fournis ne les éclairent pas.
3. DBA professionnels : Faire ce que les DBA accidentels peuvent faire avec en plus, en cas de charge excessive de la maintenance, diviser les tâches avec des plannings différents. Évidemment les diagnostics détaillés des problèmes leur seront plus familiers.
4. Scénarios de délégation : Pour les DBA professionels ou occasionnels, se libérer de la charge en délégant des opérations limitées de sauvegarde, restauration et rafraîchissement de bases de données pour des bases sélectionnées et des utilisateurs spécifiques. Ces utilisateurs sont généralement des responsables d'application.

## Comment il est livré

YourSqlDba est livré sous forme d’un script installable unique. Son exécution crée la base de données `YourSqlDba`
et tous les modules de maintenance.

L’activation initiale est réalisée par une procédure utilitaire qui ne doit être exécutée qu’une seule fois.
Une configuration Database Mail complète le processus et permet à YourSqlDba de communiquer les résultats par courriel.
