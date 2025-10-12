#!/bin/bash

# Quick Logger Migration Script
# This script helps migrate remaining services to use LoggingService

echo "🔧 Quick Logger Migration for Moctar Nutrition"
echo "=============================================="

# List of critical services that need migration (most likely to cause ANSI codes)
CRITICAL_SERVICES=(
  "lib/shared/services/notification_service.dart"
  "lib/shared/services/background_upload_service.dart"
  "lib/shared/services/stripe_subscription_service.dart"
  "lib/shared/services/meal_plan_firestore_service.dart"
  "lib/shared/services/checkin_service.dart"
  "lib/shared/providers/meal_plan_provider.dart"
  "lib/shared/providers/workout_provider.dart"
  "lib/shared/providers/checkin_provider.dart"
)

echo "📋 Critical services that need migration:"
for service in "${CRITICAL_SERVICES[@]}"; do
  if [ -f "$service" ]; then
    echo "  ✅ $service"
  else
    echo "  ❌ $service (not found)"
  fi
done

echo ""
echo "🚀 Quick migration commands:"
echo ""

for service in "${CRITICAL_SERVICES[@]}"; do
  if [ -f "$service" ]; then
    echo "# Migrate $service"
    echo "sed -i '' 's/import \"package:logger\/logger.dart\";/import \"logging_service.dart\";/g' $service"
    echo "sed -i '' 's/static final _logger = Logger();/\/\/ static final _logger = Logger();/g' $service"
    echo "sed -i '' 's/_logger\.i/LoggingService.instance.i/g' $service"
    echo "sed -i '' 's/_logger\.e/LoggingService.instance.e/g' $service"
    echo "sed -i '' 's/_logger\.w/LoggingService.instance.w/g' $service"
    echo "sed -i '' 's/_logger\.d/LoggingService.instance.d/g' $service"
    echo ""
  fi
done

echo "💡 Usage:"
echo "1. Run the sed commands above for each service"
echo "2. Or manually update each file following the pattern:"
echo "   - Replace import with 'logging_service.dart'"
echo "   - Comment out 'static final _logger = Logger();'"
echo "   - Replace '_logger.X' with 'LoggingService.instance.X'"
echo ""
echo "🎯 This should eliminate the remaining ANSI escape codes!"
