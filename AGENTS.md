# Préférences d’écriture SQL

Ces consignes s’appliquent aux modifications SQL dans ce dépôt.

- SQL Server 2019 est la version minimale prise en charge. Utiliser directement ses fonctionnalités et métadonnées disponibles, sans ajouter de branches de compatibilité pour les versions antérieures.
- Limiter les variables déclarées aux valeurs nécessaires aux échanges avec les procédures ou aux instructions suivantes. Garder les résultats intermédiaires sous forme de colonnes nommées dans une chaîne `FROM` / `APPLY`.
- Garder la projection finale simple en tête, par exemple `Select @bkpFile=bkpFile`. Construire la valeur finale dans le dernier `APPLY`, après ses dépendances.
- Aligner la source du `FROM` et les `CROSS APPLY` au même niveau, en retrait sous `FROM`. Dans un `APPLY` multiligne, aligner les `SELECT` et `UNION ALL` avec les parenthèses, sans indentation supplémentaire.
- Utiliser des noms intermédiaires explicites et, pour une affectation unique, reprendre le nom de la colonne comme alias de l’expression de table.
- Séparer les étapes fonctionnelles par des lignes vides, en respectant la présentation existante.

- Traiter les lignes `APPLY` comme l’équivalent, ligne pour ligne, d’une programmation séquentielle avec des variables. Préserver les étapes intermédiaires et leur ordre de lecture.
- Privilégier un `APPLY` distinct par affectation de colonne. Lorsqu’une étape tient sur une ligne, garder cette présentation. Ne pas fusionner les étapes en une expression composée.
- Éviter les expressions imbriquées et les indentations à l’intérieur des expressions. Décomposer les calculs en plusieurs lignes `APPLY` successives : les imbrications sont difficiles à lire pour l’utilisateur.
- Préserver les `APPLY` avec `UNION ALL` qui expriment des conditions ou des raisons distinctes. Ne pas les remplacer par un gros `CASE` ni introduire une priorité implicite entre les branches. Signaler les éventuels chevauchements avant de proposer une autre structure.
- Éviter `CASE` pour la lisibilité ; conserver l’approche existante et les `IIF` simples lorsque présents.
- Pour une colonne générée dont le nom est identique à l’alias de son expression de table, utiliser le nom de colonne sans préfixe : `DateFromName`, pas `DateFromName.DateFromName`.
- Conserver les commentaires, les lignes vides et les espacements de l’utilisateur. Limiter les changements aux corrections demandées ; ne pas reformater ou restructurer silencieusement le code.

Exemple de présentation à conserver :

```sql
CROSS APPLY (select DateFromName1=replace(DateCreate, 'h', ':')) as DateFromName1
CROSS APPLY (select DateFromName2=replace(DateFromName1, '_', ' ')) as DateFromName2
CROSS APPLY (select DateFromName=convert(datetime, DateFromName2, 121)) as DateFromName
```
