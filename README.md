# Système de Gestion Hospitalière - MCD/MLD/SQL

Projet de modélisation d'une base de données hospitalière avec la méthode MERISE.

## Contenu du projet

- `hopital_db_merise.sql` : Script SQL complet (tables, triggers, vues, données test)
- `RAPPORT_TP_MCD_MERISE.md` : Rapport du TP
- `mocodo/` : Fichiers pour visualiser le MCD

## Installation

```bash
mysql -u root -p < hopital_db_merise.sql
```

## Structure de la base

**13 entités** : PATIENT, PERSONNEL, MEDECIN, INFIRMIER, SERVICE, CHAMBRE, LIT, SEJOUR, CONSULTATION, PRESCRIPTION, ACTE_MEDICAL, INTERVENTION, BLOC_OPERATOIRE

**4 associations N-N** : OCCUPE, AFFECTE_A, FACTURE, COMPREND

**Héritage** : PERSONNEL → MEDECIN / INFIRMIER (exclusif)

## Auteur

Cheriet Abdel - Université de Strasbourg - Décembre 2025
