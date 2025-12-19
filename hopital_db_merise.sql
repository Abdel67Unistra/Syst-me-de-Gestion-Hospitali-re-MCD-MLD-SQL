-- ============================================================================
-- Base de données hospitalière - TP Modélisation MERISE
-- Cheriet Abdelmalek - M1 Statistique - Décembre 2025
-- ============================================================================
--
-- Entités (13) : PATIENT, PERSONNEL, MEDECIN, INFIRMIER, SERVICE, CHAMBRE, 
--                LIT, SEJOUR, CONSULTATION, PRESCRIPTION, ACTE_MEDICAL, 
--                INTERVENTION, BLOC_OPERATOIRE
--
-- Associations N-N (4) : OCCUPE, AFFECTE_A, FACTURE, COMPREND
--
-- Héritage exclusif : PERSONNEL -> MEDECIN ou INFIRMIER
-- ============================================================================

DROP DATABASE IF EXISTS hopital_db;
CREATE DATABASE hopital_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE hopital_db;

-- Tables principales (entités)

CREATE TABLE PATIENT (
    IPP VARCHAR(20) PRIMARY KEY COMMENT 'Identifiant Permanent Patient',
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    date_naissance DATE NOT NULL,
    sexe ENUM('M', 'F') NOT NULL,
    num_secu VARCHAR(15) UNIQUE NOT NULL,
    telephone VARCHAR(15),
    adresse TEXT,
    antecedents TEXT,
    INDEX idx_nom_prenom (nom, prenom)
) ENGINE=InnoDB COMMENT='Patients hospitalisés';

CREATE TABLE PERSONNEL (
    id_personnel INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    date_naissance DATE NOT NULL,
    date_embauche DATE NOT NULL,
    telephone VARCHAR(15),
    type_contrat ENUM('CDI', 'CDD', 'Interim') DEFAULT 'CDI',
    actif BOOLEAN DEFAULT TRUE,
    INDEX idx_nom (nom)
) ENGINE=InnoDB COMMENT='Personnel hospitalier - Entité mère (héritage)';

