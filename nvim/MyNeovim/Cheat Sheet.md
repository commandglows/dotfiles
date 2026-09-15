# H rVim Cheat Sheet

Cheat sheet courte pour les fonctions que tu utilises vraiment.

## Mail admin

Gestion des filtres Gmail depuis le systeme local :

```bash
scripts/mail-admin validate
scripts/mail-admin list-rules
scripts/mail-admin plan
scripts/mail-admin plan --live
scripts/mail-admin apply --dry-run
scripts/mail-admin apply
scripts/mail-admin bootstrap-auth <account>
scripts/mail-admin list-labels <account>
scripts/mail-admin list-filters <account>
```

Chemins utiles :

```text
~/.shipglows/private/data/mail-admin/registry.json
~/.shipglows/private/data/mail-admin/registry.example.json
~/.shipglows/private/data/mail-intake/inbox/
~/.shipglows/private/data/mail-intake/done/
~/.config/mail-admin/oauth/<account>/
```

## Mail Intelligence review

```text
:MailIntake       ouvrir le panneau de revue
:MailIntakeScan   créer les fiches d'attente depuis le Maildir local
:MailIntakeScan!  dry-run sans écrire de fiche
```

Dans le panneau : `<CR>` ouvre la source, `r` demande un résumé de 1 à 5 phrases, `a` demande l'analyse Avante, `h` copie un handoff `#source`, `y` accepte, `e` édite la fiche, `E` la marque éditée, `x` rejette, `d` envoie dans la corbeille Gmail sans confirmation, `i` ignore.

Après une décision (`y`, `E`, `x`, `i` ou `d`), l'email suivant s'ouvre automatiquement.

Mappings du flux quotidien : `<leader>mm` ouvre la review et `<leader>ms` lance le scan.

Which-Key : `<leader>`, puis `m` ouvre le groupe Mail Intelligence / Markdown.

Le handoff `h` est copié via le registre Neovim et OSC 52 ; le fallback local est `/tmp/nvim_notif.txt`.

Planification automatique à 07:00 et 14:00 Europe/Paris :

```bash
systemctl --user status shipglows-mail-intake.timer
systemctl --user list-timers shipglows-mail-intake.timer
journalctl --user -u shipglows-mail-intake.service -n 50 --no-pager
```

## Mail Intelligence reader

Exploration ponctuelle du Maildir local en lecture seule :

```text
:CompetitorMailAccounts       lister les comptes
:CompetitorMailInbox          ouvrir le dossier par defaut
:CompetitorMailFolder         ouvrir un dossier
:CompetitorMailSearch         rechercher
:CompetitorMailOpen           ouvrir par identifiant
:CompetitorMailCopyMarkdown   copier l'email en Markdown
:CompetitorMailCopySfContent  copier le prompt $sf-content
:CompetitorMailSfContent      envoyer le prompt a Avante
```

Mappings : `<leader>mI` inbox, `<leader>mS` recherche, `<leader>mf` dossier, `<leader>ma` comptes, `<leader>mO` ouverture par ID, `<leader>my` copie Markdown, `<leader>mb` copie `$sf-content`, `<leader>mA` Avante.

## Comment trouver un raccourci que tu ne connais pas

### L'aide intégrée

Quand tu cherches un raccourci, la première option c'est l'aide native :

```
:help <sujet>
```

Par exemple `:help moving` ou `:help usr_04` pour les bases de l'édition.

Pour voir tous tes mappings actifs selon le mode :

```
:nmap          " tous les mappings en mode Normal
:imap          " mode Insert
:vmap          " mode Visual
:nmap <leader> " tous ceux avec ton leader key
```

### which-key : la vraie solution

`which-key.nvim` répond exactement à ce besoin. Quand tu commences une séquence de touches, une popup apparaît automatiquement avec toutes les options disponibles.

- Tu tapes `<leader>` et tu vois toutes les possibilités s'afficher
- Tu peux aussi appeler `:WhichKey` pour ouvrir la cheatsheet complète

Pour vérifier si c'est actif dans ton setup :

```
:checkhealth which-key
```

### Déplacer une ligne vers le haut

Un exemple concret — faire remonter la ligne courante :

