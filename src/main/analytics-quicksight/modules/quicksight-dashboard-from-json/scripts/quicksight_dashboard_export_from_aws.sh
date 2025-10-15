#!/bin/bash

# This script use aws cli quicksight describe-dashboard, describe-dashboard-definition, 
# describe-dashboard-permissions and list-tags-for-resource to save all the information 
# regarding a dashboard in a json file. It really write the file to standard output. 
# The user have to redirect the command output to a file.

dashboard_id=$1 
set -euo pipefail


if ( [ -z "${dashboard_id}" ] ) then 
  echo "usage: $0 <dashboard_id>"
  echo "<dashboard_id> is the id of the QuickSight dashboard to export"
  echo ""
  echo "Try to list dashboards"
  account_id=$( aws sts get-caller-identity --query Account --output=text )
  aws quicksight list-dashboards \
      --aws-account-id ${account_id} 
  exit 1
fi

account_id=$( aws sts get-caller-identity --query Account --output=text )


dashboard_description=$( \
  aws quicksight describe-dashboard \
      --aws-account-id ${account_id} \
      --dashboard-id ${dashboard_id} \
)

dashboard_definition=$( \
  aws quicksight describe-dashboard-definition \
      --aws-account-id ${account_id} \
      --dashboard-id ${dashboard_id} \
)

dashboard_permissions=$( \
  aws quicksight describe-dashboard-permissions \
      --aws-account-id ${account_id} \
      --dashboard-id ${dashboard_id} \
)

tags=$(
  aws quicksight list-tags-for-resource \
      --resource-arn $( echo "${dashboard_description}" | jq -r '.Dashboard.Arn' )
)

# Merge 4 different json object into one.
echo "{ \"desc\": ${dashboard_description}, \"def\": ${dashboard_definition}, \"perm\": ${dashboard_permissions}, \"tags\": ${tags} }" \
  | jq '{ "Dashboard": .desc.Dashboard, "Definition": .def.Definition, "Permissions": [], "Tags": [] }'
