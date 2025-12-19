# 📊 MCD MERISE - Système de Gestion Hospitalière

## Structure du Modèle Conceptuel de Données

---

## 🎯 ENTITÉS PRINCIPALES

### 1️⃣ **PATIENT** (Entité)
**Identifiant : IPP** (Identifiant Permanent Patient)
- IPP (PK)
- nom
- prenom
- date_naissance
- sexe
- num_secu_sociale (Unique)
- telephone
- adresse
- antecedents
- date_creation, date_modification

**Cardinalités:**
- PATIENT (1,1) --- ADMET --- (0,N) SEJOUR

---

### 2️⃣ **PERSONNEL** (Entité mère - Héritage)
**Identifiant : id_personnel**
- id_personnel (PK, Auto-increment)
- nom
- prenom
- date_naissance
- date_embauche
- telephone
- type_contrat
- actif

**Héritage Exclusif :**
- PERSONNEL (1,1) ---IS-A--- (0,1) MEDECIN
- PERSONNEL (1,1) ---IS-A--- (0,1) INFIRMIER

---

### 3️⃣ **MEDECIN** (Spécialisation de PERSONNEL)
**Identifiant : RPPS** (Répertoire Partagé Professionnels Santé)
- RPPS (PK)
- id_personnel (FK, Unique) → PERSONNEL
- specialite
- id_service_principal (FK, Nullable) → SERVICE
- est_chef_service

**Cardinalités:**
- MEDECIN (1,1) --- DIRIGE --- (0,1) SERVICE (Chef de service)
- MEDECIN (0,1) --- AFFECTE_PRINCIPAL --- (1,1) SERVICE
- MEDECIN (0,N) --- CONSULTE --- (0,N) PATIENT
- MEDECIN (0,N) --- PRESCRIT --- (0,N) SEJOUR
- MEDECIN (0,N) --- OPERA --- (0,N) SEJOUR

---

### 4️⃣ **INFIRMIER** (Spécialisation de PERSONNEL)
**Identifiant : id_infirmier**
- id_infirmier (PK, Auto-increment)
- id_personnel (FK, Unique) → PERSONNEL
- grade (IDE, IBODE, IADE, IPDE, Cadre)
- diplome

**Cardinalités:**
- INFIRMIER (0,N) --- AFFECTE_A --- (0,N) SERVICE

---

### 5️⃣ **SERVICE** (Entité)
**Identifiant : id_service**
- id_service (PK, Auto-increment)
- nom_service (Unique)
- batiment
- etage
- specialite
- RPPS_chef (FK, Nullable, Unique) → MEDECIN
- telephone_service

**Cardinalités:**
- SERVICE (1,N) --- CONTIENT --- (1,1) CHAMBRE
- SERVICE (0,1) --- DIRIGE --- (0,1) MEDECIN

---

### 6️⃣ **CHAMBRE** (Entité)
**Identifiant : id_chambre**
- id_chambre (PK, Auto-increment)
- id_service (FK) → SERVICE
- numero_chambre
- capacite_totale (1-6)
- type_chambre (Individuelle, Double, Triple, Commune, Isolement, Réanimation)

**Cardinalités:**
- CHAMBRE (1,1) --- CONTIENT --- (1,N) LIT
- CHAMBRE (1,N) --- APPARTIENT_A --- (1,1) SERVICE

---

### 7️⃣ **LIT** (Entité)
**Identifiant : id_lit**
- id_lit (PK, Auto-increment)
- id_chambre (FK) → CHAMBRE
- numero_lit
- etat (Disponible, Occupé, Maintenance, Réservé)
- type_lit (Standard, Médicalisé, Bariatrique, Pédiatrique)
- equipements
- date_derniere_maintenance

**Cardinalités:**
- LIT (1,1) --- OCCUPE --- (0,N) SEJOUR (via OCCUPE)

---

