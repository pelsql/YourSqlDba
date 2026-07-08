# YourSqlDba

**Coordonnées : [Maurice Pelchat](https://www.linkedin.com/in/maurice-pelchat-9891495/)**

> **English version: [README.md](README.md).**

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

## Dernière version : 7.1.0.12

1. **Délégation contrôlée des opérations de gestion de bases de données**

   YourSqlDba fournit maintenant un modèle de délégation à privilèges minimaux pour les propriétaires d'applications et les utilisateurs de soutien avancés qui doivent rafraîchir des bases de données hors production, tester ou annuler des mises à niveau applicatives, ou nettoyer des sauvegardes sans recevoir les privilèges `sysadmin`.

   Un sysadmin autorise chaque connexion déléguée avec `Maint.DelegatedDbManagement`. Les cibles de restauration sont limitées par des règles de nommage qui empêchent les utilisateurs délégués d'écraser des bases sources ou non liées.

2. **Gestion simplifiée des fichiers de sauvegarde du journal des transactions**

   La sauvegarde initiale du journal des transactions produite après une sauvegarde de maintenance complète ou différentielle conserve maintenant son propre nom de fichier et n'est plus réutilisée par le travail régulier de sauvegarde du journal.

   La prochaine sauvegarde régulière du journal crée le fichier réutilisable de sauvegarde du journal et l'inscrit dans `Maint.JobLastBkpLocations.lastLogBkpFile`. Lorsque `@BkpLogsOnSameFile = 0`, chaque sauvegarde régulière du journal continue d'utiliser un nouveau fichier.

3. **Mises à niveau de YourSqlDba plus résilientes**

   Les informations de mise à niveau sont préservées temporairement dans la base de données `YourSqlDbaUpgradeSavedInfos`. Cela protège la configuration existante si une mise à niveau échoue. La base temporaire est supprimée après une mise à niveau réussie. La gestion de l'accès exclusif pendant les mises à niveau a aussi été améliorée.

4. **Accès exclusif pour les restaurations déléguées**

   Avant une restauration déléguée par un utilisateur non sysadmin, YourSqlDba termine les sessions actives connectées à la base cible. Les utilisateurs délégués ne peuvent normalement pas terminer ces sessions eux-mêmes, et leurs cibles de restauration sont déjà restreintes.

   Pour les sysadmins, les sessions ne sont pas terminées automatiquement, car une erreur de paramètre pourrait toucher une base non liée ou de production. Les sysadmins doivent gérer explicitement les sessions actives lorsqu'ils utilisent `Maint.DuplicateDb`, `Maint.DuplicateDbFromBackupHistory` ou `Maint.RestoreDb`. Ils peuvent appeler `S#.KillDbUsers` explicitement lorsque c'est approprié.
