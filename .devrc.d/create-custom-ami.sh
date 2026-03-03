#!/usr/bin/env bash
set -euo pipefail

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  return 0 2>/dev/null || exit 0
fi

BASE_NAME="dev-environment-work"
PROFILE="${AWS_PROFILE:-admin}"
REGION=""
MODE="safe"
WAIT_FOR_AVAILABLE=0
DRY_RUN=0
KEEP_COUNT=3
YES=0
NO_REBOOT=1

usage() {
  cat <<'EOF'
Usage: create-custom-ami.sh [options]

Modes (choose one):
  --safe                 Safe create with versioned name (default)
  --replace              Replace exact name (destructive: deletes old AMIs/snapshots)
  --cleanup              Cleanup old versioned AMIs and snapshots

General options:
  --base-name <name>     Base AMI name (default: dev-environment-work)
  --profile <name>       AWS profile (default: admin or AWS_PROFILE)
  --region <region>      AWS region (default: detected from instance metadata)
  --wait                 Wait until created AMI is available (create modes only)
  --no-reboot            Allow reboot for create-image (default: no reboot)
  --dry-run              Print planned actions without changing anything
  --yes                  Skip confirmation for destructive modes

Cleanup options:
  --keep <n>             Keep newest n AMIs in cleanup mode (default: 3)

Examples:
  create-custom-ami.sh --safe --wait
  create-custom-ami.sh --replace --yes --wait
  create-custom-ami.sh --cleanup --keep 2 --yes
EOF
}

log() {
  printf '%s\n' "$*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    log "Error: required command not found: $1"
    exit 1
  }
}

confirm_or_exit() {
  local prompt="$1"
  if [[ "$YES" -eq 1 ]]; then
    return 0
  fi

  printf '%s [y/N]: ' "$prompt"
  local answer=""
  read -r answer
  case "$answer" in
    y|Y|yes|YES)
      return 0
      ;;
    *)
      log "Cancelled."
      exit 130
      ;;
  esac
}

get_imds_token() {
  curl -fsS -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"
}

get_metadata() {
  local token="$1"
  local path="$2"
  curl -fsS -H "X-aws-ec2-metadata-token: ${token}" "http://169.254.169.254/latest/meta-data/${path}"
}

resolve_region_and_instance() {
  local token
  token="$(get_imds_token)"
  INSTANCE_ID="$(get_metadata "$token" "instance-id")"

  if [[ -z "$REGION" ]]; then
    local az
    az="$(get_metadata "$token" "placement/availability-zone")"
    REGION="${az::-1}"
  fi
}

list_image_ids_by_exact_name() {
  local name="$1"
  aws --profile "$PROFILE" ec2 describe-images \
    --region "$REGION" \
    --owners self \
    --filters "Name=name,Values=${name}" \
    --query 'Images[].ImageId' \
    --output text
}

list_image_ids_by_prefix_newest_first() {
  local prefix="$1"
  aws --profile "$PROFILE" ec2 describe-images \
    --region "$REGION" \
    --owners self \
    --filters "Name=name,Values=${prefix}*" \
    --query 'reverse(sort_by(Images,&CreationDate))[].ImageId' \
    --output text
}

collect_snapshot_ids_for_images() {
  local image_ids_text="$1"
  local snapshots=""

  for image_id in $image_ids_text; do
    local one
    one="$(aws --profile "$PROFILE" ec2 describe-images \
      --region "$REGION" \
      --image-ids "$image_id" \
      --query 'Images[0].BlockDeviceMappings[?Ebs.SnapshotId!=null].Ebs.SnapshotId' \
      --output text)"

    if [[ -n "$one" && "$one" != "None" ]]; then
      snapshots="${snapshots} ${one}"
    fi
  done

  local unique=""
  for snapshot_id in $snapshots; do
    if [[ " ${unique} " != *" ${snapshot_id} "* ]]; then
      unique="${unique} ${snapshot_id}"
    fi
  done

  printf '%s\n' "${unique}" | xargs
}

build_safe_name() {
  local date_ymd
  date_ymd="$(date -u +%Y%m%d)"
  local base_candidate="${BASE_NAME}-${date_ymd}"
  local candidate="$base_candidate"
  local v=2

  while [[ "$(list_image_ids_by_exact_name "$candidate")" != "" && "$(list_image_ids_by_exact_name "$candidate")" != "None" ]]; do
    candidate="${base_candidate}-v${v}"
    v=$((v + 1))
  done

  printf '%s\n' "$candidate"
}

