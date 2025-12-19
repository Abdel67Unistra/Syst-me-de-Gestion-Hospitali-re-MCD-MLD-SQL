-- ============================================================================
-- SCRIPT SQL COMPLET - SYSTÈME DE GESTION HOSPITALIÈRE
-- CONFORME AU MCD MERISE - MODÈLE CONCEPTUEL DE DONNÉES
-- ============================================================================
-- Base de données : MySQL 8.0+
-- Langage : Français - Terminologie médicale internationale
-- 
-- 📊 STRUCTURE MERISE COMPLÈTE:
--   ✓ 13 Entités : PATIENT, PERSONNEL, MEDECIN, INFIRMIER, SERVICE, CHAMBRE, LIT,
--                 SEJOUR, CONSULTATION, PRESCRIPTION, ACTE_MEDICAL, INTERVENTION,
--                 BLOC_OPERATOIRE
--   ✓ 4 Associations N-N : OCCUPE, AFFECTE_A, FACTURE, COMPREND
--   ✓ Héritage Exclusif : PERSONNEL → MEDECIN XOR INFIRMIER
--   ✓ Contraintes Métier : Cardinalités, triggers, vérifications d'intégrité
--
-- Auteur : Projet Hospitalier - Université de Strasbourg
-- Date : 19 décembre 2025
-- ============================================================================

-- Suppression de la base si elle existe déjà
DROP DATABASE IF EXISTS hopital_db;
CREATE DATABASE hopital_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE hopital_db;

-- ============================================================================
-- SECTION 1 : CRÉATION DES TABLES PRINCIPALES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLE PATIENT
-- Gestion des patients avec IPP unique (Identifiant Permanent Patient)
-- ----------------------------------------------------------------------------
CREATE TABLE PATIENT (
    IPP VARCHAR(20) PRIMARY KEY COMMENT 'Identifiant Permanent Patient - Unique à vie',
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    date_naissance DATE NOT NULL,
    sexe ENUM('M', 'F', 'Autre') NOT NULL,
    num_secu_sociale VARCHAR(15) UNIQUE NOT NULL COMMENT 'Numéro de sécurité sociale',
    telephone VARCHAR(15),
    adresse TEXT,
    antecedents TEXT COMMENT 'Antécédents médicaux',
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_nom_prenom (nom, prenom),
    INDEX idx_date_naissance (date_naissance)
) ENGINE=InnoDB COMMENT='Table des patients avec IPP unique';

-- ----------------------------------------------------------------------------
-- TABLE PERSONNEL
-- Entité mère pour tous les types de personnel (héritage)
-- ----------------------------------------------------------------------------
CREATE TABLE PERSONNEL (
    id_personnel INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    date_naissance DATE NOT NULL,
    date_embauche DATE NOT NULL,
    telephone VARCHAR(15),
    type_contrat ENUM('CDI', 'CDD', 'Interim', 'Liberal') NOT NULL DEFAULT 'CDI',
    actif BOOLEAN DEFAULT TRUE COMMENT 'Personnel actif ou parti',
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_nom_prenom (nom, prenom),
    CHECK (date_embauche >= date_naissance + INTERVAL 18 YEAR)
) ENGINE=InnoDB COMMENT='Table mère du personnel - Héritage vers MEDECIN et INFIRMIER';

-- ----------------------------------------------------------------------------
-- TABLE BLOC_OPERATOIRE
-- Blocs opératoires disponibles dans l'hôpital
-- ----------------------------------------------------------------------------
CREATE TABLE BLOC_OPERATOIRE (
    id_bloc INT AUTO_INCREMENT PRIMARY KEY,
    nom_bloc VARCHAR(100) NOT NULL UNIQUE,
    batiment VARCHAR(50) NOT NULL,
    etage INT NOT NULL,
    equipements TEXT COMMENT 'Liste des équipements disponibles',
    statut ENUM('Disponible', 'Occupé', 'Maintenance', 'Fermé') NOT NULL DEFAULT 'Disponible',
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_statut (statut)
) ENGINE=InnoDB COMMENT='Blocs opératoires de l''hôpital';

-- ----------------------------------------------------------------------------
-- TABLE SERVICE
-- Services médicaux de l'hôpital (Cardiologie, Chirurgie, etc.)
-- Dépend de MEDECIN pour le chef de service (FK ajoutée après création MEDECIN)
-- ----------------------------------------------------------------------------
CREATE TABLE SERVICE (
    id_service INT AUTO_INCREMENT PRIMARY KEY,
    nom_service VARCHAR(100) NOT NULL UNIQUE,
    batiment VARCHAR(50) NOT NULL,
    etage INT NOT NULL,
    specialite VARCHAR(100) NOT NULL,
    RPPS_chef VARCHAR(11) NULL COMMENT 'Chef de service - FK vers MEDECIN',
    telephone_service VARCHAR(15),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_specialite (specialite)
) ENGINE=InnoDB COMMENT='Services hospitaliers avec chef de service';

-- ----------------------------------------------------------------------------
-- TABLE MEDECIN (Héritage de PERSONNEL)
-- Spécialisation : Médecins avec RPPS
-- ----------------------------------------------------------------------------
CREATE TABLE MEDECIN (
    RPPS VARCHAR(11) PRIMARY KEY COMMENT 'Répertoire Partagé des Professionnels de Santé',
    id_personnel INT NOT NULL UNIQUE COMMENT 'FK vers PERSONNEL - Héritage',
    specialite VARCHAR(100) NOT NULL,
    id_service_principal INT NULL COMMENT 'Service d''affectation principale',
    est_chef_service BOOLEAN DEFAULT FALSE,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_personnel) REFERENCES PERSONNEL(id_personnel) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_service_principal) REFERENCES SERVICE(id_service) 
        ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_specialite (specialite),
    INDEX idx_service (id_service_principal)
) ENGINE=InnoDB COMMENT='Médecins - Héritage de PERSONNEL';

-- ----------------------------------------------------------------------------
-- TABLE INFIRMIER (Héritage de PERSONNEL)
-- Spécialisation : Infirmiers avec grade
-- ----------------------------------------------------------------------------
CREATE TABLE INFIRMIER (
    id_infirmier INT AUTO_INCREMENT PRIMARY KEY,
    id_personnel INT NOT NULL UNIQUE COMMENT 'FK vers PERSONNEL - Héritage',
    grade ENUM('IDE', 'IBODE', 'IADE', 'IPDE', 'Cadre') NOT NULL COMMENT 'Infirmier Diplômé d''État, Bloc Opératoire, Anesthésie, Puéricultrice',
    diplome VARCHAR(200),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_personnel) REFERENCES PERSONNEL(id_personnel) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_grade (grade)
) ENGINE=InnoDB COMMENT='Infirmiers - Héritage de PERSONNEL';

