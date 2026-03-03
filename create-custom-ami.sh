#!/usr/bin/env bash
set -euo pipefail

BASE_NAME="dev-environment-work"
PROFILE="${AWS_PROFILE:-admin}"
REGION=""
WAIT_FOR_AVAILABLE=0
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: create-custom-ami.sh [options]

Creates a custom AMI from the current EC2 instance with no reboot.
Default name format: dev-environment-work

Options:
  --profile <name>      AWS profile (default: admin or AWS_PROFILE env)
  --region <region>     AWS region (default: detected from instance metadata)
  --base-name <name>    Base AMI name (default: dev-environment-work)
  --wait                Wait until AMI is available
  --dry-run             Print what would run, but do not create
  -h, --help            Show this help

Behavior:
  - Always creates AMI with --no-reboot
  - If name exists, deregisters old AMI(s) and deletes their snapshot(s)
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

get_imds_token() {
  curl -fsS -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"
}

get_metadata() {
  local token="$1"
  local path="$2"
  curl -fsS -H "X-aws-ec2-metadata-token: ${token}" "http://169.254.169.254/latest/meta-data/${path}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
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

TOKEN="$(get_imds_token)"
INSTANCE_ID="$(get_metadata "$TOKEN" "instance-id")"

if [[ -z "$REGION" ]]; then
  AZ="$(get_metadata "$TOKEN" "placement/availability-zone")"
  REGION="${AZ::-1}"
fi

DATE_UTC="$(date -u +%Y%m%d)"
BASE_AMI_NAME="${BASE_NAME}"
CANDIDATE_NAME="$BASE_AMI_NAME"

EXISTING_IMAGE_IDS="$(aws --profile "$PROFILE" ec2 describe-images \
  --region "$REGION" \
  --owners self \
  --filters "Name=name,Values=${CANDIDATE_NAME}" \
  --query 'Images[].ImageId' \
  --output text)"

if [[ -n "$EXISTING_IMAGE_IDS" && "$EXISTING_IMAGE_IDS" != "None" ]]; then
  log "Found existing AMI(s) with name ${CANDIDATE_NAME}: ${EXISTING_IMAGE_IDS}"
  OLD_SNAPSHOT_IDS=""

  for IMAGE_ID in $EXISTING_IMAGE_IDS; do
    SNAPSHOT_IDS="$(aws --profile "$PROFILE" ec2 describe-images \
      --region "$REGION" \
      --image-ids "$IMAGE_ID" \
      --query 'Images[0].BlockDeviceMappings[?Ebs.SnapshotId!=null].Ebs.SnapshotId' \
      --output text)"
    if [[ -n "$SNAPSHOT_IDS" && "$SNAPSHOT_IDS" != "None" ]]; then
      OLD_SNAPSHOT_IDS="${OLD_SNAPSHOT_IDS} ${SNAPSHOT_IDS}"
    fi
  done

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "Dry run: would deregister existing AMI(s) before create."
    if [[ -n "${OLD_SNAPSHOT_IDS// }" ]]; then
      SNAPSHOTS_TO_DELETE=""
      for SNAPSHOT_ID in $OLD_SNAPSHOT_IDS; do
        if [[ " ${SNAPSHOTS_TO_DELETE} " != *" ${SNAPSHOT_ID} "* ]]; then
          SNAPSHOTS_TO_DELETE="${SNAPSHOTS_TO_DELETE} ${SNAPSHOT_ID}"
        fi
      done
      log "Dry run: would delete old snapshot(s): ${SNAPSHOTS_TO_DELETE}"
    fi
  else
    for IMAGE_ID in $EXISTING_IMAGE_IDS; do
      log "Deregistering old AMI: ${IMAGE_ID}"
      aws --profile "$PROFILE" ec2 deregister-image --region "$REGION" --image-id "$IMAGE_ID"
    done

    if [[ -n "${OLD_SNAPSHOT_IDS// }" ]]; then
      SNAPSHOTS_TO_DELETE=""
      for SNAPSHOT_ID in $OLD_SNAPSHOT_IDS; do
        if [[ " ${SNAPSHOTS_TO_DELETE} " != *" ${SNAPSHOT_ID} "* ]]; then
          SNAPSHOTS_TO_DELETE="${SNAPSHOTS_TO_DELETE} ${SNAPSHOT_ID}"
        fi
      done

      for SNAPSHOT_ID in $SNAPSHOTS_TO_DELETE; do
        log "Deleting old snapshot: ${SNAPSHOT_ID}"
        aws --profile "$PROFILE" ec2 delete-snapshot --region "$REGION" --snapshot-id "$SNAPSHOT_ID"
      done
    fi
  fi
fi

DESCRIPTION="AMI from ${INSTANCE_ID} on ${DATE_UTC} UTC"

CREATE_CMD=(
  aws --profile "$PROFILE" ec2 create-image
  --region "$REGION"
  --instance-id "$INSTANCE_ID"
  --name "$CANDIDATE_NAME"
  --description "$DESCRIPTION"
  --no-reboot
  --query ImageId
  --output text
)

log "Instance: ${INSTANCE_ID}"
log "Region: ${REGION}"
log "AMI Name: ${CANDIDATE_NAME}"
log "No reboot: enabled"

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "Dry run enabled. Command:"
  printf ' %q' "${CREATE_CMD[@]}"
  printf '\n'
  exit 0
fi

AMI_ID="$(${CREATE_CMD[@]})"

log "Created AMI: ${AMI_ID}"

if [[ "$WAIT_FOR_AVAILABLE" -eq 1 ]]; then
  log "Waiting for AMI to become available..."
  aws --profile "$PROFILE" ec2 wait image-available --region "$REGION" --image-ids "$AMI_ID"
  STATE="$(aws --profile "$PROFILE" ec2 describe-images --region "$REGION" --image-ids "$AMI_ID" --query 'Images[0].State' --output text)"
  log "AMI state: ${STATE}"
fi

log "Done."
