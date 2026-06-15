#!/usr/bin/env bash
set -Eeuo pipefail

# ==============================================================================
# Project: Xray VLESS + REALITY + Vision Learning Installer
# File: xray_vless_reality_public.sh
# Version: V8-public-kvmcc
#
# IMPORTANT NOTICE / 使用前须知：
# 1. This script is an unofficial, community-style automation example for learning,
#    lab testing, system administration practice, and lawful network configuration
#    research only. It is NOT affiliated with, endorsed by, sponsored by, or
#    maintained by Xray, XTLS, GitHub, or any cloud provider. Any sponsor/banner domain shown in this script is an advertisement display only, not a technical endorsement, official relationship, warranty, or support commitment.
#
# 2. By running, copying, modifying, or redistributing this script, you confirm that
#    you have read, understood, and agreed to this notice. You are solely responsible
#    for complying with all laws, regulations, service terms, export-control rules,
#    cloud-provider policies, and network-owner requirements in your jurisdiction.
#
# 3. Do NOT use this script for unauthorized access, traffic abuse, spam, malware,
#    fraud, credential theft, scanning third-party systems, evading lawful network
#    controls where prohibited, or any activity that violates applicable law or
#    terms of service. The script is provided "AS IS", without warranty of any kind.
#
# 4. Advertisement/Sponsor notice: www.kvmcc.com may be displayed as an ad/sponsor
#    banner. This does not mean the advertiser controls, audits, maintains, endorses,
#    guarantees, or provides support for this script.
#
# 5. The author(s), contributor(s), publisher(s), redistributor(s), advertiser(s),
#    sponsor(s), and any mentioned names/domains are not responsible for service
#    interruption, account suspension, data loss, IP blocking, legal consequences,
#    misuse, or any direct/indirect loss.
#
# 6. This script may change firewall rules, systemd services, kernel/network tuning,
#    and Xray configuration on your server. Review the code before running it on any
#    production machine. If you do not agree with these terms, do not use this file.
#
# 中文说明：
# - 本脚本仅用于学习、测试、系统运维练习和合法网络配置研究。
# - 本脚本不是 Xray/XTLS/GitHub/云厂商官方项目，也不代表任何第三方立场。
# - www.kvmcc.com 可作为广告/赞助展示出现；广告展示不代表其控制、审核、维护、担保、背书或提供技术支持。
# - 使用者必须自行确认当地法律法规、云服务商条款、网络管理要求和使用场景是否合法合规。
# - 严禁用于未授权访问、攻击、欺诈、垃圾流量、恶意软件、盗号、扫描第三方系统等用途。
# - 脚本按“现状”提供，不提供任何保证；使用、修改、转载、运行后产生的一切后果由使用者自行承担。
# - 作者、贡献者、发布者、转载者、广告主/赞助方及任何被提及名称/域名均不对误用、故障、封禁、损失或法律后果负责。
# - 不同意以上条款，请立即停止使用。
# ==============================================================================

XRAY_BIN="/usr/local/bin/xray"
XRAY_CONF_DIR="/usr/local/etc/xray"
XRAY_CONF="${XRAY_CONF_DIR}/config.json"
XRAY_INFO="/root/xray-vless-reality.env"
CLIENT_JSON="/root/xray-client-vless-reality.json"
MIHOMO_YAML="/root/mihomo-vless-reality.yaml"
LINK_TXT="/root/vless-reality-link.txt"
ONLINE_GUARD="/usr/local/sbin/xray-online-guard"
ONLINE_ENV="/etc/default/xray-online-guard"
ONLINE_UNIT="/etc/systemd/system/xray-online-guard.service"
SYSCTL_CONF="/etc/sysctl.d/99-xray-reality-tuning.conf"
XRAY_OVERRIDE_DIR="/etc/systemd/system/xray.service.d"
XRAY_OVERRIDE="${XRAY_OVERRIDE_DIR}/override.conf"
INSTALL_URL="${INSTALL_URL:-https://github.com/XTLS/Xray-install/raw/main/install-release.sh}"
# 多源下载：优先官方；官方脚本或 GitHub 资产异常时自动切换备用源。
# 可用环境变量覆盖，空格分隔：INSTALL_URLS="url1 url2 ..." XRAY_DOWNLOAD_BASES="base1 base2 ..."
INSTALL_URLS="${INSTALL_URLS:-https://github.com/XTLS/Xray-install/raw/main/install-release.sh https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh https://gh-proxy.com/https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh https://hub.gitmirror.com/https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh https://ghproxy.net/https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh}"
XRAY_DOWNLOAD_BASES="${XRAY_DOWNLOAD_BASES:-https://github.com/XTLS/Xray-core/releases/download https://gh-proxy.com/https://github.com/XTLS/Xray-core/releases/download https://hub.gitmirror.com/https://github.com/XTLS/Xray-core/releases/download https://ghproxy.net/https://github.com/XTLS/Xray-core/releases/download https://sourceforge.net/projects/xray-core.mirror/files}"
XRAY_VERSION="${XRAY_VERSION:-}"
# FORCE_RENEW=1：一键安装/重装时强制生成新 UUID/REALITY 密钥；默认保留旧链接，避免误重装导致客户端全部失效。
FORCE_RENEW="${FORCE_RENEW:-0}"
# FORCE_DETECT_IP=1：忽略已保存 SERVER_IP，重新检测公网 IPv4；默认安装时会自动重新检测。
FORCE_DETECT_IP="${FORCE_DETECT_IP:-1}"
SCRIPT_LOG="${SCRIPT_LOG:-/var/log/xray-reality-installer.log}"
DIAG_DIR="${DIAG_DIR:-/root/xray-reality-diagnostics}"
TERMS_ACCEPT_FILE="${TERMS_ACCEPT_FILE:-/root/.xray-reality-script-terms-accepted}"
ACCEPT_TERMS="${ACCEPT_TERMS:-0}"
# APT_REFRESH=auto：只在缺依赖且本地索引找不到包时刷新软件源索引；不会执行 apt upgrade。
# APT_REFRESH=0：完全禁止 apt-get update；缺少可选依赖时跳过，缺少核心依赖则提示手动安装。
APT_REFRESH="${APT_REFRESH:-auto}"
INSTALL_OPTIONAL_DEPS="${INSTALL_OPTIONAL_DEPS:-1}"

PORT="${PORT:-443}"
SNI="${SNI:-www.microsoft.com}"
DEST="${DEST:-${SNI}:443}"
FINGERPRINT="${FINGERPRINT:-chrome}"
FLOW="${FLOW:-xtls-rprx-vision}"
NODE_NAME="${NODE_NAME:-u22-xray-reality}"
ENABLE_UFW="${ENABLE_UFW:-1}"
ENABLE_BBR="${ENABLE_BBR:-1}"
ENABLE_FAIL2BAN="${ENABLE_FAIL2BAN:-1}"
ENABLE_ONLINE_GUARD="${ENABLE_ONLINE_GUARD:-1}"
XRAY_BETA="${XRAY_BETA:-0}"
SSH_PORT="${SSH_PORT:-}"
SERVER_IP="${SERVER_IP:-}"
MAX_ONLINE_IPS="${MAX_ONLINE_IPS:-2}"
LIMIT_MODE="${LIMIT_MODE:-deny_new}"
ONLINE_IDLE_SECONDS="${ONLINE_IDLE_SECONDS:-300}"
BLOCK_SECONDS="${BLOCK_SECONDS:-900}"
KICK_BLOCK_SECONDS="${KICK_BLOCK_SECONDS:-300}"
SCAN_INTERVAL="${SCAN_INTERVAL:-2}"
BLOCK_QUIC="${BLOCK_QUIC:-0}"
ENABLE_SOCKOPT="${ENABLE_SOCKOPT:-1}"

UUID="${UUID:-}"
PRIVATE_KEY="${PRIVATE_KEY:-}"
PUBLIC_KEY="${PUBLIC_KEY:-}"
SHORT_ID="${SHORT_ID:-}"
SPIDERX="${SPIDERX:-}"
VLESS_LINK="${VLESS_LINK:-}"

log() { printf '\033[1;32m[*]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*" >&2; }
err() { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; }
die() { err "$*"; exit 1; }
press_enter() { printf '\n按回车继续...'; read -r _ || true; }

show_terms_notice() {
  cat <<'TERMS'
================ 使用前须知 / Terms of Use ================
本脚本仅用于学习、测试、系统运维练习和合法网络配置研究。
本脚本不是 Xray/XTLS/GitHub/云厂商官方项目，也不代表任何第三方立场。

运行本脚本可能修改：防火墙、systemd 服务、Xray 配置、内核网络参数、在线限制规则。
使用者必须自行确认当地法律法规、云服务商条款、网络管理要求和使用场景是否合法合规。
严禁用于未授权访问、攻击、欺诈、垃圾流量、恶意软件、盗号、扫描第三方系统等用途。

脚本按“现状”提供，不提供任何保证。使用、修改、转载、运行后产生的一切后果由使用者自行承担。
不同意以上条款，请立即停止使用。
===========================================================
TERMS
}

require_terms_acceptance() {
  if [[ "${ACCEPT_TERMS:-0}" == "1" || -f "$TERMS_ACCEPT_FILE" ]]; then
    return 0
  fi
  show_terms_notice
  echo
  read -r -p "请输入 AGREE 表示你已阅读并同意以上条款，其他输入将退出：" agree
  if [[ "$agree" != "AGREE" ]]; then
    die "未同意使用条款，已退出。"
  fi
  mkdir -p "$(dirname "$TERMS_ACCEPT_FILE")" 2>/dev/null || true
  printf 'accepted_at=%q\nscript=%q\n' "$(date '+%F %T %z')" "$0" > "$TERMS_ACCEPT_FILE" 2>/dev/null || true
  chmod 600 "$TERMS_ACCEPT_FILE" 2>/dev/null || true
}

init_logging() {
  if [[ "${EUID}" -eq 0 && "${XRAY_SCRIPT_LOGGING_STARTED:-0}" != "1" ]]; then
    mkdir -p "$(dirname "$SCRIPT_LOG")" 2>/dev/null || true
    touch "$SCRIPT_LOG" 2>/dev/null || true
    chmod 600 "$SCRIPT_LOG" 2>/dev/null || true
    export XRAY_SCRIPT_LOGGING_STARTED=1
    exec > >(tee -a "$SCRIPT_LOG") 2>&1
    log "脚本日志：$SCRIPT_LOG"
  fi
}

need_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    die "请用 root 执行：sudo bash $0"
  fi
  init_logging
  require_terms_acceptance
}

