#!/usr/bin/env bash
# ==============================================================================
# Dotfiles — Instalação completa de pacotes
# Suporta: Arch Linux, Fedora, Debian / Ubuntu / Mint, Void Linux
# ==============================================================================

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ------------------------------------------------------------------------------
# Cores e helpers
# ------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[ OK ]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERR ]${NC} $*" >&2; }
skip()    { echo -e "${DIM}[SKIP]${NC} $*"; }
optional(){ echo -e "${CYAN}[OPT ]${NC} $*"; }
section() {
  echo -e "\n${BOLD}${BLUE}════════════════════════════════════════════════${NC}"
  echo -e "${BOLD}${BLUE}  $*${NC}"
  echo -e "${BOLD}${BLUE}════════════════════════════════════════════════${NC}"
}

command_exists() { command -v "$1" &>/dev/null; }

# ------------------------------------------------------------------------------
# Banner
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${BLUE}"
cat << 'BANNER'
  ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
  ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝
  ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗
  ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
  ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║
  ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝
BANNER
echo -e "${NC}"
echo -e "${BOLD}  Instalação completa de pacotes${NC}"
echo -e "${DIM}  Neovim · Fish · Sway · Waybar · Foot · Starship · e muito mais${NC}"
echo ""

# ------------------------------------------------------------------------------
# Modo de execução
# ------------------------------------------------------------------------------
AUTO_MODE=false
ONLY_OPTIONAL=false

ask_mode() {
  echo -e "Como deseja executar a instalação?\n"
  echo -e "  ${BOLD}[A]${NC} Automático  — instala tudo sem perguntar"
  echo -e "  ${BOLD}[I]${NC} Interativo  — pergunta antes de cada etapa ${DIM}(padrão)${NC}"
  echo -e "  ${BOLD}[O]${NC} Só opcionais — pula obrigatórios, pergunta apenas os opcionais\n"
  read -r -p "$(echo -e "${YELLOW}Escolha [a/I/o]: ${NC}")" MODE_CHOICE

  case "${MODE_CHOICE,,}" in
    a|auto)
      AUTO_MODE=true
      info "Modo automático ativado — tudo será instalado sem confirmação.\n" ;;
    o|opt|opcionais)
      ONLY_OPTIONAL=true
      info "Modo opcionais — apenas itens opcionais serão perguntados.\n" ;;
    *)
      info "Modo interativo ativado — você será consultado antes de cada passo.\n" ;;
  esac
}

# confirm <descrição> <cmd_display> [optional=false]
confirm() {
  local description="$1"
  local cmd_display="$2"
  local is_optional="${3:-false}"

  if [ "$is_optional" = "false" ] && [ "$ONLY_OPTIONAL" = "true" ]; then
    return 1
  fi

  if [ "$AUTO_MODE" = true ]; then
    return 0
  fi

  local prefix="${BOLD}▸${NC}"
  [ "$is_optional" = "true" ] && prefix="${CYAN}◆ [OPCIONAL]${NC}"

  echo -e "\n${prefix} ${description}"
  echo -e "  ${DIM}Comando:${NC} ${CYAN}${cmd_display}${NC}"
  read -r -p "$(echo -e "  ${YELLOW}Instalar? [Y/n]: ${NC}")" REPLY

  case "${REPLY,,}" in
    n|no|nao|não) return 1 ;;
    *)            return 0 ;;
  esac
}

# ------------------------------------------------------------------------------
# Detectar distro
# ------------------------------------------------------------------------------
detect_distro() {
  if [ ! -f /etc/os-release ]; then
    error "Não foi possível detectar a distribuição Linux (/etc/os-release ausente)."
    exit 1
  fi

  # shellcheck source=/dev/null
  . /etc/os-release
  DISTRO_ID="${ID}"
  DISTRO_LIKE="${ID_LIKE:-}"

  case "$DISTRO_ID" in
    arch|manjaro|endeavouros|garuda|cachyos|artix)
      PKG_MANAGER="arch" ;;
    fedora|rhel|centos|almalinux|rocky)
      PKG_MANAGER="fedora" ;;
    debian|ubuntu|linuxmint|pop|elementary|kali|zorin|neon|raspbian)
      PKG_MANAGER="debian" ;;
    void)
      PKG_MANAGER="void" ;;
    *)
      case "$DISTRO_LIKE" in
        *arch*)            PKG_MANAGER="arch"   ;;
        *fedora*|*rhel*)   PKG_MANAGER="fedora" ;;
        *debian*|*ubuntu*) PKG_MANAGER="debian" ;;
        *void*)            PKG_MANAGER="void"   ;;
        *)
          error "Distribuição não suportada: ${DISTRO_ID}"
          error "Suportadas: Arch, Fedora, Debian/Ubuntu/Mint, Void Linux"
          exit 1 ;;
      esac ;;
  esac

  info "Distribuição: ${BOLD}${DISTRO_ID}${NC}  |  Gerenciador: ${BOLD}${PKG_MANAGER}${NC}"
}

# ------------------------------------------------------------------------------
# Wrappers do gerenciador de pacotes
# ------------------------------------------------------------------------------
pkg_install() {
  case "$PKG_MANAGER" in
    arch)   sudo pacman -S --needed --noconfirm "$@" ;;
    fedora) sudo dnf install -y "$@" ;;
    debian) sudo apt-get install -y "$@" ;;
    void)   sudo xbps-install -Sy "$@" ;;
  esac
}

pkg_update() {
  case "$PKG_MANAGER" in
    arch)   sudo pacman -Syu --noconfirm ;;
    fedora) sudo dnf check-update -y || true ;;
    debian) sudo apt-get update -y ;;
    void)   sudo xbps-install -Su ;;
  esac
}