-- ----------------------------------------------------------------------------
-- AJOUT DE LA FK RPPS_chef DANS SERVICE (contrainte circulaire)
-- ----------------------------------------------------------------------------
ALTER TABLE SERVICE 
ADD CONSTRAINT fk_service_chef 
FOREIGN KEY (RPPS_chef) REFERENCES MEDECIN(RPPS) 
ON DELETE SET NULL ON UPDATE CASCADE;

-- Contrainte : un service ne peut avoir qu'un seul chef
ALTER TABLE SERVICE 
ADD CONSTRAINT uq_chef_service UNIQUE (RPPS_chef);

-- ----------------------------------------------------------------------------
-- TABLE CHAMBRE
-- Chambres au sein des services
-- ----------------------------------------------------------------------------
CREATE TABLE CHAMBRE (
    id_chambre INT AUTO_INCREMENT PRIMARY KEY,
    id_service INT NOT NULL COMMENT 'Service auquel appartient la chambre',
    numero_chambre VARCHAR(20) NOT NULL,
    capacite_totale INT NOT NULL DEFAULT 1 CHECK (capacite_totale BETWEEN 1 AND 6),
    type_chambre ENUM('Individuelle', 'Double', 'Triple', 'Commune', 'Isolement', 'Réanimation') NOT NULL,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_service) REFERENCES SERVICE(id_service) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    UNIQUE KEY uq_chambre_service (id_service, numero_chambre),
    INDEX idx_type (type_chambre)
) ENGINE=InnoDB COMMENT='Chambres des services hospitaliers';

-- ----------------------------------------------------------------------------
-- TABLE LIT
-- Lits au sein des chambres (gestion fine au lit)
-- ----------------------------------------------------------------------------
CREATE TABLE LIT (
    id_lit INT AUTO_INCREMENT PRIMARY KEY,
    id_chambre INT NOT NULL COMMENT 'Chambre contenant ce lit',
    numero_lit VARCHAR(10) NOT NULL COMMENT 'Ex: A, B, C ou 1, 2, 3',
    etat ENUM('Disponible', 'Occupé', 'Maintenance', 'Réservé') NOT NULL DEFAULT 'Disponible',
    type_lit ENUM('Standard', 'Médicalisé', 'Bariatrique', 'Pédiatrique') NOT NULL DEFAULT 'Standard',
    equipements TEXT COMMENT 'Équipements spécifiques (monitoring, oxygène, etc.)',
    date_derniere_maintenance DATE,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_chambre) REFERENCES CHAMBRE(id_chambre) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    UNIQUE KEY uq_lit_chambre (id_chambre, numero_lit),
    INDEX idx_etat (etat),
    INDEX idx_type_lit (type_lit)
) ENGINE=InnoDB COMMENT='Lits des chambres - Unité d''affectation patient';

-- ----------------------------------------------------------------------------
-- TABLE SEJOUR
-- Séjours/Hospitalisations avec IEP unique
-- ----------------------------------------------------------------------------
CREATE TABLE SEJOUR (
    IEP VARCHAR(20) PRIMARY KEY COMMENT 'Identifiant Épisode Patient - Unique par séjour',
    IPP VARCHAR(20) NOT NULL COMMENT 'Patient concerné',
    date_admission DATETIME NOT NULL,
    date_sortie DATETIME NULL COMMENT 'NULL si séjour en cours',
    motif_admission TEXT NOT NULL,
    mode_entree ENUM('Urgence', 'Programmé', 'Mutation', 'Naissance') NOT NULL,
    mode_sortie ENUM('Domicile', 'Transfert', 'Décès', 'Fugue') NULL,
    diagnostic_principal VARCHAR(200),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (IPP) REFERENCES PATIENT(IPP) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_patient (IPP),
    INDEX idx_dates (date_admission, date_sortie),
    INDEX idx_en_cours (date_sortie),
    CHECK (date_sortie IS NULL OR date_sortie >= date_admission)
) ENGINE=InnoDB COMMENT='Séjours hospitaliers avec IEP unique';

-- ----------------------------------------------------------------------------
-- TABLE CONSULTATION
-- Consultations médicales (ambulatoires ou liées à un séjour)
-- ----------------------------------------------------------------------------
CREATE TABLE CONSULTATION (
    id_consultation INT AUTO_INCREMENT PRIMARY KEY,
    IPP_patient VARCHAR(20) NOT NULL COMMENT 'Patient consulté',
    RPPS_medecin VARCHAR(11) NOT NULL COMMENT 'Médecin consultant',
    date_heure DATETIME NOT NULL,
    motif TEXT NOT NULL,
    diagnostic TEXT,
    compte_rendu TEXT,
    statut ENUM('Programmée', 'Réalisée', 'Annulée', 'Report') NOT NULL DEFAULT 'Programmée',
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (IPP_patient) REFERENCES PATIENT(IPP) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (RPPS_medecin) REFERENCES MEDECIN(RPPS) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_patient (IPP_patient),
    INDEX idx_medecin (RPPS_medecin),
    INDEX idx_date (date_heure),
    INDEX idx_statut (statut)
) ENGINE=InnoDB COMMENT='Consultations médicales';

-- ----------------------------------------------------------------------------
-- TABLE PRESCRIPTION
-- Prescriptions médicales liées à un séjour
-- ----------------------------------------------------------------------------
CREATE TABLE PRESCRIPTION (
    id_prescription INT AUTO_INCREMENT PRIMARY KEY,
    IEP_sejour VARCHAR(20) NOT NULL COMMENT 'Séjour concerné',
    RPPS_medecin VARCHAR(11) NOT NULL COMMENT 'Médecin prescripteur',
    date_prescription DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    medicament VARCHAR(200) NOT NULL,
    posologie TEXT NOT NULL COMMENT 'Dose, fréquence, durée',
    voie_administration ENUM('Orale', 'Injectable', 'Cutanée', 'Inhalation', 'Autre') NOT NULL,
    statut ENUM('Active', 'Terminée', 'Annulée', 'Suspendue') NOT NULL DEFAULT 'Active',
    date_debut DATE NOT NULL,
    date_fin DATE NULL,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (IEP_sejour) REFERENCES SEJOUR(IEP) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (RPPS_medecin) REFERENCES MEDECIN(RPPS) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_sejour (IEP_sejour),
    INDEX idx_medecin (RPPS_medecin),
    INDEX idx_statut (statut),
    INDEX idx_dates (date_debut, date_fin),
    CHECK (date_fin IS NULL OR date_fin >= date_debut)
) ENGINE=InnoDB COMMENT='Prescriptions médicamenteuses';

