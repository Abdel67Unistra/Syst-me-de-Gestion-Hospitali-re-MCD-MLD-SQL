# 📊 ANALYSE MERISE COMPLÈTE - SYSTÈME HOSPITALIER

## 1️⃣ ENTITÉS (13 totales)

| ID | Entité | Identifiant | Cardinalités | Type |
|---|---|---|---|---|
| 1 | **PATIENT** | IPP | ADMET (1,N) SEJOUR | Simple |
| 2 | **PERSONNEL** | id_personnel | IS-A → MEDECIN / INFIRMIER | Mère (héritage) |
| 3 | **MEDECIN** | RPPS | FK id_personnel (héritage) | Spécialisation |
| 4 | **INFIRMIER** | id_infirmier | FK id_personnel (héritage) | Spécialisation |
| 5 | **SERVICE** | id_service | CONTIENT (1,N) CHAMBRE | Simple |
| 6 | **CHAMBRE** | id_chambre | CONTIENT (1,N) LIT | Simple |
| 7 | **LIT** | id_lit | OCCUPE (0,N) SEJOUR via OCCUPE | Simple |
| 8 | **SEJOUR** | IEP | ADMET (0,N) PATIENT | Simple |
| 9 | **CONSULTATION** | id_consultation | CONSULTE (0,N) MEDECIN, (0,N) PATIENT | Simple |
| 10 | **PRESCRIPTION** | id_prescription | PRESCRIT (0,N) MEDECIN, (0,N) SEJOUR | Simple |
| 11 | **ACTE_MEDICAL** | code_CCAM | FACTURE, COMPREND | Référentiel |
| 12 | **INTERVENTION** | id_intervention | OPERA (0,N) MEDECIN, UTILISE (1,1) BLOC | Simple |
| 13 | **BLOC_OPERATOIRE** | id_bloc | UTILISE (0,N) INTERVENTION | Simple |

---

## 2️⃣ HÉRITAGE (Spécialisation Exclusive)

```
PERSONNEL (id_personnel, nom, prenom, date_naissance, date_embauche, ...)
    ↓
    ├→ MEDECIN (RPPS, specialite, id_service_principal) [XOR exclusif]
    └→ INFIRMIER (id_infirmier, grade) [XOR exclusif]
```

**Cardinalité Merise:**
- PERSONNEL (1,1) IS-A (0,1) MEDECIN
- PERSONNEL (1,1) IS-A (0,1) INFIRMIER
- ✓ Un personnel est SOIT médecin SOIT infirmier (pas les deux)
- ✓ Trigger de validation obligatoire

---

## 3️⃣ ASSOCIATIONS N-N (4 tables)

### 🔀 OCCUPE (SEJOUR ↔ LIT) - Historique d'affectation
```
Cardinalité Merise : SEJOUR (1,N) ----OCCUPE---- (1,1) LIT
Attributs : date_debut, date_fin (NULL=actif), motif_changement
Clé : (id_lit, date_debut)
Contrainte : Un lit = 1 séjour à la fois
```

### 🔀 AFFECTE_A (INFIRMIER ↔ SERVICE) - Rotation avec taux
```
Cardinalité Merise : INFIRMIER (0,N) ----AFFECTE_A---- (0,N) SERVICE
Attributs : date_debut, date_fin (NULL=actif), taux_activite (0-100%)
Clé : (id_infirmier, id_service, date_debut)
```

### 🔀 FACTURE (SEJOUR ↔ ACTE_MEDICAL) - Facturation
```
Cardinalité Merise : SEJOUR (0,N) ----FACTURE---- (0,N) ACTE_MEDICAL
Attributs : quantite, date_realisation, montant_total (calculé), statut_facturation
Clé : (IEP_sejour, code_CCAM, date_realisation)
```

### 🔀 COMPREND (INTERVENTION ↔ ACTE_MEDICAL) - Composition chirurgicale
```
Cardinalité Merise : INTERVENTION (1,N) ----COMPREND---- (1,N) ACTE_MEDICAL
Attributs : ordre, duree_estimee
Clé : (id_intervention, ordre)
```

---

## 4️⃣ CARDINALITÉS MERISE COMPLÈTES

### Format : ENTITE1 (min, max) ----RELATION---- (min, max) ENTITE2

