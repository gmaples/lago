#!/bin/bash

echo "=== Lago Security Environment Variables Bulk Import ==="
echo "This script will set all the secure environment variables for Lago"
echo

# Environment variables to set
declare -A env_vars=(
  ["SECRET_KEY_BASE"]="cf2a294e710ce3e0deef9243b272bcf5453afe73fe70021d5792e3fb8ba2b8eac88a62a6e06d061579f694a9702f13815b624fb893701d10c3076a68c4c627fa"
  ["LAGO_RSA_PRIVATE_KEY"]="LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcEFJQkFBS0NBUUVBdE5aWmFZOG1QOElaOGZFNjlqNUZuSkVKQVVhRThzVHJ3U2RUQUpSaGY2YVhvZzBuCjJRV2ZHV1JqK2lXYzRCOHo2Y0x2dEhxUUZxQ0g3aEkvNnc4Q2FZZ3RUUmh0UjZRS2JOanVxZkNLMTFnRVZsOVIKUHJvVVNGSGtKejNwVHpQYWZyVVk3d3NoS2FqQlJ2dGMrSjZCREk4bUN0cVVRNUNWbXhaTnBQQzhYTnp3ajN3NwpROEgxWHZOUElxc2VzcFIyQ2NSUDFYUFZ3d05kK3JEQ21TMzV3SnJOZFJOOGpVaXV0RlBHOVo1UGlGWU9WZmUrCjNlMi9xSEN6T0hWM3pGbzd0SlJkTk5KZ2dMejJ0Z25JcG9jMWtYOEFjNXYxZ3lLUVBwQTZEUGtLcm1vd2krQzcKRWhOMElFZUxUc0c3TEhJZHV2ZUpjTDNMa28wRGJQWnRBWXBWWndJREFRQUJBb0lCQUhOYTM1ais2SzJVNlJBQQpYakZHaDQxTVVqRnQzU2puVGt0eGxzYXJpejg2NWNjMGN2K2JQNXpIZUllK2hQOXhXbmJGWWdUengrV00yY3pOCjNyaHNGZHlLa3FubVphNGl1VlZyNWZYcWVTcFpldXdEbFFhTkFrbWk2SnBrY0Y4SHNiV2x5RXVnbzhjZnJqRjUKMnhQUWJZWXc0TTFjazZqc3dCMDZlSUFJV2NFSXpHQlJ0ZlJtY0J6SGNjdWFsZGRpY1h6L0RyTXpJdENlY0NyZgpxUnUzQlVvSTBldDYrZ1ZkTCtYSW5FcXJCZkdDbUtqdS9RTXhWSFNEWG5EOVdORFo2S20reDlNemZtczNOZ1ZMCnRYaVF1OUJPOVNZYnVOaDFMZFdUUEhGSUlOdHNieWlUc1B4OGVtQWJwNUdtWWZhNXBWWlBJR1pnSXZLY0tzeUEKa3JEWUZpRUNnWUVBMVU3ejE5UGdnWWp3YnVqYWFydHhyREJPVVJDVFR6Qjd0bjAzQ0hiUFZENm0zNDBuMGlsQwpOUkI5YmVXWk9GUmd5YUZ6NEZKOWEyTzBDdFBzSWNuUWprVERyYjk1QURxN0t4OWIzNWVNK2hvN1RwU3lzUytWCjFNRW8xTlMwTU1NTDJJSkNaeGRCN1VjYWR3dUZVN0NOQXp2cCtSaUNMSmlveVVoUXhLSWg2SjBDZ1lFQTJRUzYKcjFFOERJTkJXQ2J6am1QM2ZOT0p3bFFxQUtuZnI4WGZlblBIQkxUcXg3Q2pPMU5JWWlmT3NFWWkrQWNaK1FydApJOWtSNklZbnkyeUhzcXVqaFZnb3J4dGVWVGNrQUQrbDdoZFNPNEx5SStLKzMzZkNIZzJNSlFOOHF3VTVhQlZVCkNodWNwdzBOOW51YmJZOE5jcDVjdjVEUVJZSVNYWklOS1Y2cmVoTUNnWUVBdTlmOVcwU1Y4SVJPZWJoRzhpRVkKMlRYZFdXN3JLaytlNlkxL3ZCYlhzUzY4VVlEN3IvUVBzbGpOWGtCWmwxSkdNT0p6TEp1Q3lpYmp4ODc4UzgyNApTYjF0QlE4SStIVGdrMnpqU3QxVGQwaEVYTzhpQ3FVZ2dZYXE1WlF3N2t5TGpqM2dJUmR0SXJ6ZG8vMGFlOURiCkVMUVFtOTNtMWk3MmpqcExGZ1ZvbHFFQ2dZQXBKbW5yT3BhUzJ3ZW9aaTlZU1dPVFpKaGJhc0lRK0dGU0NhaWYKaUtjMGJSejNlNXQ4dmdyRzJOajQrMEowbjEzWE9UT09rQUs5UkIvUkJJN3Y2NW9RQ1cvK1VHU3BEWGJoN3JZNAprNVdkT0hKZlc5Q1RFYW9pM0t1RFhsNENkUnhieVNwMjNkM1E3cXVacCt5cjVsMVZkcWRyekFWUmV4WCtwcHA5ClNBWG1GUUtCZ1FDbVNGR2tYOCtOa1dydEQ2VzZXNmM1NjNqL0w2YVd5QTh0bDF4VE5TNHcyTzVRV3FldFd0S3IKUU9rdERvUGxOQkFBWWh5QUJJcGRSTVNZdmlxWGdSUHk2UjNJTStSMzV1ZkRPeWg5M0c1TTZMMm5PQzhtR3R0dwpkbG85R0VDZm1lYTkxZWlNSWdUZGdKajBHc1FCRlIrWlVNZ01oNGxaZ0I1YzBVcUtzNWNnU1E9PQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQ=="
  ["LAGO_ENCRYPTION_PRIMARY_KEY"]="fb37c969e7eb47f382b460d16823be5d"
  ["LAGO_ENCRYPTION_DETERMINISTIC_KEY"]="1a3ad1cd89b9069e29c39e0a55936bc9"
  ["LAGO_ENCRYPTION_KEY_DERIVATION_SALT"]="5e7c43cfda60c80bc33a88d14576c6e2"
  ["RAILS_MASTER_KEY"]="f0119db162cbbf43e1f8b6e3e6b04752"
)

