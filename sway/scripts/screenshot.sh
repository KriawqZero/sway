#!/bin/bash
# Menu de captura de tela via rofi + grimshot

SAVE_DIR="$HOME/Screenshots"
mkdir -p "$SAVE_DIR"

# Passo 1: o que capturar
capture=$(printf "󰩷  Selecionar região\n󰖯  Janela (selecionar)\n󰖯  Janela ativa\n󰍹  Monitor atual\n󰍺  Todos os monitores" \
    | rofi -dmenu -p "Capturar" -i)

[[ -z "$capture" ]] && exit 0

case "$capture" in
    *"Selecionar região"*)   target="area"   ;;
    *"Janela (selecionar)"*) target="window" ;;
    *"Janela ativa"*)        target="active" ;;
    *"Monitor atual"*)       target="output" ;;
    *"Todos os monitores"*)  target="screen" ;;
    *) exit 0 ;;
esac

# Passo 2: onde salvar
dest=$(printf "󰅇  Clipboard\n󰉖  Arquivo (~/Screenshots)\n󰪶  Ambos" \
    | rofi -dmenu -p "Salvar em" -i)

[[ -z "$dest" ]] && exit 0

FILENAME="$SAVE_DIR/$(date +'%Y-%m-%d_%H-%M-%S').png"

case "$dest" in
    *"Clipboard"*)
        grimshot --notify copy "$target"
        ;;
    *"Arquivo"*)
        grimshot --notify save "$target" "$FILENAME"
        ;;
    *"Ambos"*)
        grimshot --notify savecopy "$target" "$FILENAME"
        ;;
esac
