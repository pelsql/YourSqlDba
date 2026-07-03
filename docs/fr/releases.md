---
layout: default
title: Historique des versions et notes de version
---

# Historique des versions et notes de version

**Version 7.1.0.12**

{: .warning }
> **Changement critique — gestion déléguée des bases de données :** Les flux de travail existants 
> non-sysadmin pour sauvegardes, restaurations, duplications, nettoyage de sauvegardes ou mode maintenance 
> peuvent cesser de fonctionner après cette mise à niveau. Chaque login délégué et ses bases autorisées 
> doivent maintenant être configurés dans `Maint.DelegatedDbManagement`, et les cibles de restauration 
> doivent suivre les nouvelles restrictions de nommage. Consultez la 
> [documentation de gestion déléguée des bases](maintenance/delegated-database-management.md)
> avant de mettre à niveau toute instance utilisant des opérations déléguées.

1. **Délégation contrôlée des opérations de gestion des bases de données**

   YourSqlDba fournit maintenant un modèle de délégation du moindre privilège pour les propriétaires d'applications
   et les utilisateurs de support senior qui ont besoin de rafraîchir des bases non-production, tester ou 
   annuler des mises à niveau d'applications, ou nettoyer des sauvegardes sans recevoir des privilèges 
   `sysadmin`.

   Un sysadmin autorise chaque login délégué via `Maint.DelegatedDbManagement`. Les cibles de restauration 
   sont restreintes par des règles de nommage qui empêchent les utilisateurs délégués d'écraser les bases source 
   ou non liées.

2. **Gestion simplifiée des fichiers de sauvegarde de journal de transactions**

   La sauvegarde de journal de transactions initiale produite après une sauvegarde complète ou différentielle 
   garde maintenant son propre nom de fichier et n'est plus réutilisée par la tâche de sauvegarde de journal régulière.

   La prochaine sauvegarde de journal régulière crée le fichier de sauvegarde de journal réutilisable et l'enregistre 
   dans `Maint.JobLastBkpLocations.lastLogBkpFile`. Lorsque `@BkpLogsOnSameFile = 0`, chaque sauvegarde de journal 
   régulière continue à utiliser un nouveau fichier.

3. **Mises à niveau de YourSqlDba plus résilientes**

   Les informations de mise à niveau sont conservées temporairement dans la base de données 
   `YourSqlDbaUpgradeSavedInfos`. Cela protège la configuration existante si une mise à niveau échoue. 
   La base de données temporaire est supprimée après une mise à niveau réussie. La gestion de l'accès exclusif 
   pendant les mises à niveau a également été améliorée.

4. **Accès exclusif pour les restaurations déléguées**

   Avant une restauration non-sysadmin déléguée, YourSqlDba termine les sessions actives connectées à la base 
   cible. Les utilisateurs délégués ne peuvent normalement pas terminer eux-mêmes ces sessions, et leurs cibles 
   de restauration sont déjà restreintes.

   Pour les sysadmins, les sessions ne sont pas terminées automatiquement car une erreur de paramètre pourrait 
   affecter une base non liée ou de production. Les sysadmins doivent gérer explicitement les sessions actives 
   lorsqu'ils utilisent `Maint.DuplicateDb`, `Maint.DuplicateDbFromBackupHistory` ou `Maint.RestoreDb`. 
   Ils peuvent appeler `S#.KillDbUsers` explicitement si approprié.

5. **Rapport de filtrage amélioré**

   Les rapports de maintenance et les journaux incluent maintenant la liste des bases de données sélectionnées 
   par les règles de filtrage, ce qui facilite la vérification des bases ciblées par chaque exécution.

[Voir script 7.1.0.12 sur GitHub](../YourSQLDba_InstallOrUpdateScript.sql)

