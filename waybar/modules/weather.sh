#!/usr/bin/env bash
set -euo pipefail

# Corumba-MS por padrao; pode sobrescrever por variavel de ambiente.
LAT="${WAYBAR_WEATHER_LAT:--19.01}"
LON="${WAYBAR_WEATHER_LON:--57.65}"
TZ="${WAYBAR_WEATHER_TZ:-America/Campo_Grande}"
CITY="${WAYBAR_WEATHER_CITY:-Corumba-MS}"
TZ_ENCODED="${TZ//\//%2F}"

API="https://api.open-meteo.com/v1/forecast"

json_escape() {
  local s="${1:-}"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  printf '%s' "$s"
}

urlencode_min() {
  local s="${1:-}"
  s="${s// /%20}"
  printf '%s' "${s}"
}

api_url_current() {
  printf '%s?latitude=%s&longitude=%s&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,is_day&timezone=%s' \
    "${API}" "${LAT}" "${LON}" "${TZ_ENCODED}"
}

api_url_brief() {
  printf '%s?latitude=%s&longitude=%s&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,is_day&hourly=temperature_2m,weather_code,precipitation_probability&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum&forecast_days=3&timezone=%s' \
    "${API}" "${LAT}" "${LON}" "${TZ_ENCODED}"
}

fetch_json() {
  local url="$1"
  curl -fsS --max-time 7 "${url}" 2>/dev/null || true
}

icon_for_code() {
  local code="${1:-}"
  local is_day="${2:-1}"
  case "$code" in
    0)
      if [[ "$is_day" == "1" ]]; then printf "󰖙"; else printf "󰖔"; fi
      ;;
    1|2) printf "󰖕" ;;                       # parcialmente nublado
    3) printf "󰖐" ;;                         # nublado
    45|48) printf "󰖑" ;;                     # neblina
    51|53|55|56|57) printf "󰼳" ;;           # garoa
    61|63|65|66|67|80|81|82) printf "󰖗" ;;  # chuva
    71|73|75|77|85|86) printf "󰖘" ;;        # neve/granizo
    95|96|99) printf "󰖓" ;;                 # tempestade
    *) printf "󰖐" ;;                         # fallback
  esac
}

desc_for_code() {
  local code="${1:-}"
  case "$code" in
    0) printf "Ceu limpo" ;;
    1|2) printf "Parcialmente nublado" ;;
    3) printf "Nublado" ;;
    45|48) printf "Neblina" ;;
    51|53|55|56|57) printf "Garoa" ;;
    61|63|65|66|67|80|81|82) printf "Chuva" ;;
    71|73|75|77|85|86) printf "Neve/Granizo" ;;
    95|96|99) printf "Tempestade" ;;
    *) printf "Condicao desconhecida" ;;
  esac
}

status_mode() {
  local resp parsed temp app hum wind code is_day icon desc text tooltip
  resp="$(fetch_json "$(api_url_current)")"

  if [[ -z "${resp}" ]]; then
    printf '{"text":"󰖐 --°C","tooltip":"Clima indisponível no momento","class":"offline"}\n'
    return 0
  fi

  parsed="$(
    python3 -c 'import json,sys
data=json.load(sys.stdin)
c=data.get("current",{})
vals=[
  str(c.get("temperature_2m","")),
  str(c.get("apparent_temperature","")),
  str(c.get("relative_humidity_2m","")),
  str(c.get("wind_speed_10m","")),
  str(c.get("weather_code","")),
  str(c.get("is_day","1")),
]
print("|".join(vals))' <<<"${resp}" 2>/dev/null || true
  )"

  IFS="|" read -r temp app hum wind code is_day <<<"${parsed}"

  if [[ -z "${temp}" || -z "${code}" ]]; then
    printf '{"text":"󰖐 --°C","tooltip":"Clima indisponível no momento","class":"offline"}\n'
    return 0
  fi

  icon="$(icon_for_code "$code" "$is_day")"
  desc="$(desc_for_code "$code")"
  text="${icon} ${temp}°C"
  tooltip="${CITY} | ${desc} | Sensacao: ${app}°C | Umidade: ${hum}% | Vento: ${wind} km/h"

  printf '{"text":"%s","tooltip":"%s","class":"ok"}\n' \
    "$(json_escape "${text}")" \
    "$(json_escape "${tooltip}")"
}

