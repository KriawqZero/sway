#!/usr/bin/env sh

set -eu

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config"

echo "Dotfiles dir: $DOTFILES_DIR"
echo "Config dir:   $CONFIG_DIR"
echo

# garante que ~/.config exista
mkdir -p "$CONFIG_DIR"

link_item() {
    src="$1"
    dest="$2"

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        echo "Removendo existente: $dest"
        rm -rf "$dest"
    fi

    echo "Criando symlink: $dest -> $src"
    ln -s "$src" "$dest"
}

echo "Linkando diretórios..."

for item in "$DOTFILES_DIR"/*; do
    name="$(basename "$item")"

    # pula o próprio script
    [ "$name" = "install-dotfiles.sh" ] && continue

    if [ -d "$item" ]; then
        link_item "$item" "$CONFIG_DIR/$name"
    fi
done

# starship.toml
if [ -f "$DOTFILES_DIR/starship.toml" ]; then
    link_item "$DOTFILES_DIR/starship.toml" "$CONFIG_DIR/starship.toml"
fi

echo
echo "✔ Dotfiles configurados com sucesso."
