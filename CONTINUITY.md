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

---

## 🎯 4. Prochaines Étapes Immédiates (Roadmap POC)

La prochaine phase est le **Prototype (POC) — Étape 4 & 5** :

1. [x] **Définir la grammaire de la Quark Spec (`.qrk`)** (Terminé).
2. [x] **Créer le package Dart `quark_core` et le transpilateur `.qrk` ➡️ `.dart`** (Terminé).
3. [ ] **Développer le Compresseur Inverse (Dart ➡️ Quark Spec via AST `analyzer`) :**
   * Lire un fichier Dart existant avec l'API `analyzer` pour extraire les widgets clés et régénérer le fichier `.qrk` équivalent.
4. [ ] **Tester le prompt LLM en passe unique (Quark Pulse) :**
   * Écrire le template de prompt système pour Claude / Gemini permettant de modifier la Quark Spec en 1 tour.

---

## ⚡ 5. Instructions de Reprise Rapide (Prompt pour l'Agent IA)

Lors d'une nouvelle session, l'agent ou le développeur doit exécuter :

```text
"Je reprends le projet Quark Engine. Lis /home/franck-us/quark-engine/CONTINUITY.md et /home/franck-us/quark-engine/README.md pour te caler sur le contexte, puis propose-moi l'étape suivante de la feuille de route."
```