- **En mode normal** : `ddkP` (`dd` = couper la ligne, `k` = monter d'une ligne, `P` = coller au-dessus)
- **Avec une commande** : `:m .-2`
- **En mode visuel** (pour un bloc) : `:m '<-2`

---

## Édition de texte

### Mouvements indispensables

- `j` / `k` : descendre / monter d'une ligne
- `3j` / `3k` : descendre / monter de 3 lignes
- `w` : mot suivant
- `b` : mot précédent
- `e` : fin du mot
- `0` : début de ligne
- `^` : premier caractère non vide de la ligne
- `$` : fin de ligne
- `gg` : début du fichier
- `G` : fin du fichier
- `H` : haut de l'écran
- `M` : milieu de l'écran
- `L` : bas de l'écran
- `zz` : recentrer l'écran sur le curseur

### Paragraphes et texte long

- `{` : paragraphe précédent
- `}` : paragraphe suivant
- `(` / `)` : phrase précédente / suivante
- `/mot` : chercher un mot ou une expression
- `n` : résultat suivant
- `N` : résultat précédent

Pour les articles, `}` et `{` sont parmi les touches les plus utiles.

### Markdown : titres et folds

Règle importante : les titres `H1` (`#`) restent toujours ouverts.

- `]h` / `[h` : titre H2/H3 suivant / précédent
- `zh` : titre suivant, tous niveaux
- `n` / `p` : titre H2/H3 suivant / précédent en `Visual` uniquement, avec compte possible (`2n`, `3p`)
- `z2` : garde H1/H2 visibles, replie en dessous
- `z3` : garde H1/H2/H3 visibles, replie en dessous
- `z4` : garde H1/H2/H3/H4 visibles, replie en dessous
- `z5` : garde H1/H2/H3/H4/H5 visibles, replie en dessous
- `za` : ouvrir / fermer la section courante
- `zR` / `zM` : tout ouvrir / tout fermer, sans replier les H1
- `q` en `Visual` : toggle `fold all sauf H1` / `unfold all`
- `r` en `Visual` : toggle complet du titre courant et de tout son bloc

### Suppressions utiles

- `x` : supprimer un caractère
- `dw` : supprimer jusqu'au mot suivant
- `diw` : supprimer le mot sous le curseur
- `dd` : supprimer la ligne
- `D` : supprimer jusqu'à la fin de la ligne
- `d$` : idem, jusqu'à la fin de ligne
- `d0` : supprimer jusqu'au début de ligne
- `3dd` : supprimer 3 lignes

### Édition utile

- `i` : insérer avant le curseur
- `a` : insérer après le curseur
- `o` : nouvelle ligne en dessous
- `O` : nouvelle ligne au-dessus
- `u` : annuler
- `<C-r>` : refaire
- `yy` : copier une ligne
- `p` : coller après
- `P` : coller avant

### Spell (orthographe)

- `zg` / `Zg` : ajouter le mot sous le curseur au dictionnaire personnel
- `zug` / `Zug` : supprimer le mot du dictionnaire personnel
- `zw` / `Zw` : marquer le mot comme incorrect
- `z=` : proposer des corrections
- `]s` / `[s` : aller à l'erreur d’orthographe suivante / précédente

### Raccourcis très rentables sur mobile

- `s` : saut rapide visible avec `flash.nvim`
- `zz` : recentrer souvent pour garder le contexte
- `{` / `}` : naviguer de paragraphe en paragraphe
- `diw` : supprimer proprement un mot
- `dd` : supprimer vite une ligne

## Explorer

### Copier un chemin

- `Y` : copie le chemin absolu du buffer courant.
- Dans un explorateur Snacks ou Neo-tree, `Y` copie le chemin absolu du fichier ou dossier sous le curseur.
- `<leader>yp` et `:CopyPath` sont des alias pour le buffer courant.

Ce remplacement désactive volontairement le raccourci Vim natif `Y` (yank jusqu'à la fin de la ligne).

### NeoTree

Trois portes d'entrée — attention, « root » ici n'est ni le root système (`/`) ni le project root LazyVim, c'est juste `$HOME`.

| Mapping | Ancré sur | Résolution chez toi |
|---|---|---|
| `<leader>er` (root) | `$HOME` (figé dans la config) | `/home/ubuntu` |
| `<leader>ec` (cwd) | dossier où `nvim` a été lancé | figé au démarrage |
| `<leader>ee` (git) | dossier git courant, vue git_status | ouvert auto au lancement |

### Taille des panneaux

Ces raccourcis s'appliquent au panneau courant :

| Mapping | Effet |
|---|---|
| `<leader>w1` | taille 1 |
| `<leader>w2` | taille 2 |
| `<leader>w3` | taille 3 |
| `<leader>wF` | full size |

Ils détectent automatiquement le contexte :

- explorateur à gauche : largeur 20 / 35 / 50 / full
- Avante à droite : largeur 30% / 45% / 60% / full
- Avante horizontal : hauteur 15% / 20% / 30% / full
- autre fenêtre : largeur ou hauteur selon la forme du split courant

Ce qu'il faut retenir :

- les dossiers avec `*` contiennent du travail Git en cours
- les dossiers avec `?` contiennent au moins un fichier non tracké
- tu n'as plus besoin d'ouvrir chaque dossier pour savoir où il y a du travail
- `l` ouvre un dossier ou un fichier
- `h` referme un dossier

### Changer la racine de l'explorateur

Tu peux choisir n'importe quel dossier dans l'arborescence et le définir comme nouvelle racine, pour ne plus voir que son contenu.

**NeoTree** (curseur sur le dossier) :

- `.` : définir le dossier sous le curseur comme nouvelle racine (`set_root`)
- `<BS>` : remonter d'un niveau (`navigate_up`)
- `<` / `>` : naviguer entre les sources (filesystem / buffers / git)
- `H` : toggle fichiers cachés

**Snacks Explorer** (curseur sur le dossier) :

- `.` : focus sur le dossier courant et le définir comme cwd (`explorer_focus`)
- `<BS>` : remonter d'un niveau (`explorer_up`)
- `<C-c>` : changer le cwd du tab vers le dossier courant (`tcd`)
- `Z` : refermer tous les dossiers ouverts
- `H` / `I` : toggle fichiers cachés / ignorés (gitignore)

À retenir : `.` est le même raccourci dans les deux. Pour revenir en arrière, `<BS>` partout.

### Chercher dans un dossier précis

Quand tu es positionné sur un dossier dans l'explorateur, tu peux limiter une recherche à ce dossier.

**Snacks Explorer** (curseur sur le dossier) :

- `<C-f>` : grep (live grep) limité à ce dossier
- `<C-t>` : find files limité à ce dossier
- `<C-w>` : words / symbols limité à ce dossier
- `?` dans l'explorateur : liste complète des mappings actifs (la source de vérité)

**NeoTree** : pas de mapping intégré pour ça. Deux solutions :

1. Yank + picker : positionner sur le dossier, `Y` pour copier le chemin, puis `<leader>sg` ou `<leader>ff` et coller le chemin dans le champ « cwd ».
2. Ajouter un mapping custom dans `window.mappings` de `lua/plugins/neo-tree.lua` qui appelle Snacks/Telescope sur `state.tree:get_node().path`.

## Git

### Lecture rapide

- `neo-tree` sert à voir où ça a bougé
- la vue Git de `neo-tree` sert à voir uniquement les fichiers Git concernés
- `lualine` affiche déjà la branche Git et le nombre de fichiers modifiés

Important :

- `neo-tree` et `Git status` ne montrent pas le diff ligne par ligne
- ils montrent surtout quels fichiers ou dossiers sont modifiés, ajoutés ou non trackés
- pour voir le vrai contenu des changements, il faut un plugin de diff ou une commande Git

Nomenclature Git dans l'explorateur :

- `M` : modifié
- `U` : unstaged
- `S` : staged
- `A` : ajouté
- `D` : supprimé
- `R` : renommé
- `?` : non tracké
- `!` : ignoré
- `C` : conflit

### Plugins qui montrent un vrai diff visuel

- `gitsigns` : diff directement dans le fichier ouvert
- `Snacks picker` : `<leader>gd` ouvre la liste des fichiers/hunks modifiés avec preview
- `Snacks picker` : `<leader>gD` ouvre le diff contre `origin`

Dans le fichier courant avec `gitsigns` :

- la colonne gauche affiche `+`, `~`, `_`, `^`, `!` selon le type de changement
- les numéros et lignes modifiés sont colorés
- les changements intra-ligne sont visibles quand `word_diff` est actif
- `<leader>ghp` : aperçu inline du hunk courant
- `<leader>ghs` : stage le hunk courant
- `<leader>ghr` : reset le hunk courant
- `<leader>ghb` : blame de la ligne courante
- `<leader>ghd` : diff du fichier courant
- `<leader>ght` : toggle du diff intra-ligne

Si rien n'apparait avec `gitsigns` :

- vérifier que le fichier est dans un dépôt Git
- vérifier que le fichier est suivi par Git ou attachable par `gitsigns`
- vérifier qu'il reste bien des changements non commités
- lancer `:Gitsigns attach`
- lancer `:Gitsigns debug_messages`

Diff rapide avec `Snacks` :

- `<leader>gd` : Git Diff (hunks)
- `<leader>gD` : Git Diff (origin)
- le panneau de sélection est volontairement limité à 3 lignes pour mobile
- `Tab` : fichier suivant
- `<S-Tab>` : fichier précédent
- `↑` / `↓` : scroller le preview
- `<C-f>` / `<C-b>` : scroller le preview
- `<C-j>` / `<C-k>` : descendre / monter dans la liste

- `Codex` (`agentic.nvim`) : montre un diff visuel pour les changements proposés par l'agent avant validation
- `Claude Code` : ouvre aussi des diffs visuels quand Claude propose des modifications

### Neogit — agir sur Git sans taper de commandes

Interface type magit pour stage/commit/push au clavier.

Raccourcis globaux :

- `<leader>gn` : ouvrir Neogit
- `<leader>gc` : commit
- `<leader>gp` : push
- `<leader>gl` : pull

Dans le buffer Neogit (mode normal) :

- `s` : stage le fichier ou le hunk sous le curseur
- `S` : stage tout
- `u` : unstage
- `U` : unstage tout
- `x` : discard (annule les changements)
- `<Tab>` : déplier / replier un fichier pour voir le diff
- `<Enter>` : ouvrir le fichier

Commits :

- `cc` : commit (ouvre le buffer message, `:wq` pour valider)
- `ca` : commit --amend (réécrit le dernier commit)
- `ce` : extend (ajoute au dernier commit sans changer le message)
- `cf` : fixup
- `cw` : reword (changer juste le message)

Push / pull / fetch :

- `Pp` : push vers l'upstream
- `Pf` : push --force-with-lease
- `Pu` : push et set upstream
- `Fa` : fetch all
- `pp` : pull

Branches / log :

- `bb` : checkout branche
- `bc` : créer une branche
- `ll` : log de la branche
- `q` : fermer Neogit

Workflow type :

- `neo-tree` = voir où ça a bougé
- `Snacks` (`<leader>gD`) = lire ce qui a changé
- `Neogit` (`<leader>gn`) = stage + commit + push

## Recherche et navigation

### Chercher un fichier ou un texte

- `<leader>e` : explorer le projet
- `<leader>ge` : vue Git du projet
- `<leader>sg` : chercher du texte dans le projet
- `<leader>sw` : chercher le mot courant ou la sélection
- `<leader>sb` : chercher dans le buffer courant
- `<leader>su` : historique d'undo
- `<leader>bb` : revenir au buffer précédent
- `<leader>bd` : fermer le buffer courant

### Aller vite à l'endroit voulu

- `s` : `flash.nvim`, saut rapide à l'endroit voulu
- `S` : saut Treesitter, utile en code
- `<leader>e` puis `l` / `h` : ouvrir / fermer les dossiers

## Codex dans NeoVim

Ici, `Codex` correspond au plugin `agentic.nvim` branché sur `codex-acp`.
Si tu cherches "Agentic", c'est cette section.

### Panneau Codex

- `<leader>akt` : ouvre / ferme Codex
- `<leader>akf` : ajoute le fichier courant ou la sélection au contexte
- `<leader>akn` : nouvelle session
- `<leader>akr` : restaurer une session
- `<leader>akl` : ajouter le diagnostic de la ligne
- `<leader>akb` : ajouter tous les diagnostics du buffer

Ce qu'il faut retenir :

- le panneau Codex est horizontal, en bas, pratique sur mobile
- tu peux travailler en regardant tes vrais fichiers dans NeoVim
- tu vois les modifications proposées avec un diff visuel avant validation

Workflow utile :

1. Ouvrir un fichier ou un article
2. `<leader>akt`
3. `<leader>akf`
4. demander une réécriture, une amélioration ou une correction
5. relire le diff avant d'accepter

## Emails concurrents dans Neovim

Le plugin local `Mail Intel` sert à lire des emails Gmail déjà synchronisés en Maildir, les ouvrir dans Neovim, puis copier leur contenu en Markdown pour Codex, Claude, Gemini, Copilot Chat ou Avante.

La lecture reste sans effet de bord ; l'action `d` est l'exception explicite pour envoyer un email dans la corbeille Gmail :

- pas d'envoi d'email
- pas d'archive
- pas de modification Gmail

### Commandes utiles

- `<leader>mm` : ouvrir le panneau Mail Intelligence plein écran
- `<leader>ms` : scanner `_to_transcribe` vers la queue privée
- `<CR>` : ouvrir l'email source en lecture seule
- `a` : demander l'analyse Avante
- `r` : résumer l'email en 1 à 5 phrases
- `h` : copier un handoff `#source`
- `e` : éditer la fiche de revue
- `E` : marquer la fiche éditée
- `y` : accepter
- `x` : rejeter
- `d` : envoyer l'email dans la corbeille Gmail sans confirmation
- `i` : ignorer

### Workflow simple

1. Synchroniser Gmail vers le Maildir privé local avec `mbsync`.
2. Indexer avec `notmuch new`.
3. Dans Neovim, lancer `<leader>mm`.
4. Choisir un email dans la liste.
5. Utiliser `a` pour demander l'analyse Avante, puis éditer et valider la fiche.
6. Ou lancer `<leader>mb` pour copier le prompt et le coller ailleurs.

Pour vérifier la résolution d'un message sans le supprimer :

```bash
scripts/mail-delete --account business-a --folder _to_transcribe --source-id <source-id> --dry-run
```

### Configuration à connaître

Les variables importantes sont :

```bash
export MAIL_INTEL_ROOT="$HOME/.shipglows/private/data/mail-source/competitors"
export MAIL_INTEL_ACCOUNT="business-a"
export MAIL_INTEL_FOLDER="_to_transcribe"
export NOTMUCH_CONFIG="$HOME/.config/notmuch/mail-intel-config"
```

La doc complète est dans `Mail Intel.md`.

## Codex / Claude

### Sortir proprement d'une interface agent

Si tu vois `Prompt | <C-s>: submit`, tu es dans le panneau Codex, pas dans Claude Code.

- `<leader>akt` : masquer / réafficher le panneau Codex
- `q` : fermer le panneau Codex quand tu es en mode normal
- `<C-s>` : envoyer le prompt

Si tu es dans un vrai terminal Claude :

- `<leader>ac` : ouvrir / fermer Claude Code
- `<C-\><C-n>` : quitter le mode terminal sans envoyer `Esc` au process
- ensuite `<C-h>` / `<C-l>` : revenir à la fenêtre de code ou changer de split

À retenir :

- `Esc` peut avoir un effet indésirable dans certains outils agents
- pour sortir sans casser la session, préfère `<leader>akt` dans le panneau Codex
- pour un terminal, préfère toujours `<C-\><C-n>`

## Copilot

### Copilot suggestions

Copilot est déjà actif dans ton setup.

Ce qu'il faut tester :

- est-ce que les suggestions inline t'aident vraiment à écrire plus vite
- est-ce qu'elles sont utiles aussi en Markdown et en rédaction, pas seulement en code
- est-ce que l'acceptation avec `<Tab>` te paraît naturelle ou pénible

Raccourcis utiles :

- `<Tab>` en insertion : accepte la suggestion affichée
- `<M-[>` : suggestion précédente
- `<M-]>` : suggestion suivante

Ce qu'il faut retenir :

- Copilot est surtout un outil d'autocomplétion intelligente
- il est bien pour accélérer une phrase, une fonction ou une structure répétitive
- il est moins adapté qu'un vrai agent quand tu veux une réécriture réfléchie ou un diff contrôlé

### Copilot Chat

Ce qu'il faut tester :

- demander une explication rapide d'un fichier
- demander une review d'un buffer
- demander un fix minimal sur une sélection

Raccourcis utiles :

- `<leader>ap` : ouvrir / fermer Copilot Chat
- `<leader>ae` : expliquer le buffer ou la sélection
- `<leader>ar` : review du buffer ou de la sélection
- `<leader>af` : proposer un fix minimal

Question simple à te poser :

- est-ce que tu préfères ce mode "chat contextuel rapide" à Codex pour certaines tâches courtes ?

## Avante

Avante est activé dans ce setup.

Flux de base :

1. `<leader>axt` : basculer la sidebar (vertical par défaut).
2. `<leader>axv` : ouvrir verticalement (droite).
3. `<leader>axb` : ouvrir horizontalement (bas).
2. `:AvanteChat` (ou `<leader>axc`) : lancer une conversation avec le contexte courant.
3. Envoie ton prompt, puis regarde les propositions dans la sidebar Avante.
4. `a` applique le changement sous le curseur, `A` applique tous les changements proposés.

Raccourcis actifs :

- `<leader>axt` : basculer la sidebar (vertical par défaut).
- `<leader>axv` : ouvrir verticalement (droite).
- `<leader>axb` : ouvrir horizontalement (bas).
- `:AvanteChat` / `<leader>axc` : chat.
- `:AvanteAsk` / `<leader>axq` : question rapide.
- `:AvanteEdit` / `<leader>axe` : édition basée sélection/contexte.
- `:AvanteFocus` / `<leader>axf` : focus fenêtre Avante.
- `:AvanteHistory` / `<leader>axh` : historique des échanges.
- `:AvanteModels` / `<leader>axm` : choisir un modèle.
- `:AvanteChatNew` / `<leader>axn` : nouvelle session.
- `:AvanteSwitchProvider` / `<leader>axp` : changer le provider.
- `:AvanteRefresh` / `<leader>axu` : rafraîchir la vue.
- `:AvanteStop` / `<leader>axs` : arrêter une génération.
- `:AvanteBuild` / `:AvanteClear` / `:AvanteShowRepoMap` : commandes utiles selon le cas.

Ce que tu dois comparer avec le workflow Codex/Copilot Chat :

- la lisibilité des diffs,
- la qualité des suggestions,
- la fluidité d'application depuis la sidebar.

Question simple à te poser :

- est-ce que tu veux un agent "éditeur intégré" orienté UI, ou est-ce que Codex te suffit déjà ?

## Plugins à connaître

Ceux que tu devrais connaître d'abord :

- `neo-tree` : arborescence du projet + indicateurs Git
- `flash.nvim` : navigation ultra rapide dans le texte
- `Codex` : réécriture et modifications avec diff visuel
- `Copilot` : autocomplétion rapide
- `Copilot Chat` : explication / review / fix rapide d'un buffer
- `vim-pencil` : confort d'écriture en Markdown et texte
- `ShipGlows` : navigation dans les titres Markdown (ce que tu appelles parfois *Wispr Flow*)

Ceux qui valent le coup plus tard pour la rédaction :

- `nvim-ufo` : folds sur les headings Markdown
- `nvim-spider` : mouvements plus intelligents par mots
- `follow-md-links` : suivre les liens Markdown facilement

## Raccourcis à apprendre d'abord

Si tu ne dois retenir que quelques touches :

- `<leader>e` : explorer le projet
- `<leader>ge` : voir l'état Git
- `<leader>sg` : chercher dans le projet
- `s` : sauter vite à un endroit visible
- `{` / `}` : sauter de paragraphe en paragraphe
- `diw` : supprimer un mot
- `dd` : supprimer une ligne
- `]h` / `[h` : aller au titre H2/H3 suivant / précédent
- `za` : ouvrir / fermer la section courante
- `zM` / `zR` : tout fermer / tout ouvrir
- `<leader>akt` : ouvrir Codex
- `<leader>akf` : envoyer le fichier ou la sélection à Codex
- `h` / `l` dans l'arborescence : fermer / ouvrir

## Lecture des indicateurs

- `*` sur un dossier : il y a des fichiers modifiés quelque part dedans
- `?` sur un dossier : il y a au moins un fichier non tracké dedans
- Git visible sur un fichier : ce fichier a changé