CREATE TABLE MEDECIN (
    RPPS VARCHAR(11) PRIMARY KEY COMMENT 'Répertoire Partagé Professionnels Santé',
    id_personnel INT NOT NULL UNIQUE,
    specialite VARCHAR(100) NOT NULL,
    id_service_principal INT NULL,
    FOREIGN KEY (id_personnel) REFERENCES PERSONNEL(id_personnel) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Médecins - Héritage PERSONNEL';

CREATE TABLE INFIRMIER (
    id_infirmier INT AUTO_INCREMENT PRIMARY KEY,
    id_personnel INT NOT NULL UNIQUE,
    grade ENUM('IDE', 'IBODE', 'IADE') NOT NULL,
    diplome VARCHAR(100),
    FOREIGN KEY (id_personnel) REFERENCES PERSONNEL(id_personnel) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Infirmiers - Héritage PERSONNEL';

CREATE TABLE BLOC_OPERATOIRE (
    id_bloc INT AUTO_INCREMENT PRIMARY KEY,
    nom_bloc VARCHAR(100) NOT NULL UNIQUE,
    batiment VARCHAR(50) NOT NULL,
    etage INT NOT NULL,
    equipements TEXT,
    statut ENUM('Disponible', 'Occupé', 'Maintenance') DEFAULT 'Disponible'
) ENGINE=InnoDB COMMENT='Blocs opératoires';

CREATE TABLE SERVICE (
    id_service INT AUTO_INCREMENT PRIMARY KEY,
    nom_service VARCHAR(100) NOT NULL UNIQUE,
    batiment VARCHAR(50) NOT NULL,
    etage INT NOT NULL,
    specialite VARCHAR(100) NOT NULL,
    RPPS_chef VARCHAR(11) NULL UNIQUE,
    telephone_service VARCHAR(15),
    FOREIGN KEY (RPPS_chef) REFERENCES MEDECIN(RPPS) ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='Services hospitaliers';

CREATE TABLE CHAMBRE (
    id_chambre INT AUTO_INCREMENT PRIMARY KEY,
    id_service INT NOT NULL,
    numero_chambre VARCHAR(20) NOT NULL,
    capacite INT NOT NULL CHECK (capacite BETWEEN 1 AND 6),
    type_chambre ENUM('Individuelle', 'Double', 'Isolement', 'Réanimation') NOT NULL,
    FOREIGN KEY (id_service) REFERENCES SERVICE(id_service) ON DELETE RESTRICT,
    UNIQUE (id_service, numero_chambre)
) ENGINE=InnoDB COMMENT='Chambres des services';

CREATE TABLE LIT (
    id_lit INT AUTO_INCREMENT PRIMARY KEY,
    id_chambre INT NOT NULL,
    numero_lit VARCHAR(10) NOT NULL,
    etat ENUM('Disponible', 'Occupé', 'Maintenance', 'Réservé') DEFAULT 'Disponible',
    type_lit ENUM('Standard', 'Médicalisé', 'Bariatrique') DEFAULT 'Standard',
    equipements TEXT,
    FOREIGN KEY (id_chambre) REFERENCES CHAMBRE(id_chambre) ON DELETE RESTRICT,
    UNIQUE (id_chambre, numero_lit),
    INDEX idx_etat (etat)
) ENGINE=InnoDB COMMENT='Lits des chambres';

CREATE TABLE SEJOUR (
    IEP VARCHAR(20) PRIMARY KEY COMMENT 'Identifiant Épisode Patient',
    IPP VARCHAR(20) NOT NULL,
    date_admission DATETIME NOT NULL,
    date_sortie DATETIME NULL,
    motif_admission TEXT NOT NULL,
    mode_entree ENUM('Urgence', 'Programmé', 'Mutation') NOT NULL,
    mode_sortie ENUM('Domicile', 'Transfert', 'Décès') NULL,
    diagnostic_principal VARCHAR(200),
    FOREIGN KEY (IPP) REFERENCES PATIENT(IPP) ON DELETE RESTRICT,
    INDEX idx_patient (IPP),
    INDEX idx_dates (date_admission, date_sortie),
    CHECK (date_sortie IS NULL OR date_sortie >= date_admission)
) ENGINE=InnoDB COMMENT='Séjours hospitaliers';

CREATE TABLE CONSULTATION (
    id_consultation INT AUTO_INCREMENT PRIMARY KEY,
    IPP_patient VARCHAR(20) NOT NULL,
    RPPS_medecin VARCHAR(11) NOT NULL,
    date_heure DATETIME NOT NULL,
    motif TEXT NOT NULL,
    diagnostic TEXT,
    statut ENUM('Programmée', 'Réalisée', 'Annulée') DEFAULT 'Programmée',
    FOREIGN KEY (IPP_patient) REFERENCES PATIENT(IPP) ON DELETE RESTRICT,
    FOREIGN KEY (RPPS_medecin) REFERENCES MEDECIN(RPPS) ON DELETE RESTRICT,
    INDEX idx_medecin (RPPS_medecin)
) ENGINE=InnoDB COMMENT='Consultations médicales';

CREATE TABLE PRESCRIPTION (
    id_prescription INT AUTO_INCREMENT PRIMARY KEY,
    IEP_sejour VARCHAR(20) NOT NULL,
    RPPS_medecin VARCHAR(11) NOT NULL,
    date_prescription DATETIME DEFAULT CURRENT_TIMESTAMP,
    medicament VARCHAR(200) NOT NULL,
    posologie TEXT NOT NULL,
    voie_administration ENUM('Orale', 'Injectable', 'Inhalation') NOT NULL,
    date_debut DATE NOT NULL,
    date_fin DATE NULL,
    statut ENUM('Active', 'Terminée', 'Annulée') DEFAULT 'Active',
    FOREIGN KEY (IEP_sejour) REFERENCES SEJOUR(IEP) ON DELETE RESTRICT,
    FOREIGN KEY (RPPS_medecin) REFERENCES MEDECIN(RPPS) ON DELETE RESTRICT,
    CHECK (date_fin IS NULL OR date_fin >= date_debut)
) ENGINE=InnoDB COMMENT='Prescriptions médicamenteuses';

CREATE TABLE ACTE_MEDICAL (
    code_CCAM VARCHAR(10) PRIMARY KEY COMMENT 'Classification Commune des Actes Médicaux',
    libelle VARCHAR(300) NOT NULL,
    tarif DECIMAL(10, 2) NOT NULL CHECK (tarif >= 0),
    categorie ENUM('Consultation', 'Imagerie', 'Biologie', 'Chirurgie', 'Anesthésie') NOT NULL,
    duree_moyenne INT COMMENT 'Durée en minutes'
) ENGINE=InnoDB COMMENT='Catalogue des actes CCAM';

CREATE TABLE INTERVENTION (
    id_intervention INT AUTO_INCREMENT PRIMARY KEY,
    IEP_sejour VARCHAR(20) NOT NULL,
    RPPS_chirurgien VARCHAR(11) NOT NULL,
    id_bloc INT NOT NULL,
    date_intervention DATE NOT NULL,
    heure_debut TIME NOT NULL,
    heure_fin TIME NULL,
    type_intervention VARCHAR(200) NOT NULL,
    compte_rendu TEXT,
    statut ENUM('Programmée', 'En cours', 'Terminée', 'Annulée') DEFAULT 'Programmée',
    FOREIGN KEY (IEP_sejour) REFERENCES SEJOUR(IEP) ON DELETE RESTRICT,
    FOREIGN KEY (RPPS_chirurgien) REFERENCES MEDECIN(RPPS) ON DELETE RESTRICT,
    FOREIGN KEY (id_bloc) REFERENCES BLOC_OPERATOIRE(id_bloc) ON DELETE RESTRICT,
    INDEX idx_date (date_intervention),
    CHECK (heure_fin IS NULL OR heure_fin > heure_debut)
) ENGINE=InnoDB COMMENT='Interventions chirurgicales';

-- Tables d'association (N-N)

CREATE TABLE OCCUPE (
    id_occupation INT AUTO_INCREMENT PRIMARY KEY,
    IEP_sejour VARCHAR(20) NOT NULL,
    id_lit INT NOT NULL,
    date_debut DATETIME NOT NULL,
    date_fin DATETIME NULL,
    motif_changement VARCHAR(200),
    FOREIGN KEY (IEP_sejour) REFERENCES SEJOUR(IEP) ON DELETE RESTRICT,
    FOREIGN KEY (id_lit) REFERENCES LIT(id_lit) ON DELETE RESTRICT,
    INDEX idx_sejour (IEP_sejour),
    INDEX idx_lit (id_lit),
    CHECK (date_fin IS NULL OR date_fin >= date_debut),
    UNIQUE (id_lit, date_debut)
) ENGINE=InnoDB COMMENT='Association SEJOUR-LIT (historique affectations)';

CREATE TABLE AFFECTE_A (
    id_affectation INT AUTO_INCREMENT PRIMARY KEY,
    id_infirmier INT NOT NULL,
    id_service INT NOT NULL,
    date_debut DATE NOT NULL,
    date_fin DATE NULL,
    taux_activite DECIMAL(5, 2) DEFAULT 100.00,
    FOREIGN KEY (id_infirmier) REFERENCES INFIRMIER(id_infirmier) ON DELETE CASCADE,
    FOREIGN KEY (id_service) REFERENCES SERVICE(id_service) ON DELETE RESTRICT,
    INDEX idx_infirmier (id_infirmier),
    INDEX idx_service (id_service),
    CHECK (date_fin IS NULL OR date_fin >= date_debut),
    CHECK (taux_activite > 0 AND taux_activite <= 100)
) ENGINE=InnoDB COMMENT='Association INFIRMIER-SERVICE (rotation)';

-- Association réflexive : SUPERVISE (PERSONNEL -> PERSONNEL)
CREATE TABLE SUPERVISE (
    id_supervision INT AUTO_INCREMENT PRIMARY KEY,
    id_superviseur INT NOT NULL COMMENT 'Le personnel qui supervise',
    id_supervise INT NOT NULL COMMENT 'Le personnel supervisé',
    date_debut DATE NOT NULL,
    date_fin DATE NULL,
    FOREIGN KEY (id_superviseur) REFERENCES PERSONNEL(id_personnel) ON DELETE CASCADE,
    FOREIGN KEY (id_supervise) REFERENCES PERSONNEL(id_personnel) ON DELETE CASCADE,
    INDEX idx_superviseur (id_superviseur),
    INDEX idx_supervise (id_supervise),
    CHECK (date_fin IS NULL OR date_fin >= date_debut),
    CHECK (id_superviseur != id_supervise),
    UNIQUE (id_supervise, date_debut) COMMENT 'Un personnel a un seul superviseur à un instant donné'
) ENGINE=InnoDB COMMENT='Association réflexive - Hiérarchie du personnel';

CREATE TABLE FACTURE (
    id_facturation INT AUTO_INCREMENT PRIMARY KEY,
    IEP_sejour VARCHAR(20) NOT NULL,
    code_CCAM VARCHAR(10) NOT NULL,
    quantite INT NOT NULL DEFAULT 1 CHECK (quantite > 0),
    date_realisation DATETIME NOT NULL,
    montant_unitaire DECIMAL(10, 2) NOT NULL COMMENT 'Tarif copié depuis ACTE_MEDICAL',
    montant_total DECIMAL(10, 2) GENERATED ALWAYS AS (quantite * montant_unitaire) STORED,
    statut_facturation ENUM('En attente', 'Facturée', 'Payée') DEFAULT 'En attente',
    FOREIGN KEY (IEP_sejour) REFERENCES SEJOUR(IEP) ON DELETE RESTRICT,
    FOREIGN KEY (code_CCAM) REFERENCES ACTE_MEDICAL(code_CCAM) ON DELETE RESTRICT,
    INDEX idx_sejour (IEP_sejour)
) ENGINE=InnoDB COMMENT='Association SEJOUR-ACTE_MEDICAL (facturation)';

CREATE TABLE COMPREND (
    id_composition INT AUTO_INCREMENT PRIMARY KEY,
    id_intervention INT NOT NULL,
    code_CCAM VARCHAR(10) NOT NULL,
    ordre INT NOT NULL,
    duree_estimee INT,
    FOREIGN KEY (id_intervention) REFERENCES INTERVENTION(id_intervention) ON DELETE CASCADE,
    FOREIGN KEY (code_CCAM) REFERENCES ACTE_MEDICAL(code_CCAM) ON DELETE RESTRICT,
    UNIQUE (id_intervention, ordre),
    CHECK (ordre > 0),
    CHECK (duree_estimee IS NULL OR duree_estimee > 0)
) ENGINE=InnoDB COMMENT='Association INTERVENTION-ACTE_MEDICAL (composition)';

-- Triggers pour les contraintes métier

-- Héritage exclusif PERSONNEL
DELIMITER //
CREATE TRIGGER trg_heritage_exclusif_medecin BEFORE INSERT ON MEDECIN
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM INFIRMIER WHERE id_personnel = NEW.id_personnel) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ERREUR: Personnel déjà enregistré comme infirmier';
    END IF;
END//
CREATE TRIGGER trg_heritage_exclusif_infirmier BEFORE INSERT ON INFIRMIER
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM MEDECIN WHERE id_personnel = NEW.id_personnel) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ERREUR: Personnel déjà enregistré comme médecin';
    END IF;
END//

-- Un lit = 1 séjour à la fois
CREATE TRIGGER trg_occupation_lit_unique BEFORE INSERT ON OCCUPE
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM OCCUPE WHERE id_lit = NEW.id_lit AND date_fin IS NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ERREUR: Lit déjà occupé';
    END IF;
END//

-- Mise à jour état du lit
CREATE TRIGGER trg_lit_etat_insert AFTER INSERT ON OCCUPE
FOR EACH ROW
BEGIN
    UPDATE LIT SET etat = 'Occupé' WHERE id_lit = NEW.id_lit AND NEW.date_fin IS NULL;
END//
CREATE TRIGGER trg_lit_etat_update AFTER UPDATE ON OCCUPE
FOR EACH ROW
BEGIN
    IF NEW.date_fin IS NOT NULL AND OLD.date_fin IS NULL THEN
        UPDATE LIT SET etat = 'Disponible' WHERE id_lit = NEW.id_lit;
    END IF;
END//
DELIMITER ;

-- Vues

CREATE VIEW v_sejours_en_cours AS
SELECT s.IEP, p.IPP, CONCAT(p.nom, ' ', p.prenom) AS patient, 
       s.date_admission, DATEDIFF(NOW(), s.date_admission) AS jours,
       sv.nom_service, c.numero_chambre, l.numero_lit
FROM SEJOUR s
JOIN PATIENT p ON s.IPP = p.IPP
LEFT JOIN OCCUPE o ON s.IEP = o.IEP_sejour AND o.date_fin IS NULL
LEFT JOIN LIT l ON o.id_lit = l.id_lit
LEFT JOIN CHAMBRE c ON l.id_chambre = c.id_chambre
LEFT JOIN SERVICE sv ON c.id_service = sv.id_service
WHERE s.date_sortie IS NULL;

CREATE VIEW v_lits_disponibles AS
SELECT s.id_service, s.nom_service, c.numero_chambre, l.id_lit, l.numero_lit, l.type_lit
FROM SERVICE s
JOIN CHAMBRE c ON s.id_service = c.id_service
JOIN LIT l ON c.id_chambre = l.id_chambre
WHERE l.etat = 'Disponible';

CREATE VIEW v_taux_occupation_service AS
SELECT s.id_service, s.nom_service,
       COUNT(DISTINCT l.id_lit) AS total_lits,
       SUM(CASE WHEN l.etat = 'Occupé' THEN 1 ELSE 0 END) AS lits_occupes,
       ROUND(SUM(CASE WHEN l.etat = 'Occupé' THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT l.id_lit), 1) AS taux_pct
FROM SERVICE s
JOIN CHAMBRE c ON s.id_service = c.id_service
JOIN LIT l ON c.id_chambre = l.id_chambre
GROUP BY s.id_service, s.nom_service;

CREATE VIEW v_facturation_sejour AS
SELECT s.IEP, p.IPP, CONCAT(p.nom, ' ', p.prenom) AS patient,
       s.date_admission, s.date_sortie,
       COUNT(DISTINCT f.id_facturation) AS nb_actes,
       SUM(f.montant_total) AS montant_total
FROM SEJOUR s
JOIN PATIENT p ON s.IPP = p.IPP
LEFT JOIN FACTURE f ON s.IEP = f.IEP_sejour
GROUP BY s.IEP, p.IPP, p.nom, p.prenom, s.date_admission, s.date_sortie;

-- Données de test

INSERT INTO PATIENT VALUES
('PAT001', 'Dupont', 'Jean', '1975-03-15', 'M', '1750315123456', '0612345678', '123 Rue de Paris', 'Hypertension'),
('PAT002', 'Martin', 'Marie', '1982-07-22', 'F', '1820722789012', '0623456789', '456 Avenue Louise', 'Asthme');

INSERT INTO PERSONNEL (nom, prenom, date_naissance, date_embauche, type_contrat, actif) VALUES
('Leclerc', 'Henri', '1970-01-10', '2015-09-01', 'CDI', TRUE),
('Chevalier', 'Isabelle', '1972-02-20', '2016-03-15', 'CDI', TRUE),
('Fontaine', 'Marc', '1968-03-30', '2014-06-01', 'CDI', TRUE);

INSERT INTO MEDECIN (RPPS, id_personnel, specialite) VALUES
('11111111111', 1, 'Cardiologie'),
('22222222222', 2, 'Chirurgie Générale');

INSERT INTO INFIRMIER (id_personnel, grade, diplome) VALUES (3, 'IDE', 'Diplôme d''État Infirmier 2010');

INSERT INTO BLOC_OPERATOIRE (nom_bloc, batiment, etage) VALUES
('Bloc 1', 'Bâtiment A', 3),
('Bloc 2', 'Bâtiment A', 3);

INSERT INTO SERVICE (nom_service, batiment, etage, specialite, RPPS_chef) VALUES
('Cardiologie', 'Bâtiment B', 2, 'Cardiologie', '11111111111'),
('Chirurgie', 'Bâtiment A', 3, 'Chirurgie Générale', '22222222222');

UPDATE MEDECIN SET id_service_principal = 1 WHERE RPPS = '11111111111';
UPDATE MEDECIN SET id_service_principal = 2 WHERE RPPS = '22222222222';

-- Association réflexive : Le médecin 1 (chef cardio) supervise l'infirmier 3
INSERT INTO SUPERVISE (id_superviseur, id_supervise, date_debut) VALUES
(1, 3, '2020-01-01');

INSERT INTO CHAMBRE (id_service, numero_chambre, capacite, type_chambre) VALUES
(1, '101', 1, 'Individuelle'),
(1, '102', 2, 'Double'),
(2, '201', 1, 'Individuelle');

INSERT INTO LIT (id_chambre, numero_lit, type_lit) VALUES
(1, 'A', 'Médicalisé'),
(2, 'A', 'Standard'),
(2, 'B', 'Standard'),
(3, 'A', 'Standard');

INSERT INTO ACTE_MEDICAL VALUES
('CONS001', 'Consultation simple', 25.00, 'Consultation', 15),
('IMG001', 'ECG', 20.00, 'Imagerie', 15),
('CHI001', 'Appendicectomie', 1500.00, 'Chirurgie', 90);

INSERT INTO SEJOUR VALUES
('PAT001-20251219-0001', 'PAT001', '2025-12-15 10:30:00', NULL, 'Douleur thoracique', 'Urgence', NULL, 'Infarctus'),
('PAT002-20251210-0001', 'PAT002', '2025-12-10 14:00:00', '2025-12-17 11:00:00', 'Crise asthmatique', 'Urgence', 'Domicile', 'Asthme sévère');

INSERT INTO OCCUPE VALUES
(1, 'PAT001-20251219-0001', 1, '2025-12-15 10:30:00', NULL, NULL),
(2, 'PAT002-20251210-0001', 2, '2025-12-10 14:00:00', '2025-12-17 11:00:00', NULL);

INSERT INTO CONSULTATION VALUES
(1, 'PAT001', '11111111111', '2025-12-15 11:00:00', 'Douleur thoracique', 'Infarctus', 'Réalisée');

INSERT INTO PRESCRIPTION VALUES
(1, 'PAT001-20251219-0001', '11111111111', NOW(), 'Aspirine', '500mg 2x/jour', 'Orale', '2025-12-15', NULL, 'Active');

INSERT INTO FACTURE (IEP_sejour, code_CCAM, quantite, date_realisation, montant_unitaire) VALUES
('PAT001-20251219-0001', 'CONS001', 1, '2025-12-15 11:00:00', 25.00),
('PAT001-20251219-0001', 'IMG001', 1, '2025-12-15 15:30:00', 20.00);

-- ============================================================================
-- REQUÊTES SQL AVEC JOINTURES (5 requêtes demandées dans l'énoncé)
-- ============================================================================

-- 1. Lits disponibles actuellement en cardiologie
SELECT l.id_lit, l.numero_lit, l.type_lit, c.numero_chambre, s.nom_service
FROM LIT l
JOIN CHAMBRE c ON l.id_chambre = c.id_chambre
JOIN SERVICE s ON c.id_service = s.id_service
WHERE l.etat = 'Disponible' AND s.nom_service = 'Cardiologie';

-- 2. Médecin ayant réalisé le plus de consultations (avec RPPS et nom)
SELECT m.RPPS, p.nom, p.prenom, m.specialite, COUNT(c.id_consultation) AS nb_consultations
FROM MEDECIN m
JOIN PERSONNEL p ON m.id_personnel = p.id_personnel
LEFT JOIN CONSULTATION c ON m.RPPS = c.RPPS_medecin
GROUP BY m.RPPS, p.nom, p.prenom, m.specialite
ORDER BY nb_consultations DESC
LIMIT 1;

-- 3. Tous les séjours (IEP) d'un patient donné (IPP = 'PAT001')
SELECT s.IEP, s.date_admission, s.date_sortie, s.motif_admission, s.diagnostic_principal,
       sv.nom_service, c.numero_chambre, l.numero_lit
FROM SEJOUR s
LEFT JOIN OCCUPE o ON s.IEP = o.IEP_sejour
LEFT JOIN LIT l ON o.id_lit = l.id_lit
LEFT JOIN CHAMBRE c ON l.id_chambre = c.id_chambre
LEFT JOIN SERVICE sv ON c.id_service = sv.id_service
WHERE s.IPP = 'PAT001'
ORDER BY s.date_admission DESC;

-- 4. Durée moyenne de séjour par service (en jours)
SELECT sv.nom_service, 
       COUNT(DISTINCT s.IEP) AS nb_sejours,
       ROUND(AVG(DATEDIFF(COALESCE(s.date_sortie, NOW()), s.date_admission)), 1) AS duree_moyenne_jours
FROM SEJOUR s
JOIN OCCUPE o ON s.IEP = o.IEP_sejour
JOIN LIT l ON o.id_lit = l.id_lit
JOIN CHAMBRE c ON l.id_chambre = c.id_chambre
JOIN SERVICE sv ON c.id_service = sv.id_service
GROUP BY sv.id_service, sv.nom_service
ORDER BY duree_moyenne_jours DESC;

-- 5. Prescriptions actives avec informations patient et médecin prescripteur
SELECT pr.id_prescription, pr.medicament, pr.posologie, pr.voie_administration, pr.date_debut,
       CONCAT(pa.nom, ' ', pa.prenom) AS patient, s.IEP,
       CONCAT(pe.nom, ' ', pe.prenom) AS medecin, m.RPPS, m.specialite
FROM PRESCRIPTION pr
JOIN SEJOUR s ON pr.IEP_sejour = s.IEP
JOIN PATIENT pa ON s.IPP = pa.IPP
JOIN MEDECIN m ON pr.RPPS_medecin = m.RPPS
JOIN PERSONNEL pe ON m.id_personnel = pe.id_personnel
WHERE pr.statut = 'Active'
ORDER BY pr.date_debut DESC;

-- ============================================================================
-- REQUÊTES STATISTIQUES (pour M1 Statistique)
-- ============================================================================

-- 6. Distribution des patients par tranche d'âge et sexe (pyramide des âges)
SELECT 
    CASE 
        WHEN TIMESTAMPDIFF(YEAR, date_naissance, CURDATE()) < 18 THEN '0-17 ans'
        WHEN TIMESTAMPDIFF(YEAR, date_naissance, CURDATE()) BETWEEN 18 AND 30 THEN '18-30 ans'
        WHEN TIMESTAMPDIFF(YEAR, date_naissance, CURDATE()) BETWEEN 31 AND 45 THEN '31-45 ans'
        WHEN TIMESTAMPDIFF(YEAR, date_naissance, CURDATE()) BETWEEN 46 AND 60 THEN '46-60 ans'
        WHEN TIMESTAMPDIFF(YEAR, date_naissance, CURDATE()) BETWEEN 61 AND 75 THEN '61-75 ans'
        ELSE '75+ ans'
    END AS tranche_age,
    sexe,
    COUNT(*) AS effectif,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM PATIENT), 2) AS pourcentage