-- ----------------------------------------------------------------------------
-- TABLE ACTE_MEDICAL
-- Catalogue des actes médicaux CCAM
-- ----------------------------------------------------------------------------
CREATE TABLE ACTE_MEDICAL (
    code_CCAM VARCHAR(10) PRIMARY KEY COMMENT 'Classification Commune des Actes Médicaux',
    libelle VARCHAR(300) NOT NULL,
    tarif DECIMAL(10, 2) NOT NULL CHECK (tarif >= 0),
    categorie ENUM('Consultation', 'Imagerie', 'Biologie', 'Chirurgie', 'Anesthésie', 'Rééducation', 'Autre') NOT NULL,
    duree_moyenne INT NULL COMMENT 'Durée moyenne en minutes',
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_categorie (categorie),
    INDEX idx_tarif (tarif)
) ENGINE=InnoDB COMMENT='Catalogue des actes médicaux CCAM';

-- ----------------------------------------------------------------------------
-- TABLE INTERVENTION
-- Interventions chirurgicales
-- ----------------------------------------------------------------------------
CREATE TABLE INTERVENTION (
    id_intervention INT AUTO_INCREMENT PRIMARY KEY,
    IEP_sejour VARCHAR(20) NOT NULL COMMENT 'Séjour concerné',
    RPPS_chirurgien VARCHAR(11) NOT NULL COMMENT 'Chirurgien principal',
    id_bloc INT NOT NULL COMMENT 'Bloc opératoire utilisé',
    date_intervention DATE NOT NULL,
    heure_debut TIME NOT NULL,
    heure_fin TIME NULL,
    type_intervention VARCHAR(200) NOT NULL,
    compte_rendu TEXT,
    statut ENUM('Programmée', 'En cours', 'Terminée', 'Annulée') NOT NULL DEFAULT 'Programmée',
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (IEP_sejour) REFERENCES SEJOUR(IEP) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (RPPS_chirurgien) REFERENCES MEDECIN(RPPS) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_bloc) REFERENCES BLOC_OPERATOIRE(id_bloc) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_sejour (IEP_sejour),
    INDEX idx_chirurgien (RPPS_chirurgien),
    INDEX idx_bloc (id_bloc),
    INDEX idx_date (date_intervention),
    INDEX idx_statut (statut),
    CHECK (heure_fin IS NULL OR heure_fin > heure_debut)
) ENGINE=InnoDB COMMENT='Interventions chirurgicales';

-- ============================================================================
-- SECTION 2 : TABLES D'ASSOCIATION (RELATIONS N-N)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLE OCCUPE (Association SEJOUR - LIT avec attributs)
-- Gère l'historique des affectations de lits
-- ----------------------------------------------------------------------------
CREATE TABLE OCCUPE (
    id_occupation INT AUTO_INCREMENT PRIMARY KEY,
    IEP_sejour VARCHAR(20) NOT NULL,
    id_lit INT NOT NULL,
    date_debut DATETIME NOT NULL,
    date_fin DATETIME NULL COMMENT 'NULL si occupation en cours',
    motif_changement VARCHAR(200) COMMENT 'Raison du changement de lit si applicable',
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (IEP_sejour) REFERENCES SEJOUR(IEP) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (id_lit) REFERENCES LIT(id_lit) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_sejour (IEP_sejour),
    INDEX idx_lit (id_lit),
    INDEX idx_dates (date_debut, date_fin),
    INDEX idx_en_cours (date_fin),
    CHECK (date_fin IS NULL OR date_fin >= date_debut),
    -- Un lit ne peut être occupé par 2 séjours simultanément
    CONSTRAINT uq_lit_periode UNIQUE (id_lit, date_debut)
) ENGINE=InnoDB COMMENT='Association SEJOUR-LIT avec historique';

-- ----------------------------------------------------------------------------
-- TABLE AFFECTE_A (Association INFIRMIER - SERVICE)
-- Gère les affectations des infirmiers aux services (rotation possible)
-- ----------------------------------------------------------------------------
CREATE TABLE AFFECTE_A (
    id_affectation INT AUTO_INCREMENT PRIMARY KEY,
    id_infirmier INT NOT NULL,
    id_service INT NOT NULL,
    date_debut DATE NOT NULL,
    date_fin DATE NULL COMMENT 'NULL si affectation en cours',
    taux_activite DECIMAL(5, 2) DEFAULT 100.00 COMMENT 'Pourcentage du temps (ex: 50% pour mi-temps)',
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_infirmier) REFERENCES INFIRMIER(id_infirmier) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (id_service) REFERENCES SERVICE(id_service) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_infirmier (id_infirmier),
    INDEX idx_service (id_service),
    INDEX idx_dates (date_debut, date_fin),
    INDEX idx_en_cours (date_fin),
    CHECK (date_fin IS NULL OR date_fin >= date_debut),
    CHECK (taux_activite > 0 AND taux_activite <= 100)
) ENGINE=InnoDB COMMENT='Association INFIRMIER-SERVICE avec rotation';

-- ----------------------------------------------------------------------------
-- TABLE FACTURE (Association SEJOUR - ACTE_MEDICAL)
-- Actes médicaux facturés lors d'un séjour
-- ----------------------------------------------------------------------------
CREATE TABLE FACTURE (
    id_facturation INT AUTO_INCREMENT PRIMARY KEY,
    IEP_sejour VARCHAR(20) NOT NULL,
    code_CCAM VARCHAR(10) NOT NULL,
    quantite INT NOT NULL DEFAULT 1 CHECK (quantite > 0),
    date_realisation DATETIME NOT NULL,
    montant_total DECIMAL(10, 2) AS (quantite * (SELECT tarif FROM ACTE_MEDICAL WHERE code_CCAM = FACTURE.code_CCAM)) STORED,
    statut_facturation ENUM('En attente', 'Facturée', 'Payée', 'Remboursée') NOT NULL DEFAULT 'En attente',
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (IEP_sejour) REFERENCES SEJOUR(IEP) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (code_CCAM) REFERENCES ACTE_MEDICAL(code_CCAM) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_sejour (IEP_sejour),
    INDEX idx_acte (code_CCAM),
    INDEX idx_date (date_realisation),
    INDEX idx_statut (statut_facturation)
) ENGINE=InnoDB COMMENT='Association SEJOUR-ACTE_MEDICAL - Facturation';

-- ----------------------------------------------------------------------------
-- TABLE COMPREND (Association INTERVENTION - ACTE_MEDICAL)
-- Actes composant une intervention chirurgicale
-- ----------------------------------------------------------------------------
CREATE TABLE COMPREND (
    id_composition INT AUTO_INCREMENT PRIMARY KEY,
    id_intervention INT NOT NULL,
    code_CCAM VARCHAR(10) NOT NULL,
    ordre INT NOT NULL COMMENT 'Ordre de réalisation dans l''intervention',
    duree_estimee INT NULL COMMENT 'Durée estimée en minutes pour cet acte',
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_intervention) REFERENCES INTERVENTION(id_intervention) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (code_CCAM) REFERENCES ACTE_MEDICAL(code_CCAM) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_intervention (id_intervention),
    INDEX idx_acte (code_CCAM),
    UNIQUE KEY uq_intervention_ordre (id_intervention, ordre),
    CHECK (ordre > 0),
    CHECK (duree_estimee IS NULL OR duree_estimee > 0)
) ENGINE=InnoDB COMMENT='Association INTERVENTION-ACTE_MEDICAL - Composition';