load_info() {
  if [[ -r "$XRAY_INFO" ]]; then
    # shellcheck disable=SC1090
    . "$XRAY_INFO" || true
  fi
  PORT="${PORT:-443}"
  SNI="${SNI:-www.microsoft.com}"
  DEST="${DEST:-${SNI}:443}"
  FINGERPRINT="${FINGERPRINT:-chrome}"
  FLOW="${FLOW:-xtls-rprx-vision}"
  NODE_NAME="${NODE_NAME:-u22-xray-reality}"
  MAX_ONLINE_IPS="${MAX_ONLINE_IPS:-2}"
  LIMIT_MODE="${LIMIT_MODE:-deny_new}"
  ONLINE_IDLE_SECONDS="${ONLINE_IDLE_SECONDS:-300}"
  BLOCK_SECONDS="${BLOCK_SECONDS:-900}"
  KICK_BLOCK_SECONDS="${KICK_BLOCK_SECONDS:-300}"
  SCAN_INTERVAL="${SCAN_INTERVAL:-2}"
  BLOCK_QUIC="${BLOCK_QUIC:-0}"
  ENABLE_SOCKOPT="${ENABLE_SOCKOPT:-1}"
}

save_info() {
  mkdir -p "$(dirname "$XRAY_INFO")"
  {
    printf 'UUID=%q\n' "$UUID"
    printf 'PRIVATE_KEY=%q\n' "$PRIVATE_KEY"
    printf 'PUBLIC_KEY=%q\n' "$PUBLIC_KEY"
    printf 'SHORT_ID=%q\n' "$SHORT_ID"
    printf 'SPIDERX=%q\n' "$SPIDERX"
    printf 'SERVER_IP=%q\n' "$SERVER_IP"
    printf 'PORT=%q\n' "$PORT"
    printf 'SNI=%q\n' "$SNI"
    printf 'DEST=%q\n' "$DEST"
    printf 'FINGERPRINT=%q\n' "$FINGERPRINT"
    printf 'FLOW=%q\n' "$FLOW"
    printf 'NODE_NAME=%q\n' "$NODE_NAME"
    printf 'MAX_ONLINE_IPS=%q\n' "$MAX_ONLINE_IPS"
    printf 'LIMIT_MODE=%q\n' "$LIMIT_MODE"
    printf 'ONLINE_IDLE_SECONDS=%q\n' "$ONLINE_IDLE_SECONDS"
    printf 'BLOCK_SECONDS=%q\n' "$BLOCK_SECONDS"
    printf 'KICK_BLOCK_SECONDS=%q\n' "$KICK_BLOCK_SECONDS"
    printf 'SCAN_INTERVAL=%q\n' "$SCAN_INTERVAL"
    printf 'BLOCK_QUIC=%q\n' "$BLOCK_QUIC"
    printf 'ENABLE_SOCKOPT=%q\n' "$ENABLE_SOCKOPT"
    printf 'VLESS_LINK=%q\n' "$VLESS_LINK"
  } > "$XRAY_INFO"
  chmod 600 "$XRAY_INFO"
}

check_os() {
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    if [[ "${ID:-}" != "ubuntu" ]]; then
      warn "当前系统 ID=${ID:-unknown}，本脚本按 Ubuntu 22.04+ 编写，仍会继续。"
    fi
    if [[ "${ID:-}" == "ubuntu" && "${VERSION_ID:-}" < "22.04" ]]; then
      warn "当前 Ubuntu ${VERSION_ID:-unknown} 低于 22.04，可能不完全兼容。"
    fi
  fi
  command -v systemctl >/dev/null 2>&1 || die "需要 systemd。"
}

validate_input() {
  [[ "$PORT" =~ ^[0-9]+$ ]] || die "PORT 必须是数字。"
  (( PORT >= 1 && PORT <= 65535 )) || die "PORT 必须在 1-65535。"
  [[ "$SNI" =~ ^[A-Za-z0-9.-]+$ ]] || die "SNI 必须是域名，例如 www.example.com。"
  [[ "$DEST" =~ ^[A-Za-z0-9.-]+:[0-9]+$ ]] || die "DEST 必须是 domain:port，例如 www.example.com:443。"
  [[ "$FINGERPRINT" =~ ^[A-Za-z0-9_-]+$ ]] || die "FINGERPRINT 包含非法字符。"
  [[ "$FLOW" =~ ^[A-Za-z0-9._-]+$ ]] || die "FLOW 包含非法字符。"
  [[ "$MAX_ONLINE_IPS" =~ ^[0-9]+$ ]] || die "MAX_ONLINE_IPS 必须是数字。"
  (( MAX_ONLINE_IPS >= 1 && MAX_ONLINE_IPS <= 20 )) || die "MAX_ONLINE_IPS 建议 1-20。"
  [[ "$ONLINE_IDLE_SECONDS" =~ ^[0-9]+$ ]] || die "ONLINE_IDLE_SECONDS 必须是数字。"
  [[ "$BLOCK_SECONDS" =~ ^[0-9]+$ ]] || die "BLOCK_SECONDS 必须是数字。"
  [[ "$KICK_BLOCK_SECONDS" =~ ^[0-9]+$ ]] || die "KICK_BLOCK_SECONDS 必须是数字。"
  [[ "$SCAN_INTERVAL" =~ ^[0-9]+$ ]] || die "SCAN_INTERVAL 必须是数字。"
  (( SCAN_INTERVAL >= 1 && SCAN_INTERVAL <= 60 )) || die "SCAN_INTERVAL 建议 1-60。"
  [[ "$LIMIT_MODE" == "deny_new" || "$LIMIT_MODE" == "kick_old" ]] || die "LIMIT_MODE 必须是 deny_new 或 kick_old。"
  [[ "$BLOCK_QUIC" == "0" || "$BLOCK_QUIC" == "1" ]] || die "BLOCK_QUIC 必须是 0 或 1。"
  [[ "$ENABLE_SOCKOPT" == "0" || "$ENABLE_SOCKOPT" == "1" ]] || die "ENABLE_SOCKOPT 必须是 0 或 1。"
  if [[ "$PORT" != "443" ]]; then
    warn "当前端口是 ${PORT}。REALITY 通常建议优先使用 TCP 443，随机高端口不一定更安全。"
  fi
}

pkg_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'
}

apt_install_group() {
  local label="$1" required="$2"; shift 2
  local packages=("$@") missing=() pkg rc logf
  for pkg in "${packages[@]}"; do
    if ! pkg_installed "$pkg"; then
      missing+=("$pkg")
    fi
  done
  if (( ${#missing[@]} == 0 )); then
    log "${label} 已满足：跳过安装。"
    return 0
  fi

  log "安装缺失${label}，不升级已安装软件包：${missing[*]}"
  logf="/tmp/xray-apt-${label//[^A-Za-z0-9_]/_}.$$.log"
  set +e
  apt-get install -y --no-install-recommends --no-upgrade "${missing[@]}" 2>&1 | tee "$logf"
  rc=${PIPESTATUS[0]}
  set -e

  if (( rc != 0 )) && grep -Eq 'Unable to locate package|没有可用的软件包|无法定位软件包|Package .* has no installation candidate' "$logf"; then
    if [[ "$APT_REFRESH" == "1" || "$APT_REFRESH" == "auto" ]]; then
      warn "本地 apt 软件包索引找不到部分依赖；现在只执行 apt-get update 刷新索引，不升级系统。"
      apt-get update -y
      set +e
      apt-get install -y --no-install-recommends --no-upgrade "${missing[@]}" 2>&1 | tee -a "$logf"
      rc=${PIPESTATUS[0]}
      set -e
    else
      warn "APT_REFRESH=0，禁止刷新 apt 索引。"
    fi
  fi

  if (( rc != 0 )); then
    if [[ "$required" == "1" ]]; then
      die "核心依赖安装失败：${missing[*]}。请检查 /etc/apt/sources.list 或网络后重试。日志：$logf"
    fi
    warn "可选依赖安装失败，已跳过：${missing[*]}。这不会阻止 Xray 安装；相关功能会自动禁用。日志：$logf"
    return 0
  fi
  rm -f "$logf" 2>/dev/null || true
}

apt_install() {
  export DEBIAN_FRONTEND=noninteractive
  # 核心依赖：缺少会影响安装/配置/启动。只安装缺失项，不执行 apt upgrade。
  local core optional
  core=(ca-certificates curl wget unzip jq openssl uuid-runtime ufw iproute2 procps iptables lsof)
  optional=(qrencode conntrack ipset fail2ban net-tools dnsutils)
  apt_install_group "核心依赖" 1 "${core[@]}"
  if [[ "$INSTALL_OPTIONAL_DEPS" == "1" ]]; then
    apt_install_group "可选依赖" 0 "${optional[@]}"
  else
    warn "INSTALL_OPTIONAL_DEPS=0：跳过二维码、在线限制、fail2ban、诊断增强等可选依赖安装。"
  fi

  if ! command -v jq >/dev/null 2>&1 || ! command -v unzip >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1; then
    die "核心命令缺失：需要 curl/unzip/jq。"
  fi
}

detect_ssh_port() {
  if [[ -n "$SSH_PORT" ]]; then
    printf '%s' "$SSH_PORT"
    return 0
  fi
  if [[ -n "${SSH_CONNECTION:-}" ]]; then
    printf '%s' "${SSH_CONNECTION##* }"
    return 0
  fi
  if [[ -r /etc/ssh/sshd_config ]]; then
    local p
    p="$(awk 'tolower($1)=="port" {print $2; exit}' /etc/ssh/sshd_config 2>/dev/null || true)"
    if [[ -n "$p" ]]; then
      printf '%s' "$p"
      return 0
    fi
  fi
  # 兜底：有些镜像把 SSH 端口放在 sshd_config.d/ 或云初始化里，主配置未必能直接读到。
  if command -v ss >/dev/null 2>&1; then
    local sp
    sp="$(ss -H -lntp 2>/dev/null | awk '/sshd/ {n=split($4,a,":"); print a[n]; exit}' || true)"
    if [[ "$sp" =~ ^[0-9]+$ ]]; then
      printf '%s' "$sp"
      return 0
    fi
  fi
  printf '22'
}

detect_public_ip() {
  local ip=""
  if [[ -n "${SERVER_IP:-}" ]]; then
    printf '%s' "$SERVER_IP"
    return 0
  fi
  ip="$(curl -4fsS --max-time 6 https://api.ipify.org 2>/dev/null || true)"
  if [[ -z "$ip" ]]; then
    ip="$(curl -4fsS --max-time 6 https://ipv4.icanhazip.com 2>/dev/null | tr -d '\n' || true)"
  fi
  if [[ -z "$ip" ]]; then
    ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
  fi
  [[ -n "$ip" ]] || die "无法自动检测公网 IPv4，请用 SERVER_IP=你的IP 执行。"
  printf '%s' "$ip"
}

urlencode() {
  jq -nr --arg v "$1" '$v|@uri'
}

download_file_multi() {
  local output="$1"; shift
  local url tmp rc
  tmp="${output}.tmp.$$"
  rm -f "$tmp"
  for url in "$@"; do
    [[ -n "$url" ]] || continue
    log "尝试下载：$url"
    rc=0
    curl -fL --retry 3 --retry-delay 2 --retry-all-errors --connect-timeout 15 --max-time 300 -o "$tmp" "$url" || rc=$?
    if [[ "$rc" -eq 0 && -s "$tmp" ]]; then
      mv -f "$tmp" "$output"
      return 0
    fi
    warn "下载失败或文件为空：$url"
    rm -f "$tmp"
  done
  return 1
}

xray_arch() {
  case "$(uname -m)" in
    i386|i686) printf '32' ;;
    amd64|x86_64) printf '64' ;;
    armv5tel) printf 'arm32-v5' ;;
    armv6l) printf 'arm32-v6' ;;
    armv7|armv7l) printf 'arm32-v7a' ;;
    armv8|aarch64) printf 'arm64-v8a' ;;
    mips) printf 'mips32' ;;
    mipsle) printf 'mips32le' ;;
    mips64) printf 'mips64' ;;
    mips64le) printf 'mips64le' ;;
    ppc64) printf 'ppc64' ;;
    ppc64le) printf 'ppc64le' ;;
    riscv64) printf 'riscv64' ;;
    s390x) printf 's390x' ;;
    *) die "当前架构不支持：$(uname -m)" ;;
  esac
}