pkg_cmd_str() {
  case "$PKG_MANAGER" in
    arch)   echo "sudo pacman -S --needed --noconfirm $*" ;;
    fedora) echo "sudo dnf install -y $*" ;;
    debian) echo "sudo apt-get install -y $*" ;;
    void)   echo "sudo xbps-install -Sy $*" ;;
  esac
}

# Tenta instalar sem falhar caso o pacote não exista no repo
pkg_try() {
  case "$PKG_MANAGER" in
    arch)   sudo pacman -S --needed --noconfirm "$@" 2>/dev/null && return 0 ;;
    fedora) sudo dnf install -y "$@" 2>/dev/null && return 0 ;;
    debian) sudo apt-get install -y "$@" 2>/dev/null && return 0 ;;
    void)   sudo xbps-install -Sy "$@" 2>/dev/null && return 0 ;;
  esac
  warn "Pacote não encontrado no repositório: $*"
  return 1
}

# ==============================================================================
ask_mode
detect_distro

# ==============================================================================
# 1. Atualizar repositórios
# ==============================================================================
section "1/24 · Atualizar repositórios"

case "$PKG_MANAGER" in
  arch)   UPDATE_CMD="sudo pacman -Syu --noconfirm" ;;
  fedora) UPDATE_CMD="sudo dnf check-update" ;;
  debian) UPDATE_CMD="sudo apt-get update" ;;
  void)   UPDATE_CMD="sudo xbps-install -Su" ;;
esac

if confirm "Atualizar lista de pacotes" "$UPDATE_CMD"; then
  pkg_update
  success "Repositórios atualizados"
else
  skip "Atualização ignorada"
fi

# ==============================================================================
# 2. Ferramentas base
# ==============================================================================
section "2/24 · Ferramentas base (git, curl, ripgrep, fd, build tools)"

case "$PKG_MANAGER" in
  arch)   BASE_PKGS="git curl wget unzip tar gzip ripgrep fd base-devel" ;;
  fedora) BASE_PKGS="git curl wget unzip tar gzip ripgrep fd-find @development-tools" ;;
  debian) BASE_PKGS="git curl wget unzip tar gzip ripgrep fd-find build-essential" ;;
  void)   BASE_PKGS="git curl wget unzip tar gzip ripgrep fd base-devel" ;;
esac

if confirm "Instalar ferramentas base" "$(pkg_cmd_str $BASE_PKGS)"; then
  # shellcheck disable=SC2086
  pkg_install $BASE_PKGS
  success "Ferramentas base instaladas"

  # Debian/Ubuntu: fd está como fd-find; criar symlink se necessário
  if [ "$PKG_MANAGER" = "debian" ] && ! command_exists fd && command_exists fdfind; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    info "Symlink criado: ~/.local/bin/fd → fdfind"
  fi
else
  skip "Ferramentas base ignoradas"
fi

# ==============================================================================
# 3. Compiladores C/C++ + clangd  (necessários para Treesitter)
# ==============================================================================
section "3/24 · Compiladores C/C++ e clangd"

case "$PKG_MANAGER" in
  arch)   CC_PKGS="gcc clang llvm";         CLANGD_PKG="clang" ;;
  fedora) CC_PKGS="gcc gcc-c++ clang llvm"; CLANGD_PKG="clang-tools-extra" ;;
  debian) CC_PKGS="gcc g++ clang llvm";     CLANGD_PKG="clangd" ;;
  void)   CC_PKGS="gcc clang llvm";         CLANGD_PKG="clang-tools-extra" ;;
esac

if confirm "Instalar compiladores (gcc, clang, llvm)" "$(pkg_cmd_str $CC_PKGS)"; then
  # shellcheck disable=SC2086
  pkg_install $CC_PKGS
  success "Compiladores instalados"
else
  skip "Compiladores ignorados"
fi

if ! command_exists clangd; then
  if confirm "Instalar clangd (LSP C/C++)" "$(pkg_cmd_str $CLANGD_PKG)"; then
    pkg_install "$CLANGD_PKG"
    success "clangd instalado"
  else
    skip "clangd ignorado"
  fi
else
  warn "clangd já instalado: $(command -v clangd)"
fi

# ==============================================================================
# 4. Neovim
# ==============================================================================
section "4/24 · Neovim"

if command_exists nvim; then
  warn "Neovim já instalado: $(nvim --version | head -1)"
else
  if confirm "Instalar Neovim" "$(pkg_cmd_str neovim)"; then
    pkg_install neovim
    success "Neovim instalado: $(nvim --version | head -1)"
  else
    skip "Neovim ignorado"
  fi
fi

# ==============================================================================
# 5. Node.js e npm
# ==============================================================================
section "5/24 · Node.js e npm"

if command_exists node; then
  warn "Node.js já instalado: $(node --version)"
else
  case "$PKG_MANAGER" in
    arch|fedora|void)
      if confirm "Instalar Node.js e npm" "$(pkg_cmd_str nodejs npm)"; then
        pkg_install nodejs npm
        success "Node.js instalado: $(node --version)"
      else
        skip "Node.js ignorado"
      fi ;;
    debian)
      NODESOURCE_CMD="curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -"
      if confirm "Instalar Node.js LTS via NodeSource (repositório oficial)" "$NODESOURCE_CMD"; then
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        pkg_install nodejs
        success "Node.js instalado: $(node --version)"
      else
        skip "Node.js ignorado"
      fi ;;
  esac
fi

# ==============================================================================
# 6. Python 3
# ==============================================================================
section "6/24 · Python 3"

if command_exists python3; then
  warn "Python já instalado: $(python3 --version)"