**[Obtenir script 7.1.0.12](https://raw.githubusercontent.com/pelsql/YourSqlDba/refs/heads/master/YourSQLDba_InstallOrUpdateScript.sql)**

**Version 7.1.0.11**
- `YourSqlDba` est maintenant créé en mode de récupération `FULL`.
- `YourSqlDba` est toujours sauvegardé chaque fois qu'une sauvegarde de maintenance s'exécute.
- Sa sauvegarde suit le type actuel de sauvegarde de maintenance : complète, différentielle ou journal.
- Si une sauvegarde différentielle ou de journal est demandée avant qu'une sauvegarde complète valide de `YourSqlDba` 
  existe, une sauvegarde complète est prise automatiquement pour initialiser la chaîne de sauvegarde.

**[Obtenir script 7.1.0.11](https://raw.githubusercontent.com/pelsql/YourSqlDba/3dd6a23ba772320c3392693dc3ba587da43cd8e1/YourSQLDba_InstallOrUpdateScript.sql)**

**Version 7.1.0.10**
Corrige un problème rare pour les testeurs de YourSqlDba sur Windows Pro utilisant des partages SMB pour les sauvegardes.
Quand une tâche SQL Agent ignorée redémarre avec le serveur, elle peut commencer avant que les partages SMB soient disponibles. 
Cette version ajoute un délai lors de la vérification de la disponibilité de la destination de sauvegarde. 
Si la destination reste indisponible pour une autre raison, la tâche s'arrête toujours.

**[Obtenir script 7.1.0.10](https://raw.githubusercontent.com/pelsql/YourSqlDba/6cc3e280cd4a8ed81e84048d8fc24b0c6b4a9175/YourSQLDba_InstallOrUpdateScript.sql)** 


**Version 7.1.0.9**
1. YourSqlDba est maintenant défini en mode de récupération complète lors de sa création.

2. Certaines contraintes de sécurité obsolètes ont été supprimées. Elles ont été ajoutées à l'origine car le mirroring 
   effectuait des restaurations à partir d'une file Service Broker via une procédure stockée auto-activée.

   Ces contraintes pouvaient causer des problèmes lors de l'exécution de `Maint.SaveDbCopyOnly`, `Maint.DuplicateDb` 
   ou `Maint.SaveDbOnNewFileSet` sur une machine Windows Pro autonome utilisant un compte Microsoft.

**[Obtenir script 7.1.0.9](https://raw.githubusercontent.com/pelsql/YourSqlDba/2bb789c4bbb5076f15e7c4b98d355ea5574ce5c8/YourSQLDba_InstallOrUpdateScript.sql)** 


**Version 7.1.0.8**
Maint.ShrinkAllLogs est supprimé de cette version

**[Obtenir script 7.1.0.8](https://raw.githubusercontent.com/pelsql/YourSqlDba/e3cd2dfae63f8ffdf8da395cd055c1e069be3013/YourSQLDba_InstallOrUpdateScript.sql)** 

Certains bogues corrigés pour les non-utilisateurs du mirroring


Maint.ShrinkAllLogs
**Version 7.1.0.7**

**[Obtenir script 7.1.0.7](https://raw.githubusercontent.com/pelsql/YourSqlDba/534387a4b91e9866137cff7daa5fed7ff0c1f61c/YourSQLDba_InstallOrUpdateScript.sql)** 

Certaines procédures sont supprimées. Maint.ShrinkAllLogs. 
En interne, YourSqlDba n'essaie plus de réduire le journal lors de la sauvegarde du journal.

Certains correctifs pour une meilleure synchronisation entre sauvegardes/restaurations dans le mirroring. 
La tâche pour les restaurations a changé. Il existe maintenant une tâche de restauration spécifique pour une 
tâche de sauvegarde spécifique, ce qui s'avère plus fiable pour la mise en file d'attente et la synchronisation.

**Version 7.1.0.6**

**[Obtenir script 7.1.0.6](https://raw.githubusercontent.com/pelsql/YourSqlDba/340301644d2dceba1014531fb57396a9f3c61f4f/YourSQLDba_InstallOrUpdateScript.sql)** 

Correctif pour les noms de sauvegarde trop longs pour le paramètre de nom de la commande de sauvegarde

**Version 7.1.0.5**

**[Obtenir script 7.1.0.5](https://raw.githubusercontent.com/pelsql/YourSqlDba/45ae7f77d79e84581009f5a64b459a7ea77b3ab5/YourSQLDba_InstallOrUpdateScript.sql)** 

Le format de date yyyy-mm-dd utilisé dans l'instruction CREATE CREDENTIAL n'était pas universellement pris en charge.
Quand le paramètre de langue de la connexion est configuré pour le français, cela causait une erreur d'installation. 
Le format de date YYYYMMDD qui est maintenant utilisé ne dépend plus des paramètres de langue de la connexion.

Dans la fonction qui génère la commande de sauvegarde, le paramètre NoInit était mal orthographié en NoInt, 
ce qui causait une erreur dans les commandes de sauvegarde de journal.

**Version 7.1.0.4**

[Obtenir script 7.1.0.4 sur GitHub](https://raw.githubusercontent.com/pelsql/YourSqlDba/5a0674c0221b007c7bc238a78aa7f42a63164528/YourSQLDba_InstallOrUpdateScript.sql)
 
Si vous avez le script 7.1.0.3, réappliquez ce script, car la mise à niveau du "provider" de YourSqlDba 
"Mirror server" peut être incorrecte.

**Correctif** pour le petit nombre d'utilisateurs qui utilisent un compte de service géré en groupe 
(*group Managed Service Account*) pour exécuter le service du moteur de base de données.

Ce type de compte réduit légèrement les droits accordés au moteur relationnel pour l'accès disque. 
En conséquence, la création d'un assembly directement à partir de son fichier DLL peut échouer.

Une alternative valide consiste à importer le contenu binaire dans SQL Server et créer l'assembly à partir 
de ce contenu binaire.

---

**Mise à niveau forcée du fournisseur MSOLEDBSQL** Quand les serveurs YourSqlDba "Mirroring" utilisent 
l'ancien fournisseur "SQLNCLI", ils sont supprimés de force pour être demandés à être recréés avec 
Mirroring.AddServer, qui utilisera alors le fournisseur MSOLEDBSQL.

[Référence de documentation sur comment faire un Mirroring.AddServer](https://onedrive.live.com/personal/12c385255443c4ed/_layouts/15/Doc.aspx?sourcedoc=%7B5443c4ed-8525-20c3-8012-a81b00000000%7D&action=view&redeem=aHR0cHM6Ly8xZHJ2Lm1zL28vYy8xMmMzODUyNTU0NDNjNGVkL0V1M0VRMVFsaGNNZ2dCS29Hd0FBQUFBQlJ2b290QVJmaE5LQjJaenNPU09yZkE_ZT11c0h6Vms&wd=target%28REFERENCE.one%7Cc7b30aeb-6ae2-4bd6-a550-14feb11d776d%2FMirroring.AddServer%7Ca71c4787-8076-4ed3-a6be-d6c5c3c8b6b3%2F%29&wdorigin=703&wdpartid=%7B2da72b12-728f-4f44-ba3b-477df906c323%7D%7B80%7D&wdsectionfileid=%7B12c385255443c4ed%21sfb02454d2d084363a169b209686c280b%7D)
(ignorer l'erreur "cannot add YourSqlDbaRemoteServerCred because it already exists")

---

**La maintenance du code a également été effectuée pour améliorer la clarté**. Aucune fonctionnalité n'a été ajoutée ou modifiée.

**Certains outils ont été ajoutés** pour aider à la maintenance du code. Utiles uniquement pour les mainteneurs de YourSqlDba.
Un système de signet permanent est maintenant utilisé, basé sur des commentaires spéciaux dans le code de la forme. 
Le commentaire est le nom du signet.

```sql
-- @@MARK: Some comment explaining the purpose of this section of code
```

Pour ajouter cet outil, dans SSMS 22.3 ou supérieur (non testé dans les versions précédentes), allez à Tools/External Tools, cliquez ajouter :

Via Tools/External Tools

|Pour compléter | Valeur d'exemple |
|---|---|
|Title |Goto-Mark |
|Command |C:\Program Files\PowerShell\7\pwsh.exe |
|Arguments |-NoProfile -ExecutionPolicy Bypass -File "C:\Github\YourSqlDba\Goto-Mark.ps1" "$(ItemPath)" "$(ItemFileName)" |
|Initial directory |$(ItemDir) |

Le script PowerShell (cet outil) analyse la source actuelle, construit une table de ces marques et l'affiche dans une fenêtre grille.

Vous pouvez parcourir la liste ou rechercher une chaîne spécifique. Une fois qu'un élément est sélectionné, cliquez OK. 
Aucun texte ne doit être sélectionné lors de cette action.

Ces commentaires mettent en évidence les éléments architecturaux de YourSqlDba. Les lire aide à fournir un aperçu du projet. 
Ils facilitent également la localisation de ces éléments dans YourSqlDba, qui est un très grand script.

**Version 7.1.0.2**

En mode mirroring, la restauration pouvait bloquer les sauvegardes de journal. Un verrouillage interne a été ajouté pour empêcher cela.

**[Obtenir script pour version 7.1.0.2](https://raw.githubusercontent.com/pelsql/YourSqlDba/5b53e48ee0da146731bca28e92a3088108d89d38/YourSQLDba_InstallOrUpdateScript.sql)**

**Version 7.1.0.1**

La file d'attente de restauration est maintenant vidée entre les exécutions de sauvegarde complète.
Ce changement garantit que la tâche de maintenance complète ne signale plus répétitivement les entrées d'erreur résiduelles 
des cycles de maintenance précédents. À la fin d'un cycle, la tâche effectue une vérification finale mais n'intentionnellement 
pas de suppression des éléments en file d'attente en état d'erreur. Au lieu de cela, YourSqlDba envoie un message 
instructant l'utilisateur à interroger la file (via une instruction SELECT) pour identifier les restaurations échouées ; 
ces entrées sont ensuite supprimées au début de la prochaine exécution de maintenance.

**[Obtenir script pour version 7.1.0.1](https://raw.githubusercontent.com/pelsql/YourSqlDba/dc41bac618203c31b0d36371671b01ac72dfadc3/YourSQLDba_InstallOrUpdateScript.sql)**

**Version 7.1**

**[Obtenir script pour version 7.1](https://raw.githubusercontent.com/pelsql/YourSqlDba/c4460c5808e4696b75c1259a754bbcb1693cf1d8/YourSQLDba_InstallOrUpdateScript.sql)**

Cette version réalise un objectif longtemps recherché : supprimer toutes les dépendances d'assembly externe de YourSqlDba.
Le script construit maintenant ses propres assemblies à partir du code source C# défini dans une fonction table-valeur en ligne (iTvf).
Puisque le script lui-même compile et crée l'assembly, il le signe également automatiquement — aucun binaire n'est importé 
à partir de sources non fiables.

En permettant au script de compiler, déployer et sécuriser l'assembly de manière autonome, YourSqlDba fait un pas majeur 
vers l'autonomie. Cette capacité est dérivée de portions de ma propre bibliothèque, **S#** (pas encore publiée sur GitHub).
Cette bibliothèque permet au code source C# d'être intégré directement dans une définition de fonction en ligne, 
permettant un ensemble complet de commandes T-SQL pour créer l'assembly et exposer ses points d'entrée SQLCLR dans SQL Server.

Des remerciements spéciaux à **Solomon Rutzky** ([srutzky@gmail.com](mailto:srutzky@gmail.com)) pour ses intuitions 
sur la sécurité des assemblies et des modules, qui ont aidé à finaliser la conception en ajoutant une signature à la création.
Maintenant, chaque DBA peut examiner le code C# relativement simple sans le risque d'exécuter des assemblies non signés, 
améliorant considérablement la sécurité globale de YourSqlDba.

Un autre avantage important est que la base de données n'a plus besoin d'être définie comme **TRUSTWORTHY**, 
augmentant davantage la sécurité. Cette amélioration a été rendue possible en supprimant toute dépendance à 
**Service Broker** pour les opérations du serveur miroir. Auparavant, Service Broker était utilisé pour fournir 
un thread d'arrière-plan pour exécuter les restaurations en parallèle avec les sauvegardes. 
Il a maintenant été remplacé par une tâche **SQL Agent YourSqlDba** autonome créée automatiquement, 
dédiée à cet objectif. Cette tâche démarre automatiquement quand les sauvegardes sont terminées et s'arrête 
elle-même cinq minutes après la fin du traitement de `restoreQueue`.

La version 7.1 pose les fondations pour la nouvelle architecture de YourSqlDba, introduisant ces composants 
progressivement afin que les architectures originale et nouvelle puissent coexister sans compromettre la qualité du code.
La mise à niveau est fortement recommandée, en particulier pour ses améliorations de sécurité.

---

Avec la version 7.0, `YourSQLDba.Maint.HistoryView` (voir `Goals/QuickLinks table/Maint.HistoryView (V 7.0+)`) 
a reçu plusieurs améliorations qui améliorent la visualisation des interactions multi-tâches.
Les événements dans une période sélectionnée sont maintenant affichés par ordre chronologique et montrent l'activité 
simultanée des tâches. Chaque fois que l'historique des journaux bascule vers une tâche, les colonnes indiquant 
la lignée des tâches sont mises en évidence pour rendre ces transitions facilement identifiables.

`YourSQLDba.Maint.HistoryView` est un outil de diagnostic essentiel pour les opérations de maintenance.
Lorsque l'enquête dépasse le champ d'une seule tâche, les valeurs de date-heure pré-calculées de `Maint.MaintenanceEnums` 
vous permettent de demander l'activité de YourSqlDba dans les cadres temporels relatifs.
Plus de détails sont disponibles dans la documentation mise à jour.

**Version 7.0.0.5:**
**[Obtenir script pour version 7.0.0.5](https://github.com/pelsql/YourSqlDba/blob/68fbb28cfd3e380eca9b158372e0f077b5c4fa69/YourSQLDba_InstallOrUpdateScript.sql)**
La version 7.0.0.5 est obligatoire, englobant tous les changements antérieurs et corrigeant les problèmes 
avec les liens de documentation dans le README et `index.md`.
Les versions intermédiaires 7.0.0.0 à 7.0.0.4 sont dépréciées.

**Version 7.0.0.4:**
Une erreur de division par zéro peut survenir dans les tests d'intégrité quand le filtrage de la base de données 
exclut toutes les bases. C'est parce que la sélection de table est basée sur le paramètre de tâche `@SpreadCheckDd`. 
Lors du calcul de cette sélection, le nombre de bases est pris en compte pour calculer une valeur modulo, 
définie soit à `@SpreadCheckDd` soit au nombre total de bases.

**Version 7.0.0.3:**
Lors de la mise à niveau à partir d'une version antérieure, les journaux de maintenance de YourSqlDba peuvent 
s'étendre considérablement, causant potentiellement des problèmes de taille de journal. 
Pour atténuer cela, les opérations de nettoyage sont effectuées avant la mise à niveau, 
avec l'instruction DELETE décomposée en déclarations plus petites (en utilisant `TOP()`) pour éviter le dépassement du journal.
En cas de mise à niveau à partir d'une version antérieure à 7.0.0.2, la mise à niveau peut prendre du temps, 
soyez juste plus patient.

**Version 7.0.0.2:**
Le message pour les problèmes d'accès avec le serveur miroir a été mis à jour pour indiquer 
que l'instance miroir peut simplement être hors ligne.

**Version 7.0.0.1:**
Le code de nettoyage de journal, omis depuis la version 6.8.0.0, a été réintroduit dans la version 7.0.0.1.


Version 7.0.0.4:
Remplacer les liens TinyUrl dans le fichier readme et la source qui ne fonctionnent pas pour les liens github.

Version 7.0.0.5:
Lors du rétrécissement des fichiers de base de données, si une erreur était rencontrée, 
un appel inapproprié à yExecNLog.FormatBasicBeginCatchErrMsg() en dehors du contexte de la base 
de données yourSqlDba empêchait le rapport d'erreur correct. L'appel a été corrigé en YourSqlDba.yExecNLog.FormatBasicBeginCatchErrMsg()

**[Obtenir script de 6.8.2.1](https://raw.githubusercontent.com/pelsql/YourSqlDba/6e7d1fbf53fb5344efae2b9640f551b78794d758/YourSQLDba_InstallOrUpdateScript.sql)**
SQL2022 nécessitait un petit ajustement de la procédure YUtl.CollectBackupHeaderInfoFromBackupFile 
car la sortie 'Restore Header Only' a maintenant 3 colonnes supplémentaires. Je n'ai vu le problème que le 2024-04-23. 
C'est nouveau pour moi d'être informé via la fonction Issue de Github, et c'est bienvenu. 
Je vais maintenant vérifier plus souvent et être plus proactif avec les nouvelles versions.

**[Obtenir script de 6.8.2.0](https://raw.githubusercontent.com/pelsql/YourSqlDba/294f3f55dfebff31c6bb4079ab91ee6a7c9af08f/YourSQLDba_InstallOrUpdateScript.sql)**
> Cette version corrige un problème de paramètre pour YourSQLDba.Maint.HistoryView, 
> quand le paramètre de langue par défaut de la connexion est le français.
> Le paramètre de langue peut être "français" en étant la langue par défaut du login, 
> ou une fois connecté, étant défini explicitement en dehors du processus de connexion initial.

Le format de date attendu pour la date est le style 121 de la fonction convert qui est yyyy-mm-dd hh:mm:ss.mmm. 
Mais comme les paramètres de fonction de date étaient datetime, une conversion implicite se produit.

Quand le paramètre de langue de la connexion est français, la conversion implicite de date échange mm-dd en dd-mm. 
Cela donne une date différente de celle prévue ou pire une date invalide conduisant à une erreur d'exécution 
(ex : une valeur de jour de 13 ou plus étant échangée en mois n'est pas valide pour une valeur de mois).

Les paramètres de date **[YourSQLDba.Maint.HistoryView](#mainthistoryview)** ont été modifiés 
pour recevoir une chaîne qui est ensuite convertie en interne explicitement en datetime avec l'option de style 121.

Select cmdStartTime, JobNo, seq, Typ, line, Txt 
From
  (Select ShowErrOnly=1, ShowAll=NULL) as Enum
  cross apply YourSQLDba.Maint.HistoryView('2024-04-20 22:25:01.297', '2024-04-20 22:25:09.223', ShowErrOnly) 
Order By cmdStartTime, JobNo, Seq, TypSeq, Typ, Line

Parallèlement, certains travaux ont été effectués pour incorporer des éléments d'une bibliothèque externe 
(la mienne), que j'ai déjà commencé à utiliser en partie dans les versions précédentes. 
L'objectif est de permettre une réécriture significative de YourSqlDba sur la base de la rendre beaucoup 
plus compacte et facile à lire. Je m'attends à « dégonfler » beaucoup YourSqlDba en utilisant des éléments 
de cette nouvelle bibliothèque, et éventuellement supprimer beaucoup d'anciennes routines de YourSqlDba.

**[Obtenir script de 6.8.1.0](https://raw.githubusercontent.com/pelsql/YourSqlDba/df2f7622aa5606d08d144f33ca6c3674a7166a81/YourSQLDba_InstallOrUpdateScript.sql)**
## Cette version
> - Étendre les capacités de reporting de YourSqlDba pour aider au diagnostic en maintenance 
>   et renforcer le piégeage et la signalisation des exceptions dans son propre code.
> - Codage interne : généralise l'utilisation de l'instruction Drop ... if exists.
> - Codage interne : Réduction du nombre de paramètres des modules de maintenance via l'utilisation 
>   d'un concept de contexte disponible de dbo.MainContextInfo().

**[Obtenir script de 6.8.0.3](https://raw.githubusercontent.com/pelsql/YourSqlDba/afa43da1be7f18d770a97a44b373901039db79db/YourSQLDba_InstallOrUpdateScript.sql)**
> Cette version ajoute la colonne SessionId à la vue Perfmon.SessionInfo

**[Obtenir script de 6.8.0.2](https://raw.githubusercontent.com/pelsql/YourSqlDba/2e744db1731ac73749e1c32a4cffbf0e1c4c6084/YourSQLDba_InstallOrUpdateScript.sql)**
> Cette version est une réécriture significative du système de logging de YourSqlDba et du rapport 
> du code joué et des exceptions chaque fois qu'elles surviennent. Le code précédent a évolué pour 
> devenir trop complexe à maintenir. Le nouveau système de logging repose sur une architecture différente 
> pour la journalisation des actions et erreurs de YourSqlDba. Le code précédent a évolué pour devenir 
> trop complexe à maintenir. Le nouveau système de logging repose sur une architecture différente pour 
> la journalisation des actions et erreurs de YourSqlDba. Il a réduit la taille du code, l'a rendu plus moderne 
> avec moins de chemins de code et plus facile à suivre. Il considère que plus d'une tâche peut s'exécuter à la fois. 
> J'ai modifié les paramètres de Maint.HistoryView à l'heure de début et de fin de la tâche. 
> La sortie inclut également d'autres événements de tâche qui se produisent dans cette période. 
> Le formatage de sortie médiocre de l'historique des tâches de SQL Agent nécessitait de nouvelles méthodes 
> pour laisser un résultat plus lisible. Ce qui a conduit à cet examen significatif était un interblocage signalé 
> dans la table de logging lors de la réalisation du mirroring de YourSqlDba. 
> Les solutions apportées avec la version 6.7.3.2 nécessitaient une meilleure adaptation de l'architecture 
> pour la rendre plus solide. J'ai décidé qu'il était temps d'examiner le tout, donc voilà. 
> Une petite correction.

**[Obtenir script de 6.7.3.2](https://raw.githubusercontent.com/pelsql/YourSqlDba/9d78b52824110221bb2e9d6314286decbc88f4ab/YourSQLDba_InstallOrUpdateScript.sql)**
> Cette version a deux ensembles de changements de fonctionnalités non liés. 
> L'un est une amélioration de la façon d'obtenir un accès exclusif à une base de données 
> en passant au mode single_user au lieu de offline. L'utilisation du mode offline s'est avérée 
> moins fiable depuis les dernières versions de SQL Server, car passer offline était parfois bloqué 
> par les processus internes de SQL.
