#!/usr/bin/env bash
# tailor-cv runner. Reorders CV bullets by JD keyword density; emits CVVariant.

set -eu

_self="$(cd "$(dirname "$0")/../.." && pwd)"
# shellcheck source=/dev/null
. "${_self}/tools/platform-gate.sh"

_base="${LC_CV_BASE_PATH:-${_self}/fixtures/cv-base.example.md}"
_jd=""
_out_dir="${LC_CV_OUT_DIR:-${TMPDIR:-/tmp}}"
_kw="${_self}/fixtures/engineering-keywords.json"
_render_pdf=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --base)
      _base="$2"
      shift 2
      ;;
    --jd)
      _jd="$2"
      shift 2
      ;;
    --out-dir)
      _out_dir="$2"
      shift 2
      ;;
    --render-pdf)
      _render_pdf=1
      shift
      ;;
    *)
      printf 'tailor-cv: unknown arg %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

if [ -z "${_jd}" ] || [ ! -f "${_jd}" ]; then
  printf 'tailor-cv: --jd <path> required and must exist\n' >&2
  exit 2
fi
if [ ! -f "${_base}" ]; then
  printf 'tailor-cv: base CV not found: %s\n' "${_base}" >&2
  exit 4
fi
if [ ! -f "${_kw}" ]; then
  printf 'tailor-cv: keyword list missing: %s\n' "${_kw}" >&2
  exit 4
fi

mkdir -p "${_out_dir}"

# Extract frontmatter key from JD via awk (between leading --- markers).
_fm_get() {
  _file="$1"
  _key="$2"
  awk -v k="${_key}" '
    BEGIN{ in_fm=0; count=0 }
    /^---[[:space:]]*$/ { count++; if (count==1) { in_fm=1; next } else { exit } }
    in_fm==1 {
      n=index($0, ":")
      if (n>0) {
        name=substr($0,1,n-1); val=substr($0,n+1)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", name)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
        if (name==k) { print val; exit }
      }
    }
  ' "${_file}"
}

_org="$(_fm_get "${_jd}" org_slug)"
_role="$(_fm_get "${_jd}" role_slug)"
if [ -z "${_org}" ] || [ -z "${_role}" ]; then
  printf 'tailor-cv: JD missing org_slug/role_slug frontmatter\n' >&2
  exit 3
fi

# Strip frontmatter from a markdown file to stdout.
_strip_fm() {
  awk '
    BEGIN{ in_fm=0; count=0; done=0 }
    !done && /^---[[:space:]]*$/ { count++; if (count<=2) { in_fm=(count==1); next } }
    count>=2 { done=1; print; next }
    done { print }
  ' "$1"
}

# Build lowercase keyword list from engineering-keywords.json.
_keywords_lc="$(jq -r '
  [ .. | strings ] | map(ascii_downcase) | unique | .[]
' "${_kw}")"

_jd_body_lc="$(_strip_fm "${_jd}" | tr '[:upper:]' '[:lower:]')"
_cv_body_lc="$(_strip_fm "${_base}" | tr '[:upper:]' '[:lower:]')"

# Compute K_jd and K_cv via substring match (case-insensitive).
_k_jd=""
_k_cv=""
_matched=0
_n_jd=0
_n_both=0
while IFS= read -r _kw_item; do
  [ -z "${_kw_item}" ] && continue
  _in_jd=0
  _in_cv=0
  case "${_jd_body_lc}" in *"${_kw_item}"*) _in_jd=1 ;; esac
  case "${_cv_body_lc}" in *"${_kw_item}"*) _in_cv=1 ;; esac
  if [ "${_in_jd}" -eq 1 ]; then
    _n_jd=$((_n_jd + 1))
    _k_jd="${_k_jd}${_kw_item}
"
    if [ "${_in_cv}" -eq 1 ]; then
      _n_both=$((_n_both + 1))
    fi
  fi
  if [ "${_in_cv}" -eq 1 ]; then
    _k_cv="${_k_cv}${_kw_item}
"
  fi
done <<EOF
${_keywords_lc}
EOF

if [ "${_n_jd}" -eq 0 ]; then
  _coverage=0
else
  _coverage=$((_n_both * 100 / _n_jd))
fi