latest_xray_version() {
  local v="${XRAY_VERSION:-}" location=""
  if [[ -n "$v" ]]; then
    v="${v#v}"
    printf '%s' "$v"
    return 0
  fi

  # GitHub API 失败时，改用 releases/latest 的跳转地址解析版本号。
  v="$(curl -fsSL --retry 3 --connect-timeout 15 --max-time 60 https://api.github.com/repos/XTLS/Xray-core/releases/latest 2>/dev/null | jq -r '.tag_name // empty' 2>/dev/null | sed 's/^v//' || true)"
  if [[ -z "$v" ]]; then
    location="$(curl -fsSIL --retry 3 --connect-timeout 15 --max-time 60 https://github.com/XTLS/Xray-core/releases/latest 2>/dev/null | awk -F': ' 'tolower($1)=="location" {gsub("\r", "", $2); print $2}' | tail -n 1 || true)"
    v="$(printf '%s' "$location" | sed -n 's#.*/tag/v\{0,1\}\([0-9][0-9A-Za-z._-]*\).*#\1#p')"
  fi
  [[ -n "$v" ]] || return 1
  printf '%s' "$v"
}

build_xray_asset_urls() {
  local version="$1" file="$2" base
  for base in $XRAY_DOWNLOAD_BASES; do
    base="${base%/}"
    case "$base" in
      *sourceforge.net/projects/xray-core.mirror/files)
        printf '%s\n' "${base}/v${version}/${file}/download"
        ;;
      *github.com/XTLS/Xray-core/releases/download|*XTLS/Xray-core/releases/download)
        printf '%s\n' "${base}/v${version}/${file}"
        ;;
      *)
        # 兼容形如 https://mirror.example/https://github.com/.../releases/download 的代理前缀。
        printf '%s\n' "${base}/v${version}/${file}"
        ;;
    esac
  done
}

install_xray_manual() {
  local version arch zip dgst work urls sha_expected sha_actual service_file
  version="$(latest_xray_version)" || die "无法获取 Xray 最新版本；可用 XRAY_VERSION=26.x.y 指定版本后重试。"
  arch="$(xray_arch)"
  zip="/tmp/Xray-linux-${arch}.zip"
  dgst="/tmp/Xray-linux-${arch}.zip.dgst"
  work="$(mktemp -d)"
  trap 'rm -rf "$work"' RETURN

  log "官方安装脚本失败，启用多源二进制回退安装：Xray v${version} / linux-${arch}。"
  mapfile -t urls < <(build_xray_asset_urls "$version" "Xray-linux-${arch}.zip")
  download_file_multi "$zip" "${urls[@]}" || die "所有 Xray 压缩包下载源均失败。可稍后重试，或设置 XRAY_DOWNLOAD_BASES。"

  mapfile -t urls < <(build_xray_asset_urls "$version" "Xray-linux-${arch}.zip.dgst")
  if download_file_multi "$dgst" "${urls[@]}"; then
    sha_expected="$(grep -Eio '[a-f0-9]{64}' "$dgst" | head -n 1 || true)"
    if [[ -n "$sha_expected" ]]; then
      sha_actual="$(sha256sum "$zip" | awk '{print $1}')"
      [[ "$sha_expected" == "$sha_actual" ]] || die "Xray 压缩包 SHA256 校验失败。"
      log "SHA256 校验通过。"
    else
      warn "未能从 .dgst 解析 SHA256，跳过哈希校验。"
    fi
  else
    warn "未下载到 .dgst 校验文件，将继续安装；建议网络恢复后再执行 update。"
  fi

  unzip -oq "$zip" -d "$work"
  [[ -x "$work/xray" || -f "$work/xray" ]] || die "压缩包内未找到 xray 可执行文件。"
  install -m 755 "$work/xray" "$XRAY_BIN"
  setcap 'cap_net_bind_service=+ep' "$XRAY_BIN" 2>/dev/null || true

  mkdir -p /usr/local/share/xray "$XRAY_CONF_DIR" /var/log/xray
  [[ -f "$work/geoip.dat" ]] && install -m 644 "$work/geoip.dat" /usr/local/share/xray/geoip.dat
  [[ -f "$work/geosite.dat" ]] && install -m 644 "$work/geosite.dat" /usr/local/share/xray/geosite.dat
  chmod 700 "$XRAY_CONF_DIR"
  chmod 755 /var/log/xray

  service_file="/etc/systemd/system/xray.service"
  if [[ ! -f "$service_file" ]]; then
    cat > "$service_file" <<'UNIT'
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target
Wants=network.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
UNIT
  fi
  systemctl daemon-reload || true
  log "多源二进制回退安装完成：$($XRAY_BIN version | head -n 1 || true)"
}

install_xray() {
  local installer="/tmp/xray-install-release.sh" url ok=0
  rm -f "$installer"
  log "下载官方 XTLS/Xray 安装脚本，多源回退已启用。"
  for url in $INSTALL_URLS; do
    if download_file_multi "$installer" "$url"; then
      ok=1
      break
    fi
  done
  [[ "$ok" -eq 1 ]] || die "所有 Xray 安装脚本下载源均失败。"
  chmod +x "$installer"

  if [[ "$XRAY_BETA" == "1" ]]; then
    log "安装 latest pre-release Xray，因为 XRAY_BETA=1。"
    bash "$installer" install --beta || install_xray_manual
  else
    log "安装/升级 stable Xray。"
    bash "$installer" install || install_xray_manual
  fi
  [[ -x "$XRAY_BIN" ]] || die "没有找到 Xray：$XRAY_BIN"
}

generate_values() {
  UUID="$($XRAY_BIN uuid 2>/dev/null || cat /proc/sys/kernel/random/uuid)"
  local pair
  pair="$($XRAY_BIN x25519)"
  PRIVATE_KEY="$(printf '%s\n' "$pair" | awk -F': ' '/PrivateKey|Private key/ {print $2; exit}')"
  PUBLIC_KEY="$(printf '%s\n' "$pair" | awk -F': ' '/Password|PublicKey|Public key/ {print $2; exit}')"
  SHORT_ID="$(openssl rand -hex 8)"
  SPIDERX="/${SHORT_ID:0:8}"
  [[ -n "$UUID" && -n "$PRIVATE_KEY" && -n "$PUBLIC_KEY" && -n "$SHORT_ID" ]] || die "生成 UUID/REALITY 密钥失败。"
}

ensure_values() {
  load_info
  if [[ -z "${UUID:-}" || -z "${PRIVATE_KEY:-}" || -z "${PUBLIC_KEY:-}" || -z "${SHORT_ID:-}" ]]; then
    generate_values
  fi
  if [[ -z "${SERVER_IP:-}" ]]; then
    SERVER_IP="$(detect_public_ip)"
  fi
  SPIDERX="${SPIDERX:-/${SHORT_ID:0:8}}"
}

write_server_config() {
  mkdir -p "$XRAY_CONF_DIR" /var/log/xray
  chmod 700 "$XRAY_CONF_DIR"
  chmod 755 /var/log/xray
  cp -a "$XRAY_CONF" "${XRAY_CONF}.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true

  local quic_rule=""
  if [[ "$BLOCK_QUIC" == "1" ]]; then
    quic_rule=',
      {
        "type": "field",
        "protocol": ["quic"],
        "outboundTag": "block"
      }'
  fi

  local sockopt_block=""
  if [[ "$ENABLE_SOCKOPT" == "1" ]]; then
    sockopt_block=',
        "sockopt": {
          "tcpFastOpen": true,
          "tcpKeepAliveInterval": 30
        }'
  fi

  cat > "$XRAY_CONF" <<JSON
{
  "log": {
    "loglevel": "warning",
    "error": "/var/log/xray/error.log"
  },
  "inbounds": [
    {
      "tag": "vless-reality-in",
      "listen": "0.0.0.0",
      "port": ${PORT},
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${UUID}",
            "flow": "${FLOW}",
            "email": "${NODE_NAME}"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality"${sockopt_block},
        "realitySettings": {
          "show": false,
          "target": "${DEST}",
          "xver": 0,
          "serverNames": ["${SNI}"],
          "privateKey": "${PRIVATE_KEY}",
          "shortIds": ["${SHORT_ID}"]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls", "quic"],
        "routeOnly": true
      }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom"
    },
    {
      "tag": "block",
      "protocol": "blackhole"
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "protocol": ["bittorrent"],
        "outboundTag": "block"
      }${quic_rule},
      {
        "type": "field",
        "ip": ["geoip:private"],
        "outboundTag": "block"
      }
    ]
  }
}
JSON
  chmod 600 "$XRAY_CONF"
}