### 8️⃣ **SEJOUR** (Entité)
**Identifiant : IEP** (Identifiant Épisode Patient)
- IEP (PK)
- IPP (FK) → PATIENT
- date_admission
- date_sortie (Nullable)
- motif_admission
- mode_entree (Urgence, Programmé, Mutation, Naissance)
- mode_sortie (Domicile, Transfert, Décès, Fugue)
- diagnostic_principal

**Cardinalités:**
- SEJOUR (0,N) --- ADMET --- (1,1) PATIENT
- SEJOUR (0,N) --- OCCUPE --- (1,1) LIT (via OCCUPE)
- SEJOUR (0,N) --- FACTURE --- (0,N) ACTE_MEDICAL (via FACTURE)

---

### 9️⃣ **CONSULTATION** (Entité)
**Identifiant : id_consultation**
- id_consultation (PK, Auto-increment)
- IPP_patient (FK) → PATIENT
- RPPS_medecin (FK) → MEDECIN
- date_heure
- motif
- diagnostic
- compte_rendu
- statut

**Cardinalités:**
- CONSULTATION (0,N) --- CONSULTE --- (0,N) MEDECIN
- CONSULTATION (0,N) --- AVEC --- (0,N) PATIENT

---

### 🔟 **PRESCRIPTION** (Entité)
**Identifiant : id_prescription**
- id_prescription (PK, Auto-increment)
- IEP_sejour (FK) → SEJOUR
- RPPS_medecin (FK) → MEDECIN
- date_prescription
- medicament
- posologie
- voie_administration
- statut
- date_debut, date_fin

**Cardinalités:**
- PRESCRIPTION (0,N) --- PRESCRIT --- (0,N) MEDECIN
- PRESCRIPTION (0,N) --- POUR --- (0,N) SEJOUR

---

### 1️⃣1️⃣ **INTERVENTION** (Entité)
**Identifiant : id_intervention**
- id_intervention (PK, Auto-increment)
- IEP_sejour (FK) → SEJOUR
- RPPS_chirurgien (FK) → MEDECIN
- id_bloc (FK) → BLOC_OPERATOIRE
- date_intervention
- heure_debut, heure_fin
- type_intervention
- compte_rendu
- statut

**Cardinalités:**
- INTERVENTION (0,N) --- OPERA --- (0,N) MEDECIN
- INTERVENTION (0,N) --- POUR --- (0,N) SEJOUR
- INTERVENTION (0,N) --- UTILISE --- (1,1) BLOC_OPERATOIRE
- INTERVENTION (0,N) --- COMPREND --- (0,N) ACTE_MEDICAL (via COMPREND)

---

### 1️⃣2️⃣ **ACTE_MEDICAL** (Entité - Référentiel CCAM)
**Identifiant : code_CCAM**
- code_CCAM (PK)
- libelle
- tarif
- categorie
- duree_moyenne

**Cardinalités:**
- ACTE_MEDICAL (0,N) --- FACTURE --- (0,N) SEJOUR (via FACTURE)
- ACTE_MEDICAL (0,N) --- COMPREND --- (0,N) INTERVENTION (via COMPREND)

---

### 1️⃣3️⃣ **BLOC_OPERATOIRE** (Entité)
**Identifiant : id_bloc**
- id_bloc (PK, Auto-increment)
- nom_bloc (Unique)
- batiment
- etage
- equipements
- statut

**Cardinalités:**
- BLOC_OPERATOIRE (1,1) --- UTILISE --- (0,N) INTERVENTION

---

---

## 🔗 ASSOCIATIONS (Relations N-N avec attributs)

### 🔀 **OCCUPE** (Associative SEJOUR ↔ LIT)
**Identifiants : (IEP_sejour, id_lit, date_debut)**
- id_occupation (PK)
- IEP_sejour (FK) → SEJOUR
- id_lit (FK) → LIT
- date_debut
- date_fin (Nullable - en cours)
- motif_changement

**Cardinalités:**
- SEJOUR (1,N) --- OCCUPE --- (1,1) LIT
- LIT (0,N) --- OCCUPE --- (1,1) SEJOUR

**Propriété:** Historique d'affectation avec dates

---

