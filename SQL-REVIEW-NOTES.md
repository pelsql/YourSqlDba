# Reprise de la révision SQL

Intégration au 17 octobre 2026 ; pistes de revue complétées le 18 octobre 2026. Aucun déploiement SQL, aucune suppression de sauvegardes et aucun commit effectués par l’agent pendant cette intégration.

## Intégration

- `Maint.DeleteOldBackups` dans `YourSQLDba_InstallOrUpdateScript.sql` a été remplacée par la version enregistrée de `Temp.sql`, commentaires compris, sans reprendre son exemple d’appel.
- Au moment de l’intégration, la procédure était identique à celle de `Temp.sql`. Les ajustements du 19 octobre décrits ci-dessous sont enregistrés dans le script d’installation ; `Temp.sql` n’a pas été synchronisé. Aucun test d’exécution SQL n’a été effectué.
- Le paramètre `@RefDate` a été retiré. La date de référence reste `Ctx.JobStart`.
- Les étapes `APPLY`, les branches `UNION ALL` et la boucle avec `DENSE_RANK()` sont conservées. Plusieurs raisons peuvent sélectionner un fichier ; la boucle ne le traite qu’une fois.

## Points de revue et état des corrections

1. Ajusté le 19 octobre dans le script d’installation : la projection du résultat CLR convertit `FileName = NULL` en `''`, avant les `PATINDEX`. Les branches d’erreur distinguent désormais le dossier (`FileName = ''`) du fichier (`FileName <> ''`). `ErrMessage` reste nullable et la boucle n’utilise plus le nom de remplacement `?`. La syntaxe passe le parseur SQL Server 2019 ; les cas d’erreur restent à vérifier à l’exécution sur l’instance cible.
2. **Cas connu, non urgent — aucune correction demandée pour le moment :** un `@path` explicitement `NULL` peut produire un message concaténé `NULL`, éliminé par le filtre sur `HowCaseIsHandled`. Le paramètre est obligatoire : son omission provoque déjà une erreur SQL. Les appels internes actuels transmettent des chemins validés par `YourSqlDba_DoMaint`. Le risque résiduel concerne surtout un script externe qui calcule un chemin et transmet une valeur `NULL` sans le vouloir ; cet usage n’est pas jugé assez courant pour justifier un traitement immédiat. Ne pas ajouter de validation dans cette procédure sans nouvelle demande.
3. Corrigé le 19 octobre : la condition d’envoi du rapport autonome utilise maintenant `NOT EXISTS` avec `MainSqlCmd LIKE '%Exec %Maint.YourSqlDba_DoMaint%'`. Le `$` littéral final a été remplacé par `%`.
4. Pour les essais autonomes successifs dans une même connexion, prendre en compte la réutilisation du contexte de session. Ne pas modifier le mécanisme du contexte appelant sans discuter de la distinction avec un contexte résiduel.

## Décisions déjà prises

- La fonction CLR conserve le nom et le message d’erreur d’un fichier, puis continue. Une erreur globale retourne un nom `NULL` et le message. Le marqueur `<ERROR>` est abandonné.
- `YourSqlDba_ApplyDbFilter` conserve son filtre ordinaire, puis ajoute par `UNION` master, model, msdb et YourSqlDba. La seconde sélection respecte aussi `@OnlineOnly` et `MaintenanceAllowed`.
- L’absence de miroir, de failover et de mise hors ligne pour ces quatre bases est contrôlée par les flags des appelants. YourSqlDba reste soumise à la politique FULL ; son passage en SIMPLE doit être signalé.
- Les sauvegardes spéciales YourSqlDba, puis msdb, sont déplacées à la finalisation de toute maintenance, avant libération du verrou et rapport. Aucune dépendance à `@BackupPhaseStarted`. La version actuelle utilise FULL pour YourSqlDba lors d’une maintenance sans sauvegarde demandée ; cette règle sera remplacée par l’orientation du 18 octobre ci-dessous.
- Les deux chemins de sauvegarde sont obligatoires pour toute maintenance. Aucun recours au dossier par défaut ni substitution du chemin complet au chemin des journaux.
- Respecter les préférences SQL de `AGENTS.md` et ne pas restructurer le code pendant une simple révision.