FROM PATIENT
GROUP BY tranche_age, sexe
ORDER BY tranche_age, sexe;

-- 7. Statistiques descriptives des durées de séjour par service
SELECT 
    sv.nom_service,
    COUNT(s.IEP) AS n,
    ROUND(AVG(DATEDIFF(COALESCE(s.date_sortie, NOW()), s.date_admission)), 2) AS moyenne,
    ROUND(STDDEV(DATEDIFF(COALESCE(s.date_sortie, NOW()), s.date_admission)), 2) AS ecart_type,
    MIN(DATEDIFF(COALESCE(s.date_sortie, NOW()), s.date_admission)) AS minimum,
    MAX(DATEDIFF(COALESCE(s.date_sortie, NOW()), s.date_admission)) AS maximum,
    ROUND(VAR_POP(DATEDIFF(COALESCE(s.date_sortie, NOW()), s.date_admission)), 2) AS variance
FROM SEJOUR s
JOIN OCCUPE o ON s.IEP = o.IEP_sejour
JOIN LIT l ON o.id_lit = l.id_lit
JOIN CHAMBRE c ON l.id_chambre = c.id_chambre
JOIN SERVICE sv ON c.id_service = sv.id_service
GROUP BY sv.id_service, sv.nom_service
HAVING n >= 1;