create_image() {
  local ami_name="$1"
  local description="AMI from ${INSTANCE_ID} on $(date -u +%Y%m%d) UTC"

  local cmd=(
    aws --profile "$PROFILE" ec2 create-image
    --region "$REGION"
    --instance-id "$INSTANCE_ID"
    --name "$ami_name"
    --description "$description"
    --query ImageId
    --output text
  )

  if [[ "$NO_REBOOT" -eq 1 ]]; then
    cmd+=(--no-reboot)
  fi

  log "Instance: ${INSTANCE_ID}"
  log "Region: ${REGION}"
  log "AMI Name: ${ami_name}"
  if [[ "$NO_REBOOT" -eq 1 ]]; then
    log "No reboot: enabled"
  else
    log "No reboot: disabled"
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "Dry run enabled. Command:"
    printf ' %q' "${cmd[@]}"
    printf '\n'
    return 0
  fi

  local ami_id
  ami_id="$("${cmd[@]}")"
  log "Created AMI: ${ami_id}"

  if [[ "$WAIT_FOR_AVAILABLE" -eq 1 ]]; then
    log "Waiting for AMI to become available..."
    aws --profile "$PROFILE" ec2 wait image-available --region "$REGION" --image-ids "$ami_id"
    local state
    state="$(aws --profile "$PROFILE" ec2 describe-images --region "$REGION" --image-ids "$ami_id" --query 'Images[0].State' --output text)"
    log "AMI state: ${state}"
  fi
}

delete_images_and_snapshots() {
  local image_ids_text="$1"
  if [[ -z "$image_ids_text" || "$image_ids_text" == "None" ]]; then
    return 0
  fi

  local snapshot_ids
  snapshot_ids="$(collect_snapshot_ids_for_images "$image_ids_text")"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "Dry run: would deregister AMI(s): $image_ids_text"
    if [[ -n "$snapshot_ids" ]]; then
      log "Dry run: would delete snapshot(s): $snapshot_ids"
    fi
    return 0
  fi

  for image_id in $image_ids_text; do
    log "Deregistering AMI: ${image_id}"
    aws --profile "$PROFILE" ec2 deregister-image --region "$REGION" --image-id "$image_id"
  done

  for snapshot_id in $snapshot_ids; do
    log "Deleting snapshot: ${snapshot_id}"
    aws --profile "$PROFILE" ec2 delete-snapshot --region "$REGION" --snapshot-id "$snapshot_id"
  done
}

run_safe_mode() {
  resolve_region_and_instance
  local name
  name="$(build_safe_name)"
  create_image "$name"
  log "Done."
}

run_replace_mode() {
  resolve_region_and_instance
  local exact_name="$BASE_NAME"
  local existing
  existing="$(list_image_ids_by_exact_name "$exact_name")"

  if [[ -n "$existing" && "$existing" != "None" ]]; then
    confirm_or_exit "Replace exact name '${exact_name}' by deleting existing AMI(s) and snapshots?"
    delete_images_and_snapshots "$existing"
  else
    log "No existing AMI found with exact name: ${exact_name}"
  fi

  create_image "$exact_name"
  log "Done."
}

run_cleanup_mode() {
  [[ "$KEEP_COUNT" =~ ^[0-9]+$ ]] || {
    log "Error: --keep must be a non-negative integer"
    exit 1
  }

  if [[ -z "$REGION" ]]; then
    resolve_region_and_instance
  fi

  local all_ids
  all_ids="$(list_image_ids_by_prefix_newest_first "$BASE_NAME")"

  if [[ -z "$all_ids" || "$all_ids" == "None" ]]; then
    log "No AMIs found for prefix: ${BASE_NAME}"
    exit 0
  fi

  local count=0
  local to_delete=""
  for image_id in $all_ids; do
    count=$((count + 1))
    if [[ "$count" -gt "$KEEP_COUNT" ]]; then
      to_delete="${to_delete} ${image_id}"
    fi
  done

  to_delete="$(printf '%s\n' "$to_delete" | xargs)"

  if [[ -z "$to_delete" ]]; then
    log "Nothing to clean. Total AMIs <= keep count (${KEEP_COUNT})."
    exit 0
  fi

  confirm_or_exit "Cleanup mode will delete AMIs older than newest ${KEEP_COUNT} for prefix '${BASE_NAME}'. Continue?"
  delete_images_and_snapshots "$to_delete"
  log "Done."
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --safe)
      MODE="safe"
      shift
      ;;
    --replace)
      MODE="replace"
      shift
      ;;
    --cleanup)
      MODE="cleanup"
      shift
      ;;
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    --region)
      REGION="$2"
      shift 2
      ;;
    --base-name)
      BASE_NAME="$2"
      shift 2
      ;;
    --wait)
      WAIT_FOR_AVAILABLE=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --keep)
      KEEP_COUNT="$2"
      shift 2
      ;;
    --yes)
      YES=1
      shift
      ;;
    --no-reboot)
      NO_REBOOT=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log "Error: unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

require_cmd aws
require_cmd curl

case "$MODE" in
  safe)
    run_safe_mode
    ;;
  replace)
    run_replace_mode
    ;;
  cleanup)
    run_cleanup_mode
    ;;
  *)
    log "Error: unknown mode: $MODE"
    exit 1
    ;;
esac
