# Modo: foco — gaps discretos, borda verde para indicar estado
# Incluído via ~/.config/sway/config.d/99-mode.conf

gaps inner 10
gaps outer 6

default_border pixel 2

# Green (#a6da95) como accent de foco — sinaliza "modo concentração"
client.focused          #a6da95 #181926 #cad3f5 #a6da95 #a6da95
client.unfocused        #181926 #1e2030 #6e738d #181926 #181926
client.focused_inactive #363a4f #1e2030 #a5adcb #363a4f #363a4f
client.urgent           #ed8796 #ed8796 #1e2030 #ed8796 #ed8796
client.placeholder      #363a4f #1e2030 #6e738d #363a4f #363a4f
