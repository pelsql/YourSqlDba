# Préférences d’écriture SQL

Ces consignes s’appliquent aux modifications SQL dans ce dépôt.

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