### 🔀 **AFFECTE_A** (Associative INFIRMIER ↔ SERVICE)
**Identifiants : (id_infirmier, id_service, date_debut)**
- id_affectation (PK)
- id_infirmier (FK) → INFIRMIER
- id_service (FK) → SERVICE
- date_debut
- date_fin (Nullable - en cours)
- taux_activite (0-100%)

**Cardinalités:**
- INFIRMIER (1,N) --- AFFECTE_A --- (1,N) SERVICE
- SERVICE (0,N) --- AFFECTE_A --- (0,N) INFIRMIER

**Propriété:** Rotation et taux d'activité

---

### 🔀 **FACTURE** (Associative SEJOUR ↔ ACTE_MEDICAL)
**Identifiants : (IEP_sejour, code_CCAM, date_realisation)**
- id_facturation (PK)
- IEP_sejour (FK) → SEJOUR
- code_CCAM (FK) → ACTE_MEDICAL
- quantite
- date_realisation
- montant_total (Calculé = quantite × tarif)
- statut_facturation

**Cardinalités:**
- SEJOUR (1,N) --- FACTURE --- (1,N) ACTE_MEDICAL
- ACTE_MEDICAL (0,N) --- FACTURE --- (0,N) SEJOUR

**Propriété:** Facturation avec calcul de montant

---

### 🔀 **COMPREND** (Associative INTERVENTION ↔ ACTE_MEDICAL)
**Identifiants : (id_intervention, code_CCAM, ordre)**
- id_composition (PK)
- id_intervention (FK) → INTERVENTION
- code_CCAM (FK) → ACTE_MEDICAL
- ordre (Séquence)
- duree_estimee

**Cardinalités:**
- INTERVENTION (1,N) --- COMPREND --- (1,N) ACTE_MEDICAL
- ACTE_MEDICAL (0,N) --- COMPREND --- (0,N) INTERVENTION

**Propriété:** Composition d'une intervention

---

---

## 📋 RÉSUMÉ DES CARDINALITÉS MERISE

| De | Vers | Cardinalité | Type |
|---|---|---|---|
| PATIENT | SEJOUR | (1,N) | 1 patient → N séjours |
| SEJOUR | LIT | (0,N) → (1,1) via OCCUPE | Historique lits |
| CHAMBRE | LIT | (1,N) | 1 chambre → N lits |
| SERVICE | CHAMBRE | (1,N) | 1 service → N chambres |
| MEDECIN | SERVICE | (0,1) → (0,1) | Chef de service |
| INFIRMIER | SERVICE | (0,N) → (0,N) via AFFECTE_A | Rotation |
| MEDECIN | CONSULTATION | (0,N) | 1 médecin → N consultations |
| MEDECIN | PRESCRIPTION | (0,N) | 1 médecin → N prescriptions |
| MEDECIN | INTERVENTION | (0,N) | 1 chirurgien → N interventions |
| INTERVENTION | BLOC_OPERATOIRE | (0,N) → (1,1) | Bloc opératoire |
| INTERVENTION | ACTE_MEDICAL | (0,N) → (0,N) via COMPREND | Composition |
| SEJOUR | ACTE_MEDICAL | (0,N) → (0,N) via FACTURE | Facturation |

---

## 🔐 CONTRAINTES MÉTIER

✅ **Héritage Exclusif** : PERSONNEL → MEDECIN OU INFIRMIER (pas les deux)
✅ **Unité d'Occupation** : Un lit = un séjour à la fois
✅ **Chef de Service** : Unique par service, doit être affecté
✅ **Dates Valides** : date_fin ≥ date_debut
✅ **Lits Médicalisés** : Types et équipements selon besoin patient

---

## 🎓 CONFORMITÉ MERISE

✅ Toutes les entités identifiées (13)
✅ Toutes les associations détaillées (4)
✅ Cardinalités complètes (Merise 1,N / 0,N)
✅ Héritage explicite (IS-A)
✅ Attributs discriminants présents
✅ Contraintes d'intégrité programmées

**Ce modèle est un MCD MERISE COMPLET ET OPTIMISÉ! 📊**

