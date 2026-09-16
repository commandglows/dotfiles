---
artifact: operator_guide
metadata_schema_version: "1.0"
artifact_version: "1.0.0"
project: "MyNeovim"
created: "2026-09-15"
updated: "2026-09-15"
status: active
source_skill: sg-maintenance
scope: "organisation et audit des raccourcis Neovim"
owner: Diane
confidence: high
risk_level: low
security_impact: none
docs_impact: yes
linked_systems:
  - lua/config/keymaps.lua
  - lua/plugins/
  - lua/shipglows/
  - scripts/keymaps-audit.ps1
depends_on: []
supersedes: []
evidence:
  - "Inventaire statique reproductible avec scripts/keymaps-audit.ps1."
next_review: "2026-12-15"
next_step: "Executer l'audit lors de l'ajout d'un raccourci global ou partage."
---

# Organisation des raccourcis

Les raccourcis ne doivent pas tous etre centralises. Leur emplacement suit leur proprietaire et leur cycle de chargement.

- `lua/config/keymaps.lua` : raccourcis globaux, transversaux et independants d'un plugin.
- `lua/plugins/<plugin>.lua`, dans `keys = { ... }` : raccourcis qui chargent ou configurent un plugin Lazy.
- `lua/shipglows/<fonctionnalite>.lua` : raccourcis propres a une fonctionnalite ShipGlows.
- Dans la fonction qui cree le buffer : raccourcis locaux a ce buffer, avec `buffer = ...`.

Un raccourci ne doit etre deplace vers `lua/config/keymaps.lua` que s'il devient reellement transversal. Les mappings `keys` des plugins restent avec leur plugin afin de conserver le lazy-loading.

## Retrouver et verifier un raccourci

Dans Neovim :

- `:Telescope keymaps` affiche les mappings actifs.
- `:verbose nmap <touche>` indique la derniere declaration active en mode normal.
- `:verbose imap <touche>` et `:verbose tmap <touche>` font de meme en insertion et terminal.

Depuis PowerShell, l'inventaire statique reproductible est :

```powershell
pwsh -File scripts/keymaps-audit.ps1
```

Le script imprime du Markdown et renvoie le code `2` lorsqu'il trouve plusieurs declarations litterales pour la meme touche et le meme mode. La sortie est volontairement generee a la demande afin d'eviter un second registre qui deviendrait obsolete.

## Limites de l'audit

L'analyse statique couvre les appels litteraux `vim.keymap.set(...)` et les entrees litterales courantes de `keys = { ... }`. Elle ne peut pas resoudre avec certitude les touches construites dynamiquement, les mappings internes aux dependances, les modes calcules ou les mappings locaux crees seulement a l'execution. En cas de doute, `:verbose map` dans le vrai environnement LazyVim reste l'autorite.