-- ============================================================================
-- SECTION 3 : CONTRAINTES MÉTIER AVANCÉES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- CONTRAINTE : Héritage exclusif PERSONNEL
-- Un personnel est SOIT médecin SOIT infirmier (pas les deux)
-- ----------------------------------------------------------------------------
DELIMITER //
CREATE TRIGGER trg_heritage_exclusif_medecin
BEFORE INSERT ON MEDECIN
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM INFIRMIER WHERE id_personnel = NEW.id_personnel) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'ERREUR: Ce personnel est déjà enregistré comme infirmier';
    END IF;
END//

CREATE TRIGGER trg_heritage_exclusif_infirmier
BEFORE INSERT ON INFIRMIER
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM MEDECIN WHERE id_personnel = NEW.id_personnel) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'ERREUR: Ce personnel est déjà enregistré comme médecin';
    END IF;
END//
DELIMITER ;

-- ----------------------------------------------------------------------------
-- CONTRAINTE : Un lit ne peut être occupé que par un séjour à la fois
-- ----------------------------------------------------------------------------
DELIMITER //
CREATE TRIGGER trg_occupation_lit_unique
BEFORE INSERT ON OCCUPE
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM OCCUPE 
        WHERE id_lit = NEW.id_lit 
        AND date_fin IS NULL
        AND id_occupation != IFNULL(NEW.id_occupation, -1)
    ) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'ERREUR: Ce lit est déjà occupé par un autre séjour';
    END IF;
END//
DELIMITER ;

-- ----------------------------------------------------------------------------
-- CONTRAINTE : Mise à jour automatique de l'état du lit
-- ----------------------------------------------------------------------------
DELIMITER //
CREATE TRIGGER trg_lit_etat_occupation_insert
AFTER INSERT ON OCCUPE
FOR EACH ROW
BEGIN
    IF NEW.date_fin IS NULL THEN
        UPDATE LIT SET etat = 'Occupé' WHERE id_lit = NEW.id_lit;
    END IF;
END//

CREATE TRIGGER trg_lit_etat_occupation_update
AFTER UPDATE ON OCCUPE
FOR EACH ROW
BEGIN
    IF NEW.date_fin IS NOT NULL AND OLD.date_fin IS NULL THEN
        UPDATE LIT SET etat = 'Disponible' WHERE id_lit = NEW.id_lit;
    END IF;
END//
DELIMITER ;

-- ----------------------------------------------------------------------------
-- CONTRAINTE : Un médecin chef de service doit être affecté à ce service
-- ----------------------------------------------------------------------------
DELIMITER //
CREATE TRIGGER trg_chef_service_affectation
BEFORE UPDATE ON SERVICE
FOR EACH ROW
BEGIN
    IF NEW.RPPS_chef IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM MEDECIN 
            WHERE RPPS = NEW.RPPS_chef 
            AND (id_service_principal = NEW.id_service OR id_service_principal IS NULL)
        ) THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'ERREUR: Le chef de service doit être affecté à ce service';
        END IF;
    END IF;
END//
DELIMITER ;

-- ============================================================================
-- SECTION 4 : VUES MÉTIER UTILES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- VUE : Lits disponibles par service
-- ----------------------------------------------------------------------------
CREATE VIEW v_lits_disponibles AS
SELECT 
    s.id_service,
    s.nom_service,
    s.specialite,
    c.id_chambre,
    c.numero_chambre,
    c.type_chambre,
    l.id_lit,
    l.numero_lit,
    l.type_lit,
    l.equipements
FROM SERVICE s
JOIN CHAMBRE c ON s.id_service = c.id_service
JOIN LIT l ON c.id_chambre = l.id_chambre
WHERE l.etat = 'Disponible';

-- ----------------------------------------------------------------------------
-- VUE : Taux d'occupation des lits par service
-- ----------------------------------------------------------------------------
CREATE VIEW v_taux_occupation_service AS
SELECT 
    s.id_service,
    s.nom_service,
    COUNT(DISTINCT l.id_lit) AS total_lits,
    COUNT(DISTINCT CASE WHEN l.etat = 'Occupé' THEN l.id_lit END) AS lits_occupes,
    ROUND(
        COUNT(DISTINCT CASE WHEN l.etat = 'Occupé' THEN l.id_lit END) * 100.0 / 
        COUNT(DISTINCT l.id_lit), 2
    ) AS taux_occupation_pct
FROM SERVICE s
JOIN CHAMBRE c ON s.id_service = c.id_service
JOIN LIT l ON c.id_chambre = l.id_chambre
GROUP BY s.id_service, s.nom_service;

-- ----------------------------------------------------------------------------
-- VUE : Séjours en cours avec informations patient et lit
-- ----------------------------------------------------------------------------
CREATE VIEW v_sejours_en_cours AS
SELECT 
    sej.IEP,
    p.IPP,
    CONCAT(p.nom, ' ', p.prenom) AS nom_patient,
    p.date_naissance,
    sej.date_admission,
    DATEDIFF(NOW(), sej.date_admission) AS duree_sejour_jours,
    sej.motif_admission,
    s.nom_service,
    c.numero_chambre,
    l.numero_lit,
    CONCAT(c.numero_chambre, '-', l.numero_lit) AS localisation
FROM SEJOUR sej
JOIN PATIENT p ON sej.IPP = p.IPP
LEFT JOIN OCCUPE o ON sej.IEP = o.IEP_sejour AND o.date_fin IS NULL
LEFT JOIN LIT l ON o.id_lit = l.id_lit
LEFT JOIN CHAMBRE c ON l.id_chambre = c.id_chambre
LEFT JOIN SERVICE s ON c.id_service = s.id_service
WHERE sej.date_sortie IS NULL;

-- ----------------------------------------------------------------------------
-- VUE : Activité des médecins (consultations et interventions)
-- ----------------------------------------------------------------------------
CREATE VIEW v_activite_medecins AS
SELECT 
    m.RPPS,
    CONCAT(p.nom, ' ', p.prenom) AS nom_medecin,
    m.specialite,
    s.nom_service AS service_principal,
    COUNT(DISTINCT c.id_consultation) AS nb_consultations,
    COUNT(DISTINCT i.id_intervention) AS nb_interventions,
    COUNT(DISTINCT pr.id_prescription) AS nb_prescriptions
FROM MEDECIN m
JOIN PERSONNEL p ON m.id_personnel = p.id_personnel
LEFT JOIN SERVICE s ON m.id_service_principal = s.id_service
LEFT JOIN CONSULTATION c ON m.RPPS = c.RPPS_medecin
LEFT JOIN INTERVENTION i ON m.RPPS = i.RPPS_chirurgien
LEFT JOIN PRESCRIPTION pr ON m.RPPS = pr.RPPS_medecin
WHERE p.actif = TRUE
GROUP BY m.RPPS, p.nom, p.prenom, m.specialite, s.nom_service;