else
  case "$PKG_MANAGER" in
    arch)   PY_PKGS="python python-pip" ;;
    fedora) PY_PKGS="python3 python3-pip" ;;
    debian) PY_PKGS="python3 python3-pip python3-venv" ;;
    void)   PY_PKGS="python3 python3-pip" ;;
  esac

  if confirm "Instalar Python 3 e pip" "$(pkg_cmd_str $PY_PKGS)"; then
    # shellcheck disable=SC2086
    pkg_install $PY_PKGS
    success "Python instalado: $(python3 --version)"
  else
    skip "Python ignorado"
  fi
fi

# ==============================================================================
# 7. Go
# ==============================================================================
section "7/24 · Go"

if command_exists go; then
  warn "Go já instalado: $(go version)"
else
  case "$PKG_MANAGER" in
    arch|void) GO_PKG="go" ;;
    fedora)    GO_PKG="golang" ;;
    debian)    GO_PKG="golang-go" ;;
  esac

  if confirm "Instalar Go" "$(pkg_cmd_str $GO_PKG)"; then
    pkg_install "$GO_PKG"
    success "Go instalado: $(go version)"
  else
    skip "Go ignorado"
  fi
fi

if command_exists go && [ -z "${GOPATH:-}" ]; then
  export GOPATH="$HOME/go"
  export PATH="$PATH:$GOPATH/bin"
fi

# ==============================================================================
# 8. Rust (rustup)
# ==============================================================================
section "8/24 · Rust (rustup)"

if command_exists rustup; then
  warn "rustup já instalado. Atualizando toolchain..."
  rustup update stable
elif command_exists cargo; then
  warn "cargo já disponível: $(cargo --version)"
else
  RUSTUP_CMD="curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path"
  if confirm "Instalar Rust via rustup (cargo, rustc, rustfmt)" "$RUSTUP_CMD"; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env"
    success "Rust instalado: $(rustc --version)"
  else
    skip "Rust ignorado"
  fi
fi

[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

if command_exists rustup; then
  if confirm "Instalar clippy + rustfmt" "rustup component add clippy rustfmt"; then
    rustup component add clippy rustfmt
    success "clippy + rustfmt instalados"
  fi
fi

# ==============================================================================
# 9. Servidores LSP via npm
# ==============================================================================
section "9/24 · Servidores LSP via npm"

npm_step() {
  local description="$1"
  local pkg="$2"
  local bin="${3:-$2}"

  if ! command_exists npm; then
    warn "npm não encontrado — pulando $pkg"
    return
  fi

  if command_exists "$bin"; then
    warn "$bin já instalado: $(command -v "$bin")"
    return
  fi

  if confirm "$description" "sudo npm install -g $pkg"; then
    sudo npm install -g "$pkg"
    success "$pkg instalado"
  else
    skip "$pkg ignorado"
  fi
}

npm_step "intelephense — LSP para PHP"                         intelephense
npm_step "typescript — compilador TypeScript"                  typescript                    tsc
npm_step "typescript-language-server — LSP para TS/JS"         typescript-language-server    typescript-language-server
npm_step "eslint — linter JavaScript/TypeScript"               eslint
npm_step "pyright — LSP para Python"                           pyright
npm_step "vscode-langservers-extracted — LSP HTML/CSS/JSON"    vscode-langservers-extracted  vscode-html-language-server
npm_step "prettier — formatador JS/TS/CSS/HTML"                prettier
npm_step "blade-formatter — formatador para Blade (Laravel)"   blade-formatter               blade-formatter

# ==============================================================================
# 10. rust-analyzer
# ==============================================================================
section "10/24 · rust-analyzer (LSP Rust)"

if command_exists rust-analyzer; then
  warn "rust-analyzer já instalado"
else
  case "$PKG_MANAGER" in
    arch|fedora|void)
      if confirm "Instalar rust-analyzer" "$(pkg_cmd_str rust-analyzer)"; then
        pkg_install rust-analyzer
        success "rust-analyzer instalado"
      else
        skip "rust-analyzer ignorado"
      fi ;;
    debian)
      if command_exists rustup; then
        if confirm "Instalar rust-analyzer via rustup" "rustup component add rust-analyzer"; then
          rustup component add rust-analyzer
          success "rust-analyzer instalado via rustup"
        else
          skip "rust-analyzer ignorado"
        fi
      else
        warn "rustup não encontrado — instale Rust primeiro"
      fi ;;
  esac
fi

# ==============================================================================
# 11. Ferramentas Go (gopls, staticcheck, gofumpt)
# ==============================================================================
section "11/24 · Ferramentas Go (gopls, staticcheck, gofumpt)"

go_step() {
  local bin="$1"
  local pkg="$2"

  if ! command_exists go; then
    warn "go não encontrado — pulando $bin"
    return
  fi

  if command_exists "$bin"; then
    warn "$bin já instalado: $(command -v "$bin")"
    return
  fi

  if confirm "Instalar $bin" "go install $pkg"; then
    go install "$pkg"
    success "$bin instalado"
  else
    skip "$bin ignorado"
  fi
}

go_step gopls        golang.org/x/tools/gopls@latest
go_step staticcheck  honnef.co/go/tools/cmd/staticcheck@latest
go_step gofumpt      mvdan.cc/gofumpt@latest

# ==============================================================================
# 12. Formatadores de código
# ==============================================================================
section "12/24 · Formatadores (stylua, black, php-cs-fixer)"

# stylua
if command_exists stylua; then
  warn "stylua já instalado: $(command -v stylua)"
