# Politiques de Gestion des Accès et Conformité RGPD

**Projet :** Entrepôt de Données — VenteRapide (Livrable E6)  
**Auteur :** Équipe Data Engineering  
**Version :** 1.0  

---

## 1. Procédure d'Ajout et de Gestion des Accès (C16)

### 1.1 Principe de Moindre Privilège & Matrice des Rôles
L'accès à l'entrepôt `datawarehouse_e6` suit le principe du **moindre privilège** (*Least Privilege Access*). Les utilisateurs sont catégorisés selon trois rôles :

| Rôle / Utilisateur | Type de Compte | Privilèges PostgreSQL | Cas d'Usage |
| :--- | :--- | :--- | :--- |
| **`postgres`** | Superuser / Admin | `ALL PRIVILEGES` | Administration, création de base, gestion de l'infrastructure |
| **`dbt_user`** | Service / Execution | `CREATE`, `SELECT`, `INSERT`, `UPDATE`, `DELETE` | Pipelines ETL/ELT dbt, rafraîchissement des tables et vues |
| **`reporting`** | Lecture seule (Read-Only) | `SELECT` uniquement | Outils de BI (Metabase, PowerBI), requêtes ad-hoc d'analyse |

---

### 1.2 Procédure Pas-à-Pas pour Créer un Nouvel Utilisateur Analyse/BI

1. **Connexion en tant qu'administrateur :**
   ```bash
   psql -d datawarehouse_e6

2. **Création du rôle utilisateur avec mot de passe sécurisé :**
    ```bash
    CREATE USER reporting WITH PASSWORD 'votre_mot_de_passe_securise';

3. **Attribution des droits d'accès minimaux :**
    ```bash
    -- Droit de connexion
    'GRANT CONNECT ON DATABASE datawarehouse_e6 TO   reporting;'

    -- Droit de lecture sur le schéma public
    'GRANT USAGE ON SCHEMA public TO reporting;
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO  reporting;'

    -- Droit automatique de lecture sur les futures     tables générées par dbt
    'ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT     SELECT ON TABLES TO reporting;'

4. **Validation de la restriction d'écriture :**
    ```bash
    psql -U reporting -d datawarehouse_e6 -h localhost

    -- Doit réussir
    SELECT * FROM public.fact_retours LIMIT 1;

    -- Doit échouer avec "permission denied for table"
    DELETE FROM public.raw_clients;

## 2. Registre des Traitements de Données Personnelles (Article 30 RGPD)

L'entrepôt centralise plusieurs catégories de Données à Caractère Personnel (DCP). Le tableau ci-dessous constitue le registre officiel des traitements :

| Identifiant Traitement | Finalité du Traitement | Données Concernées (PII) | Base Légale | Durée de Conservation | Destinataires |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TRT-01** | Gestion des commandes et de la relation client | Nom, Prénom, Email, Date de naissance, Ville, Code Postal | Exécution du contrat (Art. 6.1.b) | Durée de la relation commerciale + 3 ans d'inactivité | Équipe commerciale, Service client |
| **TRT-02** | Analyse de la performance des ventes et retours | Identifiants commandes/retours, Motifs de retour, Montants | Intérêt légitime (Art. 6.1.f) | 5 ans (Obligations comptables / fiscales) | Équipe Data & Direction Analyste |
| **TRT-03** | Personnalisation du catalogue et segmentation | Segment client, Historique d'achats et de visites web | Consentement (Art. 6.1.a) | 3 ans après la dernière interaction | Équipe Marketing |

---

## 3. Stratégie de Purge et d'Anonymisation des Données

Pour respecter le droit à l'oubli et la limitation de la conservation (Art. 5.1.e RGPD), une procédure automatisée d'anonymisation est définie.

### 3.1 Règles d'Anonymisation (Comptes Inactifs > 36 Mois)
Lorsqu'un compte client ne présente aucune commande ni visite depuis 36 mois :
1. L'`email` est remplacé par un hash irréversible (`anonyme_hash@vente-rapide-deleted.fr`).
2. Le `nom` et le `prenom` sont remplacés par la mention `"ANONYME"`.
3. La `date_naissance` est tronquée à l'année pour conserver la donnée statistique sans permettre la réidentification.
4. Les données agrégées (commandes, montants) sont conservées pour l'exactitude des bilans financiers.

### 3.2 Fréquence et Automatisation
* **Fréquence :** Exécution mensuelle (le 1er de chaque mois à 02:00 UTC).
* **Mode d'exécution :** Script SQL automatisé via tâche `cron` exécuté sous le compte d'administration dbt.