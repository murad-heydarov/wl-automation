#!/bin/bash
set -e

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT="all_project_files_${TIMESTAMP}.txt"

print_file () {
  local file="$1"

  echo "==================================================" >> "$OUTPUT"
  echo "FILE: $file" >> "$OUTPUT"
  echo "==================================================" >> "$OUTPUT"
  echo "" >> "$OUTPUT"
  cat "$file" >> "$OUTPUT"
  echo -e "\n\n" >> "$OUTPUT"
}

# --------------------------------------------------
# 1. ROOT
# --------------------------------------------------
[ -f README.md ] && print_file README.md

# --------------------------------------------------
# 2. DOCS (əgər varsa)
# --------------------------------------------------
if [ -d docs ]; then
  find docs -type f -name "*.md" | sort | while read -r f; do
    print_file "$f"
  done
fi

# --------------------------------------------------
# 3. TERRAFORM ENVIRONMENT (prod)
# --------------------------------------------------
find terraform/environments/prod \
  -type d \( -name .terraform -o -name logs \) -prune -o \
  -type f \( \
    -name "*.tf" -o \
    -name "*.sh" -o \
    -name "*.auto.tfvars" \
  \) \
  ! -name "terraform.tfstate*" \
  -print | sort | while read -r f; do
    print_file "$f"
  done

# --------------------------------------------------
# 4. WL CONFIG TEMPLATES (MÜTLƏQ)
# --------------------------------------------------
find terraform/environments/prod/wl-configs/templates \
  -type f | sort | while read -r f; do
    print_file "$f"
  done

# --------------------------------------------------
# 5. TERRAFORM MODULES (HAMISI)
# --------------------------------------------------
find terraform/modules \
  -type d -name .terraform -prune -o \
  -type f \( -name "*.tf" -o -name "*.md" \) \
  -print | sort | while read -r f; do
    print_file "$f"
  done

echo "✅ DONE. Output file: $OUTPUT"