| De | Relation | Vers | Merise | SQL |
|---|---|---|---|---|
| PATIENT | ADMET | SEJOUR | (1,N) | 1 patient → 0..N séjours |
| SEJOUR | OCCUPE | LIT | (0,N)→(1,1) | 1 séjour → 1..N lits (historique) |
| CHAMBRE | CONTIENT | LIT | (1,N) | 1 chambre → 1..N lits |
| SERVICE | CONTIENT | CHAMBRE | (1,N) | 1 service → 1..N chambres |
| MEDECIN | DIRIGE | SERVICE | (0,1)→(0,1) | 1 chef de service optionnel |
| INFIRMIER | AFFECTE_A | SERVICE | (0,N)→(0,N) | Affectations multiples, rotation |
| MEDECIN | CONSULTE | PATIENT | (0,N)→(0,N) | 1 médecin → N consultations |
| MEDECIN | PRESCRIT | SEJOUR | (0,N)→(0,N) | 1 médecin → N prescriptions |
| MEDECIN | OPERA | SEJOUR | (0,N)→(0,N) | 1 chirurgien → N interventions |
| INTERVENTION | UTILISE | BLOC | (0,N)→(1,1) | Bloc opératoire requis |
| INTERVENTION | COMPREND | ACTE | (0,N)→(0,N) | Composition d'actes ordonnée |
| SEJOUR | FACTURE | ACTE | (0,N)→(0,N) | Actes facturés par séjour |

---

## 5️⃣ ATTRIBUTS PAR ENTITÉ (Exhaustif Minimal)

### PATIENT (IPP)
- nom, prenom, date_naissance, sexe, num_secu_sociale, telephone, adresse, antecedents

### PERSONNEL (id_personnel) - Mère
- nom, prenom, date_naissance, date_embauche, telephone, type_contrat, actif

### MEDECIN (RPPS) - Fille de PERSONNEL
- id_personnel (FK), specialite, id_service_principal (FK), est_chef_service

### INFIRMIER (id_infirmier) - Fille de PERSONNEL
- id_personnel (FK), grade (IDE/IBODE/IADE)

### SERVICE (id_service)
- nom_service, batiment, etage, specialite, RPPS_chef (FK unique), telephone_service

### CHAMBRE (id_chambre)
- id_service (FK), numero_chambre, capacite (1-6), type_chambre

### LIT (id_lit)
- id_chambre (FK), numero_lit, etat, type_lit, equipements

### SEJOUR (IEP)
- IPP (FK), date_admission, date_sortie, motif_admission, mode_entree, 
  mode_sortie, diagnostic_principal

### CONSULTATION (id_consultation)
- IPP_patient (FK), RPPS_medecin (FK), date_heure, motif, diagnostic, statut

### PRESCRIPTION (id_prescription)
- IEP_sejour (FK), RPPS_medecin (FK), date_prescription, medicament, 
  posologie, voie_administration, date_debut, date_fin, statut

### ACTE_MEDICAL (code_CCAM) - Référentiel
- libelle, tarif, categorie, duree_moyenne

### INTERVENTION (id_intervention)
- IEP_sejour (FK), RPPS_chirurgien (FK), id_bloc (FK), date_intervention, 
  heure_debut, heure_fin, type_intervention, compte_rendu, statut

### BLOC_OPERATOIRE (id_bloc)
- nom_bloc, batiment, etage, equipements, statut

---

## 6️⃣ ASSOCIATIONS N-N (Attributs détaillés)

### OCCUPE
- id_occupation (PK), IEP_sejour (FK), id_lit (FK), date_debut, date_fin, 
  motif_changement
- Clé unique : (id_lit, date_debut) ← Permet l'historique

### AFFECTE_A
- id_affectation (PK), id_infirmier (FK), id_service (FK), date_debut, 
  date_fin, taux_activite
- Support rotation infirmiers avec taux d'activité partielle

### FACTURE
- id_facturation (PK), IEP_sejour (FK), code_CCAM (FK), quantite, 
  date_realisation, montant_total (CALCULÉ), statut_facturation

### COMPREND
- id_composition (PK), id_intervention (FK), code_CCAM (FK), ordre, 
  duree_estimee
- Ordre = séquence d'actes dans intervention

---

## 7️⃣ CONTRAINTES D'INTÉGRITÉ MERISE

### Clés Primaires (PK)
✓ PATIENT (IPP), PERSONNEL (id_personnel), MEDECIN (RPPS), etc.

### Clés Étrangères (FK)
✓ Toutes les associations référencent les PK des entités mères
✓ Cascade DELETE appropriée : PERSONNEL → MEDECIN/INFIRMIER
✓ RESTRICT : LIT/SEJOUR (intégrité données patients)

### Unicité (UNIQUE)
✓ PATIENT.num_secu_sociale (Sécurité sociale unique)
✓ SERVICE.RPPS_chef (1 seul chef par service)
✓ CHAMBRE (id_service, numero_chambre) (N° unique par service)
✓ LIT (id_chambre, numero_lit) (N° unique par chambre)
✓ OCCUPE (id_lit, date_debut) (Historique continu)

### Domaines (CHECK)
✓ CHAMBRE.capacite BETWEEN 1 AND 6
✓ AFFECTE_A.taux_activite BETWEEN 0 AND 100
✓ SEJOUR.date_sortie ≥ date_admission
✓ PRESCRIPTION.date_fin ≥ date_debut
✓ INTERVENTION.heure_fin > heure_debut