write_client_files() {
  local server_ip="$1"
  local sni_enc spx_enc name_enc flow_enc
  sni_enc="$(urlencode "$SNI")"
  spx_enc="$(urlencode "$SPIDERX")"
  name_enc="$(urlencode "$NODE_NAME")"
  flow_enc="$(urlencode "$FLOW")"
  VLESS_LINK="vless://${UUID}@${server_ip}:${PORT}?encryption=none&security=reality&sni=${sni_enc}&fp=${FINGERPRINT}&pbk=${PUBLIC_KEY}&sid=${SHORT_ID}&type=tcp&flow=${flow_enc}&spx=${spx_enc}#${name_enc}"

  cat > "$CLIENT_JSON" <<JSON
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 10808,
      "protocol": "socks",
      "settings": {
        "udp": true
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls", "quic"]
      }
    }
  ],
  "outbounds": [
    {
      "tag": "proxy",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "${server_ip}",
            "port": ${PORT},
            "users": [
              {
                "id": "${UUID}",
                "encryption": "none",
                "flow": "${FLOW}"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "serverName": "${SNI}",
          "fingerprint": "${FINGERPRINT}",
          "publicKey": "${PUBLIC_KEY}",
          "shortId": "${SHORT_ID}",
          "spiderX": "${SPIDERX}"
        }
      }
    },
    {
      "tag": "direct",
      "protocol": "freedom"
    },
    {
      "tag": "block",
      "protocol": "blackhole"
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "ip": ["geoip:private"],
        "outboundTag": "direct"
      }
    ]
  }
}
JSON

  cat > "$MIHOMO_YAML" <<YAML
proxies:
  - name: "${NODE_NAME}"
    type: vless
    server: ${server_ip}
    port: ${PORT}
    uuid: ${UUID}
    network: tcp
    udp: true
    tls: true
    flow: ${FLOW}
    servername: ${SNI}
    client-fingerprint: ${FINGERPRINT}
    reality-opts:
      public-key: ${PUBLIC_KEY}
      short-id: ${SHORT_ID}
YAML

  printf '%s\n' "$VLESS_LINK" > "$LINK_TXT"
  chmod 600 "$CLIENT_JSON" "$MIHOMO_YAML" "$LINK_TXT"
  SERVER_IP="$server_ip"
  save_info
}

firewall_status_summary() {
  echo "UFW：$(ufw status 2>/dev/null | head -n 1 || echo unavailable)"
  if command -v firewall-cmd >/dev/null 2>&1; then
    if systemctl is-active --quiet firewalld 2>/dev/null; then
      echo "firewalld：running"
    else
      echo "firewalld：installed but not running"
    fi
  else
    echo "firewalld：not installed"
  fi
  if command -v iptables >/dev/null 2>&1; then
    echo "iptables：available"
  else
    echo "iptables：unavailable"
  fi
}

iptables_allow_tcp_port() {
  local port="$1"
  [[ "$port" =~ ^[0-9]+$ ]] || return 0
  iptables -C INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null || \
    iptables -I INPUT 1 -p tcp --dport "$port" -j ACCEPT 2>/dev/null || true
}

configure_firewall() {
  local ssh_port ufw_status
  ssh_port="$(detect_ssh_port)"
  log "提前放行端口：SSH ${ssh_port}/tcp，Xray ${PORT}/tcp。"

  # 1) Ubuntu 默认优先处理 UFW：先 allow，再 enable/reload，避免加固后断连。
  if command -v ufw >/dev/null 2>&1; then
    ufw allow "${ssh_port}/tcp" >/dev/null || true
    ufw allow "${PORT}/tcp" >/dev/null || true
    ufw_status="$(ufw status 2>/dev/null | head -n 1 || true)"
    if [[ "$ENABLE_UFW" == "1" ]]; then
      if printf '%s' "$ufw_status" | grep -qi inactive; then
        log "检测到 UFW 未启用：已先放行端口，现在启用 UFW。"
        ufw --force enable >/dev/null || true
      else
        log "检测到 UFW 已启用：已更新放行规则并 reload。"
        ufw reload >/dev/null 2>&1 || true
      fi
    else
      warn "ENABLE_UFW=0：已尝试写入 UFW allow 规则，但不会主动启用 UFW。"
    fi
  fi

  # 2) 如果系统启用了 firewalld，也同步放行。
  if command -v firewall-cmd >/dev/null 2>&1 && systemctl is-active --quiet firewalld 2>/dev/null; then
    log "检测到 firewalld：同步放行 SSH ${ssh_port}/tcp 和 Xray ${PORT}/tcp。"
    firewall-cmd --permanent --add-port="${ssh_port}/tcp" >/dev/null 2>&1 || true
    firewall-cmd --permanent --add-port="${PORT}/tcp" >/dev/null 2>&1 || true
    firewall-cmd --reload >/dev/null 2>&1 || true
  fi

  # 3) 兜底写入 iptables ACCEPT，放在前面，避免已有 DROP 规则挡住端口。
  if command -v iptables >/dev/null 2>&1; then
    iptables_allow_tcp_port "$ssh_port"
    iptables_allow_tcp_port "$PORT"
  fi

  warn "云厂商安全组/面板防火墙无法由脚本保证修改，请确认服务商后台也放行 TCP ${PORT}。"
}

apply_network_tuning() {
  log "写入网络优化参数：BBR、fq、TFO、MTU probing、连接队列、文件句柄。"
  cat > "$SYSCTL_CONF" <<'CONF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_keepalive_time=600
net.ipv4.tcp_keepalive_intvl=30
net.ipv4.tcp_keepalive_probes=5
net.ipv4.ip_local_port_range=1024 65000
net.core.somaxconn=65535
net.ipv4.tcp_max_syn_backlog=65535
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_ignore_bogus_error_responses=1
CONF
  sysctl --system >/dev/null || true
  mkdir -p "$XRAY_OVERRIDE_DIR"
  cat > "$XRAY_OVERRIDE" <<'CONF'
[Service]
LimitNOFILE=1048576
# 允许非 root 用户绑定 443 等低端口，避免部分系统上 status=23/permission denied。
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=
CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_NET_ADMIN CAP_NET_RAW
NoNewPrivileges=false
CONF
  systemctl daemon-reload || true
  systemctl restart xray 2>/dev/null || true
  log "网络优化完成。当前拥塞控制：$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo unknown)"
}

restore_network_tuning() {
  rm -f "$SYSCTL_CONF" "$XRAY_OVERRIDE"
  rmdir "$XRAY_OVERRIDE_DIR" 2>/dev/null || true
  systemctl daemon-reload || true
  sysctl --system >/dev/null || true
  systemctl restart xray 2>/dev/null || true
  log "已移除本脚本写入的网络优化文件。系统默认值是否恢复，取决于其他 sysctl 配置。"
}

configure_fail2ban() {
  if [[ "$ENABLE_FAIL2BAN" != "1" ]]; then
    warn "ENABLE_FAIL2BAN=0，跳过 fail2ban。"
    return 0
  fi
  if ! command -v fail2ban-server >/dev/null 2>&1; then
    warn "fail2ban 未安装，已跳过 SSH 防爆破加固；不影响 Xray 安装。"
    return 0
  fi
  mkdir -p /etc/fail2ban/jail.d
  cat > /etc/fail2ban/jail.d/sshd-xray-hardening.local <<'CONF'
[sshd]
enabled = true
backend = systemd
maxretry = 5
findtime = 10m
bantime = 1h
CONF
  systemctl enable fail2ban >/dev/null || true
  systemctl restart fail2ban || warn "fail2ban 启动失败，已跳过；不影响 Xray。"
}