else
  STYLUA_DONE=false

  case "$PKG_MANAGER" in
    arch|void)
      if confirm "Instalar stylua (formatador Lua)" "$(pkg_cmd_str stylua)"; then
        pkg_try stylua && STYLUA_DONE=true
      fi ;;
  esac

  if [ "$STYLUA_DONE" = false ] && command_exists cargo; then
    if confirm "Instalar stylua via cargo" "cargo install stylua"; then
      cargo install stylua
      success "stylua instalado"
      STYLUA_DONE=true
    fi
  fi

  [ "$STYLUA_DONE" = false ] && warn "stylua não instalado (instale Rust/cargo para usar cargo install stylua)"
fi

# black
if command_exists black; then
  warn "black já instalado: $(command -v black)"
else
  PIP_CMD=""
  command_exists pip3 && PIP_CMD="pip3" || command_exists pip && PIP_CMD="pip"

  if [ -n "$PIP_CMD" ]; then
    if confirm "Instalar black (formatador Python)" "$PIP_CMD install --user black"; then
      $PIP_CMD install --user black
      success "black instalado"
    else
      skip "black ignorado"
    fi
  else
    warn "pip não encontrado — instale Python primeiro"
  fi
fi

# php-cs-fixer (opcional)
if ! command_exists php-cs-fixer && command_exists composer; then
  if confirm "Instalar php-cs-fixer (formatador PHP via composer)" \
             "composer global require friendsofphp/php-cs-fixer" "true"; then
    composer global require friendsofphp/php-cs-fixer
    success "php-cs-fixer instalado"
  else
    skip "php-cs-fixer ignorado"
  fi
fi

# ==============================================================================
# 13. Fish shell
# ==============================================================================
section "13/24 · Fish shell"

if command_exists fish; then
  warn "fish já instalado: $(command -v fish)"
else
  case "$PKG_MANAGER" in
    arch|fedora|debian) FISH_PKG="fish" ;;
    void)               FISH_PKG="fish-shell" ;;
  esac

  if confirm "Instalar fish shell" "$(pkg_cmd_str $FISH_PKG)"; then
    pkg_install "$FISH_PKG"
    success "fish instalado"
  else
    skip "fish ignorado"
  fi
fi

# Definir fish como shell padrão
if command_exists fish && [ "$SHELL" != "$(command -v fish)" ]; then
  FISH_PATH="$(command -v fish)"
  if ! grep -qF "$FISH_PATH" /etc/shells 2>/dev/null; then
    echo "$FISH_PATH" | sudo tee -a /etc/shells > /dev/null
    info "fish adicionado a /etc/shells"
  fi
  if confirm "Definir fish como shell padrão" "chsh -s $FISH_PATH"; then
    chsh -s "$FISH_PATH"
    success "Shell padrão definido: fish"
  else
    skip "Shell padrão não alterado"
  fi
fi

# ==============================================================================
# 14. Starship (prompt)
# ==============================================================================
section "14/24 · Starship (prompt)"

if command_exists starship; then
  warn "starship já instalado: $(starship --version)"
else
  case "$PKG_MANAGER" in
    arch|fedora|void)
      if confirm "Instalar starship" "$(pkg_cmd_str starship)"; then
        pkg_install starship
        success "starship instalado"
      else
        skip "starship ignorado"
      fi ;;
    debian)
      STARSHIP_CMD="curl -sS https://starship.rs/install.sh | sh -s -- -y"
      if confirm "Instalar starship via script oficial" "$STARSHIP_CMD"; then
        curl -sS https://starship.rs/install.sh | sh -s -- -y
        success "starship instalado"
      else
        skip "starship ignorado"
      fi ;;
  esac
fi

# ==============================================================================
# 15. Foot (terminal)
# ==============================================================================
section "15/24 · Foot (terminal)"

if command_exists foot; then
  warn "foot já instalado"
else
  if confirm "Instalar foot (terminal Wayland)" "$(pkg_cmd_str foot)"; then
    pkg_install foot
    success "foot instalado"
  else
    skip "foot ignorado"
  fi
fi

# ==============================================================================
# 16. Sway + ferramentas Wayland
# ==============================================================================
section "16/24 · Sway (compositor Wayland) + ferramentas"

# sway
if command_exists sway; then
  warn "sway já instalado"
else
  if confirm "Instalar sway (compositor Wayland)" "$(pkg_cmd_str sway)"; then
    pkg_install sway
    success "sway instalado"
  else
    skip "sway ignorado"
  fi
fi

# swaylock
if command_exists swaylock; then
  warn "swaylock já instalado"
else
  if confirm "Instalar swaylock (tela de bloqueio)" "$(pkg_cmd_str swaylock)"; then
    pkg_install swaylock
    success "swaylock instalado"
  else
    skip "swaylock ignorado"
  fi
fi

# grim + slurp (screenshots)
for _TOOL in grim slurp; do
  if command_exists "$_TOOL"; then
    warn "$_TOOL já instalado"
  else
    if confirm "Instalar $_TOOL (screenshots no Sway)" "$(pkg_cmd_str $_TOOL)"; then
      pkg_install "$_TOOL"
      success "$_TOOL instalado"
    else
      skip "$_TOOL ignorado"
    fi
  fi
done

# wl-clipboard
if command_exists wl-copy; then
  warn "wl-clipboard já instalado"
else
  if confirm "Instalar wl-clipboard (clipboard Wayland)" "$(pkg_cmd_str wl-clipboard)"; then
    pkg_install wl-clipboard
    success "wl-clipboard instalado"
  else
    skip "wl-clipboard ignorado"
  fi
fi

# ==============================================================================
# 17. Waybar e dependências
# ==============================================================================
section "17/24 · Waybar (barra de status) e dependências"

# waybar
if command_exists waybar; then
  warn "waybar já instalado"
else
  if confirm "Instalar waybar" "$(pkg_cmd_str waybar)"; then
    pkg_install waybar
    success "waybar instalado"
  else
    skip "waybar ignorado"
  fi
fi

