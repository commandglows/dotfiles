# Mail Intel

Mail Intel est une passerelle locale en lecture seule pour lire des emails Gmail synchronisés en Maildir, les ouvrir dans Neovim, puis copier leur contenu en Markdown pour un agent IA.

## Mail Intelligence review

La revue interactive se lance avec `:MailIntake` ou `<leader>mi`. Elle ouvre une vue plein écran avec la liste des propositions en haut et le premier email source déjà ouvert en bas. La liste conserve environ 24 % de la hauteur disponible quand la fenêtre Neovim ou le terminal est redimensionné. `<leader>mm` ou `:MailIntakeMessage` ouvre l'email actif seul en plein écran. Depuis la liste :

- `<CR>` ouvre l'email source.
- `a` ouvre l'email et demande à Avante de proposer projet, angle, owner skill, risques et action.
- `r` ouvre l'email et demande à Avante un résumé factuel de 1 à 5 phrases maximum.
- `h` copie un handoff `#source` gouverné pour la skill suivante.
- `d` déplace immédiatement l'email vers la corbeille Gmail, sans confirmation.
- `y` accepte, `e` ouvre la fiche pour édition, `E` la marque éditée, `x` rejette et `i` ignore.

Après `y`, `E`, `x`, `i` ou `d`, la fiche traitée sort de la queue et l'email suivant s'ouvre automatiquement. Si c'était le dernier, l'email précédent devient actif.

`:MailIntakeScan` crée les fiches metadata-only dans `~/.shipglows/private/data/mail-intake/inbox/`. `:MailIntakeScan!` effectue un dry-run. Les corps bruts restent dans le Maildir et ne sont jamais écrits dans la queue privée.

L'action `a` analyse l'email avec le provider IA configuré via la couche provider-neutre de `lua/shipglows/mail/ai.lua`, attend un JSON de classification, puis persiste le résumé et les champs de routage dans la fiche privée. Avec un provider Avante ACP comme `codex`, elle donne à l'agent le chemin absolu du message Maildir privé plutôt que de recopier son corps dans le prompt. Les providers HTTP reçoivent encore l'export borné du corps, car ils ne peuvent pas lire un chemin local. Pour les messages HTML/multipart, Mail Intel extrait le texte visible avec BeautifulSoup quand la bibliothèque est disponible, puis utilise un fallback standard-library qui ignore explicitement les balises de style, script et métadonnées. Les règles CSS et le JavaScript du template ne sont donc pas affichés dans le corps. L'action `o` extrait les URLs présentes dans le message et affiche le libellé du lien quand il existe avant d'ouvrir le lien choisi via le navigateur système. Le contexte de routage est chargé depuis le cache privé approuvé `~/.shipglows/private/data/projects/`; il contient les fiches de pitch, audiences et angles des projets. Le provider par défaut reste celui configuré par Avante. Le provider ACP `codex` est lancé avec `gpt-5.5` et un effort `medium` afin de ne pas hériter d'un modèle global encore inconnu de `codex-acp`; `AVANTE_CODEX_MODEL` et `AVANTE_CODEX_REASONING_EFFORT` permettent de surcharger ces valeurs. Chaque analyse Mail Intelligence ouvre un nouveau chat Avante afin qu'une ancienne session ACP ne conserve pas son précédent modèle. `MAIL_INTEL_AI_PROVIDER=gemini` sélectionne le provider Gemini via Avante si sa configuration et ses identifiants sont disponibles.

Le corps brut peut résider dans la source Maildir privée approuvée sous `~/.shipglows/private/data/mail-source/`, mais cette arborescence est exclue du Git privé. Seules les fiches de revue metadata-only sont écrites dans `mail-intake/`.

Le handoff `h` utilise le registre Neovim, le transport terminal OSC 52 et le fallback local `/tmp/nvim_notif.txt`. Il ne contient que les métadonnées de routage et le `source_id`, jamais le corps de l’email.