-- 8. Taux d'occupation mensuel (série temporelle)
SELECT 
    DATE_FORMAT(o.date_debut, '%Y-%m') AS mois,
    COUNT(DISTINCT o.id_lit) AS lits_utilises,
    (SELECT COUNT(*) FROM LIT) AS total_lits,
    ROUND(COUNT(DISTINCT o.id_lit) * 100.0 / (SELECT COUNT(*) FROM LIT), 2) AS taux_occupation_pct
FROM OCCUPE o
GROUP BY mois
ORDER BY mois;

-- 9. Répartition des modes d'entrée (distribution de fréquences)
SELECT 
    mode_entree,
    COUNT(*) AS effectif,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS frequence_relative,
    SUM(COUNT(*)) OVER(ORDER BY COUNT(*) DESC) AS effectif_cumule
FROM SEJOUR
GROUP BY mode_entree
ORDER BY effectif DESC;

-- 10. Analyse de la charge de travail par médecin (consultations + prescriptions)
SELECT 
    m.RPPS,
    CONCAT(p.nom, ' ', p.prenom) AS medecin,
    m.specialite,
    COUNT(DISTINCT c.id_consultation) AS nb_consultations,
    COUNT(DISTINCT pr.id_prescription) AS nb_prescriptions,
    COUNT(DISTINCT c.id_consultation) + COUNT(DISTINCT pr.id_prescription) AS charge_totale,
    ROUND(AVG(COUNT(DISTINCT c.id_consultation)) OVER(), 2) AS moyenne_consultations_globale