# wireplumber (wpctl)
if command_exists wpctl; then
  warn "wireplumber já instalado"
else
  if confirm "Instalar wireplumber (controle de áudio PipeWire)" "$(pkg_cmd_str wireplumber)"; then
    pkg_install wireplumber
    success "wireplumber instalado"
  else
    skip "wireplumber ignorado"
  fi
fi

# pavucontrol
if command_exists pavucontrol; then
  warn "pavucontrol já instalado"
else
  if confirm "Instalar pavucontrol (mixer gráfico de áudio)" "$(pkg_cmd_str pavucontrol)"; then
    pkg_install pavucontrol
    success "pavucontrol instalado"
  else
    skip "pavucontrol ignorado"
  fi
fi

# playerctl
if command_exists playerctl; then
  warn "playerctl já instalado"
else
  if confirm "Instalar playerctl (controle de mídia)" "$(pkg_cmd_str playerctl)"; then
    pkg_install playerctl
    success "playerctl instalado"
  else
    skip "playerctl ignorado"
  fi
fi

# light (controle de brilho)
if command_exists light; then
  warn "light já instalado"
else
  if confirm "Instalar light (controle de brilho)" "$(pkg_cmd_str light)"; then
    pkg_install light
    success "light instalado"
    info "Para usar sem sudo, adicione seu usuário ao grupo video:"
    info "  sudo usermod -aG video \$USER  (requer logout/login)"
  else
    skip "light ignorado"
  fi
fi

# wlogout
if command_exists wlogout; then
  warn "wlogout já instalado"
else
  WLOGOUT_DONE=false

  case "$PKG_MANAGER" in
    arch)
      if command_exists yay || command_exists paru; then
        AUR_HELPER=$(command_exists yay && echo yay || echo paru)
        if confirm "Instalar wlogout via AUR ($AUR_HELPER)" \
                   "$AUR_HELPER -S --noconfirm wlogout" "true"; then
          $AUR_HELPER -S --noconfirm wlogout && WLOGOUT_DONE=true
        fi
      else
        optional "wlogout: instale via AUR (yay/paru -S wlogout)"
      fi ;;
    fedora)
      if confirm "Instalar wlogout" "$(pkg_cmd_str wlogout)" "true"; then
        pkg_try wlogout && WLOGOUT_DONE=true || \
          optional "wlogout não encontrado no repo. Tente: https://github.com/ArtsyMacaw/wlogout"
      fi ;;
    debian)
      optional "wlogout não está nos repositórios padrão do Debian/Ubuntu."
      optional "Instale manualmente: https://github.com/ArtsyMacaw/wlogout" ;;
    void)
      if confirm "Instalar wlogout" "$(pkg_cmd_str wlogout)" "true"; then
        pkg_try wlogout && WLOGOUT_DONE=true || \
          optional "wlogout não encontrado no repo Void"
      fi ;;
  esac
fi

# python3-gobject (para mediaplayer.py da waybar)
PYGOBJECT_OK=false
python3 -c "import gi" &>/dev/null && PYGOBJECT_OK=true

if [ "$PYGOBJECT_OK" = true ]; then
  warn "python3-gobject já instalado"
else
  case "$PKG_MANAGER" in
    arch)   PYGOBJECT_PKG="python-gobject" ;;
    fedora) PYGOBJECT_PKG="python3-gobject" ;;
    debian) PYGOBJECT_PKG="python3-gi" ;;
    void)   PYGOBJECT_PKG="python3-gobject" ;;
  esac

  if confirm "Instalar python3-gobject (módulo mediaplayer da Waybar)" \
             "$(pkg_cmd_str $PYGOBJECT_PKG)"; then
    pkg_install "$PYGOBJECT_PKG"
    success "python3-gobject instalado"
  else
    skip "python3-gobject ignorado"
  fi
fi

# ==============================================================================
# 18. Rofi (launcher)
# ==============================================================================
section "18/24 · Rofi (launcher de aplicativos)"

if command_exists rofi; then
  warn "rofi já instalado"
else
  case "$PKG_MANAGER" in
    arch|fedora) ROFI_PKG="rofi-wayland" ;;
    debian|void) ROFI_PKG="rofi" ;;
  esac

  if confirm "Instalar rofi (launcher)" "$(pkg_cmd_str $ROFI_PKG)"; then
    if ! pkg_try "$ROFI_PKG" && [ "$ROFI_PKG" = "rofi-wayland" ]; then
      info "rofi-wayland não encontrado, tentando rofi..."
      pkg_try rofi || warn "rofi não pôde ser instalado"
    fi
    command_exists rofi && success "rofi instalado"
  else
    skip "rofi ignorado"
  fi
fi

# ==============================================================================
# 19. Apps de desktop (btop, thunar, qalculate)
# ==============================================================================
section "19/24 · Apps de desktop (btop, thunar, qalculate)"

# btop
if command_exists btop; then
  warn "btop já instalado"
else
  if confirm "Instalar btop (monitor de sistema)" "$(pkg_cmd_str btop)"; then
    pkg_install btop
    success "btop instalado"
  else
    skip "btop ignorado"
  fi
fi

# thunar
if command_exists thunar; then
  warn "thunar já instalado"
else
  if confirm "Instalar thunar (gerenciador de arquivos)" "$(pkg_cmd_str thunar)"; then
    pkg_install thunar
    success "thunar instalado"
  else
    skip "thunar ignorado"
  fi
fi

# qalculate
if command_exists qalc || command_exists qalculate-gtk; then
  warn "qalculate já instalado"
else
  if confirm "Instalar qalculate-gtk (calculadora)" "$(pkg_cmd_str qalculate-gtk)"; then
    pkg_install qalculate-gtk
    success "qalculate instalado"
  else
    skip "qalculate ignorado"
  fi
