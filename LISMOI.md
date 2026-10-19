# YourSqlDba

[![Documentation IA : llms.txt](https://img.shields.io/badge/Documentation%20IA-llms.txt-555555)](https://pelsql.github.io/YourSqlDba/llms.txt)

**Coordonnées : [Maurice Pelchat](https://www.linkedin.com/in/maurice-pelchat-9891495/)**

> **English version: [README.md](README.md).**

YourSqlDba est un outil open source de maintenance et d’automatisation pour
Microsoft SQL Server, développé par Maurice Pelchat. Entièrement écrit en
T-SQL, il est distribué sous la forme d’un script unique qui installe une base
dédiée aux sauvegardes, aux contrôles d’intégrité, à l’entretien des index et
des statistiques, au nettoyage, aux diagnostics, aux rapports et à la
délégation contrôlée de certaines opérations à des utilisateurs non `sysadmin`.

Présentation canonique : [Qu’est-ce que YourSqlDba ?](https://pelsql.github.io/YourSqlDba/fr/qu-est-ce-que-yoursqldba.html)

À qui s'adresse YourSqlDba : [Introduction](https://pelsql.github.io/YourSqlDba/fr/Who-YourSqlDba-is-for.html)

Toute la documentation de YourSqlDba est disponible dans la
**[documentation GitHub Pages en français](https://pelsql.github.io/YourSqlDba/fr/)**.

Pour afficher la version actuellement installée de YourSqlDba, exécutez :
```sql
SELECT * FROM Install.VersionInfo();
```

**[Script d'installation de la dernière version](https://raw.githubusercontent.com/pelsql/YourSqlDba/refs/heads/master/YourSQLDba_InstallOrUpdateScript.sql)**

Pour les versions précédentes et les détails des changements entre les versions, consultez
l'[historique des versions et notes de version](https://pelsql.github.io/YourSqlDba/fr/releases.html).

> [!WARNING]
> **Changement incompatible - À partir de la version 7.1.0.12 - gestion déléguée des bases de données :** Les flux de travail existants de sauvegarde, restauration, duplication, nettoyage des sauvegardes ou mode maintenance pour des utilisateurs non sysadmin peuvent cesser de fonctionner après cette mise à niveau. Chaque connexion déléguée et ses bases de données autorisées doivent maintenant être configurées dans `Maint.DelegatedDbManagement`, et les cibles de restauration doivent respecter les nouvelles restrictions de nommage. Consultez la
> [documentation sur la gestion déléguée des bases de données](https://pelsql.github.io/YourSqlDba/fr/maintenance/delegated-database-management.html)
> avant de mettre à niveau une instance qui utilise des opérations déléguées.

> YourSqlDba fonctionne avec des travaux SQL Server Agent et Database Mail, qui doivent tous deux être configurés. Après avoir téléchargé et exécuté le script YourSqlDba, exécutez `Install.InitialSetupOfYourSqlDba` une fois par instance. Cette procédure configure Database Mail, les répertoires de sauvegarde et les comportements par défaut. Elle crée et planifie aussi deux travaux SQL Server Agent. Les mises à niveau futures ne nécessitent pas de réexécuter cette procédure.

> Chaque travail contient une seule étape de maintenance. Les deux appellent la procédure stockée principale, `Maint.YourSqlDba_DoMaint`, avec les paramètres appropriés au type de travail. Ces paramètres sont documentés en détail dans la documentation en ligne.

> Le rapport généré et les journaux incluent maintenant la liste des bases de données sélectionnées par les filtres de maintenance, afin que les utilisateurs puissent vérifier l'ensemble exact des bases ciblées par chaque exécution.

YourSqlDba est un grand script T-SQL qui automatise les tâches de maintenance de bases de données pour SQL Server. Il crée une base de données nommée `YourSqlDba` qui contient des modules T-SQL, dont des fonctions, des procédures stockées et des vues. La plupart fonctionnent derrière les travaux de maintenance planifiés, tandis que certains sont aussi utiles pour des travaux DBA occasionnels.

## Dernière version : 7.1.0.13

Le nettoyage des anciennes sauvegardes et la journalisation ont été améliorés.
La base de données `YourSqlDba` est maintenant sauvegardée séparément à la fin de
la maintenance afin de conserver un historique de maintenance aussi complet et
à jour que possible.

Pour les détails des versions précédentes, notamment le changement incompatible
introduit dans la version 7.1.0.12, consultez les
[notes de version en ligne](https://pelsql.github.io/YourSqlDba/fr/releases.html).