write_online_guard() {
  cat > "$ONLINE_ENV" <<ENV
PORT=${PORT}
MAX_ONLINE_IPS=${MAX_ONLINE_IPS}
LIMIT_MODE=${LIMIT_MODE}
ONLINE_IDLE_SECONDS=${ONLINE_IDLE_SECONDS}
BLOCK_SECONDS=${BLOCK_SECONDS}
KICK_BLOCK_SECONDS=${KICK_BLOCK_SECONDS}
SCAN_INTERVAL=${SCAN_INTERVAL}
SERVER_IP=${SERVER_IP}
ENV
  chmod 600 "$ONLINE_ENV"

  cat > "$ONLINE_GUARD" <<'GUARD'
#!/usr/bin/env bash
set -Eeuo pipefail

PORT="${PORT:-443}"
MAX_ONLINE_IPS="${MAX_ONLINE_IPS:-2}"
LIMIT_MODE="${LIMIT_MODE:-deny_new}"
ONLINE_IDLE_SECONDS="${ONLINE_IDLE_SECONDS:-300}"
BLOCK_SECONDS="${BLOCK_SECONDS:-900}"
KICK_BLOCK_SECONDS="${KICK_BLOCK_SECONDS:-300}"
SCAN_INTERVAL="${SCAN_INTERVAL:-2}"
SET_NAME="xray_guard_block"
STATE_DIR="/run/xray-online-guard"
STATE_FILE="${STATE_DIR}/clients.tsv"
ACTIVE_FILE="${STATE_DIR}/active.list"
LOG_FILE="/var/log/xray/online-guard.log"

# Bash 4.4 在 set -u 下，空关联数组如果只 declare -A，读取长度会报 unbound variable。
# 必须初始化为 =()，否则菜单 5 可能一直 none，服务日志出现 FIRST: unbound variable。
declare -A FIRST=() LAST=()

mkdir -p "$STATE_DIR" /var/log/xray
touch "$STATE_FILE" "$ACTIVE_FILE" "$LOG_FILE"
chmod 700 "$STATE_DIR"
chmod 600 "$STATE_FILE" "$ACTIVE_FILE" "$LOG_FILE"

log() {
  printf '%s %s\n' "$(date '+%F %T')" "$*" >> "$LOG_FILE"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { log "missing command: $1"; return 1; }
}

is_num() { [[ "${1:-}" =~ ^[0-9]+$ ]]; }

validate_runtime_env() {
  is_num "$PORT" || PORT=443
  is_num "$MAX_ONLINE_IPS" || MAX_ONLINE_IPS=2
  is_num "$ONLINE_IDLE_SECONDS" || ONLINE_IDLE_SECONDS=300
  is_num "$BLOCK_SECONDS" || BLOCK_SECONDS=900
  is_num "$KICK_BLOCK_SECONDS" || KICK_BLOCK_SECONDS=60
  is_num "$SCAN_INTERVAL" || SCAN_INTERVAL=2
  (( MAX_ONLINE_IPS >= 1 )) || MAX_ONLINE_IPS=1
  (( MAX_ONLINE_IPS <= 100 )) || MAX_ONLINE_IPS=100
  (( SCAN_INTERVAL >= 1 )) || SCAN_INTERVAL=1
  (( SCAN_INTERVAL <= 60 )) || SCAN_INTERVAL=60
  [[ "$LIMIT_MODE" == "deny_new" || "$LIMIT_MODE" == "kick_old" ]] || LIMIT_MODE="deny_new"
}

setup_firewall() {
  need_cmd ipset || exit 1
  need_cmd iptables || exit 1
  ipset create "$SET_NAME" hash:ip family inet timeout "$BLOCK_SECONDS" -exist
  while iptables -D INPUT -p tcp --dport "$PORT" -m set --match-set "$SET_NAME" src -j REJECT --reject-with tcp-reset 2>/dev/null; do :; done
  iptables -I INPUT 1 -p tcp --dport "$PORT" -m set --match-set "$SET_NAME" src -j REJECT --reject-with tcp-reset
}

cleanup_firewall() {
  iptables -D INPUT -p tcp --dport "$PORT" -m set --match-set "$SET_NAME" src -j REJECT --reject-with tcp-reset 2>/dev/null || true
}

local_ipv4_list() {
  {
    printf '%s\n' "${SERVER_IP:-}"
    ip -o -4 addr show scope global 2>/dev/null | awk '{split($4,a,"/"); print a[1]}'
    ip -o -4 addr show scope host 2>/dev/null | awk '{split($4,a,"/"); print a[1]}'
  } | grep -E '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' | sort -u || true
}

active_ips_conntrack() {
  command -v conntrack >/dev/null 2>&1 || return 0
  local locals
  locals="$(local_ipv4_list | tr '\n' ' ')"
  conntrack -L -f ipv4 -p tcp --dport "$PORT" 2>/dev/null \
    | awk -v port="$PORT" -v locals="$locals" '
      BEGIN { split(locals,l," "); for (i in l) if (l[i] != "") local[l[i]]=1 }
      $0 ~ ("dport=" port) && ($0 ~ /ESTABLISHED|SYN_SENT|SYN_RECV|FIN_WAIT|CLOSE_WAIT/) {
        src=""; dst="";
        for (i=1; i<=NF; i++) {
          if ($i ~ /^src=/ && src == "") { split($i,a,"="); src=a[2] }
          if ($i ~ /^dst=/ && dst == "") { split($i,b,"="); dst=b[2] }
        }
        if (src ~ /^[0-9]{1,3}(\.[0-9]{1,3}){3}$/ && !(src in local) && (dst in local || dst == "0.0.0.0")) print src
      }' || true
}

active_ips_ss() {
  command -v ss >/dev/null 2>&1 || return 0
  local locals
  locals="$(local_ipv4_list | tr '\n' ' ')"
  ss -Htan state established 2>/dev/null \
    | awk -v p=":${PORT}" -v locals="$locals" '
      BEGIN { split(locals,l," "); for (i in l) if (l[i] != "") local[l[i]]=1 }
      function strip_port(x) { gsub(/^\[|\]$/, "", x); sub(/^::ffff:/,"",x); sub(/:[0-9]+$/, "", x); return x }
      {
        lip=strip_port($4); peer=strip_port($5)
        if (index($4, p) && peer ~ /^[0-9]{1,3}(\.[0-9]{1,3}){3}$/ && !(peer in local)) print peer
      }' || true
}

active_ips() {
  { active_ips_conntrack; active_ips_ss; } \
    | grep -E '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' \
    | grep -Ev '^(0\.0\.0\.0|127\.|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)' \
    | sort -u || true
}

block_ip() {
  local ip="$1" timeout="$2"
  ipset add "$SET_NAME" "$ip" timeout "$timeout" -exist 2>/dev/null || true
}

unblock_ip() {
  local ip="$1"
  ipset del "$SET_NAME" "$ip" 2>/dev/null || true
}

drop_conntrack() {
  local ip="$1"
  conntrack -D -f ipv4 -p tcp -s "$ip" --dport "$PORT" >/dev/null 2>&1 || \
  conntrack -D -f ipv4 -p tcp -s "$ip" >/dev/null 2>&1 || true
}

write_state() {
  local tmp="${STATE_FILE}.tmp"
  : > "$tmp"
  local ip
  for ip in "${!FIRST[@]}"; do
    printf '%s\t%s\t%s\n' "$ip" "${FIRST[$ip]}" "${LAST[$ip]}" >> "$tmp"
  done
  sort -k2,2n "$tmp" > "$STATE_FILE" || mv "$tmp" "$STATE_FILE"
  rm -f "$tmp" 2>/dev/null || true
}

load_state() {
  FIRST=()
  LAST=()
  local ip first last
  while IFS=$'\t' read -r ip first last; do
    [[ -n "${ip:-}" && -n "${first:-}" && -n "${last:-}" ]] || continue
    [[ "$ip" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]] || continue
    is_num "$first" || continue
    is_num "$last" || continue
    FIRST["$ip"]="$first"
    LAST["$ip"]="$last"
  done < "$STATE_FILE"
}

count_state() {
  printf '%s' "${#FIRST[@]}"
}

oldest_ip() {
  local ip oldest="" oldest_time="9999999999"
  for ip in "${!FIRST[@]}"; do
    if (( FIRST[$ip] < oldest_time )); then
      oldest_time="${FIRST[$ip]}"
      oldest="$ip"
    fi
  done
  printf '%s' "$oldest"
}

main_loop() {
  validate_runtime_env
  setup_firewall
  trap cleanup_firewall EXIT
  log "started: port=${PORT}, max=${MAX_ONLINE_IPS}, mode=${LIMIT_MODE}, scan=${SCAN_INTERVAL}s"
  while true; do
    local now ip found old
    now="$(date +%s)"
    load_state

    active_ips > "$ACTIVE_FILE"

    for ip in "${!FIRST[@]}"; do
      found=0
      if grep -Fxq "$ip" "$ACTIVE_FILE"; then
        found=1
      fi
      if (( found == 0 )) && (( now - LAST[$ip] > ONLINE_IDLE_SECONDS )); then
        unset 'FIRST[$ip]'
        unset 'LAST[$ip]'
        unblock_ip "$ip"
        log "released inactive client ip=${ip}"
      fi
    done

    while IFS= read -r ip; do
      [[ -n "$ip" ]] || continue
      if [[ -n "${FIRST[$ip]:-}" ]]; then
        LAST["$ip"]="$now"
        unblock_ip "$ip"
        continue
      fi

      if (( ${#FIRST[@]} < MAX_ONLINE_IPS )); then
        FIRST["$ip"]="$now"
        LAST["$ip"]="$now"
        unblock_ip "$ip"
        log "accepted client ip=${ip}; online=${#FIRST[@]}/${MAX_ONLINE_IPS}"
        continue
      fi

      if [[ "$LIMIT_MODE" == "kick_old" ]]; then
        old="$(oldest_ip)"
        if [[ -n "$old" && "$old" != "$ip" ]]; then
          block_ip "$old" "$KICK_BLOCK_SECONDS"
          drop_conntrack "$old"
          unset 'FIRST[$old]'
          unset 'LAST[$old]'
          FIRST["$ip"]="$now"
          LAST["$ip"]="$now"
          unblock_ip "$ip"
          log "kicked old ip=${old}; accepted new ip=${ip}; online=${#FIRST[@]}/${MAX_ONLINE_IPS}"
        fi
      else
        block_ip "$ip" "$BLOCK_SECONDS"
        drop_conntrack "$ip"
        log "denied extra client ip=${ip}; online=${#FIRST[@]}/${MAX_ONLINE_IPS}"
      fi
    done < "$ACTIVE_FILE"

    write_state
    sleep "$SCAN_INTERVAL"
  done
}

main_loop
GUARD
  chmod 700 "$ONLINE_GUARD"

  cat > "$ONLINE_UNIT" <<'UNIT'
[Unit]
Description=Xray online client IP guard
After=network-online.target xray.service
Wants=network-online.target
Requires=xray.service

[Service]
Type=simple
EnvironmentFile=/etc/default/xray-online-guard
ExecStart=/usr/local/sbin/xray-online-guard
Restart=always
RestartSec=2
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=true

[Install]
WantedBy=multi-user.target
UNIT
  chmod 644 "$ONLINE_UNIT"
}

start_online_guard() {
  if [[ "$ENABLE_ONLINE_GUARD" != "1" ]]; then
    warn "ENABLE_ONLINE_GUARD=0，已跳过在线客户端限制。"
    return 0
  fi
  local missing=()
  command -v ipset >/dev/null 2>&1 || missing+=(ipset)
  command -v conntrack >/dev/null 2>&1 || missing+=(conntrack)
  command -v iptables >/dev/null 2>&1 || missing+=(iptables)
  if (( ${#missing[@]} > 0 )); then
    warn "在线人数限制依赖缺失，已自动跳过该功能：${missing[*]}。Xray 主服务仍可正常使用。"
    return 0
  fi
  write_online_guard
  systemctl daemon-reload
  systemctl enable xray-online-guard >/dev/null || true
  if ! systemctl restart xray-online-guard; then
    warn "在线限制服务启动失败，已跳过；不影响 Xray 主服务。可运行 diag 导出日志。"
    systemctl --no-pager --full status xray-online-guard | sed -n '1,10p' || true
    return 0
  fi
  sleep 1
  systemctl --no-pager --full status xray-online-guard | sed -n '1,8p' || true
}

stop_online_guard() {
  local old_port="$PORT"
  if [[ -r "$ONLINE_ENV" ]]; then
    old_port="$(awk -F= '$1=="PORT" {print $2; exit}' "$ONLINE_ENV" 2>/dev/null || printf '%s' "$PORT")"
  fi
  systemctl disable --now xray-online-guard 2>/dev/null || true
  iptables -D INPUT -p tcp --dport "$old_port" -m set --match-set xray_guard_block src -j REJECT --reject-with tcp-reset 2>/dev/null || true
  ipset destroy xray_guard_block 2>/dev/null || true
  rm -f /run/xray-online-guard/clients.tsv /run/xray-online-guard/active.list 2>/dev/null || true
}

restart_services() {
  need_root
  load_info
  if [[ -x "$XRAY_BIN" && -r "$XRAY_CONF" ]]; then
    "$XRAY_BIN" run -test -config "$XRAY_CONF"
  fi
  systemctl restart xray 2>/dev/null || {
    warn "Xray 重启失败，正在生成排查日志包。"
    collect_diagnostics >/dev/null || true
    systemctl --no-pager --full status xray | sed -n '1,20p' || true
    return 1
  }
  stop_online_guard
  start_online_guard
  log "已重启 Xray，并已重写/重启在线统计与限制服务。"
}

redact_sensitive() {
  sed -E \
    -e 's/("id"[[:space:]]*:[[:space:]]*")[^"]+(".*)/\1***REDACTED_UUID***\2/g' \
    -e 's/("privateKey"[[:space:]]*:[[:space:]]*")[^"]+(".*)/\1***REDACTED_PRIVATE_KEY***\2/g' \
    -e 's/("password"[[:space:]]*:[[:space:]]*")[^"]+(".*)/\1***REDACTED_PUBLIC_KEY***\2/g' \
    -e 's/("shortIds"[[:space:]]*:[[:space:]]*\[?")[^"]+(".*)/\1***REDACTED_SHORT_ID***\2/g' \
    -e 's/(short-id:[[:space:]]*).*/\1***REDACTED_SHORT_ID***/g' \
    -e 's/(public-key:[[:space:]]*).*/\1***REDACTED_PUBLIC_KEY***/g' \
    -e 's/(UUID=).*/\1***REDACTED_UUID***/g' \
    -e 's/(PRIVATE_KEY=).*/\1***REDACTED_PRIVATE_KEY***/g' \
    -e 's/(PUBLIC_KEY=).*/\1***REDACTED_PUBLIC_KEY***/g' \
    -e 's/(SHORT_ID=).*/\1***REDACTED_SHORT_ID***/g' \
    -e 's#(vless://)[^@]+@#\1***REDACTED_UUID***@#g'
}

collect_diagnostics() {
  need_root
  local ts out archive
  ts="$(date +%Y%m%d-%H%M%S)"
  out="${DIAG_DIR}/${ts}"
  archive="${DIAG_DIR}/xray-diagnostic-${ts}.tar.gz"
  mkdir -p "$out"
  chmod 700 "$DIAG_DIR" "$out" 2>/dev/null || true

  {
    echo "date: $(date -Is)"
    echo "script: $0"
    echo "log: $SCRIPT_LOG"
    echo "port: ${PORT:-unknown}"
    echo "sni: ${SNI:-unknown}"
    echo "dest: ${DEST:-unknown}"
    echo "user: $(id 2>/dev/null || true)"
    echo
    [[ -r /etc/os-release ]] && cat /etc/os-release
  } > "$out/00-system.txt" 2>&1 || true

  { command -v "$XRAY_BIN" >/dev/null 2>&1 && "$XRAY_BIN" version || true; } > "$out/01-xray-version.txt" 2>&1 || true
  { systemctl cat xray || true; } > "$out/02-systemctl-cat-xray.txt" 2>&1 || true
  { systemctl --no-pager --full status xray || true; } > "$out/03-systemctl-status-xray.txt" 2>&1 || true
  { journalctl -u xray --no-pager -n 200 || true; } > "$out/04-journal-xray.txt" 2>&1 || true
  { journalctl -u xray-online-guard --no-pager -n 120 || true; } > "$out/05-journal-online-guard.txt" 2>&1 || true
  { ss -lntup || true; echo; lsof -nP -iTCP:"${PORT:-443}" -sTCP:LISTEN || true; } > "$out/06-port-listen.txt" 2>&1 || true
  { ufw status verbose || true; echo; iptables -S || true; echo; command -v ipset >/dev/null 2>&1 && ipset list || echo 'ipset: not installed'; } > "$out/07-firewall.txt" 2>&1 || true
  { sysctl net.ipv4.tcp_congestion_control net.core.default_qdisc net.ipv4.tcp_fastopen net.ipv4.tcp_mtu_probing 2>/dev/null || true; } > "$out/08-sysctl.txt" 2>&1 || true
  { [[ -r "$XRAY_CONF" ]] && redact_sensitive < "$XRAY_CONF" || true; } > "$out/09-config-redacted.json" 2>&1 || true
  { [[ -r "$XRAY_INFO" ]] && redact_sensitive < "$XRAY_INFO" || true; } > "$out/10-env-redacted.txt" 2>&1 || true
  { [[ -r /var/log/xray/error.log ]] && tail -n 300 /var/log/xray/error.log || true; } > "$out/11-xray-error-log.txt" 2>&1 || true
  { [[ -r "$SCRIPT_LOG" ]] && tail -n 500 "$SCRIPT_LOG" || true; } > "$out/12-installer-log-tail.txt" 2>&1 || true
  { command -v "$XRAY_BIN" >/dev/null 2>&1 && [[ -r "$XRAY_CONF" ]] && "$XRAY_BIN" run -test -config "$XRAY_CONF" || true; } > "$out/13-xray-config-test.txt" 2>&1 || true
  { apt-cache policy qrencode fail2ban conntrack ipset jq unzip curl 2>/dev/null || true; } > "$out/14-apt-policy.txt" 2>&1 || true
  { echo "--- clients.tsv ---"; cat /run/xray-online-guard/clients.tsv 2>/dev/null || true; echo; echo "--- active.list ---"; cat /run/xray-online-guard/active.list 2>/dev/null || true; echo; echo "--- online-guard.log ---"; tail -n 300 /var/log/xray/online-guard.log 2>/dev/null || true; } > "$out/15-online-state.txt" 2>&1 || true

  tar -C "$DIAG_DIR" -czf "$archive" "$ts"
  chmod 600 "$archive" 2>/dev/null || true
  log "排查日志包已生成：$archive"
  echo "$archive"
}

ensure_xray_service_runtime() {
  mkdir -p "$XRAY_OVERRIDE_DIR" /var/log/xray
  # 为了新系统和官方/手动两种安装方式都稳定：用 root 运行主服务，避免 /var/log/xray 权限和 443 低端口 capability 差异导致 status=23。
  cat > "$XRAY_OVERRIDE_DIR/99-xray-reality-runtime.conf" <<'CONF'
[Service]
User=root
Group=root
LimitNOFILE=1048576
CapabilityBoundingSet=
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=false
CONF
  chmod 644 "$XRAY_OVERRIDE_DIR/99-xray-reality-runtime.conf"
  chown -R root:root /var/log/xray 2>/dev/null || true
  chmod 755 /var/log/xray 2>/dev/null || true
  touch /var/log/xray/error.log 2>/dev/null || true
  chmod 644 /var/log/xray/error.log 2>/dev/null || true
  systemctl daemon-reload || true
}

start_service() {
  ensure_xray_service_runtime
  "$XRAY_BIN" run -test -config "$XRAY_CONF"
  systemctl daemon-reload
  systemctl enable xray >/dev/null
  if ! systemctl restart xray; then
    err "Xray 服务启动失败。下面输出关键排查信息："
    systemctl --no-pager --full status xray || true
    echo
    echo "--- journalctl -u xray 最近 80 行 ---"
    journalctl -u xray --no-pager -n 80 || true
    echo
    echo "--- ${PORT}/tcp 端口占用 ---"
    ss -lntup 2>/dev/null | awk -v p=":${PORT}" '$4 ~ p {print}' || true
    lsof -nP -iTCP:"${PORT}" -sTCP:LISTEN 2>/dev/null || true
    echo
    collect_diagnostics >/dev/null || true
    die "Xray 启动失败。请把上面显示的排查日志包发给我。常见原因：443 已被 nginx/apache/caddy 占用、systemd 权限/Capability 异常、旧 drop-in 覆盖了服务启动参数。"
  fi
  sleep 1
  systemctl --no-pager --full status xray | sed -n '1,10p'
}

print_info() {
  load_info
  if [[ ! -r "$XRAY_INFO" ]]; then
    die "没有安装信息：$XRAY_INFO。请先安装。"
  fi
  cat <<OUT

================ Xray VLESS REALITY V3.1 菜单版 ================
Server:       ${SERVER_IP}:${PORT}
Protocol:     VLESS + TCP/RAW + REALITY + Vision
UUID:         ${UUID}
SNI:          ${SNI}
Public key:   ${PUBLIC_KEY}
Short ID:     ${SHORT_ID}
Fingerprint:  ${FINGERPRINT}
Flow:         ${FLOW}
Online limit: ${MAX_ONLINE_IPS} client IP(s), mode=${LIMIT_MODE}
Idle release: ${ONLINE_IDLE_SECONDS}s
Block QUIC:   ${BLOCK_QUIC}
Sockopt/TFO:  ${ENABLE_SOCKOPT}

Import link:
${VLESS_LINK}

Saved files:
  ${LINK_TXT}
  ${CLIENT_JSON}
  ${MIHOMO_YAML}
  ${XRAY_CONF}
  ${XRAY_INFO}
===========================================================
OUT
  if command -v qrencode >/dev/null 2>&1; then
    qrencode -t ANSIUTF8 "$VLESS_LINK" || true
  fi
}

service_active() {
  local s="$1"
  if systemctl is-active --quiet "$s" 2>/dev/null; then
    printf '运行中'
  else
    printf '未运行'
  fi
}

print_online() {
  need_root
  load_info
  local state_file="/run/xray-online-guard/clients.tsv"
  local active_file="/run/xray-online-guard/active.list"
  local tmp_active="/tmp/xray_online_active.$$"

  echo "================ 客户端在线情况 ================"
  echo "Xray 服务：$(service_active xray)"
  echo "在线限制服务：$(service_active xray-online-guard)"
  echo "监听端口：${PORT:-unknown}"
  echo "限制配置：MAX_ONLINE_IPS=${MAX_ONLINE_IPS}, LIMIT_MODE=${LIMIT_MODE}, idle=${ONLINE_IDLE_SECONDS}s"
  echo

  echo "实时连接 IP（只统计远端客户端连接到本机 ${PORT}/tcp；服务器本机 IP/内网 IP 不占名额）："
  : > "$tmp_active"
  local local_ips
  local_ips="$( { printf '%s\n' "${SERVER_IP:-}"; ip -o -4 addr show 2>/dev/null | awk '{split($4,a,"/"); print a[1]}'; } | grep -E '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' | sort -u | tr '\n' ' ' )"
  if command -v conntrack >/dev/null 2>&1; then
    conntrack -L -f ipv4 -p tcp --dport "$PORT" 2>/dev/null \
      | awk -v port="$PORT" -v locals="$local_ips" '
        BEGIN{split(locals,l," "); for(i in l) if(l[i]!="") local[l[i]]=1}
        $0 ~ ("dport=" port) && ($0 ~ /ESTABLISHED|SYN_SENT|SYN_RECV|FIN_WAIT|CLOSE_WAIT/) {
          src=""; dst=""; for(i=1;i<=NF;i++){if($i~/^src=/&&src==""){split($i,a,"=");src=a[2]} if($i~/^dst=/&&dst==""){split($i,b,"=");dst=b[2]}}
          if(src ~ /^[0-9]{1,3}(\.[0-9]{1,3}){3}$/ && !(src in local) && (dst in local || dst=="0.0.0.0")) print src
        }' >> "$tmp_active" || true
  fi
  if command -v ss >/dev/null 2>&1; then
    ss -Htan state established 2>/dev/null \
      | awk -v p=":${PORT}" -v locals="$local_ips" '
        BEGIN{split(locals,l," "); for(i in l) if(l[i]!="") local[l[i]]=1}
        function strip(x){gsub(/^\[|\]$/,"",x); sub(/^::ffff:/,"",x); sub(/:[0-9]+$/,"",x); return x}
        index($4,p){peer=strip($5); if(peer ~ /^[0-9]{1,3}(\.[0-9]{1,3}){3}$/ && !(peer in local)) print peer}
      ' >> "$tmp_active" || true
  fi
  sort -u "$tmp_active" | grep -Ev '^(0\.0\.0\.0|127\.|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)' | grep -Fvx "${SERVER_IP:-__none__}" > "${tmp_active}.sorted" || true
  if [[ -s "${tmp_active}.sorted" ]]; then
    awk 'BEGIN{n=0} {n++; print "  " n ". IP=" $1} END{print "  合计：" n " 个实时在线 IP"}' "${tmp_active}.sorted"
  else
    echo "  none"
    echo "  说明：none 不一定代表节点异常；只有客户端正在连接/访问时，实时连接才会出现。"
  fi
  rm -f "$tmp_active" "${tmp_active}.sorted" 2>/dev/null || true

  echo
  echo "在线限制服务记录的 IP 名额："
  if [[ -r "$state_file" ]]; then
    awk -F'\t' -v locals="$local_ips" '
      BEGIN{split(locals,l," "); for(i in l) if(l[i]!="") local[l[i]]=1; n=0}
      $1 ~ /^[0-9]{1,3}(\.[0-9]{1,3}){3}$/ && !($1 in local) && $1 !~ /^(0\.0\.0\.0|127\.|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)/ {
        n++; print "  " n ". IP=" $1 "  first_seen=" strftime("%F %T", $2) "  last_seen=" strftime("%F %T", $3)
      }
      END{if(n==0) print "  none"; else print "  合计：" n " 个已占用名额"}' "$state_file"
  else
    echo "  none（状态文件不存在，在线限制服务可能未启动）"
  fi

  echo
  echo "当前仍在限制/踢下线冷却中的 IP："
  if command -v ipset >/dev/null 2>&1 && ipset list xray_guard_block >/tmp/xray_guard_ipset.$$ 2>/dev/null; then
    awk '/^[0-9]+\./ {n++; print "  " n ". " $0} END{if(n==0) print "  none（正常：表示当前没有正在封锁倒计时的 IP）"}' /tmp/xray_guard_ipset.$$ || true
    rm -f /tmp/xray_guard_ipset.$$
  else
    echo "  none（ipset 不存在或在线限制未启用）"
  fi

  echo
  echo "最近限制/踢下线历史日志："
  if [[ -r /var/log/xray/online-guard.log ]]; then
    grep -E 'kicked old|denied extra|released inactive|accepted client' /var/log/xray/online-guard.log 2>/dev/null | tail -n 12 | sed 's/^/  /' || true
  else
    echo "  none"
  fi

  if ! systemctl is-active --quiet xray-online-guard 2>/dev/null; then
    echo
    warn "在线限制服务未运行或异常，最近日志如下："
    journalctl -u xray-online-guard -n 20 --no-pager 2>/dev/null || true
  fi
  echo "================================================"
}
print_status() {
  need_root
  load_info
  echo "================ 环境检测 / 运行状态 ================"
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    echo "系统：${PRETTY_NAME:-unknown}"
  fi
  echo "Root 权限：$([[ ${EUID} -eq 0 ]] && echo yes || echo no)"
  echo "Xray 安装：$([[ -x $XRAY_BIN ]] && echo yes || echo no)"
  if [[ -x "$XRAY_BIN" ]]; then
    "$XRAY_BIN" version | head -n 1 || true
  fi
  echo "Xray 服务：$(service_active xray)"
  echo "在线限制服务：$(service_active xray-online-guard)"
  echo "监听端口：${PORT:-unknown}"
  ss -lntp 2>/dev/null | awk -v p=":${PORT}" '$4 ~ p {print "  " $0}' || true
  echo "BBR：$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo unknown)"
  echo "TFO：$(sysctl -n net.ipv4.tcp_fastopen 2>/dev/null || echo unknown)"
  echo "防火墙检测："
  firewall_status_summary | sed 's/^/  /'
  echo "Fail2ban：$(service_active fail2ban)"
  if [[ -r "$XRAY_CONF" && -x "$XRAY_BIN" ]]; then
    echo "配置测试："
    "$XRAY_BIN" run -test -config "$XRAY_CONF" || true
  fi
  echo "====================================================="
}

prepare_install_environment() {
  need_root
  log "准备首次安装/重装环境：停止旧 Xray/在线限制、清理旧限制规则，并检查端口冲突。"
  stop_online_guard
  systemctl stop xray 2>/dev/null || true
  mkdir -p "$XRAY_CONF_DIR" /var/log/xray "$XRAY_OVERRIDE_DIR"
  chown -R root:root "$XRAY_CONF_DIR" /var/log/xray 2>/dev/null || true
  chmod 700 "$XRAY_CONF_DIR" 2>/dev/null || true
  chmod 755 /var/log/xray 2>/dev/null || true
  local conflict
  conflict="$(ss -H -lntp 2>/dev/null | awk -v p=":${PORT}" '$4 ~ p {print}' | grep -v 'xray' || true)"
  if [[ -n "$conflict" ]]; then
    warn "检测到 ${PORT}/tcp 已被其他服务占用，Xray 无法启动。占用如下："
    printf '%s
' "$conflict"
    die "请先停止 nginx/apache/caddy/面板等占用 ${PORT}/tcp 的服务，或用 PORT=其他端口 安装。"
  fi
}

install_all() {
  need_root
  check_os
  validate_input
  apt_install
  prepare_install_environment
  configure_firewall
  install_xray
  load_info
  if [[ "$FORCE_RENEW" == "1" ]]; then
    warn "FORCE_RENEW=1：将生成新的 UUID/REALITY 密钥/Short ID，旧客户端链接会失效。"
    generate_values
  else
    ensure_values
    log "一键安装/重装默认保留现有 UUID/REALITY 密钥；如需换新请用菜单 10 或 FORCE_RENEW=1。"
  fi
  if [[ "$FORCE_DETECT_IP" == "1" ]]; then
    # 安装/重装时默认重新检测公网 IPv4，避免换机/换 IP 后链接仍写旧地址。
    local saved_server_ip="$SERVER_IP"
    SERVER_IP=""
    SERVER_IP="$(detect_public_ip)" || SERVER_IP="$saved_server_ip"
  else
    SERVER_IP="$(detect_public_ip)"
  fi
  write_server_config
  write_client_files "$SERVER_IP"
  [[ "$ENABLE_BBR" == "1" ]] && apply_network_tuning
  configure_fail2ban
  start_service
  start_online_guard
  print_info
}

update_xray() {
  need_root
  apt_install
  install_xray
  systemctl restart xray
  systemctl restart xray-online-guard 2>/dev/null || true
  "$XRAY_BIN" version | head -n 1
  log "已升级。现有配置和导入链接不变。"
}

rotate_secret() {
  need_root
  [[ -r "$XRAY_INFO" ]] || die "没有安装信息，请先安装。"
  load_info
  generate_values
  write_server_config
  write_client_files "$SERVER_IP"
  start_service
  start_online_guard
  print_info
  warn "旧链接已经失效，请改用上面的新链接。"
}

rebuild_config_keep_secret() {
  need_root
  [[ -r "$XRAY_INFO" ]] || die "没有安装信息，请先安装。"
  load_info
  validate_input
  ensure_values
  configure_firewall
  stop_online_guard
  write_server_config
  write_client_files "$SERVER_IP"
  start_service
  start_online_guard
  print_info
}

modify_limit_interactive() {
  need_root
  [[ -r "$XRAY_INFO" ]] || die "没有安装信息，请先安装。"
  load_info
  echo "当前：最多 ${MAX_ONLINE_IPS} 个客户端公网 IP 在线，模式 ${LIMIT_MODE}。"
  read -rp "请输入最大在线客户端 IP 数量 [1-20，默认 ${MAX_ONLINE_IPS}]：" v
  v="${v:-$MAX_ONLINE_IPS}"
  read -rp "限制模式：1=满员后拒绝新客户端 deny_new（推荐，稳定），2=新客户端进来踢最早旧客户端 kick_old（多设备反复重连可能轮换掉线）[默认 ${LIMIT_MODE}]：" m
  case "$m" in
    1|deny_new|"") [[ "$m" == "" ]] || LIMIT_MODE="deny_new" ;;
    2|kick_old) LIMIT_MODE="kick_old" ;;
    *) die "模式输入无效。" ;;
  esac
  MAX_ONLINE_IPS="$v"
  if [[ "$LIMIT_MODE" == "kick_old" ]]; then
    warn "kick_old 适合临时让新设备顶掉旧设备；如果多台设备持续自动重连，可能出现轮换踢下线。长期稳定建议用 deny_new。"
  fi
  read -rp "无活动多久释放在线名额，秒 [默认 ${ONLINE_IDLE_SECONDS}]：" idle
  ONLINE_IDLE_SECONDS="${idle:-$ONLINE_IDLE_SECONDS}"
  validate_input
  save_info
  stop_online_guard
  start_online_guard
  log "在线限制已更新并已立即重启生效：MAX_ONLINE_IPS=${MAX_ONLINE_IPS}, LIMIT_MODE=${LIMIT_MODE}, idle=${ONLINE_IDLE_SECONDS}s"
}

modify_basic_interactive() {
  need_root
  [[ -r "$XRAY_INFO" ]] || die "没有安装信息，请先安装。"
  load_info
  echo "当前端口：${PORT}；当前 SNI：${SNI}；当前 DEST：${DEST}；节点名：${NODE_NAME}"
  read -rp "端口 [默认 ${PORT}]：" p
  PORT="${p:-$PORT}"
  read -rp "SNI 域名 [默认 ${SNI}]：" s
  SNI="${s:-$SNI}"
  read -rp "DEST 目标 [默认 ${DEST}，通常与 SNI 保持一致，如 ${SNI}:443]：" d
  DEST="${d:-${SNI}:443}"
  read -rp "节点名称 [默认 ${NODE_NAME}]：" n
  NODE_NAME="${n:-$NODE_NAME}"
  read -rp "是否阻断 QUIC/HTTP3 出站？0=不阻断，1=阻断让浏览器回落 TCP [默认 ${BLOCK_QUIC}]：" q
  BLOCK_QUIC="${q:-$BLOCK_QUIC}"
  validate_input
  rebuild_config_keep_secret
}

network_menu() {
  while true; do
    clear || true
    cat <<MENU
================ 网络优化菜单 ================
1) 应用网络优化：BBR/fq/TFO/MTU/连接队列/文件句柄
2) 移除本脚本写入的网络优化配置
3) 查看当前网络参数
0) 返回上级菜单
==============================================
MENU
    read -rp "请选择：" c
    case "$c" in
      1) need_root; apply_network_tuning; press_enter ;;
      2) need_root; restore_network_tuning; press_enter ;;
      3) echo "拥塞控制：$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo unknown)"; echo "队列算法：$(sysctl -n net.core.default_qdisc 2>/dev/null || echo unknown)"; echo "TFO：$(sysctl -n net.ipv4.tcp_fastopen 2>/dev/null || echo unknown)"; echo "MTU probing：$(sysctl -n net.ipv4.tcp_mtu_probing 2>/dev/null || echo unknown)"; press_enter ;;
      0) return 0 ;;
      *) echo "无效选择"; sleep 1 ;;
    esac
  done
}