fi

# ==============================================================================
# 20. Ferramentas de shell (direnv, zoxide, eza, lazygit, dua-cli)
# ==============================================================================
section "20/24 · Ferramentas de shell"

# direnv
if command_exists direnv; then
  warn "direnv já instalado"
else
  if confirm "Instalar direnv (env vars por diretório)" "$(pkg_cmd_str direnv)"; then
    pkg_install direnv
    success "direnv instalado"
  else
    skip "direnv ignorado"
  fi
fi

# zoxide
if command_exists zoxide; then
  warn "zoxide já instalado"
else
  if confirm "Instalar zoxide (cd inteligente)" "$(pkg_cmd_str zoxide)"; then
    pkg_install zoxide
    success "zoxide instalado"
  else
    skip "zoxide ignorado"
  fi
fi

# eza
if command_exists eza; then
  warn "eza já instalado"
else
  EZA_DONE=false

  if confirm "Instalar eza (ls moderno com ícones)" "$(pkg_cmd_str eza)"; then
    pkg_try eza && EZA_DONE=true
  fi

  if [ "$EZA_DONE" = false ] && command_exists cargo; then
    if confirm "Instalar eza via cargo (fallback)" "cargo install eza"; then
      cargo install eza
      success "eza instalado via cargo"
      EZA_DONE=true
    fi
  fi

  [ "$EZA_DONE" = false ] && warn "eza não instalado"
fi

# lazygit
if command_exists lazygit; then
  warn "lazygit já instalado"
else
  LAZYGIT_DONE=false

  case "$PKG_MANAGER" in
    arch)
      if confirm "Instalar lazygit" "$(pkg_cmd_str lazygit)"; then
        pkg_install lazygit && LAZYGIT_DONE=true
      fi ;;
    fedora)
      if confirm "Instalar lazygit" "$(pkg_cmd_str lazygit)"; then
        pkg_try lazygit && LAZYGIT_DONE=true
      fi ;;
    debian|void)
      : ;;
  esac

  # Fallback: baixar binário do GitHub
  if ! $LAZYGIT_DONE && ! command_exists lazygit; then
    LG_FALLBACK_CMD="curl (binário do GitHub jesseduffield/lazygit)"
    if confirm "Instalar lazygit via binário do GitHub" "$LG_FALLBACK_CMD"; then
      info "Buscando versão mais recente do lazygit..."
      LG_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
        | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
      LG_TMP=$(mktemp -d)
      curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VERSION}/lazygit_${LG_VERSION}_Linux_x86_64.tar.gz" \
        | tar xz -C "$LG_TMP"
      sudo install "$LG_TMP/lazygit" /usr/local/bin/lazygit
      rm -rf "$LG_TMP"
      success "lazygit instalado: $(lazygit --version)"
    else
      skip "lazygit ignorado"
    fi
  fi
fi

# dua-cli
if command_exists dua; then
  warn "dua já instalado"
else
  DUA_DONE=false

  case "$PKG_MANAGER" in
    arch|void)
      if confirm "Instalar dua-cli (analisador de disco)" "$(pkg_cmd_str dua-cli)"; then
        pkg_try dua-cli && command_exists dua && DUA_DONE=true
      fi ;;
  esac

  if [ "$DUA_DONE" = false ] && command_exists cargo; then
    if confirm "Instalar dua-cli via cargo" "cargo install dua-cli"; then
      cargo install dua-cli
      success "dua-cli instalado"
      DUA_DONE=true
    fi
  fi

  [ "$DUA_DONE" = false ] && optional "dua-cli: instale via cargo (cargo install dua-cli)"
fi

# ==============================================================================
# 21. JetBrains Mono Nerd Font  (fonte configurada no foot.ini)
# ==============================================================================
section "21/24 · JetBrains Mono Nerd Font"

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

if fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd\|JetBrains Mono Nerd"; then
  warn "JetBrains Mono Nerd Font já instalada"
else
  JBM_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
  if confirm "Instalar JetBrains Mono Nerd Font (fonte do terminal foot)" "$JBM_URL"; then
    info "Baixando JetBrains Mono Nerd Font..."
    curl -fLo /tmp/JetBrainsMono.zip "$JBM_URL"
    unzip -o /tmp/JetBrainsMono.zip -d "$FONT_DIR/JetBrainsMonoNerdFont" "*.ttf" 2>/dev/null || true
    rm -f /tmp/JetBrainsMono.zip
    fc-cache -fv "$FONT_DIR" &>/dev/null
    success "JetBrains Mono Nerd Font instalada"
  else
    skip "JetBrains Mono Nerd Font ignorada"
  fi
fi

# Hack Nerd Font (ícones do dashboard Neovim)
if fc-list 2>/dev/null | grep -qi "Hack Nerd\|HackNerd"; then
  warn "Hack Nerd Font já instalada"
else
  HACK_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip"
  if confirm "Instalar Hack Nerd Font (ícones do dashboard Neovim)" "$HACK_URL"; then
    info "Baixando Hack Nerd Font..."
    curl -fLo /tmp/HackNerdFont.zip "$HACK_URL"
    unzip -o /tmp/HackNerdFont.zip -d "$FONT_DIR/HackNerdFont" "*.ttf" 2>/dev/null || true
    rm -f /tmp/HackNerdFont.zip
    fc-cache -fv "$FONT_DIR" &>/dev/null
    success "Hack Nerd Font instalada"
  else
    skip "Hack Nerd Font ignorada"
  fi
fi

# ==============================================================================
# 22. Cursor theme: Bibata-Modern-Classic
# ==============================================================================
section "22/24 · Cursor theme: Bibata-Modern-Classic"