La suppression distante est séparée du rejet `x` : `x` retire seulement la fiche de revue, tandis que `d` utilise le compte IMAP configuré par `mbsync`, copie le message dans le dossier Gmail Trash, supprime sa présence dans le dossier courant et marque la fiche `deleted`. Aucune confirmation interactive n'est demandée. La restauration se fait depuis la corbeille Gmail.

Le lecteur v1 reste actif en parallèle pour explorer directement le Maildir, rechercher un message et l'envoyer explicitement vers le workflow `$sf-content`. La review v2 est le flux quotidien; le lecteur v1 est la surface d'exploration ponctuelle.

L'administration amont des labels et filtres Gmail vit maintenant a cote, via `scripts/mail-admin`, avec un registre local versionne sous `~/.shipglows/private/data/mail-admin/`.

## Architecture

```text
Gmail personnel
  -> scripts/mail-admin
  -> labels/filtres Gmail
  -> mbsync/isync
  -> ~/.shipglows/private/data/mail-source/<account>/
  -> notmuch
  -> scripts/mail-intel
  -> lua/shipglows/mail/
  -> Neovim
```

`scripts/mail-intel` ne sait pas envoyer, supprimer, archiver, deplacer, taguer ou marquer des emails. Il lit uniquement un Maildir local deja synchronise.

`scripts/mail-intake` est le voisin review-first : il crée une queue privée idempotente et déplace les décisions terminées vers `mail-intake/done/`. Il ne modifie pas le Maildir ni Gmail.

`scripts/mail-admin` reste le chemin de mutation Gmail pour les labels et filtres via l'API officielle. `scripts/mail-delete` est l'exception dédiée à l'envoi explicite d'un message dans la corbeille Gmail via IMAP.

## Planification locale

Un timer systemd utilisateur lance automatiquement deux passages par jour, à 07:00 et 14:00 Europe/Paris :

```text
mbsync business-a-mail
  -> notmuch new
  -> scripts/mail-intake scan
```

Le service ne lance pas Avante, ne classe pas automatiquement les projets et n'envoie aucun email. Il prépare seulement les fiches privées à revoir dans Neovim.

Contrôle :

```bash
systemctl --user status shipglows-mail-intake.timer
systemctl --user list-timers shipglows-mail-intake.timer
journalctl --user -u shipglows-mail-intake.service -n 50 --no-pager
```

Déclenchement manuel du même passage :

```bash
systemctl --user start shipglows-mail-intake.service
```

Les unités vivent sous `~/.config/systemd/user/shipglows-mail-intake.{service,timer}` et utilisent la source privée `~/.shipglows/private/data/mail-source/`.
Le linger systemd utilisateur est activé pour que le timer continue à fonctionner après déconnexion : `loginctl show-user "$USER" -p Linger` doit afficher `Linger=yes`.

## Prérequis

- `mbsync` ou `isync` pour synchroniser Gmail vers Maildir.
- `notmuch` pour indexer et rechercher les emails locaux.
- La source Maildir privée locale `~/.shipglows/private/data/mail-source`.

Ne committez jamais de mot de passe Gmail, app password, token OAuth, cookie ou contenu réel d'email dans ce dépôt.

Sur Ubuntu/Debian :

```bash
sudo apt-get update
sudo apt-get install -y notmuch isync
```

## Configuration

Variables utiles:

```bash
export MAIL_INTEL_ROOT="$HOME/.shipglows/private/data/mail-source/competitors"
export MAIL_INTEL_ACCOUNT="business-a"
export MAIL_INTEL_FOLDER="_to_transcribe"
export MAIL_INTEL_LIMIT="30"
# Optionnel si un autre index notmuch est utilisé :
export NOTMUCH_CONFIG="$HOME/.config/notmuch/mail-intel-config"
```

Structure attendue:

```text
~/.shipglows/private/data/mail-source/competitors/
  business-a/
    INBOX/
      cur/
      new/
      tmp/
```

## CLI

