#!/bin/bash
cd "$(dirname "$0")"  # script directory

output_file="collected_$(date +%Y%m%d_%H%M).txt"
> "$output_file"

# Əvvəlcə bütün faylları 'git status' ilə yoxlayır
echo "Collecting latest saved files (including unstaged changes)..."

find terraform -type f \( -name "*.tf" -o -name "*.tfvars" -o -name ".env" \) -print0 | while IFS= read -r -d '' file; do
  echo "----------------------------" >> "$output_file"
  echo "# $file" >> "$output_file"
  echo "" >> "$output_file"
  echo "\`\`\`" >> "$output_file"
  cat "$file" >> "$output_file"
  echo "\`\`\`" >> "$output_file"
  echo "----------------------------" >> "$output_file"
  echo "" >> "$output_file"
done

echo "✅ All Terraform files collected in: $output_file"