-- ----------------------------------------------------------------------------
-- VUE : Planning des interventions
-- ----------------------------------------------------------------------------
CREATE VIEW v_planning_interventions AS
SELECT 
    i.id_intervention,
    i.date_intervention,
    i.heure_debut,
    i.heure_fin,
    i.statut,
    bo.nom_bloc,
    CONCAT(pm.nom, ' ', pm.prenom) AS chirurgien,
    m.specialite AS specialite_chirurgien,
    sej.IEP,
    CONCAT(pp.nom, ' ', pp.prenom) AS patient,
    i.type_intervention
FROM INTERVENTION i
JOIN BLOC_OPERATOIRE bo ON i.id_bloc = bo.id_bloc
JOIN MEDECIN m ON i.RPPS_chirurgien = m.RPPS
JOIN PERSONNEL pm ON m.id_personnel = pm.id_personnel
JOIN SEJOUR sej ON i.IEP_sejour = sej.IEP
JOIN PATIENT pp ON sej.IPP = pp.IPP
ORDER BY i.date_intervention DESC, i.heure_debut;

-- ----------------------------------------------------------------------------
-- VUE : Facturation par séjour
-- ----------------------------------------------------------------------------
CREATE VIEW v_facturation_sejour AS
SELECT 
    sej.IEP,
    p.IPP,
    CONCAT(p.nom, ' ', p.prenom) AS patient,
    sej.date_admission,
    sej.date_sortie,
    COUNT(DISTINCT f.id_facturation) AS nb_actes_factures,
    SUM(f.quantite) AS total_actes,
    SUM(f.montant_total) AS montant_total_euro
FROM SEJOUR sej
JOIN PATIENT p ON sej.IPP = p.IPP
LEFT JOIN FACTURE f ON sej.IEP = f.IEP_sejour
GROUP BY sej.IEP, p.IPP, p.nom, p.prenom, sej.date_admission, sej.date_sortie;

-- ============================================================================
-- SECTION 5 : INDEX DE PERFORMANCE SUPPLÉMENTAIRES
-- ============================================================================

-- Index pour recherche rapide des séjours en cours
CREATE INDEX idx_sejour_en_cours ON SEJOUR(date_sortie) 
    WHERE date_sortie IS NULL;

-- Index composite pour les consultations récentes
CREATE INDEX idx_consultation_recent ON CONSULTATION(date_heure DESC, statut);

-- Index pour les prescriptions actives
CREATE INDEX idx_prescription_active ON PRESCRIPTION(statut, date_fin) 
    WHERE statut = 'Active';

-- Index pour les interventions à venir
CREATE INDEX idx_intervention_future ON INTERVENTION(date_intervention, statut) 
    WHERE statut IN ('Programmée', 'En cours');