uninstall_xray() {
  need_root
  load_info
  warn "将停止并卸载 Xray 与在线限制服务。"
  read -rp "确认卸载？输入 yes 继续：" ok
  [[ "$ok" == "yes" ]] || { warn "已取消。"; return 0; }
  stop_online_guard
  rm -f "$ONLINE_GUARD" "$ONLINE_ENV" "$ONLINE_UNIT"
  systemctl daemon-reload || true
  systemctl disable --now xray 2>/dev/null || true
  local installer="/tmp/xray-install-release.sh"
  curl -fL --retry 3 --connect-timeout 15 -o "$installer" "$INSTALL_URL" || true
  if [[ -s "$installer" ]]; then
    bash "$installer" remove || true
  fi
  warn "客户端/配置文件可能保留。如需彻底清理，可手动删除：$XRAY_INFO $CLIENT_JSON $MIHOMO_YAML $LINK_TXT $XRAY_CONF"
}

show_tips() {
  cat <<'TIPS'
================ 降低封锁与暴露风险建议 ================
1) 优先使用 TCP 443，不建议为了“随机”而改高端口；随机高端口不等于更隐蔽。
2) 不要多人共享同一个节点；本脚本默认按客户端公网 IP 限制最多 2 个在线，满员后拒绝新客户端，稳定优先。
3) 不跑 BT，不做代理给陌生人，不开放面板，不复用弱口令。
4) 客户端必须支持 VLESS + REALITY + Vision；旧 v2ray-core 或旧 App 可能不支持。
5) SNI/DEST 不要用苹果、iCloud 等敏感目标；建议使用稳定、常见、行为正常的大站。
6) 定期 rotate 重置 UUID、Reality 密钥和 Short ID；泄露链接后立即重置。
7) 云厂商安全组只开放 SSH 与节点端口；SSH 建议用密钥登录并关闭密码登录。
8) 没有脚本能保证 IP 永不被封；IP 质量、地区网络策略、客户端版本、流量习惯都会影响结果。
=========================================================
TIPS
}

