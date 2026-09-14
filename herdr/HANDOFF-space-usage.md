# Handoff — Plugin herdr `ez-corp.space-usage` : patchs locaux + PR upstream

> Contexte pour un agent frais. Machine : Windows « Nucbox M5Ultra » (Diane).
> Terminal : WezTerm. Herdr v0.9.0 (serveur/client, sessions persistantes).

## 1. État actuel (fonctionnel, ne rien casser)

- Plugin installé et compilé localement :
  `C:\Users\Diane\AppData\Roaming\herdr\plugins\github\ez-corp.space-usage-2ecf2abc9b18\`
  (v1.12.0, binaire : `target\release\space-usage.exe`, Rust/cargo requis).
- Daemon lancé par Herdr (env `HERDR_PLUGIN_CONFIG_DIR` injectée) — **jamais**
  le lancer manuellement via `Start-Process` : sans l'env Herdr il lit une
  config de secours dans tmp et ignore `window_title_totals` (c'est ce qui a
  fait revenir « spaces · … » dans le titre une première fois).
- Config utilisateur du plugin
  (`C:\Users\Diane\AppData\Roaming\herdr\plugins\config\ez-corp.space-usage\config.toml`) :
  ```toml
  window_title_totals = true
  cpu_label = ""
  ram_label = ""
  disk_label = ""
  ```
  → titre : `spaces · 26% · 8% · 78%` (labels vides = chiffres seuls).
- Sidebar Herdr : lignes `cpu % · ram %` par espace via token `$usage`
  (8/8 workspaces OK, vérifiable par `herdr api snapshot` →
  `workspaces[].tokens.usage`).
- Barre d'onglets droite : script `C:\Users\Diane\ShipGlows\dotfiles\herdr\status.ps1`
  via `[ui].tab_bar_right` dans `C:\Users\Diane\ShipGlows\dotfiles\herdr\config.toml`
  (= `C:\Users\Diane\AppData\Roaming\herdr\config.toml`, même fichier).

## 2. Patchs locaux dans la source du plugin (à transformer en PR)

Deux retouches faites dans `src/`, **perdues à toute mise à jour du plugin**
(`herdr plugin install` remplace le checkout et recompile depuis GitHub) :

### Patch A — honorer un `disk_label` vide (cohérence)
- Fichier : `src/config.rs`, dans `parse_config`, ligne ~640.
- Avant : `"disk_label" => cfg.disk_label = non_empty(value),`
- Après : `"disk_label" => cfg.disk_label = Some(value.to_string()),`
- Pourquoi : cpu/ram/battery honorent déjà une valeur vide (« ne rien nommer »,
  voir `icons.rs::labelled`), mais `disk_label` passait par `non_empty()` et
  retombait sur le mot « disk ». Avec un label vide on obtient `78% 387G`.

### Patch B — option `disk_size` (FAIT, en option plutôt qu'un retrait brut)
- `src/config.rs` : nouveau champ `disk_size: bool` (défaut `true`), clé
  `disk_size = false` parsée comme `disk`/`battery`.
- `src/render.rs` : `RowStyle` porte `disk_size` (`from_config`), `disk_cell`
  prend un `show_size: bool`.
- `src/icons.rs` : `IconSet::disk` garde le pourcentage seul quand la taille
  est vide (pas d'espace traînant).
- Test : `a_disk_cell_can_drop_the_free_size_and_keep_the_percent`.
- Config de Diane : `disk_size = false` ajouté au `config.toml` du plugin.

### Autre sujet PR — le préfixe `spaces · ` du titre (FAIT EN LOCAL)
- `src/daemon.rs` : `title_totals()` préfixe en dur `"spaces · "`.
- Implémenté en local : option plugin `title_prefix` (défaut `"spaces"`,
  valeur vide = pas de préfixe ni séparateur). Test :
  `a_custom_title_prefix_replaces_spaces_and_an_empty_one_names_nothing`.
- Reste à porter en PR upstream avec les patchs A et B.

## 3. Plan de PR (propre)

**FAIT — deux PR ouvertes** (fork `dianedef/herdr-pc-ram-and-cpu-usage-overlay`,
clone local de travail : `C:\Users\Diane\ShipGlows\herdr-pr`) :

1. **PR #11** — `config-disk-size-and-title-prefix` : Patch A (disk_label vide),
   Patch B (`disk_size = false`), option `title_prefix`.
2. **PR #12** — `machine-totals` : option `machine_totals = true` → le titre
   affiche les chiffres **globaux de la machine** (cpu/ram comme le Gestionnaire
   des tâches) au lieu de la somme des espaces herdr. Lecteurs : /proc/stat +
   MemAvailable (Linux), GetSystemTimes + GlobalMemoryStatusEx (Windows),
   host_processor_info + host_statistics (macOS, non compilé localement).

Les deux branches sont sur le fork ; le checkout local
`plugins\github\ez-corp...` a tout fusionné (commit `merge machine_totals`) et
la config de Diane a `disk_size = false` + `machine_totals = true`.

En cas d'écrasement par `herdr plugin install` : re-construire depuis la
branche du fork (§4) ou re-fusionner depuis `C:\Users\Diane\ShipGlows\herdr-pr`.

## 4. Rebuild local (procédure testée)

```sh
# 1. Tuer le daemon (sinon l'exe est verrouillé : « Accès refusé, os error 5 »)
powershell -NoProfile -Command "Stop-Process -Name space-usage -Force"
# 2. Recompiler
cd "C:/Users/Diane/AppData/Roaming/herdr/plugins/github/ez-corp.space-usage-2ecf2abc9b18"
cargo build --release
# 3. Relancer VIA HERDR (env garantie) — status-enable est idempotent
herdr plugin action invoke status-enable --plugin ez-corp.space-usage
# 4. Vérifier après ~8 s : titre + sidebar
herdr api snapshot   # tokens.usage présents sur tous les workspaces
```

## 5. Gotchas durement appris (à respecter)

- **Tuer le daemon avec `Stop-Process -Force`** saute le nettoyage
  (`window_title_clear`) → le vieux titre reste collé dans l'onglet WezTerm.
  Un cycle `status-disable` puis `status-enable` (ou changer d'espace) force
  Herdr à réécrire le titre.
- La config du plugin est **relue à chaque rafraîchissement** (5 s) : pas
  besoin de redémarrer le daemon pour un changement de config, seulement
  après recompil.
- **Ne jamais** `herdr server stop` : les processus dans les panes
  (crush/nvim) meurent avec.
- Environnement bash limité (pas de grep/head/tail/sleep/find) : utiliser
  `python` et `powershell`. `$TEMP` au lieu de `/tmp`.
- Le dépôt courant `C:\Users\Diane\ShipGlows\dotfiles` contient des
  changements non commités liés à ce travail (`herdr/status.ps1`,
  `herdr/config.toml`) — proposer un commit séparé.

## 6. Critères d'acceptation

- Titre de fenêtre/onglet : `spaces · NN% · NN% · NN%` sans mots cpu/ram/disk
  ni taille disque.
- Sidebar : lignes `cpu NN% · ram NN%` sur tous les espaces.
- Aucun `spaces · …` résiduel si les totaux sont désactivés.
- PR ouverte (patchs A + B ± `title_prefix`) avec tests, CI verte.