```bash
scripts/mail-intel --maildir-root "$HOME/.shipglows/private/data/mail-source/competitors" accounts
scripts/mail-intel --maildir-root "$HOME/.shipglows/private/data/mail-source/competitors" folders business-a
scripts/mail-intel --maildir-root "$HOME/.shipglows/private/data/mail-source/competitors" --format json list business-a _to_transcribe --limit 10
scripts/mail-intel --maildir-root "$HOME/.shipglows/private/data/mail-source/competitors" --format json search business-a "pricing" --limit 10
scripts/mail-intel export <message-or-thread-id> --markdown
```

`list`, `search`, `show` et `export` utilisent `notmuch`. Si `notmuch` n'est pas installé ou si le Maildir n'est pas encore indexé, la commande renvoie une erreur explicite.

L’index de cette installation est séparé de l’ancien Maildir de test :

```text
~/.config/notmuch/mail-intel-config
  path=/home/claude/.shipglows/private/data/mail-source/competitors
```

## Gmail Admin

Le registre declaratif non secret vit sous :

```text
~/.shipglows/private/data/mail-admin/
  registry.json
  registry.example.json
```

Les secrets OAuth restent hors Git, par exemple :

```text
~/.config/mail-admin/oauth/<account>/credentials.json
~/.config/mail-admin/oauth/<account>/token.json
```

Commandes principales :

```bash
scripts/mail-admin init-registry
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

`plan` sans `--live` reste purement local. `plan --live` et `apply` comparent le registre local a Gmail et evitent de recreer des filtres equivalents. En cas de meme requete distante avec une action differente, la commande signale un conflit au lieu d'empiler des doublons.

Quand une regle declare `"trash": true`, `mail-admin` applique le label cible et ajoute aussi `TRASH` au filtre Gmail. Cela correspond a la suppression immediate voulue, avec recuperation possible via la corbeille Gmail.

Dependances Python distantes a installer avant les commandes Gmail API :

```bash
python3 -m pip install --user google-api-python-client google-auth-oauthlib google-auth-httplib2
```

Scopes utilises :

- `https://www.googleapis.com/auth/gmail.labels`
- `https://www.googleapis.com/auth/gmail.settings.basic`

## Lecteur Neovim v1

Les commandes `CompetitorMail*` sont actives sous le namespace `shipglows.mail.reader` et réutilisent le CLI local en lecture seule `scripts/mail-intel`.

```vim
:CompetitorMailAccounts
:CompetitorMailInbox
:CompetitorMailInbox business-a
:CompetitorMailFolder _to_transcribe
:CompetitorMailSearch pricing
:CompetitorMailOpen <message-or-thread-id>
:CompetitorMailCopyMarkdown
:CompetitorMailCopySfContent
:CompetitorMailSfContent
```

`CompetitorMailInbox` et `CompetitorMailSearch` ouvrent une sélection via `vim.ui.select`. L'email choisi est rendu dans un buffer Markdown temporaire. `CompetitorMailCopyMarkdown` copie le contenu courant dans le presse-papiers et le registre par défaut.

`CompetitorMailCopySfContent` copie le prompt et l'email courant sans appeler d'IA. `CompetitorMailSfContent` copie le même prompt puis l'envoie à Avante si celui-ci est disponible; sinon le prompt reste copié. L'alias historique `:CompetitorMailAvanteSfContent` reste enregistré pour compatibilité.

Mappings du lecteur v1 :

```text
<leader>mI  inbox du lecteur
<leader>mS  recherche dans le lecteur
<leader>mf  choisir un dossier
<leader>ma  lister les comptes
<leader>mO  ouvrir par identifiant
<leader>my  copier le Markdown
<leader>mb  copier le prompt $sf-content
<leader>mA  envoyer le prompt $sf-content a Avante
```

Les mappings `<leader>mi`, `<leader>mm` et `<leader>ms` sont réservés à la review v2 (`:MailIntake`, `:MailIntakeMessage` et `:MailIntakeScan`). Aucun chemin du lecteur ne modifie Gmail, les labels, le Maildir ou l'état distant.

