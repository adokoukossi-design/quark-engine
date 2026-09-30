# 📐 Quark Spec v1 — Spécification du Format (.qrk)

> **Version :** 1.0.0-draft  
> **Statut :** Validé pour le Prototype POC  
> **Format sous-jacent :** YAML épuré (DSL déclaratif pour Flutter/Dart)

---

## 1. Objectifs de Conception

1. **Ultra-compacité (Zero-Token Focus) :** Réduire la taille de description d'un composant de 70 % à 90 % par rapport au code Dart brut.
2. **Déterminisme absolu :** Chaque élément de la spec possède une traduction univoque en nœuds d'AST Dart.
3. **Zéro syntaxe parasite :** Aucun besoin de déclarer `BuildContext`, `Key`, `super.key`, `return`, `Widget build`, accolades ou virgules d'imbrication.
4. **Interprétabilité universelle :** Facilement généré et modifié par n'importe quel LLM sans fine-tuning.

---

## 2. Structure Générale d'un fichier `.qrk`

Un fichier `.qrk` est composé de trois sections principales :

```yaml
widget: <NomDuWidget>
props:
  - <nomChamp>: <type>
ui:
  <noeudRacine>:
    ...
```

---

## 3. Définition des Propriétés (`props`)

La section `props` définit le contrat de données du composant. Le transpilateur génère automatiquement :
- Les champs déclarés `final`.
- Le constructeur `const` avec paramètres nommés `required` (ou optionnels si valeur par défaut).

### Types Primitifs Supportés :

| Type Quark | Type Dart Généré | Exemple |
| :--- | :--- | :--- |
| `string` | `String` | `name: string` |
| `int` | `int` | `count: int` |
| `double` | `double` | `price: double` |
| `bool` | `bool` | `isPro: bool` |
| `action` | `VoidCallback` | `onTap: action` |
| `action<T>` | `ValueChanged<T>` | `onChange: action<String>` |

---

## 4. Arbre d'Interface (`ui`)

L'arbre UI utilise l'indentation YAML pour exprimer la hiérarchie parent-enfant.

### Conteneurs & Mises en page

* **`card:`** Génère un `Card(child: ...)`
* **`row:`** Génère un `Row(children: [...])`
* **`col:`** Génère un `Column(children: [...])`
* **`stack:`** Génère un `Stack(children: [...])`
* **`box:`** Génère un `Container` ou `SizedBox`

### Éléments d'Affichage

* **`text:`** Génère un `Text(...)`
* **`avatar:`** Génère un `CircleAvatar(...)`
* **`chip:`** Génère un `Chip(...)`
* **`button:`** Génère un `ElevatedButton(...)`
* **`icon:`** Génère un `Icon(...)`

---

## 5. Modificateurs en Ligne `(...)`

Les parenthèses suffixées à un élément permettent d'ajouter des attributs secondaires sans alourdir la hiérarchie :

```yaml
- text: $name (titleMedium)
- chip: 'PRO' (when: $isPro)
- button: 'Valider' (onTap: $onSubmit)
```

### Modificateurs Reconnus :

1. **Typographie / Thème :**
   * Format court : `(titleMedium)`, `(bodySmall)`, `(headlineLarge)`.
   * Dart : `style: Theme.of(context).textTheme.titleMedium`
2. **Conditionnel (`when`) :**
   * Format : `(when: $condition)`
   * Dart : Utilise le `collection-if` natif (`if (condition) Widget`)
3. **Événements (`onTap`, `onPressed`) :**
   * Format : `(onTap: $callback)`
   * Dart : `onPressed: callback`

---

## 6. Résolution des Variables (`$`)

* Tout identifiant préfixé par un `$` (ex: `$name`, `$avatarUrl`, `$isPro`) est interprété comme une **variable Dart**.
* Les valeurs sans `$` entourées de guillemets simples ou doubles (ex: `'Suivre'`, `'PRO'`) sont traitées comme des **chaînes littérales**.

---

## 7. Exemple Complet de Référence

Fichier : `examples/user_profile_card.qrk`

```yaml
widget: UserProfileCard
props:
  - name: string
  - avatarUrl: string
  - isPro: bool
  - onFollow: action

ui:
  card:
    row:
      - avatar: $avatarUrl
      - col:
          - text: $name (titleMedium)
          - chip: 'PRO' (when: $isPro)
      - button: 'Suivre' (onTap: $onFollow)
```