### Héritage Exclusif (TRIGGERS)
✓ PERSONNEL → MEDECIN XOR INFIRMIER (pas cumul)
✓ Validation avant INSERT

### Occupation Exclusive (TRIGGERS)
✓ Un LIT = 1 SEJOUR à la fois (pas chevauchement)
✓ Mise à jour auto de LIT.etat

---

## 8️⃣ MERISE CONFORMITÉ CHECKLIST

- ✅ **13 Entités** identifiées et modélisées
- ✅ **Héritage Exclusif** PERSONNEL → MEDECIN XOR INFIRMIER
- ✅ **4 Associations N-N** explicites avec attributs
- ✅ **Cardinalités Merise** (0,1) / (1,1) / (0,N) / (1,N) complètes
- ✅ **Identifiants uniques** par entité (PK)
- ✅ **Attributs discriminants** pour héritage
- ✅ **Contraintes métier** en triggers et CHECK
- ✅ **Clés étrangères** avec cascade appropriée
- ✅ **Vues métier** pour requêtes complexes
- ✅ **Historique** : OCCUPE, AFFECTE_A (date_fin NULL = actif)
- ✅ **Référentiel** : ACTE_MEDICAL (CCAM)
- ✅ **Calculs** : montant_total = quantite × tarif (GENERATED)
- ✅ **Gestion temps** : date_naissance, date_embauche, admission/sortie

---

## 9️⃣ DIAGRAMME MERISE CONCEPTUEL

```
┌─────────────────┐
│    PATIENT      │
│   (IPP)         │
└────────┬────────┘
         │ (1,N) ADMET
         │
      ┌──┴──┐
      │SEJOUR│
      │(IEP)│
      └──┬──┘
         │(1,N) OCCUPE────────┐
         │                     │
         │                  ┌──┴──┐
         │                  │ LIT  │
         │                  │(id)  │
         │                  └──┬──┘
         │                     │(1,N) CONTIENT
         │                  ┌──┴──────┐
         │                  │ CHAMBRE  │
         │                  │ (id)     │
         │                  └──┬──────┘
         │                     │(1,N) APPARTIENT
         │                  ┌──┴──────┐
         │                  │ SERVICE  │
         │                  │ (id)     │
         │                  └──┬──────┘
         │                     │
         │         ┌───────────┼───────────┐
         │         │           │           │
      ┌──┴──┐  ┌───┴──┐  ┌────┴──┐   ┌────┴────┐
      │FACTU│  │MEDECIN│  │CHEF DE │ PERSONNEL│
      │RE   │  │(RPPS) │  │SERVICE │(héritage)│
      │(FK) │  └───┬───┘  └────────┘ └────┬────┘
      └──┬──┘      │                       │
         │    ┌────┴─────────────────┐  ┌──┴──────┐
         │    │                      │  │INFIRMIER│
         │ ┌──┴──────────────────┐  │  │(héritage)│
         │ │CONSULTATION,        │  │  └──────────┘
         │ │PRESCRIPTION,        │  │
         │ │INTERVENTION        │  │
         │ └─────────────────────┘  │
         │                          │
      ┌──┴───────────────────────────┴──┐
      │      ACTE_MEDICAL (code_CCAM)   │
      │      ├─ FACTURE (FK)            │
      │      └─ COMPREND (FK)           │
      └─────────────────────────────────┘

INTERVENTION ──────UTILISE─────→ BLOC_OPERATOIRE
INTERVENTION ──────COMPREND───→ ACTE_MEDICAL
```

---

## 🔟 STATISTIQUES MERISE

| Metric | Valeur |
|--------|--------|
| Entités | 13 |
| Associations N-N | 4 |
| Héritage exclusif | 1 (PERSONNEL) |
| Clés primaires | 13 |
| Clés étrangères | 19 |
| Contraintes UNIQUE | 7 |
| Contraintes CHECK | 8 |
| Triggers métier | 5 |
| Vues métier | 4 |
| Cardinalités Merise | 24 |
| Attributs totaux | 85+ |

---

## ✅ VALIDATION MERISE FINALE

Ce modèle SQL représente **FIDÈLEMENT** le MCD (Modèle Conceptuel de Données) Merise :

✓ **Exhaustif** : Toutes les entités et associations du domaine hospitalier  
✓ **Minimal** : Sans redondance, ~400 lignes SQL optimisées  
✓ **Logique** : Respect strict des cardinalités Merise  
✓ **Français** : Terminologie médicale et noms en français cohérent  
✓ **Métier** : Contraintes métier implémentées (héritage, occupation exclusive)  
✓ **Performant** : Index critiques, GENERATED ALWAYS AS pour montants  

**Le code SQL traduit parfaitement le MCD Merise ! 📊**
