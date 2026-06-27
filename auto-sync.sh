#!/bin/bash

# ========================================
# Poultry App - Auto Sync Script
# Syncs Local Changes ↔ GitHub
# ========================================

PROJECT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INTERVAL=30  # هر 30 ثانیه
LOG_FILE="$PROJECT_PATH/auto-sync.log"

# رنگ‌ها
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🚀 Poultry App Auto-Sync Started${NC}"
echo -e "${BLUE}========================================${NC}"

while true; do
    cd "$PROJECT_PATH"
    
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 1️⃣ Local تغییرات را commit کنید
    if [[ -n $(git status --porcelain) ]]; then
        echo -e "${GREEN}✅ [$TIMESTAMP] تغییرات محلی یافت شد${NC}"
        git add .
        COMMIT_MSG="Auto-sync: Local changes at $TIMESTAMP"
        git commit -m "$COMMIT_MSG"
        echo "$TIMESTAMP - Committed: $COMMIT_MSG" >> "$LOG_FILE"
    fi
    
    # 2️⃣ GitHub تغییرات را دریافت کنید
    echo -e "${YELLOW}🔄 [$TIMESTAMP] Syncing with GitHub...${NC}"
    
    if git pull origin master --ff-only 2>/dev/null; then
        echo -e "${GREEN}✅ [$TIMESTAMP] Pull completed${NC}"
        echo "$TIMESTAMP - Pull successful" >> "$LOG_FILE"
    else
        echo -e "${RED}❌ [$TIMESTAMP] Pull failed - conflict detected${NC}"
        echo "$TIMESTAMP - Pull FAILED" >> "$LOG_FILE"
    fi
    
    if git push origin master 2>/dev/null; then
        echo -e "${GREEN}✅ [$TIMESTAMP] Push completed${NC}"
        echo "$TIMESTAMP - Push successful" >> "$LOG_FILE"
    else
        echo -e "${YELLOW}⚠️  [$TIMESTAMP] Push skipped (no changes)${NC}"
    fi
    
    # 3️⃣ Flutter pub get
    echo -e "${BLUE}📦 [$TIMESTAMP] Refreshing Flutter dependencies...${NC}"
    flutter pub get > /dev/null 2>&1
    echo -e "${GREEN}✅ [$TIMESTAMP] Flutter updated${NC}"
    echo "$TIMESTAMP - Flutter pub get" >> "$LOG_FILE"
    
    echo -e "${BLUE}⏳ Next sync in $INTERVAL seconds...${NC}"
    echo "---" >> "$LOG_FILE"
    
    sleep $INTERVAL
done