-- ============================================================================
-- SECTION 6 : PROCÉDURES STOCKÉES MÉTIER
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PROCÉDURE 1 : Admission d'un patient (SEJOUR + OCCUPE)
-- Paramètres : IPP, motif, mode_entrée, id_lit
-- Sortie : IEP généré automatiquement
-- ----------------------------------------------------------------------------
DELIMITER //
CREATE PROCEDURE sp_admis_patient(
    IN p_IPP VARCHAR(20),
    IN p_motif TEXT,
    IN p_mode_entree VARCHAR(20),
    IN p_id_lit INT,
    OUT p_IEP VARCHAR(20),
    OUT p_message VARCHAR(500)
)
BEGIN
    DECLARE v_lit_etat VARCHAR(20);
    DECLARE v_lit_occupe INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 
            p_message = MESSAGE_TEXT;
    END;
    
    -- Vérifier que le patient existe
    IF NOT EXISTS (SELECT 1 FROM PATIENT WHERE IPP = p_IPP) THEN
        SET p_message = 'ERREUR: Patient non trouvé';
        LEAVE sp_admis_patient;
    END IF;
    
    -- Vérifier l'état du lit
    SELECT etat INTO v_lit_etat FROM LIT WHERE id_lit = p_id_lit;
    IF v_lit_etat != 'Disponible' THEN
        SET p_message = CONCAT('ERREUR: Le lit n''est pas disponible (état: ', v_lit_etat, ')');
        LEAVE sp_admis_patient;
    END IF;
    
    -- Générer l'IEP (IPP + Date + Séquence)
    SET p_IEP = CONCAT(p_IPP, '-', DATE_FORMAT(NOW(), '%Y%m%d'), '-', 
                       LPAD(IFNULL((SELECT MAX(CAST(SUBSTRING(IEP, -4) AS UNSIGNED)) 
                                   FROM SEJOUR WHERE IPP = p_IPP 
                                   AND DATE(date_admission) = CURDATE()), 0) + 1, 4, '0'));
    
    -- Créer le séjour
    INSERT INTO SEJOUR (IEP, IPP, date_admission, motif_admission, mode_entree, diagnostic_principal)
    VALUES (p_IEP, p_IPP, NOW(), p_motif, p_mode_entree, p_motif);
    
    -- Attribuer le lit (créer l'occupation)
    INSERT INTO OCCUPE (IEP_sejour, id_lit, date_debut, date_fin)
    VALUES (p_IEP, p_id_lit, NOW(), NULL);
    
    SET p_message = CONCAT('SUCCESS: Patient admis avec IEP=', p_IEP);
END//
DELIMITER ;

-- ----------------------------------------------------------------------------
-- PROCÉDURE 2 : Sortie d'un patient (Clôture du SEJOUR)
-- Paramètres : IEP, mode_sortie, diagnostic
-- Sortie : Message de confirmation
-- ----------------------------------------------------------------------------
DELIMITER //
CREATE PROCEDURE sp_sortie_patient(
    IN p_IEP VARCHAR(20),
    IN p_mode_sortie VARCHAR(20),
    IN p_diagnostic_final VARCHAR(200),
    OUT p_message VARCHAR(500)
)
BEGIN
    DECLARE v_date_sortie DATETIME;
    DECLARE v_occupation_id INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 
            p_message = MESSAGE_TEXT;
    END;
    
    -- Vérifier l'existence du séjour en cours
    IF NOT EXISTS (SELECT 1 FROM SEJOUR WHERE IEP = p_IEP AND date_sortie IS NULL) THEN
        SET p_message = 'ERREUR: Séjour non trouvé ou déjà clôturé';
        LEAVE sp_sortie_patient;
    END IF;
    
    -- Mettre à jour le séjour
    UPDATE SEJOUR 
    SET date_sortie = NOW(),
        mode_sortie = p_mode_sortie,
        diagnostic_principal = IFNULL(p_diagnostic_final, diagnostic_principal)
    WHERE IEP = p_IEP;
    
    -- Fermer l'occupation du lit
    UPDATE OCCUPE
    SET date_fin = NOW()
    WHERE IEP_sejour = p_IEP AND date_fin IS NULL;
    
    SET p_message = CONCAT('SUCCESS: Patient ', p_IEP, ' déchargé - Mode: ', p_mode_sortie);
END//
DELIMITER ;

-- ----------------------------------------------------------------------------
-- PROCÉDURE 3 : Changer un patient de lit
-- Paramètres : IEP, ancien_lit_id, nouveau_lit_id, motif
-- Sortie : Message de confirmation
-- ----------------------------------------------------------------------------
DELIMITER //
CREATE PROCEDURE sp_changer_lit_patient(
    IN p_IEP VARCHAR(20),
    IN p_ancien_lit INT,
    IN p_nouveau_lit INT,
    IN p_motif VARCHAR(200),
    OUT p_message VARCHAR(500)
)
BEGIN
    DECLARE v_nouveau_etat VARCHAR(20);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 
            p_message = MESSAGE_TEXT;
    END;
    
    -- Vérifier le nouveau lit
    SELECT etat INTO v_nouveau_etat FROM LIT WHERE id_lit = p_nouveau_lit;
    IF v_nouveau_etat != 'Disponible' THEN
        SET p_message = CONCAT('ERREUR: Nouveau lit non disponible (état: ', v_nouveau_etat, ')');
        LEAVE sp_changer_lit_patient;
    END IF;
    
    -- Fermer l'ancienne occupation
    UPDATE OCCUPE
    SET date_fin = NOW(),
        motif_changement = p_motif
    WHERE IEP_sejour = p_IEP AND id_lit = p_ancien_lit AND date_fin IS NULL;
    
    -- Créer la nouvelle occupation
    INSERT INTO OCCUPE (IEP_sejour, id_lit, date_debut, motif_changement)
    VALUES (p_IEP, p_nouveau_lit, NOW(), CONCAT('Changement de lit: ', p_motif));
    
    SET p_message = CONCAT('SUCCESS: Patient changé de lit (motif: ', p_motif, ')');
END//
DELIMITER ;

-- ----------------------------------------------------------------------------
-- PROCÉDURE 4 : Prescrire un médicament pour un séjour
-- Paramètres : IEP, RPPS_medecin, medicament, posologie, voie, dates
-- Sortie : ID prescription
-- ----------------------------------------------------------------------------
DELIMITER //
CREATE PROCEDURE sp_prescrire_medicament(
    IN p_IEP VARCHAR(20),
    IN p_RPPS VARCHAR(11),
    IN p_medicament VARCHAR(200),
    IN p_posologie TEXT,
    IN p_voie VARCHAR(20),
    IN p_date_debut DATE,
    IN p_date_fin DATE,
    OUT p_id_prescription INT,
    OUT p_message VARCHAR(500)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 
            p_message = MESSAGE_TEXT;
    END;
    
    -- Vérifier le séjour et le médecin
    IF NOT EXISTS (SELECT 1 FROM SEJOUR WHERE IEP = p_IEP) THEN
        SET p_message = 'ERREUR: Séjour non trouvé';
        LEAVE sp_prescrire_medicament;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM MEDECIN WHERE RPPS = p_RPPS) THEN
        SET p_message = 'ERREUR: Médecin non trouvé';
        LEAVE sp_prescrire_medicament;
    END IF;
    
    -- Insérer la prescription
    INSERT INTO PRESCRIPTION 
    (IEP_sejour, RPPS_medecin, medicament, posologie, voie_administration, date_debut, date_fin)
    VALUES (p_IEP, p_RPPS, p_medicament, p_posologie, p_voie, p_date_debut, p_date_fin);
    
    SET p_id_prescription = LAST_INSERT_ID();
    SET p_message = CONCAT('SUCCESS: Prescription créée (ID=', p_id_prescription, ')');
END//
DELIMITER ;

-- ----------------------------------------------------------------------------
-- PROCÉDURE 5 : Programmer une intervention chirurgicale
-- Paramètres : IEP, RPPS_chirurgien, id_bloc, date, heure_debut, type
-- Sortie : ID intervention
-- ----------------------------------------------------------------------------
DELIMITER //
CREATE PROCEDURE sp_programmer_intervention(
    IN p_IEP VARCHAR(20),
    IN p_RPPS_chirurgien VARCHAR(11),
    IN p_id_bloc INT,
    IN p_date_intervention DATE,
    IN p_heure_debut TIME,
    IN p_type_intervention VARCHAR(200),
    OUT p_id_intervention INT,
    OUT p_message VARCHAR(500)
)
BEGIN
    DECLARE v_bloc_statut VARCHAR(20);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 
            p_message = MESSAGE_TEXT;
    END;
    
    -- Vérifications préalables
    IF NOT EXISTS (SELECT 1 FROM SEJOUR WHERE IEP = p_IEP) THEN
        SET p_message = 'ERREUR: Séjour non trouvé';
        LEAVE sp_programmer_intervention;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM MEDECIN WHERE RPPS = p_RPPS_chirurgien) THEN
        SET p_message = 'ERREUR: Chirurgien non trouvé';
        LEAVE sp_programmer_intervention;
    END IF;
    
    SELECT statut INTO v_bloc_statut FROM BLOC_OPERATOIRE WHERE id_bloc = p_id_bloc;
    IF v_bloc_statut NOT IN ('Disponible', 'Occupé') THEN
        SET p_message = CONCAT('ERREUR: Bloc opératoire non disponible (statut: ', v_bloc_statut, ')');
        LEAVE sp_programmer_intervention;
    END IF;
    
    -- Créer l'intervention
    INSERT INTO INTERVENTION 
    (IEP_sejour, RPPS_chirurgien, id_bloc, date_intervention, heure_debut, type_intervention, statut)
    VALUES (p_IEP, p_RPPS_chirurgien, p_id_bloc, p_date_intervention, p_heure_debut, 
            p_type_intervention, 'Programmée');
    
    SET p_id_intervention = LAST_INSERT_ID();
    SET p_message = CONCAT('SUCCESS: Intervention programmée (ID=', p_id_intervention, ')');
END//
DELIMITER ;