FROM MEDECIN m
JOIN PERSONNEL p ON m.id_personnel = p.id_personnel
LEFT JOIN CONSULTATION c ON m.RPPS = c.RPPS_medecin
LEFT JOIN PRESCRIPTION pr ON m.RPPS = pr.RPPS_medecin
GROUP BY m.RPPS, p.nom, p.prenom, m.specialite
ORDER BY charge_totale DESC;

-- 11. Corrélation entre durée de séjour et nombre d'actes facturés
SELECT 
    s.IEP,
    DATEDIFF(COALESCE(s.date_sortie, NOW()), s.date_admission) AS duree_sejour,
    COUNT(f.id_facturation) AS nb_actes,
    SUM(f.montant_total) AS montant_total,
    ROUND(SUM(f.montant_total) / DATEDIFF(COALESCE(s.date_sortie, NOW()), s.date_admission), 2) AS cout_journalier
FROM SEJOUR s
LEFT JOIN FACTURE f ON s.IEP = f.IEP_sejour
GROUP BY s.IEP, s.date_admission, s.date_sortie
HAVING duree_sejour > 0;

-- 12. Distribution des actes médicaux par catégorie (diagramme en secteurs)
SELECT 
    a.categorie,
    COUNT(f.id_facturation) AS nb_actes_realises,
    SUM(f.montant_total) AS chiffre_affaires,
    ROUND(COUNT(f.id_facturation) * 100.0 / SUM(COUNT(f.id_facturation)) OVER(), 2) AS pct_actes,
    ROUND(SUM(f.montant_total) * 100.0 / SUM(SUM(f.montant_total)) OVER(), 2) AS pct_ca
