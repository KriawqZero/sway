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

## Pós-instalação

Após abrir o Neovim pela primeira vez, o lazy.nvim instala os plugins automaticamente. Em seguida:

```
:TSUpdate        — atualiza parsers do Treesitter
:Copilot auth    — autenticar GitHub Copilot
:WakaTimeApiKey  — configurar WakaTime
```
