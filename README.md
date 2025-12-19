# 🏥 Système de Gestion Hospitalière - MCD/MLD/SQL

[![MySQL](https://img.shields.io/badge/MySQL-8.0+-blue.svg)](https://www.mysql.com/)
[![MERISE](https://img.shields.io/badge/Méthode-MERISE-green.svg)](https://fr.wikipedia.org/wiki/Merise_(informatique))
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 📋 Description

Projet de conception et d'implémentation d'une **base de données hospitalière** complète, suivant la méthode **MERISE** (MCD → MLD → SQL).

Ce projet académique couvre l'ensemble du cycle de modélisation des données pour un système de gestion hospitalière : patients, personnel médical, séjours, actes médicaux et facturation.

---

## 🎯 Objectifs du Projet

- ✅ Modéliser un système hospitalier complet avec la méthode MERISE
- ✅ Implémenter 13 entités et 4 associations N-N
- ✅ Gérer l'héritage exclusif (PERSONNEL → MEDECIN/INFIRMIER)
- ✅ Optimiser le code SQL (~350 lignes vs 1100)
- ✅ Implémenter les contraintes métier via triggers

---

## 📊 Modèle Conceptuel de Données (MCD)

### Entités (13)

| Entité | Identifiant | Description |
|--------|-------------|-------------|
| PATIENT | IPP | Patients hospitalisés |
| PERSONNEL | id_personnel | Personnel (entité mère) |
| MEDECIN | RPPS | Médecins (hérite de PERSONNEL) |
| INFIRMIER | id_infirmier | Infirmiers (hérite de PERSONNEL) |
| SERVICE | id_service | Services hospitaliers |
| CHAMBRE | id_chambre | Chambres des services |
| LIT | id_lit | Lits des chambres |
| SEJOUR | IEP | Séjours hospitaliers |
| CONSULTATION | id_consultation | Consultations médicales |
| PRESCRIPTION | id_prescription | Prescriptions médicamenteuses |
| ACTE_MEDICAL | code_CCAM | Catalogue des actes CCAM |
| INTERVENTION | id_intervention | Interventions chirurgicales |
| BLOC_OPERATOIRE | id_bloc | Blocs opératoires |

### Associations N-N (4)

| Association | Entités liées | Attributs |
|-------------|---------------|-----------|
| OCCUPE | SEJOUR ↔ LIT | date_debut, date_fin |
| AFFECTE_A | INFIRMIER ↔ SERVICE | taux_activite |
| FACTURE | SEJOUR ↔ ACTE_MEDICAL | quantite, montant |
| COMPREND | INTERVENTION ↔ ACTE_MEDICAL | ordre |

### Héritage Exclusif

```
        PERSONNEL
            │
     ┌──────┴──────┐
     │    IS-A     │  (Exclusif)
     │    (XT)     │
     ▼             ▼
  MEDECIN      INFIRMIER
```

---

## 📁 Structure du Projet

```
projet-hopitale-bdd/
├── README.md                         # Ce fichier
├── RAPPORT_TP_MCD_MERISE.md          # Rapport du TP
├── hopital_db_merise.sql             # Script SQL (~350 lignes)
├── MCD_MERISE_DOCUMENTATION.md       # Documentation MCD
├── MERISE_ANALYSE.md                 # Analyse Merise
├── COMPARAISON_OPTIMISATION.md       # Notes d'optimisation
├── mocodo/                           # Fichiers Mocodo
│   ├── MCD_MOCODO.mcd
│   └── MCD_MOCODO_SIMPLE.mcd
└── projet_mcd-1.pdf                  # Énoncé du TP
```

---

## 🚀 Installation

### Prérequis

- MySQL 8.0+ ou MariaDB 10.5+
- Client MySQL (mysql-client, MySQL Workbench, DBeaver, etc.)

### Exécution

```bash
# Cloner le dépôt
git clone https://github.com/Abdel67Unistra/Syst-me-de-Gestion-Hospitali-re-MCD-MLD-SQL.git
cd Syst-me-de-Gestion-Hospitali-re-MCD-MLD-SQL

# Créer la base de données (version optimisée)
mysql -u root -p < hopital_db_merise.sql

# OU version complète
mysql -u root -p < hopital_db_complete.sql
```

---

## 🔧 Fonctionnalités

### Triggers Métier (5)

| Trigger | Fonction |
|---------|----------|
| `trg_heritage_exclusif_medecin` | Empêche un infirmier d'être médecin |
| `trg_heritage_exclusif_infirmier` | Empêche un médecin d'être infirmier |
| `trg_occupation_lit_unique` | Un lit = un séjour à la fois |
| `trg_lit_etat_insert` | Met à jour l'état du lit (Occupé) |
| `trg_lit_etat_update` | Met à jour l'état du lit (Disponible) |

### Vues Métier (4)

| Vue | Description |
|-----|-------------|
| `v_sejours_en_cours` | Séjours actifs avec localisation |
| `v_lits_disponibles` | Lits libres par service |
| `v_taux_occupation_service` | Taux d'occupation par service |
| `v_facturation_sejour` | Facturation par séjour |

---

## 📈 Statistiques

| Métrique | Valeur |
|----------|--------|
| Entités | 13 |
| Associations N-N | 4 |
| Triggers | 5 |
| Vues | 4 |
| Lignes SQL (optimisé) | ~350 |
| Réduction vs version complète | -68% |

---

## 🛠️ Technologies

- **SGBD** : MySQL 8.0+ / MariaDB
- **Méthode** : MERISE (MCD → MLD → MPD)
- **Visualisation MCD** : Mocodo
- **Documentation** : Markdown

---

## 📚 Documentation

- [Rapport TP complet](RAPPORT_TP_MCD_MERISE.md)
- [Documentation MCD](MCD_MERISE_DOCUMENTATION.md)
- [Analyse Merise détaillée](MERISE_ANALYSE.md)
- [Comparaison optimisation](COMPARAISON_OPTIMISATION.md)

---

## 👤 Auteur

**Abdel67Unistra**

- GitHub: [@Abdel67Unistra](https://github.com/Abdel67Unistra)

---

## 📝 Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails.

---

## 🙏 Remerciements

- Université de Strasbourg
- Méthode MERISE
- Communauté MySQL

---

*Projet réalisé dans le cadre d'un TP de Base de Données - Décembre 2025*
