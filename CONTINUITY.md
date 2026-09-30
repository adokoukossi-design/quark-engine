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

---

## 🎯 4. Prochaines Étapes Immédiates (Roadmap POC)

La prochaine phase est le **Prototype (POC) — Étape 2 & 3** :

1. [x] **Définir la grammaire / le format de la Quark Spec (`.qrk`)** (Terminé).
2. [ ] **Créer le projet Dart / Package d'outils local (`packages/quark_core`) :**
   * Initialiser le `pubspec.yaml` avec `yaml`, `code_builder`, `dart_style`, `analyzer`.
3. **Tester la transpilation `.qrk` ➡️ `.dart` :**
   * Générer un widget Flutter propre et prêt à l'emploi à partir d'un fichier de spec de moins de 30 lignes (~150 tokens).
4. **Tester l'extraction `.dart` ➡️ `.qrk` (Compression AST) :**
   * Lire un fichier Dart existant avec l'API `analyzer` et en extraire la spec condensée.

---

## ⚡ 5. Instructions de Reprise Rapide (Prompt pour l'Agent IA)

Lors d'une nouvelle session, l'agent ou le développeur doit exécuter :

```text
"Je reprends le projet Quark Engine. Lis /home/franck-us/quark-engine/CONTINUITY.md et /home/franck-us/quark-engine/README.md pour te caler sur le contexte, puis propose-moi l'étape suivante de la feuille de route."
```
