#!/bin/bash

# Logging Migration Script for Moctar Nutrition
# This script helps automate the migration from old logging patterns to LoggingService

echo "🚀 Starting logging migration for Moctar Nutrition..."

# Find all Dart files that import logger
echo "📋 Finding files that need migration..."
FILES=$(grep -r "import 'package:logger/logger.dart';" lib/ --include="*.dart" | cut -d: -f1 | sort -u)

if [ -z "$FILES" ]; then
    echo "✅ No files found that need migration!"
    exit 0
fi

echo "Found ${#FILES[@]} files to migrate:"
for file in $FILES; do
    echo "  - $file"
done

echo ""
echo "🔧 Migration steps:"
echo "1. Update imports"
echo "2. Remove Logger() instances"
echo "3. Replace logging calls"
echo "4. Add structured logging where appropriate"
echo ""
echo "📖 See docs/logging_migration_guide.md for detailed instructions"
echo ""
echo "⚠️  Please review each file manually after running this script!"

# Create a backup
echo "💾 Creating backup..."
cp -r lib/ lib_backup_$(date +%Y%m%d_%H%M%S)/

echo "✅ Backup created. Ready for manual migration!"
echo ""
echo "Next steps:"
echo "1. Review each file listed above"
echo "2. Follow the migration guide"
echo "3. Test your changes"
echo "4. Remove the backup when satisfied"
