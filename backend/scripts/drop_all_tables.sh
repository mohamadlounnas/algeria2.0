#!/usr/bin/env bash
set -euo pipefail

# Drops all user tables, views, indexes, and triggers from a SQLite DB
# Usage: ./drop_all_tables.sh [path/to/db.sqlite3]

DB_PATH=${1:-"$(dirname "$0")/../tmp/db.sqlite3"}
DB_PATH=$(realpath "$DB_PATH")

if [[ ! -f "$DB_PATH" ]]; then
  echo "Error: DB file not found at $DB_PATH"
  exit 1
fi

TIMESTAMP=$(date +%Y%m%dT%H%M%S)
BACKUP_PATH="${DB_PATH}.bak.${TIMESTAMP}"
echo "Creating backup: $BACKUP_PATH"
cp "$DB_PATH" "$BACKUP_PATH"

echo "Dropping objects from $DB_PATH"

# Helper to execute SQL
exec_sql() {
  sqlite3 "$DB_PATH" "$1"
}

# Drop indexes
indexes=$(sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%';")
if [[ -n "$indexes" ]]; then
  echo "Dropping indexes..."
  while IFS= read -r idx; do
    echo "DROP INDEX \"$idx\";"
    exec_sql "DROP INDEX \"$idx\";"
  done <<< "$indexes"
fi

# Drop triggers
triggers=$(sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='trigger' AND name NOT LIKE 'sqlite_%';")
if [[ -n "$triggers" ]]; then
  echo "Dropping triggers..."
  while IFS= read -r trg; do
    echo "DROP TRIGGER \"$trg\";"
    exec_sql "DROP TRIGGER \"$trg\";"
  done <<< "$triggers"
fi

# Drop views
views=$(sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='view' AND name NOT LIKE 'sqlite_%';")
if [[ -n "$views" ]]; then
  echo "Dropping views..."
  while IFS= read -r v; do
    echo "DROP VIEW \"$v\";"
    exec_sql "DROP VIEW \"$v\";"
  done <<< "$views"
fi

# Drop tables (skip sqlite_ internal ones)
tables=$(sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")
if [[ -n "$tables" ]]; then
  echo "Dropping tables..."
  while IFS= read -r t; do
    echo "DROP TABLE \"$t\";"
    exec_sql "DROP TABLE \"$t\";"
  done <<< "$tables"
fi

echo "All user objects dropped from $DB_PATH. Backup preserved as $BACKUP_PATH"