-- ----------------------------------------------------------------------------
-- PROCÉDURE 6 : Facturer un acte médical pour un séjour
-- Paramètres : IEP, code_CCAM, quantité
-- Sortie : Montant total
-- ----------------------------------------------------------------------------
DELIMITER //
CREATE PROCEDURE sp_facturer_acte(
    IN p_IEP VARCHAR(20),
    IN p_code_CCAM VARCHAR(10),
    IN p_quantite INT,
    OUT p_montant_total DECIMAL(10, 2),
    OUT p_message VARCHAR(500)
)
BEGIN
    DECLARE v_tarif DECIMAL(10, 2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 
            p_message = MESSAGE_TEXT;
    END;
    
    -- Vérifier l'existence de l'acte
    SELECT tarif INTO v_tarif FROM ACTE_MEDICAL WHERE code_CCAM = p_code_CCAM;
    IF v_tarif IS NULL THEN
        SET p_message = 'ERREUR: Acte médical non trouvé';
        LEAVE sp_facturer_acte;
    END IF;
    
    -- Insérer la facturation
    INSERT INTO FACTURE (IEP_sejour, code_CCAM, quantite, date_realisation)
    VALUES (p_IEP, p_code_CCAM, p_quantite, NOW());
    
    SET p_montant_total = v_tarif * p_quantite;
    SET p_message = CONCAT('SUCCESS: Acte facturé - Montant: ', p_montant_total, '€');
END//
DELIMITER ;

-- ============================================================================
-- SECTION 7 : DONNÉES DE TEST
-- ============================================================================

-- Insertion de patients de test
INSERT INTO PATIENT VALUES
('PAT001', 'Dupont', 'Jean', '1975-03-15', 'M', '1750315123456', '0612345678', 
 '123 Rue de Paris, 67000 Strasbourg', 'Hypertension, Diabète', NOW(), NOW()),
('PAT002', 'Martin', 'Marie', '1982-07-22', 'F', '1820722789012', '0623456789',
 '456 Avenue Louise, 67000 Strasbourg', 'Asthme', NOW(), NOW()),
('PAT003', 'Bernard', 'Pierre', '1968-11-08', 'M', '1681108234567', '0634567890',
 '789 Boulevard de Rennes, 67000 Strasbourg', 'Obésité', NOW(), NOW()),
('PAT004', 'Durand', 'Sophie', '1990-05-12', 'F', '1900512890123', '0645678901',
 '321 Chemin Vert, 67000 Strasbourg', 'Aucun antécédent notable', NOW(), NOW()),
('PAT005', 'Moreau', 'Luc', '1955-09-30', 'M', '1550930345678', '0656789012',
 '654 Rue du Commerce, 67000 Strasbourg', 'Cancer antérieur traité', NOW(), NOW());

-- Insertion de personnel
INSERT INTO PERSONNEL (nom, prenom, date_naissance, date_embauche, telephone, type_contrat, actif)
VALUES
('Leclerc', 'Henri', '1970-01-10', '2015-09-01', '0601020304', 'CDI', TRUE),
('Chevalier', 'Isabelle', '1972-02-20', '2016-03-15', '0602030405', 'CDI', TRUE),
('Fontaine', 'Marc', '1968-03-30', '2014-06-01', '0603040506', 'CDI', TRUE),
('Gauthier', 'Anne', '1985-04-15', '2018-01-10', '0604050607', 'CDI', TRUE),
('Renault', 'Laurent', '1962-05-25', '2005-09-01', '0605060708', 'CDI', TRUE),
('Duval', 'Florence', '1988-06-10', '2019-02-01', '0606070809', 'CDD', TRUE),
('Mercier', 'Jean-Paul', '1975-07-12', '2012-05-15', '0607080910', 'CDI', TRUE),
('Olivier', 'Catherine', '1990-08-20', '2020-01-15', '0608091011', 'CDI', TRUE);

-- Insertion des médecins
INSERT INTO MEDECIN (RPPS, id_personnel, specialite, est_chef_service)
VALUES
('12345678901', 1, 'Cardiologie', FALSE),
('12345678902', 2, 'Chirurgie Générale', FALSE),
('12345678903', 3, 'Neurologie', FALSE),
('12345678904', 4, 'Anesthésie-Réanimation', FALSE),
('12345678905', 5, 'Pneumologie', FALSE);

-- Insertion des infirmiers
INSERT INTO INFIRMIER (id_personnel, grade, diplome)
VALUES
(6, 'IDE', 'Diplôme d''État 2018'),
(7, 'IBODE', 'Spécialisation Bloc Opératoire 2010'),
(8, 'IDE', 'Diplôme d''État 2020');

-- Insertion des blocs opératoires
INSERT INTO BLOC_OPERATOIRE (nom_bloc, batiment, etage, equipements, statut)
VALUES
('Bloc 1 - Chirurgie', 'Bâtiment A', 3, 'Lampe opératoire, Monitoring, Table électrique', 'Disponible'),
('Bloc 2 - Chirurgie', 'Bâtiment A', 3, 'Lampe opératoire, Monitoring, Table électrique', 'Disponible'),
('Bloc 3 - Cardiologie', 'Bâtiment B', 2, 'Bistouri électrique, Défibrillateur, Monitoring continu', 'Disponible');

-- Insertion des services
INSERT INTO SERVICE (nom_service, batiment, etage, specialite, telephone_service)
VALUES
('Service de Cardiologie', 'Bâtiment B', 2, 'Cardiologie', '0389123451'),
('Service de Chirurgie Générale', 'Bâtiment A', 3, 'Chirurgie', '0389123452'),
('Service de Réanimation', 'Bâtiment C', 4, 'Réanimation', '0389123453'),
('Service de Neurologie', 'Bâtiment A', 2, 'Neurologie', '0389123454'),
('Service de Pneumologie', 'Bâtiment B', 3, 'Pneumologie', '0389123455');

-- Mise à jour des services avec les chefs
UPDATE SERVICE SET RPPS_chef = '12345678901' WHERE id_service = 1;
UPDATE SERVICE SET RPPS_chef = '12345678902' WHERE id_service = 2;
UPDATE SERVICE SET RPPS_chef = '12345678905' WHERE id_service = 5;

-- Mise à jour des affectations principales des médecins
UPDATE MEDECIN SET id_service_principal = 1 WHERE RPPS = '12345678901';
UPDATE MEDECIN SET id_service_principal = 2 WHERE RPPS = '12345678902';
UPDATE MEDECIN SET id_service_principal = 4 WHERE RPPS = '12345678904';
UPDATE MEDECIN SET id_service_principal = 4 WHERE RPPS = '12345678903';
UPDATE MEDECIN SET id_service_principal = 5 WHERE RPPS = '12345678905';

-- Insertion des chambres
INSERT INTO CHAMBRE (id_service, numero_chambre, capacite_totale, type_chambre)
VALUES
(1, '101', 1, 'Individuelle'),
(1, '102', 2, 'Double'),
(2, '201', 1, 'Individuelle'),
(2, '202', 3, 'Triple'),
(3, '301', 1, 'Réanimation'),
(3, '302', 1, 'Réanimation'),
(4, '101', 1, 'Individuelle'),
(5, '101', 2, 'Double');

-- Insertion des lits
INSERT INTO LIT (id_chambre, numero_lit, etat, type_lit, equipements)
VALUES
(1, 'A', 'Disponible', 'Médicalisé', 'Monitoring, Oxygène'),
(1, 'B', 'Disponible', 'Standard', NULL),
(2, 'A', 'Disponible', 'Standard', NULL),
(2, 'B', 'Disponible', 'Standard', NULL),
(3, 'A', 'Disponible', 'Médicalisé', 'Monitoring complet'),
(4, 'A', 'Disponible', 'Standard', NULL),
(4, 'B', 'Disponible', 'Standard', NULL),
(5, 'A', 'Disponible', 'Médicalisé', 'Monitoring réanimation, Ventilation'),
(6, 'A', 'Disponible', 'Médicalisé', 'Monitoring réanimation, Ventilation');

-- Insertion des actes médicaux (catalogue CCAM)
INSERT INTO ACTE_MEDICAL (code_CCAM, libelle, tarif, categorie, duree_moyenne)
VALUES
('CONS001', 'Consultation simple', 25.00, 'Consultation', 15),
('CONS002', 'Consultation cardiologie', 50.00, 'Consultation', 30),
('IMG001', 'ECG', 20.00, 'Imagerie', 15),
('IMG002', 'Radiographie thorax', 35.00, 'Imagerie', 10),
('BIO001', 'Prise de sang', 10.00, 'Biologie', 5),
('BIO002', 'Analyse sanguine complète', 45.00, 'Biologie', 0),
('CHI001', 'Chirurgie - Appendicectomie', 1500.00, 'Chirurgie', 90),
('CHI002', 'Chirurgie - Pontage coronarien', 5000.00, 'Chirurgie', 240),
('ANE001', 'Anesthésie générale', 400.00, 'Anesthésie', 0),
('REE001', 'Séance de rééducation', 60.00, 'Rééducation', 45);

-- Insertion des affectations infirmiers-services
INSERT INTO AFFECTE_A (id_infirmier, id_service, date_debut, date_fin, taux_activite)
VALUES
(1, 1, '2024-01-01', NULL, 100.00),
(2, 2, '2024-01-01', NULL, 100.00),
(3, 3, '2024-06-01', NULL, 80.00);

-- Insertion de séjours de test
INSERT INTO SEJOUR (IEP, IPP, date_admission, date_sortie, motif_admission, mode_entree, mode_sortie, diagnostic_principal)
VALUES
('PAT001-20251219-0001', 'PAT001', '2025-12-15 10:30:00', NULL, 'Douleur thoracique et dyspnée', 'Urgence', NULL, 'Infarctus du myocarde antérieur'),
('PAT002-20251218-0001', 'PAT002', '2025-12-10 14:00:00', '2025-12-17 11:00:00', 'Crise asthmatique sévère', 'Urgence', 'Domicile', 'Asthme sévère déclenché'),
('PAT003-20251216-0001', 'PAT003', '2025-12-16 09:00:00', NULL, 'Syndrome occlusif', 'Programmé', NULL, 'Suspicion hernie hiatale'),
('PAT004-20251201-0001', 'PAT004', '2025-12-01 07:30:00', NULL, 'Dépistage et bilan de santé', 'Programmé', NULL, 'Bilan de santé systématique');

-- Insertion des occupations de lits
INSERT INTO OCCUPE (IEP_sejour, id_lit, date_debut, date_fin, motif_changement)
VALUES
('PAT001-20251219-0001', 1, '2025-12-15 10:30:00', NULL, NULL),
('PAT002-20251218-0001', 3, '2025-12-10 14:00:00', '2025-12-17 11:00:00', NULL),
('PAT003-20251216-0001', 6, '2025-12-16 09:00:00', NULL, NULL),
('PAT004-20251201-0001', 9, '2025-12-01 07:30:00', NULL, NULL);

-- Insertion de consultations
INSERT INTO CONSULTATION (IPP_patient, RPPS_medecin, date_heure, motif, diagnostic, compte_rendu, statut)
VALUES
('PAT001', '12345678901', '2025-12-15 11:00:00', 'Douleur thoracique', 'Infarctus du myocarde', 'Patient stable, admission recommandée', 'Réalisée'),
('PAT002', '12345678905', '2025-12-10 15:00:00', 'Asthme sévère', 'Crise asthmatique', 'Traitement initié, suivi en hospitalisation', 'Réalisée'),
('PAT004', '12345678901', '2025-12-01 08:00:00', 'Bilan cardiovasculaire', 'Pas d''anomalies détectées', 'Suivi recommandé annuellement', 'Réalisée');

-- Insertion de prescriptions
INSERT INTO PRESCRIPTION (IEP_sejour, RPPS_medecin, medicament, posologie, voie_administration, statut, date_debut, date_fin)
VALUES
('PAT001-20251219-0001', '12345678901', 'Aspirine', '500mg deux fois par jour', 'Orale', 'Active', '2025-12-15', NULL),
('PAT001-20251219-0001', '12345678901', 'Atorvastatine', '40mg une fois le soir', 'Orale', 'Active', '2025-12-15', NULL),
('PAT002-20251218-0001', '12345678905', 'Salbutamol', '2 inhalations toutes les 4 heures', 'Inhalation', 'Terminée', '2025-12-10', '2025-12-17'),
('PAT003-20251216-0001', '12345678902', 'Oméprazole', '20mg une fois le matin', 'Orale', 'Active', '2025-12-16', NULL);

-- Insertion d'interventions programmées
INSERT INTO INTERVENTION (IEP_sejour, RPPS_chirurgien, id_bloc, date_intervention, heure_debut, heure_fin, type_intervention, statut)
VALUES
('PAT003-20251216-0001', '12345678902', 1, '2025-12-20', '09:00:00', NULL, 'Traitement endoscopique', 'Programmée');

-- Insertion de facturations
INSERT INTO FACTURE (IEP_sejour, code_CCAM, quantite, date_realisation, statut_facturation)
VALUES
('PAT001-20251219-0001', 'CONS002', 1, '2025-12-15 11:00:00', 'Facturée'),
('PAT001-20251219-0001', 'IMG001', 1, '2025-12-15 15:30:00', 'Facturée'),
('PAT001-20251219-0001', 'BIO002', 1, '2025-12-15 12:00:00', 'Facturée'),
('PAT002-20251218-0001', 'CONS001', 1, '2025-12-10 15:00:00', 'Facturée'),
('PAT004-20251201-0001', 'CONS002', 1, '2025-12-01 08:00:00', 'Payée');

-- ============================================================================
-- SECTION 8 : REQUÊTES DE VÉRIFICATION UTILES
-- ============================================================================

-- Requête 1 : Vérifier les séjours en cours
-- SELECT * FROM v_sejours_en_cours;

-- Requête 2 : Taux d'occupation par service
-- SELECT * FROM v_taux_occupation_service;

-- Requête 3 : Lits disponibles
-- SELECT * FROM v_lits_disponibles;

-- Requête 4 : Activité des médecins
-- SELECT * FROM v_activite_medecins;

-- Requête 5 : Facturation par séjour
-- SELECT * FROM v_facturation_sejour WHERE montant_total_euro > 0;

-- Requête 6 : Planning des interventions
-- SELECT * FROM v_planning_interventions WHERE statut IN ('Programmée', 'En cours');

-- ============================================================================
-- FIN DU SCRIPT
-- ============================================================================