## Piste ajoutée le 18 octobre — différentiels en l’absence de sauvegardes de journaux

Demande à étudier, sans modification du code SQL à ce stade :

- Ajouter un indicateur à `Maint.DbInfoForYourSqlDba`, la vue qui alimente `YourSqlDba_ApplyDbFilter`. Il exprimerait la règle de sauvegarde différentielle lorsqu’il n’y a pas de sauvegardes de journaux. Le nom de l’indicateur reste à convenir.
- Le périmètre demandé est master, model, msdb et YourSqlDba, avec les exceptions techniques et fonctionnelles décrites ci-dessous.
- Préciser à la revue ce que signifie « pas de logs » : journaux non demandés dans cette exécution, absence de chaîne de sauvegardes de journaux, ou mode de récupération ne permettant pas ces sauvegardes. Ne pas confondre ces situations lors de l’implémentation.
- Examiner la propagation de cet indicateur à la boucle de sauvegarde et à la procédure de sauvegardes finales. Une sauvegarde complète servant de base doit exister avant de produire un différentiel.
- Revoir `Maint.DeleteOldBackups` et la nomination des fichiers : pour restaurer au dernier différentiel d’un intervalle entre sauvegardes complètes, les différentiels précédents du même intervalle ne sont pas requis. Étudier la conservation du dernier différentiel réussi par base complète conservée, plutôt qu’un seul différentiel global pour la base de données.
- Ne pas supprimer le dernier différentiel exploitable avant la réussite de son remplaçant. Préserver la sauvegarde complète dont dépend chaque différentiel retenu et tenir compte des points de restauration historiques attendus.
- YourSqlDba étant en récupération FULL, examiner aussi la gestion de son journal : une sauvegarde différentielle ne remplace pas une sauvegarde de journal pour la troncature de celui-ci.

Exceptions à conserver explicitement :

- **MSDB : ne rien changer à son traitement actuel.** Conserver une sauvegarde complète, avec écrasement de celle de la journée à chaque exécution. L’objectif exprimé est de rendre le recouvrement plus rapide. Cette exception prévaut sur la règle générale de différentiel.
- **master : SQL Server ne permet que les sauvegardes complètes de cette base.** L’idée d’un différentiel ne peut donc pas lui être appliquée directement ; définir son traitement explicite à la revue, sans lui envoyer de commande DIFFERENTIAL ou BACKUP LOG.

## Orientation précisée le 18 octobre — sauvegardes normales et journal final

État au 19 octobre : l’exclusion de master pour les sauvegardes de journaux est implémentée ; les autres points restent à implémenter après cette discussion :

- **master :** la boucle ignore maintenant cette base lorsque `@DoLogBkp = 1`. Ses sauvegardes complètes ordinaires sont conservées. L’exclusion des sauvegardes DIFFERENTIAL, non prises en charge par SQL Server pour cette base, reste à implémenter.
- **YourSqlDba :** la réintégrer dans le traitement normal de `yMaint.Backups` pour ses sauvegardes complètes et différentielles. La liste du filtre l’inclut déjà systématiquement.
- **Journal de YourSqlDba :** le sauvegarder à la toute fin de chaque maintenance, dans `yMaint.BackupMaintenanceDatabases`, même sans sauvegardes demandées pour les autres bases. Éviter une seconde sauvegarde de journal dans la boucle ordinaire lors des exécutions de type L.
- **Initialisation :** prévoir le cas d’une nouvelle installation ou d’une chaîne non initialisée avant le premier journal final. Une sauvegarde complète exploitable reste nécessaire ; les détails de cette initialisation sont à revoir.
- **MSDB :** conserver sa sauvegarde complète après le journal final de YourSqlDba, avec écrasement de la sauvegarde de la journée. Son historique doit ainsi inclure cette sauvegarde de journal.
- **Rétention :** conserver les fichiers de journaux nécessaires entre la sauvegarde complète retenue et le point de restauration visé. La règle « seul le dernier différentiel est nécessaire » ne s’applique pas aux journaux successifs.
- Cette orientation remplace l’idée de copier toute la base YourSqlDba en fin de chaque maintenance : la sauvegarde ordinaire fournit la base de restauration, puis le journal final protège les dernières écritures d’historique.