echo "Setting environment variables in Gitpod..."
echo

# Set each environment variable
for var_name in "${!env_vars[@]}"; do
  echo "Setting $var_name..."
  gp env "$var_name=${env_vars[$var_name]}"
  if [ $? -eq 0 ]; then
    echo "✅ $var_name set successfully"
  else
    echo "❌ Failed to set $var_name"
  fi
done

echo
echo "=== Summary ==="
echo "The following environment variables have been set:"
echo "- SECRET_KEY_BASE (128 chars) - Rails session encryption"
echo "- LAGO_RSA_PRIVATE_KEY (2240 chars) - JWT/API key signing"
echo "- LAGO_ENCRYPTION_PRIMARY_KEY (32 chars) - Primary encryption"
echo "- LAGO_ENCRYPTION_DETERMINISTIC_KEY (32 chars) - Deterministic encryption"
echo "- LAGO_ENCRYPTION_KEY_DERIVATION_SALT (32 chars) - Key derivation salt"
echo "- RAILS_MASTER_KEY (32 chars) - Rails master key"
echo
echo "🚨 IMPORTANT: You need to restart your workspace or start a new terminal"
echo "   for these environment variables to be available in terminal sessions."
echo
echo "To update your current terminal session immediately, run:"
echo "   eval \$(gp env -e)"
echo
echo "Next steps:"
echo "1. Add these same values to your GitHub repository secrets for CI/CD"
echo "2. Run BFG to clean the old hardcoded values from Git history" 