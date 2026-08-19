#!/usr/bin/env bash
#
# fetch_arxiv.sh — resolve, cache, and extract the LaTeX source of an arXiv paper.
#
# Usage:  fetch_arxiv.sh <arxiv-url-or-id>
#
# Accepts any of:
#   https://arxiv.org/abs/2606.24869        https://arxiv.org/abs/2606.24869v2
#   https://arxiv.org/pdf/2606.24869        https://arxiv.org/pdf/2606.24869v2.pdf
#   2606.24869                              2606.24869v2
#   (best-effort) old-style ids: hep-th/9901001, math.GT/0309136
#
# Behaviour:
#   - If the id carries no version, the current version is resolved via the arXiv
#     API so the cache directory always carries an explicit version.
#   - Caches under  ${XDG_CACHE_HOME:-$HOME/.cache}/arXiv/<id>v<N>/
#   - If that directory already exists and is non-empty, nothing is downloaded.
#   - Source is an arXiv e-print: a gzipped tarball, a single gzipped .tex, or
#     (rarely) a PDF-only submission. All three are handled.
#   - Extraction is atomic: a half-finished download never leaves a populated
#     cache dir that the existence check would mistake for complete.
#
# Output is a key=value block on stdout (parse it; do not re-derive paths):
#   ARXIV_ID=<id-with-version>
#   CACHE_DIR=<absolute path>
#   STATUS=cached|downloaded|pdf-only
#   MAIN_TEX=<absolute path> | AMBIGUOUS | NONE
#   TEX_CANDIDATES: (followed by one path per line, may be empty)

set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

UA="arxiv-paper-skill/1.0 (mailto:a.alberti82@gmail.com)"
API="https://export.arxiv.org/api/query"
EPRINT="https://arxiv.org/e-print"

die() { echo "ERROR: $*" >&2; exit 1; }