BIBATA_INSTALLED=false
{ [ -d "$HOME/.local/share/icons/Bibata-Modern-Classic" ] || \
  [ -d "/usr/share/icons/Bibata-Modern-Classic" ]; } && BIBATA_INSTALLED=true

if [ "$BIBATA_INSTALLED" = true ]; then
  warn "Bibata-Modern-Classic já instalado"
else
  case "$PKG_MANAGER" in
    arch)
      if command_exists yay || command_exists paru; then
        AUR_HELPER=$(command_exists yay && echo yay || echo paru)
        if confirm "Instalar Bibata-Modern-Classic cursor via AUR ($AUR_HELPER)" \
                   "$AUR_HELPER -S --noconfirm bibata-cursor-theme" "true"; then
          $AUR_HELPER -S --noconfirm bibata-cursor-theme && BIBATA_INSTALLED=true
        fi
      fi ;;
  esac

  if [ "$BIBATA_INSTALLED" = false ]; then
    BIBATA_CMD="download de https://github.com/ful1e5/Bibata_Cursor/releases/latest"
    if confirm "Instalar Bibata-Modern-Classic cursor via download do GitHub" \
               "$BIBATA_CMD" "true"; then
      info "Buscando URL do release mais recente..."
      BIBATA_URL=$(curl -s "https://api.github.com/repos/ful1e5/Bibata_Cursor/releases/latest" \
        | grep "browser_download_url.*Bibata-Modern-Classic\.tar\.xz" \
        | cut -d '"' -f4)

      if [ -z "$BIBATA_URL" ]; then
        BIBATA_URL="https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Classic.tar.xz"
      fi

      BIBATA_TMP=$(mktemp -d)
      curl -fL "$BIBATA_URL" -o "$BIBATA_TMP/Bibata-Modern-Classic.tar.xz"
      mkdir -p "$HOME/.local/share/icons"
      tar -xJf "$BIBATA_TMP/Bibata-Modern-Classic.tar.xz" -C "$HOME/.local/share/icons/"
      rm -rf "$BIBATA_TMP"
      success "Bibata-Modern-Classic instalado em ~/.local/share/icons/"

      # Configurar como cursor padrão
      mkdir -p "$HOME/.local/share/icons/default"
      printf '[Icon Theme]\nInherits=Bibata-Modern-Classic\n' \
        > "$HOME/.local/share/icons/default/index.theme"

      if command_exists gsettings; then
        gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true
      fi
    else
      skip "Bibata cursor ignorado"
    fi
  fi
fi

# ==============================================================================
# 23. Fisher e plugins Fish
# ==============================================================================
section "23/24 · Fisher (gerenciador de plugins Fish) e plugins"

if ! command_exists fish; then
  warn "fish não encontrado — pulando fisher e plugins"
else
  # Instalar fisher
  FISHER_OK=false
  fish -c "functions -q fisher" 2>/dev/null && FISHER_OK=true

  if [ "$FISHER_OK" = false ]; then
    FISHER_CMD="curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | fish"
    if confirm "Instalar fisher (gerenciador de plugins fish)" "$FISHER_CMD"; then
      curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | fish
      success "fisher instalado"
      FISHER_OK=true
    else
      skip "fisher ignorado"
    fi
  else
    warn "fisher já instalado"
  fi

  # Instalar plugins via fish_plugins
  FISH_PLUGINS_FILE="$DOTFILES_DIR/fish/fish_plugins"
  if [ "$FISHER_OK" = true ] && [ -f "$FISH_PLUGINS_FILE" ]; then
    if confirm "Instalar plugins fish (nvm.fish, etc.) via fisher" \
               "fish -c 'fisher install < $FISH_PLUGINS_FILE'"; then
      mkdir -p "$HOME/.config/fish"
      # Garante que o arquivo de plugins exista em ~/.config antes de rodar fisher
      if [ ! -e "$HOME/.config/fish/fish_plugins" ]; then
        cp "$FISH_PLUGINS_FILE" "$HOME/.config/fish/fish_plugins"
      fi
      fish -c "fisher install < $FISH_PLUGINS_FILE" 2>/dev/null || \
        fish -c "fisher update" 2>/dev/null || true
      success "Plugins fish instalados"
    else
      skip "Plugins fish ignorados"
    fi
  fi
fi

# ==============================================================================
# 24. Symlinks das dotfiles (~/.config)
# ==============================================================================
section "24/24 · Criando symlinks em ~/.config"

