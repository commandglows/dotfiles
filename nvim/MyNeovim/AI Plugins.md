# AI Plugins

Résumé court des plugins IA activés dans cette config.

## Choix rapide

- **Copilot Chat** : le plus intégré a NeoVim pour discuter avec le code, demander une review, expliquer ou corriger.
- **Avante Codex** : interface Avante branchee sur Codex ACP avec l'auth ChatGPT/Codex, sans cle API OpenAI transmise au provider.
- **Gemini CLI** : le plus proche d'un agent/terminal Gemini officiel dans NeoVim.
- **Claude Code** : reste pertinent si vous voulez un agent tres autonome dans un terminal/diff.

## Raccourcis utiles

Si votre `leader` est celui par défaut de LazyVim, `<leader>` correspond en général a `Espace`.

### Copilot Chat

- `Espace a p` : ouvrir / fermer Copilot Chat
- `Espace a e` : expliquer le buffer ou la sélection
- `Espace a r` : review du buffer ou de la sélection
- `Espace a f` : aider a corriger le buffer ou la sélection

### Avante Codex

- `Espace a x t` : ouvrir / fermer Avante
- `Espace a x c` : ouvrir le chat Avante
- `Espace a x q` : poser une question
- `Espace a x e` : editer avec Avante
- `Espace a x p` : changer de provider Avante
- `Espace a x m` : choisir le modele Avante des providers HTTP
- `Espace a x M` : choisir le modele de l'agent ACP courant, par exemple Codex
- `Espace a x s` : arrêter la génération et son processus ACP

Avante lance directement le binaire natif `codex-acp`, afin que `:AvanteStop` et la fermeture normale de Neovim puissent arrêter le processus qu'ils possèdent. Il n'est donc pas nécessaire de fermer manuellement Codex ACP après chaque analyse. Après un crash brutal ou un arrêt forcé de la machine, un contrôle ponctuel des processus orphelins reste recommandé.

L'installateur dotfiles conserve `@zed-industries/codex-acp@0.16.0`, la version compatible avec les arguments `-c` configurés ici, et refuse de considérer l'installation complète si le runtime natif OS/architecture manque. Le successeur officiel `@agentclientprotocol/codex-acp` utilise une autre interface de configuration et doit faire l'objet d'une migration dédiée avant remplacement.

Pour l'installation, les vérifications sûres, les erreurs à éviter et la procédure de dépannage, lire le [guide opérateur Avante et Codex ACP](../../shipglows_data/technical/operator-guides/avante-codex-acp.md).

### Gemini CLI

- `Espace a g t` : ouvrir / fermer Gemini CLI
- `Espace a g a` : ajouter le fichier courant au contexte Gemini
- `Espace a g d` : demander un fix des diagnostics du buffer courant
- `Espace a g /` : ouvrir le picker des slash commands Gemini

### Codock

Dock nvim pour les agents en CLI (par défaut Claude Code), avec popup d'actions custom.

- `Espace C C` : toggle du dock
- `Espace C A` : popup des actions (5 actions custom en français)
- `Espace C Y` : yank la position du fichier (rejoignable par l'agent)
- `Espace C P` : coller la position yankée (jump à un fichier/ligne/colonne)

L'agent par défaut est `claude --permission-mode bypassPermissions`. Plus large d'action qu'un simple terminal car il expose le fichier courant, le buffer et les diagnostics à l'agent.

### Code Preview (agent-agnostic)

Diff live/auto des modifications proposées par les agents CLI (Claude Code, Codex CLI), indépendamment de l'agent utilisé. Layout : onglet séparé. `:CodePreviewCloseDiff` ferme le diff, `:CodePreviewStatus` affiche l'état.

> ⚠️ **OpenCode : ne pas installer le hook.** Le plugin `.opencode/plugins/` (code-preview) fait planter le serveur opencode au démarrage (« Unexpected server error ») sur le fork installé (`opencode` 1.18.30, anomalycocompatible) — l'API de plugin y est incompatible. Ce hook a été retiré du workspace. Ne pas lancer `:CodePreviewInstallOpenCodeHooks`.

Installation par projet (le hook est écrit dans le répertoire de travail courant de Nvim) :

```vim
:CodePreviewInstallClaudeCodeHooks   " -> .claude/settings.local.json
:CodePreviewInstallCodexCliHooks     " -> .codex/hooks.json
```

Prérequis : `jq` dans le PATH (installer via `winget install --id jqlang.jq`). Redémarrer les CLI après l'installation des hooks.

**Mode YOLO** : les permissions opencode restent `"permission": "allow"` (cf. `C:\Users\Diane\.config\opencode\opencode.json`) et aucun `approval_policy` n'est configuré pour Codex. En conséquence, Codex applique ses modifications sans bloquer sur une décision : la préview n'apparaît pas pour Codex. La préview reste effective pour **Claude Code** (hooks + `--permission-mode` qui bloque), le diff affichant les changements avant leur application manuelle via `:CodePreviewApplyChanges`.

## Migration / changement de machine

- Les hooks code-preview sont **par projet** : relancer les 2 commandes `:CodePreviewInstallClaudeCodeHooks` / `:CodePreviewInstallCodexCliHooks` dans chaque projet, puis redémarrer les CLI.
- `jq` doit être présent dans le PATH (winget).
- `install-dotfiles.ps1` pointe par défaut vers `~/.dotfiles` : le junction `%LOCALAPPDATA%\nvim` ramène vers `C:\Users\Diane\ShipGlows\dotfiles\nvim\MyNeovim`. Après une réinstallation dotfiles, vérifier que le junction regarde la copie de travail (ShipGlows) et non `.dotfiles`.
- `.codex/hooks.json` et les hooks dans `.claude/settings.local.json` sont des fichiers du dépôt (racine) : présents au clone.
- **Ne pas réinstaller le hook opencode** (cf. avertissement ci-dessus) : la présence d'un `.opencode/` avec plugin casse le lancement d'opencode dans le projet.
- Les hooks codock/code-preview ne couvrent pas Gemini CLI ni Crush.

## Comment choisir

- Prenez **Copilot Chat** si vous voulez une intégration NeoVim plus poussée et une UX plus opinionated.
- Prenez **Avante Codex** si vous voulez utiliser Codex dans Avante via votre abonnement ChatGPT/Codex plutot que la facturation API OpenAI.
- Prenez **Gemini CLI** si vous voulez un mode agent plus direct, proche du CLI officiel.
- Gardez **Claude Code** pour les sessions plus longues ou les diffs plus ambitieux.
- Prenez **Code Preview** pour voir/approuver les diffs de n'importe quel agent CLI sans dépendre d'un seul éditeur.
