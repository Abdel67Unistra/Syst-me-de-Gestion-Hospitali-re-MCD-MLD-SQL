# 📋 RAPPORT TP - MODÈLE CONCEPTUEL DE DONNÉES MERISE
## Système de Gestion Hospitalière

---

**Projet :** Base de données Hôpital  
**Date :** 19 décembre 2025  
**Méthode :** MERISE (MCD → MLD → SQL)  
**SGBD :** MySQL 8.0+  

---

## 📑 TABLE DES MATIÈRES

1. [Introduction](#1-introduction)
2. [Analyse des Besoins](#2-analyse-des-besoins)
3. [Modèle Conceptuel de Données (MCD)](#3-modèle-conceptuel-de-données-mcd)
4. [Dictionnaire des Données](#4-dictionnaire-des-données)
5. [Cardinalités Merise](#5-cardinalités-merise)
6. [Modèle Logique de Données (MLD)](#6-modèle-logique-de-données-mld)
7. [Implémentation SQL](#7-implémentation-sql)
8. [Triggers et Contraintes](#8-triggers-et-contraintes)
9. [Vues Métier](#9-vues-métier)
10. [Tests et Validation](#10-tests-et-validation)
11. [Conclusion](#11-conclusion)

---

## 1. INTRODUCTION

### 1.1 Contexte
Ce projet consiste à concevoir et implémenter une base de données pour la gestion d'un établissement hospitalier, en suivant la méthode **MERISE**.

### 1.2 Objectifs
- Modéliser les données du système hospitalier (patients, personnel, séjours, actes médicaux)
- Appliquer la méthode MERISE : MCD → MLD → SQL
- Implémenter les contraintes d'intégrité métier
- Optimiser le code SQL (version minimale exhaustive)

### 1.3 Périmètre fonctionnel
| Domaine | Fonctionnalités |
|---------|-----------------|
| **Patients** | Gestion des patients, antécédents, identifiants (IPP) |
| **Séjours** | Admissions, sorties, affectation lits (IEP) |
| **Personnel** | Médecins (RPPS), infirmiers (IDE/IBODE/IADE), héritage |
| **Actes médicaux** | Consultations, prescriptions, interventions (CCAM) |
| **Facturation** | Actes réalisés, tarification, suivi paiements |
| **Infrastructure** | Services, chambres, lits, blocs opératoires |

---

## 2. ANALYSE DES BESOINS

### 2.1 Règles de gestion
| # | Règle de gestion |
|---|------------------|
| RG1 | Un patient est identifié de façon unique par son IPP (Identifiant Permanent Patient) |
| RG2 | Chaque séjour possède un IEP unique (Identifiant Épisode Patient) |
| RG3 | Un personnel est SOIT médecin SOIT infirmier (héritage exclusif) |
| RG4 | Un médecin est identifié par son numéro RPPS (11 caractères) |
| RG5 | Un lit ne peut être occupé que par un seul séjour à la fois |
| RG6 | Un service peut avoir au maximum un chef de service (médecin) |
| RG7 | Les actes médicaux sont codifiés selon la nomenclature CCAM |
| RG8 | Une intervention peut comprendre plusieurs actes médicaux ordonnés |
| RG9 | Un infirmier peut être affecté à plusieurs services (rotation) |
| RG10 | La facturation est calculée : quantité × tarif de l'acte |

### 2.2 Contraintes techniques
- **SGBD :** MySQL 8.0+ avec InnoDB
- **Charset :** UTF-8 (utf8mb4) pour les caractères français
- **Intégrité :** Clés étrangères avec actions référentielles
- **Performance :** Index sur les colonnes fréquemment interrogées

---

## 3. MODÈLE CONCEPTUEL DE DONNÉES (MCD)

### 3.1 Vue d'ensemble

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           MCD SYSTÈME HOSPITALIER                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌──────────┐                                      ┌──────────────┐       │
│   │ PATIENT  │──────(1,N)──────EFFECTUE────(0,N)────│ CONSULTATION │       │
│   │   IPP    │                                      │id_consultation│       │
│   └────┬─────┘                                      └───────┬──────┘       │
│        │                                                    │              │
│      (1,N)                                               (1,1)             │
│        │                                                    │              │
│   ┌────▼─────┐                                      ┌───────▼──────┐       │
│   │ A_SEJOUR │                                      │   CONSULTE   │       │
│   └────┬─────┘                                      └───────┬──────┘       │
│        │                                                    │              │
│      (1,1)                                               (0,N)             │
│        │                                                    │              │
│   ┌────▼─────┐     ┌──────────┐                    ┌───────▼──────┐       │
│   │  SEJOUR  │─────│  OCCUPE  │────────────────────│   MEDECIN    │       │
│   │   IEP    │     │date_debut│                    │    RPPS      │       │
│   └────┬─────┘     │ date_fin │                    └───────┬──────┘       │
│        │           └────┬─────┘                            │              │
│      (0,N)            (1,1)                              (0,1)             │
│        │                │                                  │              │
│   ┌────▼─────┐     ┌────▼─────┐                    ┌───────▼──────┐       │
│   │ FACTURE  │     │   LIT    │                    │   EST_UN     │       │
│   │ quantité │     │  id_lit  │                    │  (héritage)  │       │
│   └────┬─────┘     └────┬─────┘                    └───────┬──────┘       │
│        │                │                                  │              │
│      (0,N)            (1,1)                              (1,1)             │
│        │                │                                  │              │
│   ┌────▼─────┐     ┌────▼─────┐                    ┌───────▼──────┐       │
│   │ACTE_MED  │     │ CHAMBRE  │                    │  PERSONNEL   │       │
│   │code_CCAM │     │id_chambre│                    │id_personnel  │       │
│   └────┬─────┘     └────┬─────┘                    └───────┬──────┘       │
│        │                │                                  │              │
│      (1,N)            (1,1)                              (1,1)             │
│        │                │                                  │              │
│   ┌────▼─────┐     ┌────▼─────┐                    ┌───────▼──────┐       │
│   │ COMPREND │     │ SERVICE  │                    │   EST_UN     │       │
│   │  ordre   │     │id_service│                    │  (héritage)  │       │
│   └────┬─────┘     └──────────┘                    └───────┬──────┘       │
│        │                                                   │              │
│      (1,N)                                               (0,1)             │
│        │                                                   │              │
│   ┌────▼─────────┐                                 ┌───────▼──────┐       │
│   │ INTERVENTION │                                 │  INFIRMIER   │       │
│   │id_intervention│                                │ id_infirmier │       │
│   └──────────────┘                                 └──────────────┘       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Liste des Entités (13)

| # | Entité | Identifiant | Description |
|---|--------|-------------|-------------|
| 1 | PATIENT | IPP | Patients hospitalisés |
| 2 | PERSONNEL | id_personnel | Personnel hospitalier (entité mère) |
| 3 | MEDECIN | RPPS | Médecins (hérite de PERSONNEL) |
| 4 | INFIRMIER | id_infirmier | Infirmiers (hérite de PERSONNEL) |
| 5 | SERVICE | id_service | Services hospitaliers |
| 6 | CHAMBRE | id_chambre | Chambres des services |
| 7 | LIT | id_lit | Lits des chambres |
| 8 | SEJOUR | IEP | Séjours hospitaliers |
| 9 | CONSULTATION | id_consultation | Consultations médicales |
| 10 | PRESCRIPTION | id_prescription | Prescriptions médicamenteuses |
| 11 | ACTE_MEDICAL | code_CCAM | Catalogue des actes CCAM |
| 12 | INTERVENTION | id_intervention | Interventions chirurgicales |
| 13 | BLOC_OPERATOIRE | id_bloc | Blocs opératoires |

### 3.3 Liste des Associations (4 N-N)

| # | Association | Entités liées | Attributs portés |
|---|-------------|---------------|------------------|
| 1 | OCCUPE | SEJOUR ↔ LIT | date_debut, date_fin, motif_changement |
| 2 | AFFECTE_A | INFIRMIER ↔ SERVICE | date_debut, date_fin, taux_activite |
| 3 | FACTURE | SEJOUR ↔ ACTE_MEDICAL | quantite, date_realisation, montant_total |
| 4 | COMPREND | INTERVENTION ↔ ACTE_MEDICAL | ordre, duree_estimee |

### 3.4 Héritage Merise

```
                    ┌─────────────┐
                    │  PERSONNEL  │
                    │id_personnel │
                    │ nom, prenom │
                    │date_embauche│
                    └──────┬──────┘
                           │
                    ┌──────┴──────┐
                    │   IS-A (XT) │  ← Exclusif Total
                    └──────┬──────┘
              ┌────────────┼────────────┐
              │                         │
       ┌──────▼──────┐           ┌──────▼──────┐
       │   MEDECIN   │           │  INFIRMIER  │
       │    RPPS     │           │ id_infirmier│
       │ specialite  │           │   grade     │
       └─────────────┘           └─────────────┘
```

**Type d'héritage :** Exclusif Total (XT)
- Un PERSONNEL est obligatoirement SOIT un MEDECIN SOIT un INFIRMIER
- Un PERSONNEL ne peut PAS être les deux à la fois
- Contrainte implémentée par **triggers** en SQL

---

## 4. DICTIONNAIRE DES DONNÉES

### 4.1 Entité PATIENT
| Attribut | Type | Taille | Null | Description |
|----------|------|--------|------|-------------|
| **IPP** | VARCHAR | 20 | NON | Identifiant Permanent Patient (PK) |
| nom | VARCHAR | 100 | NON | Nom de famille |
| prenom | VARCHAR | 100 | NON | Prénom |
| date_naissance | DATE | - | NON | Date de naissance |
| sexe | ENUM | M/F | NON | Sexe du patient |
| num_secu | VARCHAR | 15 | NON | N° Sécurité Sociale (UNIQUE) |
| telephone | VARCHAR | 15 | OUI | Téléphone de contact |
| adresse | TEXT | - | OUI | Adresse postale |
| antecedents | TEXT | - | OUI | Antécédents médicaux |

### 4.2 Entité PERSONNEL
| Attribut | Type | Taille | Null | Description |
|----------|------|--------|------|-------------|
| **id_personnel** | INT | AUTO | NON | Identifiant personnel (PK) |
| nom | VARCHAR | 100 | NON | Nom de famille |
| prenom | VARCHAR | 100 | NON | Prénom |
| date_naissance | DATE | - | NON | Date de naissance |
| date_embauche | DATE | - | NON | Date d'embauche |
| telephone | VARCHAR | 15 | OUI | Téléphone professionnel |
| type_contrat | ENUM | CDI/CDD/Interim | NON | Type de contrat |
| actif | BOOLEAN | - | NON | Personnel en activité |

### 4.3 Entité MEDECIN
| Attribut | Type | Taille | Null | Description |
|----------|------|--------|------|-------------|
| **RPPS** | VARCHAR | 11 | NON | Répertoire Partagé Professionnels Santé (PK) |
| id_personnel | INT | - | NON | FK vers PERSONNEL (UNIQUE) |
| specialite | VARCHAR | 100 | NON | Spécialité médicale |
| id_service_principal | INT | - | OUI | FK vers SERVICE |

### 4.4 Entité SEJOUR
| Attribut | Type | Taille | Null | Description |
|----------|------|--------|------|-------------|
| **IEP** | VARCHAR | 20 | NON | Identifiant Épisode Patient (PK) |
| IPP | VARCHAR | 20 | NON | FK vers PATIENT |
| date_admission | DATETIME | - | NON | Date et heure d'admission |
| date_sortie | DATETIME | - | OUI | Date et heure de sortie |
| motif_admission | TEXT | - | NON | Motif d'hospitalisation |
| mode_entree | ENUM | Urgence/Programmé/Mutation | NON | Mode d'entrée |
| mode_sortie | ENUM | Domicile/Transfert/Décès | OUI | Mode de sortie |
| diagnostic_principal | VARCHAR | 200 | OUI | Diagnostic principal |

### 4.5 Entité ACTE_MEDICAL
| Attribut | Type | Taille | Null | Description |
|----------|------|--------|------|-------------|
| **code_CCAM** | VARCHAR | 10 | NON | Code CCAM de l'acte (PK) |
| libelle | VARCHAR | 300 | NON | Libellé de l'acte |
| tarif | DECIMAL | 10,2 | NON | Tarif de l'acte (€) |
| categorie | ENUM | Consultation/Imagerie/Biologie/Chirurgie/Anesthésie | NON | Catégorie |
| duree_moyenne | INT | - | OUI | Durée moyenne en minutes |

---

## 5. CARDINALITÉS MERISE

### 5.1 Tableau des cardinalités

| Entité 1 | Card. | Association | Card. | Entité 2 | Signification |
|----------|-------|-------------|-------|----------|---------------|
| PATIENT | 1,N | A_SEJOUR | 1,1 | SEJOUR | Un patient a au moins 1 séjour |
| SEJOUR | 1,N | OCCUPE | 1,1 | LIT | Un séjour occupe au moins 1 lit |
| SEJOUR | 0,N | FACTURE | 0,N | ACTE_MEDICAL | Association N-N facturation |
| LIT | 1,1 | APPARTIENT | 1,N | CHAMBRE | Un lit appartient à 1 chambre |
| CHAMBRE | 1,1 | CONTIENT | 1,N | SERVICE | Une chambre appartient à 1 service |
| PERSONNEL | 1,1 | EST_MEDECIN | 0,1 | MEDECIN | Héritage exclusif |
| PERSONNEL | 1,1 | EST_INFIRMIER | 0,1 | INFIRMIER | Héritage exclusif |
| INFIRMIER | 0,N | AFFECTE_A | 0,N | SERVICE | Association N-N rotation |
| MEDECIN | 0,1 | DIRIGE | 1,1 | SERVICE | Un service a au max 1 chef |
| INTERVENTION | 1,N | COMPREND | 1,N | ACTE_MEDICAL | Association N-N composition |
| INTERVENTION | 1,1 | SE_DEROULE | 0,N | BLOC_OPERATOIRE | Une intervention dans 1 bloc |
| PATIENT | 1,N | EFFECTUE | 0,N | CONSULTATION | Un patient peut avoir N consultations |
| CONSULTATION | 1,1 | CONSULTE | 0,N | MEDECIN | Une consultation par 1 médecin |
| SEJOUR | 0,N | CONCERNE | 0,N | PRESCRIPTION | Prescriptions pendant séjour |
| PRESCRIPTION | 1,1 | REDIGE | 0,N | MEDECIN | Une prescription par 1 médecin |

### 5.2 Notation Merise

| Notation | Signification |
|----------|---------------|
| (0,1) | Optionnel, au maximum 1 |
| (1,1) | Obligatoire, exactement 1 |
| (0,N) | Optionnel, plusieurs possibles |
| (1,N) | Obligatoire, au moins 1 |

---

## 6. MODÈLE LOGIQUE DE DONNÉES (MLD)

### 6.1 Règles de transformation MCD → MLD

| Règle | Application |
|-------|-------------|
| **R1** | Entité → Table avec PK |
| **R2** | Association 1-N → FK dans table côté N |
| **R3** | Association N-N → Table associative avec 2 FK |
| **R4** | Héritage exclusif → FK + triggers de validation |

### 6.2 Schéma relationnel

```sql
PATIENT (IPP, nom, prenom, date_naissance, sexe, num_secu, telephone, adresse, antecedents)
    PK: IPP
    UNIQUE: num_secu

PERSONNEL (id_personnel, nom, prenom, date_naissance, date_embauche, telephone, type_contrat, actif)
    PK: id_personnel

MEDECIN (RPPS, id_personnel, specialite, id_service_principal)
    PK: RPPS
    FK: id_personnel → PERSONNEL(id_personnel) ON DELETE CASCADE
    FK: id_service_principal → SERVICE(id_service) ON DELETE SET NULL
    UNIQUE: id_personnel

INFIRMIER (id_infirmier, id_personnel, grade)
    PK: id_infirmier
    FK: id_personnel → PERSONNEL(id_personnel) ON DELETE CASCADE
    UNIQUE: id_personnel

SERVICE (id_service, nom_service, batiment, etage, specialite, RPPS_chef, telephone_service)
    PK: id_service
    FK: RPPS_chef → MEDECIN(RPPS) ON DELETE SET NULL
    UNIQUE: nom_service, RPPS_chef

CHAMBRE (id_chambre, id_service, numero_chambre, capacite, type_chambre)
    PK: id_chambre
    FK: id_service → SERVICE(id_service) ON DELETE RESTRICT
    UNIQUE: (id_service, numero_chambre)

LIT (id_lit, id_chambre, numero_lit, etat, type_lit, equipements)
    PK: id_lit
    FK: id_chambre → CHAMBRE(id_chambre) ON DELETE RESTRICT
    UNIQUE: (id_chambre, numero_lit)

SEJOUR (IEP, IPP, date_admission, date_sortie, motif_admission, mode_entree, mode_sortie, diagnostic_principal)
    PK: IEP
    FK: IPP → PATIENT(IPP) ON DELETE RESTRICT
    CHECK: date_sortie >= date_admission

CONSULTATION (id_consultation, IPP_patient, RPPS_medecin, date_heure, motif, diagnostic, statut)
    PK: id_consultation
    FK: IPP_patient → PATIENT(IPP) ON DELETE RESTRICT
    FK: RPPS_medecin → MEDECIN(RPPS) ON DELETE RESTRICT

PRESCRIPTION (id_prescription, IEP_sejour, RPPS_medecin, date_prescription, medicament, posologie, voie_administration, date_debut, date_fin, statut)
    PK: id_prescription
    FK: IEP_sejour → SEJOUR(IEP) ON DELETE RESTRICT
    FK: RPPS_medecin → MEDECIN(RPPS) ON DELETE RESTRICT

ACTE_MEDICAL (code_CCAM, libelle, tarif, categorie, duree_moyenne)
    PK: code_CCAM
    CHECK: tarif >= 0

BLOC_OPERATOIRE (id_bloc, nom_bloc, batiment, etage, equipements, statut)
    PK: id_bloc
    UNIQUE: nom_bloc

INTERVENTION (id_intervention, IEP_sejour, RPPS_chirurgien, id_bloc, date_intervention, heure_debut, heure_fin, type_intervention, compte_rendu, statut)
    PK: id_intervention
    FK: IEP_sejour → SEJOUR(IEP) ON DELETE RESTRICT
    FK: RPPS_chirurgien → MEDECIN(RPPS) ON DELETE RESTRICT
    FK: id_bloc → BLOC_OPERATOIRE(id_bloc) ON DELETE RESTRICT

-- TABLES ASSOCIATIVES (Associations N-N)

OCCUPE (id_occupation, IEP_sejour, id_lit, date_debut, date_fin, motif_changement)
    PK: id_occupation
    FK: IEP_sejour → SEJOUR(IEP) ON DELETE RESTRICT
    FK: id_lit → LIT(id_lit) ON DELETE RESTRICT
    UNIQUE: (id_lit, date_debut)

AFFECTE_A (id_affectation, id_infirmier, id_service, date_debut, date_fin, taux_activite)
    PK: id_affectation
    FK: id_infirmier → INFIRMIER(id_infirmier) ON DELETE CASCADE
    FK: id_service → SERVICE(id_service) ON DELETE RESTRICT

FACTURE (id_facturation, IEP_sejour, code_CCAM, quantite, date_realisation, montant_total, statut_facturation)
    PK: id_facturation
    FK: IEP_sejour → SEJOUR(IEP) ON DELETE RESTRICT
    FK: code_CCAM → ACTE_MEDICAL(code_CCAM) ON DELETE RESTRICT
    COMPUTED: montant_total = quantite × tarif

COMPREND (id_composition, id_intervention, code_CCAM, ordre, duree_estimee)
    PK: id_composition
    FK: id_intervention → INTERVENTION(id_intervention) ON DELETE CASCADE
    FK: code_CCAM → ACTE_MEDICAL(code_CCAM) ON DELETE RESTRICT
    UNIQUE: (id_intervention, ordre)
```

---

## 7. IMPLÉMENTATION SQL

### 7.1 Fichiers du projet

| Fichier | Description | Lignes |
|---------|-------------|--------|
| `hopital_db_merise.sql` | Code SQL optimisé (version minimale) | ~350 |
| `hopital_db_complete.sql` | Code SQL complet (version référence) | ~1100 |

### 7.2 Structure du code SQL

```sql
-- Structure du fichier hopital_db_merise.sql
-- ============================================

-- SECTION 1 : ENTITÉS SIMPLES (13 tables)
CREATE TABLE PATIENT (...);
CREATE TABLE PERSONNEL (...);
CREATE TABLE MEDECIN (...);
CREATE TABLE INFIRMIER (...);
CREATE TABLE BLOC_OPERATOIRE (...);
CREATE TABLE SERVICE (...);
CREATE TABLE CHAMBRE (...);
CREATE TABLE LIT (...);
CREATE TABLE SEJOUR (...);
CREATE TABLE CONSULTATION (...);
CREATE TABLE PRESCRIPTION (...);
CREATE TABLE ACTE_MEDICAL (...);
CREATE TABLE INTERVENTION (...);

-- SECTION 2 : ASSOCIATIONS N-N (4 tables)
CREATE TABLE OCCUPE (...);
CREATE TABLE AFFECTE_A (...);
CREATE TABLE FACTURE (...);
CREATE TABLE COMPREND (...);

-- SECTION 3 : TRIGGERS MÉTIER (5 triggers)
CREATE TRIGGER trg_heritage_exclusif_medecin ...
CREATE TRIGGER trg_heritage_exclusif_infirmier ...
CREATE TRIGGER trg_occupation_lit_unique ...
CREATE TRIGGER trg_lit_etat_insert ...
CREATE TRIGGER trg_lit_etat_update ...

-- SECTION 4 : VUES MÉTIER (4 vues)
CREATE VIEW v_sejours_en_cours ...
CREATE VIEW v_lits_disponibles ...
CREATE VIEW v_taux_occupation_service ...
CREATE VIEW v_facturation_sejour ...

-- SECTION 5 : DONNÉES DE TEST
INSERT INTO PATIENT ...
INSERT INTO PERSONNEL ...
...
```

---

## 8. TRIGGERS ET CONTRAINTES

### 8.1 Triggers implémentés

| # | Trigger | Table | Événement | Fonction |
|---|---------|-------|-----------|----------|
| 1 | trg_heritage_exclusif_medecin | MEDECIN | BEFORE INSERT | Vérifie qu'un personnel n'est pas déjà infirmier |
| 2 | trg_heritage_exclusif_infirmier | INFIRMIER | BEFORE INSERT | Vérifie qu'un personnel n'est pas déjà médecin |
| 3 | trg_occupation_lit_unique | OCCUPE | BEFORE INSERT | Vérifie qu'un lit n'est pas déjà occupé |
| 4 | trg_lit_etat_insert | OCCUPE | AFTER INSERT | Met à jour l'état du lit en "Occupé" |
| 5 | trg_lit_etat_update | OCCUPE | AFTER UPDATE | Met à jour l'état du lit en "Disponible" |

### 8.2 Exemple de trigger

```sql
-- Trigger : Héritage exclusif PERSONNEL → MEDECIN
CREATE TRIGGER trg_heritage_exclusif_medecin 
BEFORE INSERT ON MEDECIN
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM INFIRMIER WHERE id_personnel = NEW.id_personnel) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'ERREUR: Personnel déjà enregistré comme infirmier';
    END IF;
END;
```

### 8.3 Contraintes CHECK

| Table | Contrainte | Expression |
|-------|------------|------------|
| CHAMBRE | capacite_valide | capacite BETWEEN 1 AND 6 |
| SEJOUR | dates_coherentes | date_sortie IS NULL OR date_sortie >= date_admission |
| ACTE_MEDICAL | tarif_positif | tarif >= 0 |
| AFFECTE_A | taux_valide | taux_activite > 0 AND taux_activite <= 100 |
| COMPREND | ordre_positif | ordre > 0 |

---

## 9. VUES MÉTIER

### 9.1 Liste des vues

| Vue | Description | Utilisation |
|-----|-------------|-------------|
| v_sejours_en_cours | Séjours actifs avec localisation | Dashboard admissions |
| v_lits_disponibles | Lits libres par service | Gestion des places |
| v_taux_occupation_service | Taux d'occupation par service | Pilotage activité |
| v_facturation_sejour | Facturation par séjour | Reporting financier |

### 9.2 Exemple de vue

```sql
-- Vue : Séjours en cours avec localisation
CREATE VIEW v_sejours_en_cours AS
SELECT 
    s.IEP, 
    p.IPP, 
    CONCAT(p.nom, ' ', p.prenom) AS patient, 
    s.date_admission, 
    DATEDIFF(NOW(), s.date_admission) AS jours,
    sv.nom_service, 
    c.numero_chambre, 
    l.numero_lit
FROM SEJOUR s
JOIN PATIENT p ON s.IPP = p.IPP
LEFT JOIN OCCUPE o ON s.IEP = o.IEP_sejour AND o.date_fin IS NULL
LEFT JOIN LIT l ON o.id_lit = l.id_lit
LEFT JOIN CHAMBRE c ON l.id_chambre = c.id_chambre
LEFT JOIN SERVICE sv ON c.id_service = sv.id_service
WHERE s.date_sortie IS NULL;
```

---

## 10. TESTS ET VALIDATION

### 10.1 Requêtes de test

```sql
-- Test 1 : Vérifier l'héritage exclusif
INSERT INTO MEDECIN (RPPS, id_personnel, specialite) VALUES ('99999999999', 3, 'Test');
-- Attendu : ERREUR (id_personnel=3 est déjà infirmier)

-- Test 2 : Vérifier l'occupation unique des lits
INSERT INTO OCCUPE (IEP_sejour, id_lit, date_debut) VALUES ('PAT001-20251219-0001', 1, NOW());
-- Attendu : ERREUR (lit 1 déjà occupé)

-- Test 3 : Vérifier les vues
SELECT * FROM v_sejours_en_cours;
SELECT * FROM v_lits_disponibles;
SELECT * FROM v_taux_occupation_service;
```

### 10.2 Résultats attendus

| Test | Résultat attendu | Validé |
|------|------------------|--------|
| Héritage exclusif médecin | Erreur SQLSTATE 45000 | ✅ |
| Héritage exclusif infirmier | Erreur SQLSTATE 45000 | ✅ |
| Occupation lit unique | Erreur SQLSTATE 45000 | ✅ |
| État lit après insertion | etat = 'Occupé' | ✅ |
| État lit après mise à jour | etat = 'Disponible' | ✅ |
| Vue sejours_en_cours | Données cohérentes | ✅ |

---

## 11. CONCLUSION

### 11.1 Bilan du projet

| Critère | Statut |
|---------|--------|
| MCD conforme Merise | ✅ Validé |
| 13 entités modélisées | ✅ Complet |
| 4 associations N-N | ✅ Implémentées |
| Héritage exclusif | ✅ Triggers fonctionnels |
| Cardinalités respectées | ✅ FK et contraintes |
| Code SQL optimisé | ✅ ~350 lignes (vs 1100) |
| Terminologie française | ✅ 100% français |

### 11.2 Points forts
- ✅ Modèle complet et exhaustif
- ✅ Respect strict de la méthode Merise
- ✅ Code SQL optimisé et lisible
- ✅ Triggers métier fonctionnels
- ✅ Vues métier essentielles

### 11.3 Améliorations possibles
- 📌 Ajouter des index sur les requêtes fréquentes
- 📌 Implémenter des procédures stockées pour les opérations complexes
- 📌 Ajouter des triggers d'audit (historisation des modifications)
- 📌 Créer une API REST pour l'accès aux données

---

## 📁 STRUCTURE DES FICHIERS

```
projet-hopitale-bdd/
├── 📄 RAPPORT_TP_MCD_MERISE.md      # Ce rapport
├── 📄 hopital_db_merise.sql          # Code SQL optimisé (~350 lignes)
├── 📄 hopital_db_complete.sql        # Code SQL complet (~1100 lignes)
├── 📄 MERISE_ANALYSE.md              # Analyse détaillée Merise
├── 📄 COMPARAISON_OPTIMISATION.md    # Comparaison avant/après
├── 📄 MCD_MERISE_DOCUMENTATION.md    # Documentation MCD
├── 📁 mocodo/
│   ├── 📄 MCD_MOCODO.mcd             # Code Mocodo détaillé
│   └── 📄 MCD_MOCODO_SIMPLE.mcd      # Code Mocodo simplifié
└── 📄 projet_mcd-1.pdf               # Énoncé du TP
```

---

**Fin du rapport**

*Généré le 19 décembre 2025*
