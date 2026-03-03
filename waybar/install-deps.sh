#!/usr/bin/env bash

set -euo pipefail

echo "=== Instalador de dependências da Waybar (Fedora + Sway) ==="

if ! command -v dnf >/dev/null 2>&1; then
  echo "Erro: este script foi pensado para Fedora (usa 'dnf')."
  exit 1
fi

ask_yes_no() {
  local prompt="$1"
  local default_no="${2:-1}" # 1 = padrão N, 0 = padrão S
  local def_char
  if [[ "$default_no" -eq 1 ]]; then
    def_char="N/s"
  else
    def_char="S/n"
  fi
  while true; do
    read -r -p "$prompt [$def_char] " ans || ans=""
    ans="${ans:-}"
    if [[ -z "$ans" ]]; then
      if [[ "$default_no" -eq 1 ]]; then
        return 1
      else
        return 0
      fi
    fi
    case "${ans,,}" in
      s|sim|y|yes) return 0 ;;
      n|nao|não|no) return 1 ;;
      *) echo "Responda com s ou n." ;;
    esac
  done
}

install_pkg() {
  local pkg="$1"
  echo
  echo "---- Instalando pacote: $pkg ----"
  sudo dnf install -y "$pkg"
}

check_dep() {
  local cmd="$1"
  local pkg="$2"
  local desc="$3"

  if command -v "$cmd" >/dev/null 2>&1; then
    echo "[OK] '$cmd' já está disponível ($desc)"
    return 0
  fi

  echo "[FALTA] Comando '$cmd' não encontrado ($desc)"
  if ask_yes_no "Instalar pacote '$pkg' com sudo dnf install -y?"; then
    install_pkg "$pkg"
  else
    echo ">> Você optou por NÃO instalar '$pkg' agora. O módulo que usa '$cmd' pode não funcionar."
  fi
}

echo
echo "Verificando comandos básicos usados na sua Waybar..."

# Waybar em si (normalmente já vem na spin do Sway)
check_dep "waybar" "waybar" "Barra Waybar"

# Áudio / PipeWire
check_dep "wpctl" "wireplumber" "Controle de volume PipeWire (wpctl)"
check_dep "pavucontrol" "pavucontrol" "Mixer gráfico de áudio (pavucontrol)"

# Terminal e apps de sistema
check_dep "foot" "foot" "Terminal foot (usado por alguns atalhos da Waybar)"
check_dep "btop" "btop" "Monitor de sistema btop (usado pelo módulo de memória)"

# Disco (dua-cli)
check_dep "dua" "dua-cli" "Analizador de disco dua-cli (módulo 'disk')"

# Brilho
check_dep "light" "light" "Controle de brilho 'light' para o módulo backlight"

# Mídia / playerctl
check_dep "playerctl" "playerctl" "Controle de players de mídia (playerctl)"

# Logout / power menu
check_dep "wlogout" "wlogout" "Tela de logout (wlogout)"

# Launcher (walker) – pode não existir em todos os repositórios
echo
echo "Launchers / menu de aplicativos:"
if command -v walker >/dev/null 2>&1; then
  echo "[OK] 'walker' já encontrado (usado pelo módulo custom/launcher)."
else
  echo "[OPCIONAL] O módulo launcher usa 'walker'."
  echo "Se esse pacote não existir no repositório padrão, você pode trocar depois para 'wofi', 'fuzzel' ou outro, editando o 'config.jsonc'."
  if ask_yes_no "Tentar instalar pacote 'walker' via dnf (pode falhar se não existir)?"; then
    install_pkg "walker" || echo "Falha ao instalar 'walker' (talvez não exista na sua base)."
  else
    echo ">> Mantendo como está; ajuste manualmente depois se quiser outro launcher."
  fi
fi

echo
echo "Verificando dependências Python para o script de mídia..."
if python3 -c "import gi; from gi.repository import Playerctl" >/dev/null 2>&1; then
  echo "[OK] Python + gi + Playerctl já disponíveis."
else
  echo "[FALTA] Bindings Python para Playerctl (gi + Playerctl)."
  if ask_yes_no "Instalar bindings Python para Playerctl (python3-gobject + playerctl)?"; then
    install_pkg "python3-gobject"
    install_pkg "playerctl"
  else
    echo ">> Sem essas libs, o módulo 'custom/media' pode não funcionar."
  fi
fi

echo
MEDIA_SCRIPT="$HOME/.config/waybar/modules/mediaplayer.py"
if [[ -f "$MEDIA_SCRIPT" ]]; then
  chmod +x "$MEDIA_SCRIPT" || true
  echo "[OK] Script de mídia encontrado em '$MEDIA_SCRIPT' e marcado como executável."
else
  echo "[AVISO] Script de mídia '$MEDIA_SCRIPT' não encontrado. Verifique se o arquivo existe."
fi

echo
echo "Verificação de dependências concluída."
echo "Reinicie o Sway ou recarregue a Waybar para testar (por exemplo: pkill waybar && waybar &)."