[ $# -ge 1 ] || die "usage: fetch_arxiv.sh <arxiv-url-or-id>"
INPUT="$1"

# ---- 1. extract the bare id (with optional version) -------------------------
# strip query/fragment and a trailing .pdf, then match a known id shape.
clean=$(printf '%s' "$INPUT" | sed -E 's/[?#].*$//; s/\.pdf$//')
id=$(printf '%s' "$clean" | grep -oE '[0-9]{4}\.[0-9]{4,5}(v[0-9]+)?' | head -n1 || true)
if [ -z "$id" ]; then
  # old-style: archive[.subclass]/NNNNNNN[vN]
  id=$(printf '%s' "$clean" | grep -oE '[a-z-]+(\.[A-Z]{2})?/[0-9]{7}(v[0-9]+)?' | head -n1 || true)
fi
[ -n "$id" ] || die "could not parse an arXiv id from: $INPUT"

# ---- 2. resolve version if absent -------------------------------------------
if printf '%s' "$id" | grep -qE 'v[0-9]+$'; then
  full_id="$id"
else
  resolved=$(curl -fsSL -A "$UA" "$API?id_list=$id&max_results=1" 2>/dev/null \
    | grep -oE 'arxiv\.org/abs/[^<[:space:]]*v[0-9]+' | head -n1 \
    | grep -oE '[^/]*v[0-9]+$' || true)
  if [ -n "$resolved" ]; then
    full_id="$resolved"
  else
    # API gave no version (rare); fall back to the bare id.
    full_id="$id"
    echo "WARNING: could not resolve version for $id; caching without version" >&2
  fi
fi

# ---- 3. compute cache dir & check existence ---------------------------------
cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/arXiv"
# old-style ids contain a slash; flatten it for the directory name.
safe_id=$(printf '%s' "$full_id" | tr '/' '_')
dir="$cache_root/$safe_id"

emit() {
  echo "ARXIV_ID=$full_id"
  echo "CACHE_DIR=$dir"
  echo "STATUS=$1"
  convert_figures
  normalize_svgs
  echo "SVG=$SVG_STATUS$SVG_NORMALIZE_NOTE"
  detect_main
}

# Convert non-displayable figure sources in the cache to SVG so they render in the
# chat buffer. Only formats that CAN'T be shown directly are touched — PDF, EPS, PS
# (raster figures like png/jpg/gif/tiff/webp are already displayable and left alone).
#   - PDF        -> mutool (the engine that won the fidelity/size/speed comparison)
#   - EPS/PS     -> epstopdf -> mutool (same engine; route verified faithful)
# Single-page sources become <base>.svg; multipage become <base>-1.svg, -2.svg, …
# Runs on fresh downloads and cache hits, skipping sources already converted
# (self-heals older caches). No silent fallback to a different engine: if a required
# tool is missing, report it so the user can install it and re-run.
SVG_STATUS=none

# Post-processing of every SVG in the cache dir (converted ones *and* SVGs the
# authors shipped) is delegated to `normalize_svg.py' next to this script — one
# batch call, no backups (the original PDF/EPS is kept and the SVG is
# regenerable).  It does two idempotent things:
#   - injects an opaque background rect (SVG_BG, default `white'; `none' to skip)
#     since LaTeX figures are transparent black-on-nothing and vanish on a dark
#     background;
#   - rewrites the root `width'/`height' to SVG_TARGET_WIDTH px (viewBox kept, so
#     content just scales), because agent shells render an SVG at its intrinsic
#     width and arXiv sources are frequently tiny.
# Requires python3; if it is missing, figures are left as converted and the SVG=
# status line says so instead of failing the fetch.
SVG_TARGET_WIDTH=${SVG_TARGET_WIDTH:-600}
SVG_BG=${SVG_BG:-white}
SVG_NORMALIZE_NOTE=""

normalize_svgs() {
  [ -d "$dir" ] || return 0
  if ! command -v python3 >/dev/null 2>&1; then
    SVG_NORMALIZE_NOTE=" unnormalized:no-python3"
    echo "WARNING: python3 not found — figures not resized/background-filled." >&2
    return 0
  fi
  if ! python3 "$script_dir/normalize_svg.py" "$dir" \
        --width "$SVG_TARGET_WIDTH" --color "$SVG_BG" -q >/dev/null 2>&1; then
    SVG_NORMALIZE_NOTE=" unnormalized:failed"
    echo "WARNING: normalize_svg.py failed; figures kept as converted." >&2
  fi
}

convert_figures() {
  local listf f ext base pdf td n i total need converted failed missing
  listf=$(mktemp "${TMPDIR:-/tmp}/arxivfig.XXXXXX")
  find "$dir" -type f \( -iname '*.pdf' -o -iname '*.eps' -o -iname '*.ps' \
       -o -iname '*.epsi' \) > "$listf" 2>/dev/null || true
  total=$(grep -c . "$listf" || true)
  if [ "$total" -eq 0 ]; then SVG_STATUS=none; rm -f "$listf"; return; fi

  need=0
  while IFS= read -r f; do
    base="${f%.*}"
    # Already converted -> nothing to do here; normalize_svgs() self-heals it.
    if [ -f "$base.svg" ] || [ -f "${base}-1.svg" ]; then continue; fi
    need=$((need + 1))
  done < "$listf"
  if [ "$need" -eq 0 ]; then SVG_STATUS="ok:$total/$total"; rm -f "$listf"; return; fi

  converted=0; failed=0; missing=""
  while IFS= read -r f; do
    base="${f%.*}"
    if [ -f "$base.svg" ] || [ -f "${base}-1.svg" ]; then continue; fi
    ext=$(printf '%s' "${f##*.}" | tr 'A-Z' 'a-z')
    td=$(mktemp -d "${TMPDIR:-/tmp}/arxivsvg.XXXXXX")
    pdf="$f"

    # PostScript sources: lift to PDF first (preserves vector), then share the
    # mutool path below.
    case "$ext" in
      eps|epsi|ps)
        if ! command -v epstopdf >/dev/null 2>&1; then
          missing="$missing epstopdf"; failed=$((failed + 1)); rm -rf "$td"; continue
        fi
        if ! epstopdf --outfile="$td/conv.pdf" "$f" >/dev/null 2>&1; then
          failed=$((failed + 1)); rm -rf "$td"; continue
        fi
        pdf="$td/conv.pdf"
        ;;
    esac

    if ! command -v mutool >/dev/null 2>&1; then
      missing="$missing mutool"; failed=$((failed + 1)); rm -rf "$td"; continue
    fi
    if mutool convert -o "$td/p-%d.svg" "$pdf" >/dev/null 2>&1; then
      n=$(find "$td" -name 'p-*.svg' | grep -c . || true)
      if [ "$n" -eq 1 ]; then
        mv "$td/p-1.svg" "$base.svg"
      else
        i=1
        for s in $(find "$td" -name 'p-*.svg' | sort -t- -k2 -n); do
          mv "$s" "${base}-${i}.svg"; i=$((i + 1))
        done
      fi
      converted=$((converted + 1))
    else
      failed=$((failed + 1))
    fi
    rm -rf "$td"
  done < "$listf"
  rm -f "$listf"

  missing=$(printf '%s' "$missing" | tr ' ' '\n' | grep -v '^$' | sort -u \
            | tr '\n' ',' | sed 's/,$//' || true)
  if [ -n "$missing" ]; then
    SVG_STATUS="missing-tools:$missing"
    echo "WARNING: missing tool(s): $missing — $failed figure(s) left unconverted." >&2
    case ",$missing," in *,mutool,*) echo "         mutool: 'brew install mupdf-tools'." >&2 ;; esac
    case ",$missing," in *,epstopdf,*) echo "         epstopdf: install a TeX distribution (MacTeX / TeX Live)." >&2 ;; esac
  elif [ "$failed" -gt 0 ]; then
    SVG_STATUS="partial:${converted}_converted_${failed}_failed"
  else
    SVG_STATUS="ok:$total/$total"
  fi
}