Dans Which-Key, appuyer sur `<leader>`, puis `m`, ouvre le groupe `Mail Intelligence / Markdown` avec les commandes de review et du lecteur. Les mappings `mm`, `ms`, `mI`, `mS`, `mf`, `ma`, `mO`, `my`, `mb` et `mA` sont enregistrés lorsque le module Mail est chargé. Markmap, désactivé dans cette configuration, est réservé à `<leader>mK` s'il est réactivé.

## Gmail

Pour les comptes Gmail personnels, consultez la documentation officielle Google avant de configurer la synchronisation:

- Gmail avec un autre client email: `https://support.google.com/mail/answer/7126229`
- App passwords: `https://support.google.com/accounts/answer/185833`

Google recommande les connexions modernes avec Sign in with Google. Les app passwords demandent la validation en deux étapes et ne sont pas toujours disponibles.

## Connexion d'un compte Gmail pilote

Le plus simple pour une v1 locale est de commencer avec un seul compte Gmail et un alias local, par exemple `business-a`.

1. Installer les dépendances:

```bash
sudo apt-get update
sudo apt-get install -y notmuch isync
```

2. Préparer les dossiers locaux:

```bash
mkdir -p "$HOME/.shipglows/private/data/mail-source/competitors/business-a/INBOX"
```

3. Créer un secret local hors dépôt:

```bash
mkdir -p "$HOME/.config/mail-intel"
chmod 700 "$HOME/.config/mail-intel"
nvim "$HOME/.config/mail-intel/business-a-password"
chmod 600 "$HOME/.config/mail-intel/business-a-password"
```

Le fichier `business-a-password` doit contenir uniquement le mot de passe d'application Gmail si votre compte le permet. Sinon, il faudra passer par une configuration OAuth plus avancée.

4. Créer `~/.mbsyncrc`:

```conf
IMAPAccount business-a
Host imap.gmail.com
User votre-adresse@gmail.com
PassCmd "cat ~/.config/mail-intel/business-a-password"
SSLType IMAPS
AuthMechs LOGIN

IMAPStore business-a-remote
Account business-a

MaildirStore business-a-local
SubFolders Verbatim
Path ~/.shipglows/private/data/mail-source/competitors/business-a/
Inbox ~/.shipglows/private/data/mail-source/competitors/business-a/INBOX

Channel business-a-inbox
Far :business-a-remote:
Near :business-a-local:
Patterns "INBOX"
Create Near
Sync Pull
Expunge None
CopyArrivalDate yes
```

Cette configuration est volontairement orientée lecture: `Sync Pull` récupère depuis Gmail vers le local, et `Expunge None` évite de propager des suppressions.

5. Synchroniser:

```bash
mbsync business-a-inbox
```

6. Initialiser `notmuch`:

```bash
notmuch setup
```

Quand `notmuch setup` demande le dossier mail, indiquez:

```text
~/.shipglows/private/data/mail-source/competitors
```

Puis indexez:

```bash
notmuch new
```

7. Exporter les variables pour Neovim:

```bash
export MAIL_INTEL_ROOT="$HOME/.shipglows/private/data/mail-source/competitors"
export MAIL_INTEL_ACCOUNT="business-a"
export MAIL_INTEL_FOLDER="_to_transcribe"
```

Pour les rendre permanentes, ajoutez-les à votre shell (`~/.bashrc`, `~/.zshrc`, ou le fichier équivalent utilisé par votre dotfiles).

8. Tester:

```bash
scripts/mail-intel --maildir-root "$HOME/.shipglows/private/data/mail-source/competitors" accounts
scripts/mail-intel --maildir-root "$HOME/.shipglows/private/data/mail-source/competitors" folders business-a
scripts/mail-intel --maildir-root "$HOME/.shipglows/private/data/mail-source/competitors" --format json list business-a _to_transcribe --limit 10
```

Ensuite dans Neovim:

```vim
:MailIntake
:CompetitorMailInbox
```