if confirm "Criar symlinks via install_dotfiles.sh" \
           "bash $DOTFILES_DIR/install_dotfiles.sh"; then
  # Inicializa submódulo do nvim se necessário
  if [ -d "$DOTFILES_DIR/.git" ]; then
    info "Inicializando submódulos git (nvim)..."
    git -C "$DOTFILES_DIR" submodule update --init --recursive 2>/dev/null || \
      warn "Não foi possível inicializar submódulos (verifique acesso SSH ao github.com)"
  fi

  bash "$DOTFILES_DIR/install_dotfiles.sh"
  success "Symlinks criados em ~/.config"

  # Marca scripts como executáveis
  chmod +x "$HOME/.config/waybar/modules/"*.py 2>/dev/null || true
  chmod +x "$HOME/.config/sway/scripts/"*.sh 2>/dev/null || true
  chmod +x "$HOME/.config/rofi/"*.sh 2>/dev/null || true
  info "Permissões de execução aplicadas nos scripts da waybar/sway/rofi"

  # Sistema de modos visuais
  info "Instalando scripts de modos visuais (marcilio-mode / marcilio-menu)..."
  mkdir -p "$HOME/.local/bin"
  chmod +x "$DOTFILES_DIR/scripts/marcilio-mode" "$DOTFILES_DIR/scripts/marcilio-menu" 2>/dev/null || true
  ln -sf "$DOTFILES_DIR/scripts/marcilio-mode" "$HOME/.local/bin/marcilio-mode"
  ln -sf "$DOTFILES_DIR/scripts/marcilio-menu" "$HOME/.local/bin/marcilio-menu"

  # Estado inicial do modo normal
  mkdir -p "$HOME/.local/share/marcilio-mode"
  [ ! -f "$HOME/.local/share/marcilio-mode/current" ] && \
    echo "normal" > "$HOME/.local/share/marcilio-mode/current"
  [ ! -f "$HOME/.local/share/marcilio-mode/wallpaper" ] && \
    echo "$HOME/Wallpapers/background" > "$HOME/.local/share/marcilio-mode/wallpaper"

  # Symlinks ativos (modo normal como padrão)
  ln -sf "$DOTFILES_DIR/modes/normal/waybar.jsonc"  "$DOTFILES_DIR/waybar/config.jsonc"
  ln -sf "$DOTFILES_DIR/modes/normal/waybar.css"    "$DOTFILES_DIR/waybar/style.css"
  ln -sf "$DOTFILES_DIR/modes/normal/rofi.rasi"     "$DOTFILES_DIR/rofi/theme.rasi"
  ln -sf "$DOTFILES_DIR/modes/normal/sway.inc"      "$DOTFILES_DIR/sway/config.d/99-mode.conf"
  success "Scripts instalados em ~/.local/bin e modo 'normal' ativado"
else
  skip "Symlinks ignorados"
fi

# ==============================================================================
# Resumo final
# ==============================================================================
section "Verificação final"
echo ""

check_cmd() {
  local label="$1"
  local cmd="$2"
  if command_exists "$cmd"; then
    success "${BOLD}${label}${NC}: $(command -v "$cmd")"
  else
    warn "${BOLD}${label}${NC}: não encontrado  ${DIM}(reinicie o terminal se acabou de instalar)${NC}"
  fi
}

echo -e "${BOLD}── Essenciais ──────────────────────────────────${NC}"
check_cmd "nvim"      nvim
check_cmd "git"       git
check_cmd "rg"        rg
check_cmd "fd"        fd

echo -e "\n${BOLD}── Shell & Prompt ──────────────────────────────${NC}"
check_cmd "fish"      fish
check_cmd "starship"  starship
check_cmd "direnv"    direnv
check_cmd "zoxide"    zoxide
check_cmd "eza"       eza
check_cmd "lazygit"   lazygit
check_cmd "dua"       dua

echo -e "\n${BOLD}── Wayland / Desktop ───────────────────────────${NC}"
check_cmd "sway"      sway
check_cmd "waybar"    waybar
check_cmd "swaylock"  swaylock
check_cmd "foot"      foot
check_cmd "rofi"      rofi
check_cmd "btop"      btop
check_cmd "thunar"    thunar
check_cmd "grim"      grim
check_cmd "slurp"     slurp
check_cmd "wl-copy"   wl-copy
check_cmd "playerctl" playerctl
check_cmd "wlogout"   wlogout
check_cmd "light"     light

echo -e "\n${BOLD}── Compiladores ────────────────────────────────${NC}"
check_cmd "gcc"       gcc
check_cmd "clang"     clang
check_cmd "clangd"    clangd

echo -e "\n${BOLD}── Runtimes ────────────────────────────────────${NC}"
check_cmd "node"      node
check_cmd "npm"       npm
check_cmd "python3"   python3
check_cmd "go"        go
check_cmd "cargo"     cargo

echo -e "\n${BOLD}── Servidores LSP ──────────────────────────────${NC}"
check_cmd "rust-analyzer"              rust-analyzer
check_cmd "gopls"                      gopls
check_cmd "intelephense"               intelephense
check_cmd "typescript-language-server" typescript-language-server
check_cmd "pyright"                    pyright
check_cmd "vscode-html-language-server" vscode-html-language-server
check_cmd "eslint"                     eslint

echo -e "\n${BOLD}── Formatadores ────────────────────────────────${NC}"
check_cmd "prettier"        prettier
check_cmd "stylua"          stylua
check_cmd "black"           black
check_cmd "rustfmt"         rustfmt
check_cmd "gofumpt"         gofumpt
check_cmd "blade-formatter" blade-formatter

echo ""
echo -e "${GREEN}${BOLD}════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  Instalação concluída!${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Próximos passos:${NC}"
echo -e "  1. ${BOLD}Reinicie o terminal${NC} para carregar o fish / variáveis de PATH"
echo -e "  2. Abra o Neovim: ${BOLD}nvim${NC}"
echo -e "     → lazy.nvim instala todos os plugins automaticamente na 1ª abertura"
echo -e "  3. Dentro do Neovim: ${BOLD}:TSUpdate${NC}  (parsers do Treesitter)"
echo -e "  4. Configure o Copilot: ${BOLD}:Copilot auth${NC}"
echo -e "  5. Configure o WakaTime: ${BOLD}:WakaTimeApiKey${NC}"
echo -e "  6. Ajuste ${BOLD}~/.config/sway/config${NC} conforme seus monitores e wallpaper"
echo ""
echo -e "${DIM}Se algum binário não aparecer após reiniciar o terminal:${NC}"
echo -e "  ${CYAN}source ~/.cargo/env${NC}                     # Rust / cargo tools"
echo -e "  ${CYAN}export PATH=\"\$PATH:\$HOME/go/bin\"${NC}        # gopls, lazygit, gofumpt"
echo -e "  ${CYAN}export PATH=\"\$PATH:\$HOME/.local/bin\"${NC}    # black, fd (Debian)"
echo ""