main_menu() {
  need_root
  while true; do
    load_info
    clear || true
    cat <<MENU
================ Xray VLESS REALITY V3.1 菜单版 ================
广告位：www.kvmcc.com｜非官方学习/测试脚本，使用前请确认合法合规。
当前状态：Xray=$(service_active xray) | 在线限制=$(service_active xray-online-guard) | 端口=${PORT:-443} | 上限=${MAX_ONLINE_IPS:-2} | 模式=${LIMIT_MODE:-deny_new}

1) 环境检测 / 运行状态
2) 一键安装 / 重装
3) 卸载
4) 查看节点链接 / 二维码 / 客户端配置路径
5) 查看客户端在线情况
6) 修改在线人数限制与踢下线模式
7) 修改端口 / SNI / 节点名 / QUIC策略
8) 网络优化菜单
9) 更新 Xray-core
10) 重置 UUID + REALITY 密钥 + Short ID
11) 重启 Xray 与在线限制服务
12) 查看日志
13) 降低封锁与暴露风险建议
14) 生成排查日志包 / 导出故障日记
0) 退出
================================================================
MENU
    read -rp "请选择：" choice
    case "$choice" in
      1) print_status; press_enter ;;
      2) install_all; press_enter ;;
      3) uninstall_xray; press_enter ;;
      4) print_info; press_enter ;;
      5) print_online; press_enter ;;
      6) modify_limit_interactive; press_enter ;;
      7) modify_basic_interactive; press_enter ;;
      8) network_menu ;;
      9) update_xray; press_enter ;;
      10) rotate_secret; press_enter ;;
      11) restart_services; press_enter ;;
      12) echo "--- Xray error.log ---"; tail -n 80 /var/log/xray/error.log 2>/dev/null || true; echo; echo "--- online-guard.log ---"; tail -n 80 /var/log/xray/online-guard.log 2>/dev/null || true; press_enter ;;
      13) show_tips; press_enter ;;
      14) collect_diagnostics; press_enter ;;
      0) exit 0 ;;
      *) echo "无效选择"; sleep 1 ;;
    esac
  done
}

