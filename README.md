# dotfiles

Configurações pessoais para um ambiente Wayland com Sway no Linux.

## Ferramentas configuradas

| Ferramenta | Função |
|---|---|
| [Sway](https://swaywm.org) | Compositor Wayland (WM) |
| [Waybar](https://github.com/Alexays/Waybar) | Barra de status |
| [Foot](https://codeberg.org/dnkl/foot) | Terminal |
| [Fish](https://fishshell.com) | Shell |
| [Starship](https://starship.rs) | Prompt |
| [Neovim](https://neovim.io) | Editor (config: [KriawqVim](https://github.com/KriawqZero/nvim)) |
| [Rofi](https://github.com/lbonn/rofi) | Launcher |
| [swaylock](https://github.com/swaywm/swaylock) | Tela de bloqueio |
| [btop](https://github.com/aristocratos/btop) | Monitor de sistema |
| [Thunar](https://docs.xfce.org/xfce/thunar/start) | Gerenciador de arquivos |

**Tema:** Catppuccin Macchiato  
**Fonte:** JetBrains Mono Nerd Font  
**Cursor:** Bibata-Modern-Classic

## Instalação

```bash
git clone --recurse-submodules https://github.com/KriawqZero/dotfiles ~/dotfiles
cd ~/dotfiles

# 1. Instala todos os pacotes necessários (Arch, Fedora, Debian/Ubuntu/Mint, Void)
bash install_needed_packages.sh

# 2. Cria os symlinks em ~/.config  (já incluso no passo acima, mas pode rodar separado)
bash install_dotfiles.sh
```

> O script de instalação detecta a distro automaticamente e oferece modo automático ou interativo.

## Estrutura

```
dotfiles/
├── fish/          # Shell Fish + plugins (fisher, nvm.fish)
├── nvim/          # Neovim — submódulo git (KriawqZero/nvim)
├── sway/          # Compositor + scripts de screenshot
├── waybar/        # Barra de status + módulos
├── foot/          # Terminal
├── swaylock/      # Tela de bloqueio
├── rofi/          # Launcher
├── btop/          # Monitor de sistema
├── gtk-3.0/       # Tema GTK 3
├── gtk-4.0/       # Tema GTK 4
├── starship.toml  # Prompt
├── install_needed_packages.sh  # Instala todos os pacotes
└── install_dotfiles.sh         # Cria symlinks em ~/.config
```

## Sistema de modos visuais

Troca a aparência completa do ambiente (waybar, rofi, sway gaps/bordas, wallpaper) sem tocar em configurações do sistema.

| Modo | Accent | Gaps | Waybar | Uso |
|---|---|---|---|---|
| `normal` | Blue `#8aadf4` | 0/0 | Completa | Uso geral |
| `foco` | Green `#a6da95` | inner 10 / outer 6 | Minimal (workspaces + clock) | Concentração |
| `musica` | Mauve `#c6a0f6` | inner 14 / outer 8 | Media em destaque | Chill / música |

### Usar

```bash
marcilio-mode normal    # ativa o modo
marcilio-mode foco
marcilio-mode musica
```

Ou via keybind no Sway: **`Super + M`** abre o menu rofi.

### Estrutura

```
dotfiles/
├── modes/
│   ├── normal/   waybar.jsonc · waybar.css · rofi.rasi · sway.inc · wallpaper
│   ├── foco/     waybar.jsonc · waybar.css · rofi.rasi · sway.inc · wallpaper
│   └── musica/   waybar.jsonc · waybar.css · rofi.rasi · sway.inc · wallpaper
└── scripts/
    ├── marcilio-mode   — troca modo, recarrega sway, reinicia waybar, troca wallpaper
    └── marcilio-menu   — abre seletor rofi
```

### Wallpapers

Coloque as imagens nos caminhos abaixo (ou edite os arquivos `modes/*/wallpaper`):

```
~/Wallpapers/background   # normal (já existe)
~/Wallpapers/foco         # modo foco
~/Wallpapers/musica       # modo musica
```

### Instalar scripts (feito automaticamente pelo install_needed_packages.sh)

```bash
mkdir -p ~/.local/bin
ln -sf ~/dotfiles/scripts/marcilio-mode ~/.local/bin/marcilio-mode
ln -sf ~/dotfiles/scripts/marcilio-menu ~/.local/bin/marcilio-menu
marcilio-mode normal   # ativa modo padrão
```

---

## Pós-instalação

Após abrir o Neovim pela primeira vez, o lazy.nvim instala os plugins automaticamente. Em seguida:

```
:TSUpdate        — atualiza parsers do Treesitter
:Copilot auth    — autenticar GitHub Copilot
:WakaTimeApiKey  — configurar WakaTime
```