# Reorder experience bullets by JD-keyword density within each role.
# Preserve frontmatter and non-experience sections verbatim.
_today_ymd="$(date -u +%Y%m%d)"
_today_iso="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
_md_path="${_out_dir}/cv-${_org}-${_role}-${_today_ymd}.md"

# Generate ULID-ish id from /dev/urandom (Crockford base32 alphabet, 26 chars).
_ulid="$(LC_ALL=C awk -v n=26 'BEGIN{
  srand();
  a="0123456789ABCDEFGHJKMNPQRSTVWXYZ";
  for(i=0;i<n;i++) printf "%s", substr(a, int(rand()*32)+1, 1);
}')"

# awk script: within "## Experience" section, buffer bullets per role and
# re-emit sorted by keyword density (descending, stable for ties).
# Keyword list passed via temp file — BSD awk rejects literal newlines in
# `-v var=...` values ("newline in string" abort).
_kjd_file="$(mktemp)"
trap 'rm -f "${_kjd_file}"' EXIT
printf '%s' "${_k_jd}" >"${_kjd_file}"

awk -v kjdfile="${_kjd_file}" '
  function load_keywords(    line, n) {
    n=0
    while ((getline line < kjdfile) > 0) {
      if (line != "") { n++; kjd[n]=line }
    }
    close(kjdfile)
    nkj=n
  }
  function score_bullet(line,    s, i, k) {
    s=0
    lc=tolower(line)
    for(i=1;i<=nkj;i++){
      k=kjd[i]
      if (k=="") continue
      if (index(lc, k) > 0) s++
    }
    return s
  }
  function flush(    i, j, tmp, tmps, n, lines, k) {
    # stable sort by desc score; bullets[] with scores[]
    for(i=1;i<=nb;i++){
      for(j=i+1;j<=nb;j++){
        if (scores[j] > scores[i]) {
          tmp=bullets[i]; bullets[i]=bullets[j]; bullets[j]=tmp
          tmps=scores[i]; scores[i]=scores[j]; scores[j]=tmps
        }
      }
    }
    # Bullets store continuation lines joined by \033 sentinel (BSD awk
    # rejects literal \n inside array values). Split + reprint here.
    for(i=1;i<=nb;i++){
      n=split(bullets[i], lines, "\033")
      for(k=1;k<=n;k++) print lines[k]
    }
    nb=0
  }
  BEGIN{ in_exp=0; in_role=0; nb=0; nkj=0; load_keywords() }
  /^## / {
    if (in_role) flush()
    in_role=0
    in_exp=($0 ~ /^## Experience/)
    print; next
  }
  /^### / {
    if (in_role) flush()
    in_role=in_exp
    nb=0
    print; next
  }
  {
    if (in_role && $0 ~ /^[[:space:]]*-[[:space:]]/) {
      nb++
      bullets[nb]=$0
      scores[nb]=score_bullet($0)
      next
    }
    if (in_role && nb>0 && $0 ~ /^[[:space:]]+[^[:space:]]/) {
      # continuation of previous bullet — join with \033 sentinel
      bullets[nb]=bullets[nb] "\033" $0
      scores[nb]=scores[nb] + score_bullet($0)
      next
    }
    if (in_role && nb>0 && $0 !~ /^[[:space:]]*$/ && $0 !~ /^[[:space:]]/) {
      flush()
    }
    print
  }
  END{ if (in_role) flush() }
' "${_base}" >"${_md_path}"

_pdf_path="null"
if [ "${_render_pdf}" -eq 1 ]; then
  _pdf_out="${_out_dir}/cv-${_org}-${_role}-${_today_ymd}.pdf"
  if command -v pandoc >/dev/null 2>&1; then
    pandoc "${_md_path}" -o "${_pdf_out}" >/dev/null 2>&1 && _pdf_path="\"${_pdf_out}\""
  elif command -v typst >/dev/null 2>&1; then
    typst compile "${_md_path}" "${_pdf_out}" >/dev/null 2>&1 && _pdf_path="\"${_pdf_out}\""
  fi
fi

cat <<JSON
{
  "schema": "cv-variant",
  "id": "${_ulid}",
  "base_cv_ref": "${_base}",
  "jd_ref": "${_jd}",
  "org_slug": "${_org}",
  "role_slug": "${_role}",
  "keyword_coverage_pct": ${_coverage},
  "output_md_path": "${_md_path}",
  "output_pdf_path": ${_pdf_path},
  "created_iso": "${_today_iso}"
}
JSON