## Piste complémentaire — bases en récupération SIMPLE

À examiner, sans décision de fréquence ni modification SQL à ce stade :

- Pour les bases en récupération SIMPLE, déterminer si une sauvegarde différentielle devrait remplacer la sauvegarde de journal lors des exécutions de type L, ou être produite à une fréquence distincte, moins élevée.
- Comparer la perte de données acceptable, le volume de changements depuis la sauvegarde complète, la durée des différentiels et la charge induite par une fréquence identique à celle des journaux.
- Si une périodicité distincte est retenue, définir comment décider qu’un nouveau différentiel est dû, notamment à partir de la dernière sauvegarde différentielle réussie et de sa base complète.
- Articuler cette règle avec le futur indicateur de la vue, les filtres de sélection et la rétention des sauvegardes. Conserver le dernier différentiel utile jusqu’à la réussite du suivant.
- Maintenir les exceptions déjà relevées : master en sauvegarde complète uniquement ; MSDB conserve sa sauvegarde complète finale avec écrasement de celle de la journée.
- Ne pas confondre une base en SIMPLE, qui ne permet pas les sauvegardes de journaux, et une base en FULL dont les journaux ne sont simplement pas demandés dans cette exécution.

## Piste complémentaire — datation, fichiers et ménage des différentiels

À décider conjointement avec leur fréquence de production :

- Comment identifier la date d’un différentiel dans son nom : date seule, comme le fichier quotidien de MSDB, ou date et heure de chaque exécution ?
- Comparer deux approches : réutiliser et écraser un fichier pour limiter leur nombre, ou créer un fichier par exécution puis supprimer les différentiels précédents devenus inutiles.
- Avec une date seule, préciser si le fichier est réutilisé uniquement dans la journée et comment distinguer les différentiels rattachés à des sauvegardes complètes différentes, y compris lorsque plusieurs complètes sont produites le même jour.
- Avec un fichier par exécution, définir le ménage après réussite de la nouvelle sauvegarde et conserver le dernier différentiel utile pour chaque base complète retenue, selon les points de restauration attendus.
- Examiner le risque qu’un écrasement détruise le dernier différentiel valide si la nouvelle sauvegarde échoue. Ne pas décider du nommage indépendamment de cette protection.
- Adapter ensemble la génération des noms, la reconnaissance et l’extraction des dates dans `Maint.DeleteOldBackups`, puis les règles de sélection et de suppression. La date du nom ne suffit pas nécessairement à identifier la base complète dont dépend le différentiel.
- MSDB reste l’exception déjà décidée : sauvegarde complète quotidienne écrasée à chaque exécution. Son comportement sert ici de comparaison, sans décider de l’appliquer aux différentiels.

## Références

- Documentation PATINDEX : https://learn.microsoft.com/en-us/sql/t-sql/functions/patindex-transact-sql
- Restrictions de master (sauvegardes complètes uniquement) : https://learn.microsoft.com/en-us/sql/relational-databases/databases/master-database
- Sauvegardes des bases système : https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/back-up-and-restore-of-system-databases-sql-server
- Types de sauvegardes et troncature du journal : https://learn.microsoft.com/en-us/sql/t-sql/statements/backup-transact-sql
- Des copies avant/après l’intégration sont conservées dans le répertoire temporaire `YourSqlDba-integrate-cleanup-*` pour permettre une annulation ciblée. Préserver les modifications ultérieures si une annulation est demandée.