detect_main() {
  # all .tex files containing \documentclass
  docs=$(grep -rlE '\\documentclass' "$dir" --include='*.tex' 2>/dev/null | sort || true)
  if [ -z "$docs" ]; then
    # no \documentclass found: list any .tex at all
    anytex=$(find "$dir" -name '*.tex' 2>/dev/null | sort || true)
    if [ -z "$anytex" ]; then
      echo "MAIN_TEX=NONE"
      echo "TEX_CANDIDATES:"
      return
    fi
    main=$(printf '%s\n' "$anytex" | head -n1)
    echo "MAIN_TEX=$main"
    echo "TEX_CANDIDATES:"
    printf '%s\n' "$anytex"
    return
  fi
  count=$(printf '%s\n' "$docs" | grep -c . || true)
  if [ "$count" -eq 1 ]; then
    echo "MAIN_TEX=$docs"
    echo "TEX_CANDIDATES:"
    printf '%s\n' "$docs"
    return
  fi
  # multiple \documentclass files: try to pick an obvious one by basename.
  pick=""
  for pat in '^main\.tex$' '^ms\.tex$' '^paper\.tex$' '^manuscript\.tex$' \
             '^article\.tex$' '^root\.tex$' "^${full_id%v*}\.tex$"; do
    cand=$(printf '%s\n' "$docs" | awk -F/ -v p="$pat" 'tolower($NF) ~ p {print; exit}')
    if [ -n "$cand" ]; then pick="$cand"; break; fi
  done
  if [ -n "$pick" ]; then
    echo "MAIN_TEX=$pick"
  else
    echo "MAIN_TEX=AMBIGUOUS"
  fi
  echo "TEX_CANDIDATES:"
  printf '%s\n' "$docs"
}

if [ -d "$dir" ] && [ -n "$(ls -A "$dir" 2>/dev/null)" ]; then
  emit cached
  exit 0
fi

# ---- 4. download e-print source ---------------------------------------------
tmp=$(mktemp -d "${TMPDIR:-/tmp}/arxiv.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
src="$tmp/src"

curl -fsSL -A "$UA" "$EPRINT/$full_id" -o "$src" \
  || die "download failed: $EPRINT/$full_id"
[ -s "$src" ] || die "downloaded source is empty"

stage="$tmp/stage"
mkdir -p "$stage"
status=downloaded

if tar -tzf "$src" >/dev/null 2>&1; then
  tar -xzf "$src" -C "$stage"
elif tar -tf "$src" >/dev/null 2>&1; then
  tar -xf "$src" -C "$stage"
else
  ftype=$(file -b "$src" 2>/dev/null || echo unknown)
  case "$ftype" in
    *gzip*)   gunzip -c "$src" > "$stage/main.tex" ;;
    *PDF*)    cp "$src" "$stage/paper.pdf"; status=pdf-only ;;
    *)        cp "$src" "$stage/source.dat" ;;
  esac
fi

# ---- 5. atomic publish into the cache ---------------------------------------
mkdir -p "$cache_root"
rm -rf "$dir.partial"
mv "$stage" "$dir.partial"
mv "$dir.partial" "$dir"

emit "$status"