brief_mode() {
  local resp
  resp="$(fetch_json "$(api_url_brief)")"

  if [[ -z "${resp}" ]]; then
    printf 'Clima indisponivel no momento.\n'
    return 0
  fi

  CITY_ENV="${CITY}" RESP_JSON="${resp}" python3 - <<'PY' 2>/dev/null || printf 'Falha ao montar briefing do clima.\n'
import json
import os

data = json.loads(os.environ.get("RESP_JSON", "{}"))

def desc(code):
    code = int(code) if str(code).strip() else -1
    if code == 0:
        return "Ceu limpo"
    if code in (1, 2):
        return "Parcialmente nublado"
    if code == 3:
        return "Nublado"
    if code in (45, 48):
        return "Neblina"
    if code in (51, 53, 55, 56, 57):
        return "Garoa"
    if code in (61, 63, 65, 66, 67, 80, 81, 82):
        return "Chuva"
    if code in (71, 73, 75, 77, 85, 86):
        return "Neve/Granizo"
    if code in (95, 96, 99):
        return "Tempestade"
    return "Desconhecido"

city = os.environ.get("CITY_ENV", "Cidade")
lat = data.get("latitude")
lon = data.get("longitude")
c = data.get("current", {})
h = data.get("hourly", {})
d = data.get("daily", {})

print("=== Briefing do Clima ===")
print(f"Cidade: {city} ({lat}, {lon})")
print(f"Timezone: {data.get('timezone', '-')}")
print("")
print("[Agora]")
print(f"Temp: {c.get('temperature_2m', '-')}°C")
print(f"Sensacao: {c.get('apparent_temperature', '-')}°C")
print(f"Umidade: {c.get('relative_humidity_2m', '-')}%")
print(f"Vento: {c.get('wind_speed_10m', '-')} km/h")
print(f"Condicao: {desc(c.get('weather_code', -1))}")
print("")
print("[Proximas horas]")
times = h.get("time", [])[:6]
temps = h.get("temperature_2m", [])[:6]
codes = h.get("weather_code", [])[:6]
pops = h.get("precipitation_probability", [])[:6]
for i, t in enumerate(times):
    hh = t.split("T")[1] if "T" in t else t
    tt = temps[i] if i < len(temps) else "-"
    cc = codes[i] if i < len(codes) else -1
    pp = pops[i] if i < len(pops) else "-"
    print(f"{hh}  {tt}°C  {desc(cc)}  Chuva:{pp}%")
print("")
print("[Proximos 3 dias]")
days = d.get("time", [])
tmax = d.get("temperature_2m_max", [])
tmin = d.get("temperature_2m_min", [])
dcodes = d.get("weather_code", [])
psum = d.get("precipitation_sum", [])
for i, day in enumerate(days[:3]):
    mx = tmax[i] if i < len(tmax) else "-"
    mn = tmin[i] if i < len(tmin) else "-"
    cc = dcodes[i] if i < len(dcodes) else -1
    ps = psum[i] if i < len(psum) else "-"
    print(f"{day}  Min:{mn}°C  Max:{mx}°C  {desc(cc)}  Chuva:{ps}mm")
PY
}

source_url_mode() {
  printf 'https://www.climatempo.com.br/previsao-do-tempo/cidade/751/corumba-ms'
}

main() {
  local action="${1:-status}"
  case "${action}" in
    status)
      status_mode
      ;;
    brief)
      brief_mode
      ;;
    source-url)
      source_url_mode
      ;;
    *)
      status_mode
      ;;
  esac
}

main "$@"