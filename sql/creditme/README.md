# CreditMe / Lisa PostgreSQL

Ce répertoire contient un schéma de hackathon dérivé du dictionnaire fixed-width
`Sopra Banking Software 22-JAN-2021 – DOSSIER` fourni localement. Le dictionnaire
décrit des formats, pas des données métier réelles.

## Fichiers

- `01_schema.sql` : schéma `creditme`, catalogue exhaustif des
  enregistrements/champs (positions, niveaux, pictures, descriptions), staging
  `raw_record_payload` et projection prudente `dossier`.
- `02_demo_seed.sql` : une charge de démonstration manifestement fictive.
- `03_realistic_synthetic_seed.sql` : 12 dossiers de prêt synthétiques,
  crédibles pour une démonstration, ainsi que quelques payloads raw associés.
- `04_ppi_stock_reporting.sql` : table d'intégration et vues de reporting pour
  le stock PPI en cours, les prélèvements SG/externes et les impayés externes.
- `05_ppi_stock_demo.sql` : lignes synthétiques permettant de tester le
  reporting.

## Exécution sur Azure PostgreSQL

1. Utiliser `psql` installé localement ou dans Azure Cloud Shell; récupérer le
   nom d’hôte, la base et l’utilisateur depuis Azure, sans les écrire dans le
   dépôt.
2. Fournir le secret via le mécanisme local de `psql` (invite interactive,
   fichier `.pgpass` protégé ou variable d’environnement temporaire), jamais
   dans une commande versionnée.
3. Exécuter :

```powershell
psql "host=<serveur>.postgres.database.azure.com port=5432 dbname=<base> user=<utilisateur> sslmode=require" -f sql/creditme/01_schema.sql
psql "host=<serveur>.postgres.database.azure.com port=5432 dbname=<base> user=<utilisateur> sslmode=require" -f sql/creditme/02_demo_seed.sql
```

Le catalogue conserve les champs non modélisés dans
`creditme.raw_record_payload`; seules les colonnes de `creditme.dossier`
directement identifiables sont projetées.

Les données du fichier `03_realistic_synthetic_seed.sql` sont entièrement
fictives. Elles ressemblent à des dossiers de crédit réalistes, mais ne
représentent aucun client ni compte réel.

## Reporting du stock PPI

Le flux normalisé vers `creditme.loan_stock_snapshot` doit alimenter les
colonnes issues de `DLANC`, `DPAY`, `DSTAT` et `TFONC` :

- `cdselect5 = '00001'` sélectionne les prêts particuliers (PPI/LISA);
- `cddevise12` est la devise et `crdu22` le montant en cours;
- `cdsitdos22 IN ('1', '2')` sélectionne les dossiers en cours;
- `cdmdreg14 = '2'` signifie prélèvement sur compte SG, toute autre valeur
  signifie compte externe;
- `tyblk21 = '01'` et `stadoss_position_22 = 'O'` signalent un impayé.

La vue `creditme.ppi_stock_summary` retourne, par date et devise, le nombre
et le montant en cours, le stock prélevé à l'externe et le sous-ensemble
externe en impayé :

```sql
SELECT *
FROM creditme.ppi_stock_summary
ORDER BY snapshot_date DESC, currency_code;
```
