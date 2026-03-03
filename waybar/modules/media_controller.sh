#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/waybar-media"
SELECTED_FILE="${STATE_DIR}/selected_player"

if ! mkdir -p "${STATE_DIR}" 2>/dev/null; then
  STATE_DIR="/tmp/waybar-media"
  SELECTED_FILE="${STATE_DIR}/selected_player"
  mkdir -p "${STATE_DIR}"
fi

json_escape() {
  local s="${1:-}"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  printf '%s' "${s}"
}

truncate_text() {
  local input="${1:-}"
  local max_len="${2:-320}"
  if (( ${#input} <= max_len )); then
    printf '%s' "${input}"
  elif (( max_len > 3 )); then
    printf '%s' "${input:0:max_len-3}"
  else
    printf '%s' "${input:0:max_len}"
  fi
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

list_players() {
  if ! has_cmd playerctl; then
    return 0
  fi
  playerctl -l 2>/dev/null | awk 'NF && !seen[$0]++'
}

is_player_available() {
  local wanted="$1"
  list_players | awk -v p="${wanted}" '$0 == p { found=1 } END { exit(found ? 0 : 1) }'
}

read_selected_player() {
  if [[ -s "${SELECTED_FILE}" ]]; then
    local player
    player="$(<"${SELECTED_FILE}")"
    if is_player_available "${player}"; then
      printf '%s' "${player}"
      return 0
    fi
  fi
  return 1
}

set_selected_player() {
  printf '%s' "$1" > "${SELECTED_FILE}"
}

first_playing_player() {
  while IFS= read -r player; do
    [[ -z "${player}" ]] && continue
    if [[ "$(playerctl -p "${player}" status 2>/dev/null || true)" == "Playing" ]]; then
      printf '%s' "${player}"
      return 0
    fi
  done < <(list_players)
  return 1
}

first_player() {
  list_players | awk 'NR==1 {print; exit}'
}

resolve_player() {
  local chosen
  if chosen="$(read_selected_player 2>/dev/null)"; then
    printf '%s' "${chosen}"
    return 0
  fi
  if chosen="$(first_playing_player 2>/dev/null)"; then
    printf '%s' "${chosen}"
    return 0
  fi
  chosen="$(first_player || true)"
  [[ -n "${chosen}" ]] && printf '%s' "${chosen}"
}

player_label() {
  local player="$1"
  local identity
  identity="$(playerctl -p "${player}" metadata mpris:identity 2>/dev/null || true)"
  if [[ -z "${identity}" ]]; then
    identity="${player%%.*}"
  fi

  case "${identity,,}" in
    *spotify*)
      printf '%s' "Spotify"
      ;;
    *chromium*|*chrome*)
      printf '%s' "Chromium"
      ;;
    *firefox*)
      printf '%s' "Firefox"
      ;;
    *)
      printf '%s' "$(truncate_text "${identity}" 10)"
      ;;
  esac
}

show_status() {
  local player status status_pt artist title label icon track display_track tooltip class text
  player="$(resolve_player || true)"

  if [[ -z "${player}" ]]; then
    printf '{"text":"󰎈 sem mídia","tooltip":"Nenhum player MPRIS encontrado","class":"inactive"}\n'
    return 0
  fi

  status="$(playerctl -p "${player}" status 2>/dev/null || echo "Stopped")"
  artist="$(playerctl -p "${player}" metadata xesam:artist 2>/dev/null | paste -sd ', ' - || true)"
  title="$(playerctl -p "${player}" metadata xesam:title 2>/dev/null || true)"
  label="$(player_label "${player}")"

  if [[ -n "${artist}" && -n "${title}" ]]; then
    track="${artist} - ${title}"
  elif [[ -n "${title}" ]]; then
    track="${title}"
  else
    track="Sem metadados"
  fi

  case "${status}" in
    Playing)
      icon=""
      class="playing"
      status_pt="Tocando"
      ;;
    Paused)
      icon=""
      class="paused"
      status_pt="Pausado"
      ;;
    *)
      icon=""
      class="stopped"
      status_pt="Parado"
      ;;
  esac

  display_track="$(truncate_text "${track}" 15)"
  text="$(truncate_text "${icon} ${label}: ${display_track}" 42)"
  tooltip="App: ${label}  |  Status: ${status_pt}  |  Faixa: ${track}  |  Esq: play/pause  •  Scroll: ant/prox  •  Dir: escolher player"

  printf '{"text":"%s","tooltip":"%s","class":"%s","alt":"%s"}\n' \
    "$(json_escape "${text}")" \
    "$(json_escape "${tooltip}")" \
    "${class}" \
    "$(json_escape "${player}")"
}

control_player() {
  local cmd="$1"
  local player
  player="$(resolve_player || true)"
  [[ -z "${player}" ]] && exit 0
  playerctl -p "${player}" "${cmd}" >/dev/null 2>&1 || true
}

pick_with_launcher() {
  local prompt="$1"
  if has_cmd rofi; then
    rofi -dmenu -p "${prompt}" 2>/dev/null && return 0
  fi
  if has_cmd wofi; then
    wofi --dmenu --prompt "${prompt}" 2>/dev/null && return 0
  fi
  if has_cmd walker; then
    walker --dmenu --prompt "${prompt}" 2>/dev/null && return 0
  fi
  if has_cmd fuzzel; then
    fuzzel --dmenu --prompt "${prompt}" 2>/dev/null && return 0
  fi
  if has_cmd bemenu; then
    bemenu -p "${prompt}" 2>/dev/null && return 0
  fi
  return 1
}

menu_select_player() {
  mapfile -t players < <(list_players)
  [[ "${#players[@]}" -eq 0 ]] && exit 0

  local current choice display line selected_player
  current="$(resolve_player || true)"

  display=""
  for line in "${players[@]}"; do
    if [[ "${line}" == "${current}" ]]; then
      display+="* ${line}"$'\n'
    else
      display+="  ${line}"$'\n'
    fi
  done

  choice="$(printf '%s' "${display}" | pick_with_launcher "Controlar player")" || exit 0
  selected_player="$(printf '%s' "${choice}" | sed 's/^[* ]*//')"
  [[ -z "${selected_player}" ]] && exit 0
  set_selected_player "${selected_player}"
}

main() {
  local action="${1:-status}"
  case "${action}" in
    status)
      show_status
      ;;
    play-pause)
      control_player play-pause
      ;;
    previous)
      control_player previous
      ;;
    next)
      control_player next
      ;;
    menu)
      menu_select_player
      ;;
    set-player)
      [[ -n "${2:-}" ]] && set_selected_player "${2}"
      ;;
    *)
      show_status
      ;;
  esac
}

main "$@"