usage() {
  cat <<USAGE
用法：sudo bash $0 [menu|install|status|online|info|limit|configure|optimize|update|rotate|diag|uninstall]

首次运行需要输入 AGREE 同意使用条款；自动化场景可设置 ACCEPT_TERMS=1。

不带参数默认进入菜单。

常用：
  sudo bash $0
  sudo bash $0 install
  sudo bash $0 status
  sudo bash $0 online
  sudo bash $0 diag        # 生成排查日志包，发给我定位问题
  sudo MAX_ONLINE_IPS=1 LIMIT_MODE=deny_new bash $0 install
  sudo MAX_ONLINE_IPS=2 LIMIT_MODE=deny_new bash $0 install
  sudo PORT=443 SNI=www.microsoft.com NODE_NAME=my-node bash $0 install

环境变量：
  PORT=443
  SNI=www.microsoft.com
  DEST=www.microsoft.com:443
  SERVER_IP=1.2.3.4
  SSH_PORT=22
  NODE_NAME=u22-xray-reality
  MAX_ONLINE_IPS=2
  LIMIT_MODE=deny_new        # 默认 deny_new：满员后拒绝新客户端，更稳；也可用 kick_old 踢掉最早旧客户端
  ONLINE_IDLE_SECONDS=300
  BLOCK_SECONDS=900
  KICK_BLOCK_SECONDS=300
  SCAN_INTERVAL=2
  BLOCK_QUIC=0               # 1=阻断 QUIC/HTTP3 出站，可能更稳但可能影响部分体验
  ENABLE_SOCKOPT=1
  XRAY_BETA=0                # 1=安装预发布版
  XRAY_VERSION=26.x.y        # 可选：指定 Xray 版本，绕过 latest 检测
  FORCE_RENEW=0              # 1=一键安装/重装时强制生成新链接；默认保留旧 UUID/密钥
  FORCE_DETECT_IP=1          # 1=安装/重装时重新检测公网 IPv4，避免链接写旧 IP
  INSTALL_URLS="url1 url2"    # 可选：自定义安装脚本下载源，空格分隔
  XRAY_DOWNLOAD_BASES="url1 url2" # 可选：自定义 Xray 二进制下载源，空格分隔
  ENABLE_UFW=1
  ENABLE_BBR=1
  ENABLE_FAIL2BAN=1
  ENABLE_ONLINE_GUARD=1
  APT_REFRESH=auto            # auto=缺依赖找不到包时只刷新索引；0=完全不 apt-get update；1=允许刷新索引
  INSTALL_OPTIONAL_DEPS=1     # 0=跳过 qrencode/fail2ban/conntrack/ipset 等可选依赖
  SCRIPT_LOG=/var/log/xray-reality-installer.log
  DIAG_DIR=/root/xray-reality-diagnostics
  ACCEPT_TERMS=0              # 1=非交互同意使用条款，仅在你已阅读并接受条款时使用
  TERMS_ACCEPT_FILE=/root/.xray-reality-script-terms-accepted
USAGE
}

case "${1:-menu}" in
  menu) main_menu ;;
  install) install_all ;;
  status|check) print_status ;;
  online) print_online ;;
  info) print_info ;;
  limit) modify_limit_interactive ;;
  configure|config) modify_basic_interactive ;;
  optimize) need_root; apply_network_tuning ;;
  restore-optimization) need_root; restore_network_tuning ;;
  update) update_xray ;;
  rotate) rotate_secret ;;
  uninstall|remove) uninstall_xray ;;
  terms|notice) show_terms_notice ;;
  tips) show_tips ;;
  diag|diagnose|collect-log|collect-logs) collect_diagnostics ;;
  help|-h|--help) usage ;;
  *) usage; exit 1 ;;
esac
