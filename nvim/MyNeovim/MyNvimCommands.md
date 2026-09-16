# MyNeovim Commands Reference

## Espaces, tabs et buffers

La ligne du haut est partagee en deux par Tabby : l'espace de travail courant a gauche, puis ses buffers a droite. Les autres espaces ne prennent donc aucune place ; le selecteur visuel permet de les retrouver. Scope masque leurs buffers sans les fermer. La winbar juste au-dessus du contenu appartient a Dropbar et affiche le chemin du fichier puis le contexte de code ou Markdown courant.

Quand Neo-tree ou Snacks Explorer est ouvert a gauche, Tabby reserve sa largeur et affiche uniquement `Explorateur` au-dessus du panneau. L'espace courant et ses buffers commencent au-dessus de la zone d'edition.

### Commands

| Command | Description |
|---------|-------------|
| `:Telescope scope buffers` | Parcourir les buffers de tous les espaces |
| `:ScopeMoveBuf` | Deplacer le buffer courant vers un autre espace |
| `:ScopeSaveState` | Sauvegarder l'etat de Scope dans la session |
| `:ScopeLoadState` | Restaurer l'etat de Scope depuis la session |
| `:Tabby rename_tab <nom>` | Renommer l'espace actif |

### Raccourcis

| Raccourci | Action |
|-----------|--------|
| `<Tab>` / `<S-Tab>` | Buffer suivant / precedent dans l'espace actif |
| `]t` / `[t` | Espace suivant / precedent |
| `<leader><tab><tab>` | Creer un espace |
| `<leader><tab>r` | Renommer l'espace |
| `<leader><tab>d` | Fermer l'espace |
| `<leader><tab>o` | Fermer les autres espaces |
| `<leader><tab>1...9` | Aller directement a un espace |
| `<leader><tab>j` | Choisir visuellement un espace |
| `<leader><tab>m` | Deplacer le buffer vers un espace |
| `<leader><tab>b` | Voir les buffers de tous les espaces |
| `<leader>;` | Choisir un element du fil d'Ariane Dropbar |
| `[;` / `];` | Contexte precedent / suivant dans Dropbar |

### How it works

- Les buffers ouverts dans l'espace 1 ne sont visibles que dans l'espace 1.
- Les buffers ouverts dans l'espace 2 ne sont visibles que dans l'espace 2.
- Tabby n'affiche que les buffers de l'espace courant sur son unique ligne.
- Dropbar sert a naviguer dans le chemin et les symboles du fichier, pas a changer de buffer.

Useful when working with multiple tabs to keep buffers organized per-project/context.
