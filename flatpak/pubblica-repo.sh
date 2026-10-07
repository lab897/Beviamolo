#!/usr/bin/env bash
# Costruisce il sito del repository Flatpak di Beviamolo (https://flatpak.beviamolo.it) a
# partire dal tarball Linux di una release. Lo lancia il workflow flatpak.yml; si può
# provare in locale prima di pubblicare (vedi PUBLISH_LINUX_FLATPAK.md nel monorepo).
#
#   GPG_KEY=<id chiave> ./pubblica-repo.sh <tarball: URL o percorso> <cartella del sito>
#
# Variabili:
#   GPG_KEY     chiave con cui firmare commit e summary (obbligatoria)
#   URL_SITO    indirizzo pubblico del sito (default https://flatpak.beviamolo.it)
#   MIRROR_DA   sito da cui riprendere il repo già pubblicato (default URL_SITO; vuoto = da zero)
#   PROFONDITA  versioni da tenere per ogni ref (default 3)
#
# Il repo pubblicato è lo stato: lo si scarica (ostree pull --mirror), ci si aggiunge la
# versione nuova, si potano le vecchie e si ripubblica tutto. Niente binari in git.
set -euo pipefail

QUI="$(cd "$(dirname "$0")" && pwd)"
TAR="${1:?indica il tarball (URL o percorso)}"
SITO="$(mkdir -p "${2:?indica la cartella del sito}" && cd "$2" && pwd)"
: "${GPG_KEY:?serve GPG_KEY, la chiave di firma}"
URL_SITO="${URL_SITO:-https://flatpak.beviamolo.it}"
MIRROR_DA="${MIRROR_DA-$URL_SITO}"
PROFONDITA="${PROFONDITA:-3}"
APP_ID=dev.lab897.beviamolo
RAMO=stable

LAVORO="$(mktemp -d)"; trap 'rm -rf "$LAVORO"' EXIT

# 1. Tarball
if [[ "$TAR" =~ ^https?:// ]]; then
  echo "→ Scarico $TAR"
  curl -fsSL -o "$LAVORO/beviamolo-linux-x64.tar.gz" "$TAR"
else
  cp "$TAR" "$LAVORO/beviamolo-linux-x64.tar.gz"
fi
SHA="$(sha256sum "$LAVORO/beviamolo-linux-x64.tar.gz" | cut -d' ' -f1)"
tar -xzf "$LAVORO/beviamolo-linux-x64.tar.gz" -C "$LAVORO" \
  beviamolo-linux/dev.lab897.beviamolo.png beviamolo-linux/dev.lab897.beviamolo.metainfo.xml
VER="$(grep -oP '<release version="\K[0-9.]+' "$LAVORO/beviamolo-linux/dev.lab897.beviamolo.metainfo.xml" | head -1)"
echo "→ Versione $VER, sha256 $SHA"

# 2. Manifest con il tarball locale al posto dell'URL
sed -e "s|^\(\s*\)url: .*|\1path: $LAVORO/beviamolo-linux-x64.tar.gz|" \
    -e "s|^\(\s*\)sha256: .*|\1sha256: $SHA|" \
    "$QUI/$APP_ID.yml" > "$LAVORO/$APP_ID.yml"

# 3. Repo già pubblicato
REPO="$SITO/repo"
rm -rf "$REPO"
if [ -n "$MIRROR_DA" ] && curl -fsS -o /dev/null "$MIRROR_DA/repo/config"; then
  echo "→ Riprendo il repo da $MIRROR_DA"
  ostree --repo="$REPO" init --mode=archive
  ostree --repo="$REPO" remote add --no-gpg-verify pubblicato "$MIRROR_DA/repo"
  ostree --repo="$REPO" pull --mirror pubblicato
  ostree --repo="$REPO" remote delete pubblicato
else
  echo "→ Repo nuovo"
fi

# 4. Build ed export firmato. Il runtime GNOME arriva da Flathub se non è già installato.
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak-builder --user --install-deps-from=flathub --disable-rofiles-fuse --force-clean \
  --state-dir="$LAVORO/.flatpak-builder" \
  --repo="$REPO" --default-branch="$RAMO" --gpg-sign="$GPG_KEY" \
  "$LAVORO/build" "$LAVORO/$APP_ID.yml"

flatpak build-update-repo --title=Beviamolo --default-branch="$RAMO" \
  --generate-static-deltas --prune --prune-depth="$PROFONDITA" \
  --gpg-sign="$GPG_KEY" "$REPO"

# 5. File per installare: .flatpakref (un'app) e .flatpakrepo (il remote)
CHIAVE="$(gpg --export "$GPG_KEY" | base64 -w0)"
gpg --armor --export "$GPG_KEY" > "$SITO/beviamolo.gpg"
cp "$LAVORO/beviamolo-linux/dev.lab897.beviamolo.png" "$SITO/beviamolo.png"

cat > "$SITO/beviamolo.flatpakref" <<REF
[Flatpak Ref]
Title=Beviamolo
Name=$APP_ID
Branch=$RAMO
Url=$URL_SITO/repo/
SuggestRemoteName=beviamolo
Homepage=https://www.beviamolo.it/
Icon=$URL_SITO/beviamolo.png
RuntimeRepo=https://dl.flathub.org/repo/flathub.flatpakrepo
IsRuntime=false
GPGKey=$CHIAVE
REF

cat > "$SITO/beviamolo.flatpakrepo" <<REPO
[Flatpak Repo]
Title=Beviamolo
Url=$URL_SITO/repo/
Homepage=https://www.beviamolo.it/
Comment=Beviamolo, wine cellar manager
Icon=$URL_SITO/beviamolo.png
DefaultBranch=$RAMO
GPGKey=$CHIAVE
REPO

# Pagina (con font e loghi del sito): si sostituiscono versione e indirizzo
cp -r "$QUI/pagina/." "$SITO/"
sed -i -e "s|@VERSIONE@|$VER|g" -e "s|@URL_SITO@|$URL_SITO|g" "$SITO/index.html"

echo "✓ Sito pronto in $SITO (Beviamolo $VER)"
