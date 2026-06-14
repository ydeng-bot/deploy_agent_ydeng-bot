#!/usr/bin/env bash

# Hard exit rules for safety
set -euo pipefail

# Style flags for terminal feedback
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
C='\033[0;36m'; B='\033[1m'; NC='\033[0m'

log_info()   { echo -e "${C}[INFO]${NC} $*"; }
log_ok()     { echo -e "${G}[SUCCESS]${NC} $*"; }
log_warn()   { echo -e "${Y}[WARNING]${NC} $*"; }
log_err()    { echo -e "${R}[ERROR]${NC} $*"; }

echo -e "${B}*** Attendance Tracker - project Initializer ***${NC}\n"

# Get the target folder tag from input or prompt
if [ $# -gt 0 ]; then
	USER_TAG="$1"
else 
	read -rp "Enter a project identifier suffix (e.g., cohort_A): " USER_TAG
fi

# Simple validation check
if [ -z "$USER_TAG" ]; then
     log_err "Blank input provided. Execution killed."
     exit 1
fi

PROJECT_DIR="attendance_tracker_${USER_TAG}"
ARCHIVE_NAME="attendance_tracker_${USER_TAG}_archive"

#setup emergency handler for unexpected interruptions (Ctrl+C)
emergency_cleanup() {
    echo ""
    log_warn "interruption caught! Bundling workspace data..."

    if [ -d "$PROJECT_DIR" ]; then
	 #package whatever is built so far, drop errors if empty
	 tar -czf "${ARCHIVE_NAME}.tar.gz" "$PROJECT_DIR" 2>/dev/null \
		 && log_ok "State successfully archived -> ${ARCHIVE_NAME}.tar.gz" \
		 || log_warn "Could not create backup archive."

	 #clear out workspace to avoid half-baked files cluttering things
	 rm -rf "$PROJECT_DIR"
	 log_ok "Cleaned up partial build directory: ${PROJECT_DIR}"
    fi  

    echo -e "${R}process killed early.${NC}"
    exit 130
}

trap emergency_cleanup SIGINT SIGTERM

log_info "Setting up root folder at: ${PROJECT_DIR}"

#Block conflicts if folder is already occupied
if [ -d "$PROJECT_DIR" ]; then
	log_warn "The path '${PROJECT_DIR}' is already occupied by a directory."
	read -rp "Do you want to overwrite it entirely? (y/N): " FORCE_DROP
	if [[ "$FORCE_DROP" =~ ^[Yy]$ ]]; then
	       rm -rf "$PROJECT_DIR"
               log_info "old directory wiped out clean."
        else
               log_err "Halting execution to protect current directory contents."
               exit 1
        fi
fi

# Build out baseline architecture paths
mkdir -p "${PROJECT_DIR}/Helpers" "${PROJECT_DIR}/reports" || {
	log_err "permission denied or storage failure. Failed creating directory skeleton."
        exit 1
}
# Generating the python core application file
cat > "${PROJECT_DIR}/attendance_checker.py" << 'EOF'
import csv
import json
import os
from datetime import datetime

def run_attendance_check():
    # 1. Load Config
    with open('Helpers/config.json', 'r') as f:
        config = json.load(f)

    # 2. Archive old reports.log if it exists
    if os.path.exists('reports/reports.log'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename('reports/reports.log', f'reports/reports_{timestamp}.log.archive')

    # 3. Process Data
    with open('Helpers/assets.csv', mode='r') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)
        total_sessions = config['total_sessions']

        log.write(f"--- Attendance Report Run: {datetime.now()} ---\n")

        for row in reader:
            name = row['Names']
            email = row['Email']
            attended = int(row['Attendance Count'])

            # Simple Math: (Attended / Total) * 100
            attendance_pct = (attended / total_sessions) * 100

            message = ""
            if attendance_pct < config['thresholds']['failure']:
                message = f"URGENT: {name}, your attendance is {attendance_pct:.1f}%. You will fail this class."
            elif attendance_pct < config['thresholds']['warning']:
                message = f"WARNING: {name}, your attendance is {attendance_pct:.1f}%. Please be careful."

            if message:
                if config['run_mode'] == "live":
                    log.write(f"[{datetime.now()}] ALERT SENT TO {email}: {message}\n")
                    print(f"Logged alert for {name}")
                else:
                    print(f"[DRY RUN] Email to {email}: {message}")

if __name__ == "__main__":
    run_attendance_check()
EOF

# Generating local data tracking sheet
cat > "${PROJECT_DIR}/Helpers/assets.csv" << 'EOF'
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
EOF

# Generating default settings manifest
cat > "${PROJECT_DIR}/Helpers/config.json" << 'EOF'
{
    "thresholds": {
        "warning": 75,
        "failure": 50
    },
    "run_mode": "live",
    "total_sessions": 15
}
EOF

# Raw initial execution record log setup
cat > "${PROJECT_DIR}/reports/reports.log" << 'EOF'
--- Attendance Report Run: 2026-02-06 18:10:01.468726 ---
[2026-02-06 18:10:01.469363] ALERT SENT TO bob@example.com: URGENT: Bob Smith, your attendance is 46.7%. You will fail this class.
[2026-02-06 18:10:01.469424] ALERT SENT TO charlie@example.com: URGENT: Charlie Davis, your attendance is 26.7%. You will fail this class.
EOF

log_ok "Core structural files written down successfully."

# configuration turning phase
echo ""
log_info "Config Turning: Current standard is warning=75% and failure=50%"
read -rp "Modify these values now? (y/N): " CHANGE_CFG

if [[ "$CHANGE_CFG" =~ ^[Yy]$ ]]; then

     # input validation collector loop
     fetch_clean_numeric() {
	     local SEED_PROMPT="$1"
	     local TYPED_IN=""
	     while true; do
		     read -rp "$SEED_PROMPT" TYPED_IN
		     # Return nothing if they just skip with enter key
		     if [ -z "$TYPED_IN" ]; then
			     echo ""
			     return
	             fi
		     # Ensure safe digits within reasonable limits
		     if [[ "$TYPED_IN" =~ ^[0-9]+$ ]] && [ "$TYPED_IN" -ge 1 ] && [ "$TYPED_IN" -le 99 ];then
			     echo "$TYPED_IN"
			     return
		     fi
		     log_warn "Bad value input ('${TYPED_IN}'). Use whole integers from 1 up to 99."
		  done
     }

     NEW_WARN=$(fetch_clean_numeric "Enter warning rate [1-99] (Leave blank to keep default): ")
     NEW_FAIL=$(fetch_clean_numeric "Enter failure rate [1-99] (Leave blank to keep default): ")
     TARGET_CONF="${PROJECT_DIR}/Helpers/config.json"

if [ -n "$NEW_WARN" ];then
      sed -i "s/\"warning\": [0-9]*/\"warning\": ${NEW_WARN}/" "$TARGET_CONF"
      log_ok "Warning point updated to ${NEW_WARN}%"
else
	log_info "warning point left unchanged."
fi

if [ -n "$NEW_FAIL" ]; then
      sed -i "s/\"failure\": [0-9]*/\"failure\": ${NEW_FAIL}/" "$TARGET_CONF"
      log_ok "Failure point updated to ${NEW_FAIL}%"
  else
     log_info "Failure point left unchanged."
  fi
else
    log_info "keeping standard settings layout unchanged."
fi

# Environment sanity and build confirmations
echo -e "\n${B}--- Environment Sanity Validation ---${NC}"

if python3 --version &>/dev/null;then
	CURRENT_PY_VER=$(python3 --version 2>&1)
	log_ok "python 3 environment validation: ${CURRENT_PY_VER}"
else
	log_warn "python3 is missing on this machine. This script will break if run."
	log_warn "Run 'sudo apt install python3' to patch this error."
fi

echo ""
log_info "Verifying directory file maps..."
V_OK=true
CHECK_MAP=(
	"${PROJECT_DIR}/attendance_checker.py"
	"${PROJECT_DIR}/Helpers/assets.csv"
	"${PROJECT_DIR}/Helpers/config.json"
	"${PROJECT_DIR}/reports/reports.log"
)

for MAP_ITEM in "${CHECK_MAP[@]}"; do
	if [[ -e "$MAP_ITEM" ]]; then
	      log_ok "Verified file path -> ${MAP_ITEM}"
	      
      else
	    log_err "Missing resource -> ${MAP_ITEM}"
	    V_OK=false
	fi
 done

 if [ "$V_OK" = true ]; then
	 log_ok "All component pathways validated. Build complete."
else
	log_err "Workspace mismatch flagged. Double-check local execution permissions."
fi

echo -e "\n${B}=== Deployment Workspace Configured ===${NC}"
echo -e "Target Workspace: ${C}${PROJECT_DIR}/${NC}"
echo -e "Execution Guide : ${C}cd ${PROJECT_DIR} && python3 attendance_checker.py${NC}\n"

