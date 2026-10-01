# 🧠 Quark Engine — Mémoire de Continuité (Session & State)

> **Fichier de persistance contextuelle**  
> Ce document sert de point de reprise immédiat pour l'utilisateur et l'agent IA lors d'une nouvelle session, d'un redémarrage ou d'une reconnexion.

---

## 📌 1. Fiche d'Identité du Projet

* **Nom du projet :** Quark Engine
* **Vision :** Agent de développement hybride & norme d'architecture **Zero-Token** réduisant de **99.9 %** les tokens d'entrée via le **Spec-Driven Development (SDD)** et la transpilation AST locale pour Flutter/Dart.
* **Dépôt GitHub public :** [https://github.com/adokoukossi-design/quark-engine](https://github.com/adokoukossi-design/quark-engine)
* **Emplacement local :** `/home/franck-us/quark-engine`
* **Branche active :** `main`

---

## 🛠️ 2. Environnement & Outils Validés

* **Système d'exploitation :** Linux x86_64 (Ubuntu)
* **Dart SDK :** `3.10.4`
* **Flutter SDK :** `3.38.5` (canal stable)
* **GitHub CLI (`gh`) :** `v2.45.0` installé dans `~/.local/bin/gh`
* **Compte GitHub authentifié :** `adokoukossi-design` (scopes : `repo`, `gist`, `read:org`)
* **Git User Local :** `zenithstruct-max` / `adokoukossi-design`

---

## 📈 3. Ce qui a été accompli (Statut Actuel)

- [x] Définition conceptuelle et validation de l'architecture en 4 briques (`Quark Spec`, `Quark Core`, `Quark Router`, `Quark Pulse`).
- [x] Installation et configuration de GitHub CLI (`gh`).
- [x] Initialisation du dépôt Git local `/home/franck-us/quark-engine`.
- [x] Rédaction et publication du [`README.md`](README.md) synthétisant la vision, les métriques et la roadmap.
- [x] Création et synchronisation du dépôt public GitHub.
- [x] Mise en place du présent fichier de continuité contextuelle (`CONTINUITY.md`).
- [x] Spécification formelle de la Quark Spec v1 ([`spec/QUARK_SPEC_V1.md`](spec/QUARK_SPEC_V1.md)).
- [x] Création du premier fichier d'exemple officiel ([`examples/user_profile_card.qrk`](examples/user_profile_card.qrk)).
- [x] Création du package Dart [`packages/quark_core`](packages/quark_core) avec `yaml` et `dart_style`.
- [x] Implémentation du transpilateur déterministe Quark Spec ➡️ Code Flutter Dart (`lib/src/transpiler.dart`).
- [x] Création et validation du CLI exécutable `bin/quark.dart` avec rapport métrique de tokens (-64 % sur le composant test).
- [x] Génération réussie du code Flutter officiel ([`examples/user_profile_card.dart`](examples/user_profile_card.dart)).
- [x] Implémentation du Compresseur Inverse AST Dart ➡️ Quark Spec ([`packages/quark_core/lib/src/extractor.dart`](packages/quark_core/lib/src/extractor.dart)).
- [x] Support complet des instanciations de widgets résolues/non-résolues (`InstanceCreationExpression` et `MethodInvocation`).
- [x] Validation du Round-Trip bidirectionnel strict 1:1 (`.qrk` ➡️ `.dart` ➡️ `.qrk`) sur cas v1 et cas étendu v2 ([`examples/user_profile_card_v2.dart`](examples/user_profile_card_v2.dart)).
- [x] Suite complète de tests unitaires automatisés validée (`dart test` : 5/5 passants, 0 avertissement d'analyse).
- [x] Conception et implémentation du module **Quark Pulse** ([`packages/quark_core/lib/src/pulse.dart`](packages/quark_core/lib/src/pulse.dart)).
- [x] Définition du prompt système ultra-dense Zero-Token (< 250 tokens) forçant une réponse YAML pure et déterministe.
- [x] Intégration CLI `quark pulse <file.qrk> "<instruction>" [--dry-run]` avec calcul en temps réel de l'empreinte de tokens.
- [x] Validation end-to-end d'édition en 1 tour (Single Pass) avec mise à jour automatique de la spec et transpilation Flutter Dart immédiate.
- [x] Suite de tests automatisée étendue à 9/9 tests passants (0 avertissement d'analyse).

---

## 🎯 4. Prochaines Étapes Immédiates (Roadmap POC)

La prochaine phase est le **Prototype (POC) — Étape 5** :

1. [x] **Définir la grammaire de la Quark Spec (`.qrk`)** (Terminé).
2. [x] **Créer le package Dart `quark_core` et le transpilateur `.qrk` ➡️ `.dart`** (Terminé).
3. [x] **Développer le Compresseur Inverse (Dart ➡️ Quark Spec via AST `analyzer`)** (Terminé).
4. [x] **Développer & tester le module Quark Pulse (Prompt LLM en passe unique)** (Terminé).
5. [ ] **Développer Quark Router (Aiguillage sémantique local) :**
   * Classificateur d'intention local (règles sémantiques ou SLM ultra-léger) distinguant les refactors locaux directs (ex: renommage, mise en forme, validation) des requêtes nécessitant une nouvelle logique métier / UI via Quark Pulse.
   * Orchestration de la chaîne : `Intention Utilisateur` ➡️ `Quark Router` ➡️ `Quark Pulse` ou `Moteur Local Direct` ➡️ `Quark Core` ➡️ `Dart`.

---

## ⚡ 5. Instructions de Reprise Rapide (Prompt pour l'Agent IA)

Lors d'une nouvelle session, l'agent ou le développeur doit exécuter :

```text
"Je reprends le projet Quark Engine. Lis /home/franck-us/quark-engine/CONTINUITY.md et /home/franck-us/quark-engine/README.md pour te caler sur le contexte, puis propose-moi l'étape suivante de la feuille de route."
```