FROM ACTE_MEDICAL a
LEFT JOIN FACTURE f ON a.code_CCAM = f.code_CCAM
GROUP BY a.categorie
ORDER BY chiffre_affaires DESC;

-- 13. Analyse temporelle des admissions (saisonnalité)
SELECT 
    DAYNAME(date_admission) AS jour_semaine,
    DAYOFWEEK(date_admission) AS num_jour,
    COUNT(*) AS nb_admissions,
    ROUND(AVG(COUNT(*)) OVER(), 2) AS moyenne_journaliere
FROM SEJOUR
GROUP BY jour_semaine, num_jour
ORDER BY num_jour;

-- 14. Indicateurs de performance par service (tableau de bord)
SELECT 
    sv.nom_service,
    COUNT(DISTINCT s.IEP) AS nb_sejours,
    COUNT(DISTINCT s.IPP) AS nb_patients_uniques,
    ROUND(AVG(DATEDIFF(COALESCE(s.date_sortie, NOW()), s.date_admission)), 1) AS dms,
    SUM(CASE WHEN s.mode_entree = 'Urgence' THEN 1 ELSE 0 END) AS admissions_urgence,
    ROUND(SUM(CASE WHEN s.mode_entree = 'Urgence' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_urgences,
    COALESCE(SUM(f.montant_total), 0) AS recettes_totales
FROM SERVICE sv
LEFT JOIN CHAMBRE c ON sv.id_service = c.id_service
LEFT JOIN LIT l ON c.id_chambre = l.id_chambre
LEFT JOIN OCCUPE o ON l.id_lit = o.id_lit
LEFT JOIN SEJOUR s ON o.IEP_sejour = s.IEP
LEFT JOIN FACTURE f ON s.IEP = f.IEP_sejour
GROUP BY sv.id_service, sv.nom_service
ORDER BY recettes_totales DESC;

-- 15. Comparaison avant/après (exemple : évolution sur 2 périodes)
SELECT 
    'Période 1' AS periode,
    COUNT(*) AS nb_sejours,
    ROUND(AVG(DATEDIFF(COALESCE(date_sortie, NOW()), date_admission)), 2) AS dms
FROM SEJOUR
WHERE date_admission < '2025-12-15'
UNION ALL
SELECT 
    'Période 2' AS periode,
    COUNT(*) AS nb_sejours,
    ROUND(AVG(DATEDIFF(COALESCE(date_sortie, NOW()), date_admission)), 2) AS dms
FROM SEJOUR
WHERE date_admission >= '2025-12-15';

-- 16. Requête sur l'association réflexive : Hiérarchie du personnel
SELECT 
    sup.id_personnel AS id_superviseur,
    CONCAT(sup.nom, ' ', sup.prenom) AS superviseur,
    CASE 
        WHEN m.RPPS IS NOT NULL THEN 'Médecin'
        WHEN i.id_infirmier IS NOT NULL THEN 'Infirmier'
        ELSE 'Autre'
    END AS type_superviseur,
    sub.id_personnel AS id_supervise,
    CONCAT(sub.nom, ' ', sub.prenom) AS supervise,
    CASE 
        WHEN m2.RPPS IS NOT NULL THEN 'Médecin'
        WHEN i2.id_infirmier IS NOT NULL THEN 'Infirmier'
        ELSE 'Autre'
    END AS type_supervise,
    s.date_debut,
    s.date_fin
FROM SUPERVISE s
JOIN PERSONNEL sup ON s.id_superviseur = sup.id_personnel
JOIN PERSONNEL sub ON s.id_supervise = sub.id_personnel
LEFT JOIN MEDECIN m ON sup.id_personnel = m.id_personnel
LEFT JOIN INFIRMIER i ON sup.id_personnel = i.id_personnel
LEFT JOIN MEDECIN m2 ON sub.id_personnel = m2.id_personnel
LEFT JOIN INFIRMIER i2 ON sub.id_personnel = i2.id_personnel
WHERE s.date_fin IS NULL
ORDER BY superviseur, supervise;

-- 17. Nombre de personnes supervisées par superviseur (span of control)
SELECT 
    sup.id_personnel,
    CONCAT(sup.nom, ' ', sup.prenom) AS superviseur,
    COUNT(s.id_supervise) AS nb_supervises
FROM PERSONNEL sup
LEFT JOIN SUPERVISE s ON sup.id_personnel = s.id_superviseur AND s.date_fin IS NULL
GROUP BY sup.id_personnel, sup.nom, sup.prenom
HAVING nb_supervises > 0
ORDER BY nb_supervises DESC;

-- Fin du script

