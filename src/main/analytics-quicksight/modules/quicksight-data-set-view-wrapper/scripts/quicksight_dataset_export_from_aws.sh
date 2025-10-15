#!/bin/bash

# Given the id of a QuickSight DataSet in the default region of the current AWS_PROFILE account
# this script extract the view name and the column list; 
# print them in a format suitable for cut&paste as argument into a quicksight-data-set-view-wrapper 
# module block

data_set_id=$1 
set -euo pipefail

if ( [ -z "${data_set_id}" ] ) then 
  echo "usage: $0 <data_set_id>"
  echo "<data_set_id> is the id of the QuickSight dataset to export"
  echo ""
  echo "Try to retrieve data-set list"
  account_id=$( aws sts get-caller-identity --query Account --output=text )
  aws quicksight list-data-sets \
      --aws-account-id ${account_id}
  exit 1
fi



account_id=$( aws sts get-caller-identity --query Account --output=text )

data_set_description=$( \
  aws quicksight describe-data-set \
      --aws-account-id ${account_id} \
      --data-set-id ${data_set_id} \
)

view_name=$( \
  echo "${data_set_description}" \
  | jq -r ' .DataSet.PhysicalTableMap | to_entries | .[0] | .value.RelationalTable.Name ' \
)

echo "Print quicksight-dataset-view-wrapper module configuration"
echo ""
echo "  view_name = \"${view_name}\""
# Extract column names and data type
echo "${data_set_description}" \
  | jq '[ .DataSet.OutputColumns[] | { "name": .Name, "type": .Type } ]' \
  | sed -e 's/"type":/type =/' -e 's/"name":/name = /' \
  | sed -e 's/",/"/' \
  | sed -e 's/\[/columns = [/' \
  | sed -e 's/^/  /'

