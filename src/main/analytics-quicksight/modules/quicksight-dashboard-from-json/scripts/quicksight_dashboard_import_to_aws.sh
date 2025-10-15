#!/bin/bash

if ( [ -z "${dashboard_id}" ] ) then  
  echo "Variable <dashboard_id> is required."
  exit 1
fi

if ( [ -z "${dashboard_name}" ] ) then  
  echo "Variable <dashboard_name> is required"
  exit 1
fi

if ( [ -z "${dashboard_arn}" ] ) then  
  echo "Variable <dashboard_arn> is required."
  echo " It is computed by terraform using dashboard_id, dashboard_name and some other information like region, AWS account id, ..."
  exit 1
fi

if ( [ -z "${data_sets_arns}" ] ) then  
  echo "Variable <data_sets_arns> is required. See README.md for further details"
  exit 1
fi

if ( [ -z "${dashboard_definition_file_path}" ] ) then  
  echo "Variable <dashboard_definition_file_path> is required. See README.md for further details"
  exit 1
fi

if ( [ -z "${dashboard_permissions}" ] ) then  
  echo "Variable <dashboard_permissions> is required. See README.md for further details"
  exit 1
fi

if ( [ -z "${dashboard_tags}" ] ) then  
  echo "Variable <dashboard_tags> is required. Computed by terraform module."
  exit 1
fi


set -euo pipefail

# Prepare max script run-time check
start_epoch_time=$( date +%s )
MAX_DURATION_SECONDS=300 # 5 minutes

function test_max_time() {
  current_epoch_time=$( date +%s )
  delta_seconds=$[ $current_epoch_time - $start_epoch_time ]
  if ( [ "$delta_seconds" -gt "$MAX_DURATION_SECONDS" ] ) then
    echo "Abort due maximum duration exceeded"
    exit 2
  fi
}

echo "                  dashboard_id = ${dashboard_id}"
echo "                dashboard_name = ${dashboard_name}"
echo "dashboard_definition_file_path = ${dashboard_definition_file_path}"
echo "         dashboard_permissions = ${dashboard_permissions}"
echo "                dashboard_tags = ${dashboard_tags}"
echo "                data_sets_arns = ${data_sets_arns}"


# Replace DataSetIdentifierDeclarations inside definition file with data_sets_arns 
# configured inside terraform files
dashboard_definition=$( \
  ( \
    echo "{ \"ds_arns\": ${data_sets_arns}, \"file\": " \
    && cat "${dashboard_definition_file_path}" \
    && echo "}" \
  ) \
  | jq -r '([.ds_arns[] | {"Identifier": .identifier, "DataSetArn": .data_set_arn} ]) as $data_set_arns | .file.Definition | .DataSetIdentifierDeclarations = $data_set_arns | tojson' \
)


account_id=$( aws sts get-caller-identity --query Account --output=text )

dashboard_exsists=$( \
  aws quicksight list-dashboards \
      --aws-account-id "${account_id}" \
    | jq '.DashboardSummaryList | [ .[] | select( .DashboardId == "'${dashboard_id}'" ) ] | length ' \
)

if ( [ "${dashboard_exsists}" -eq "1" ] ) then 
  update_or_create="UPDATE"
  qs_command=update-dashboard
else
  update_or_create="CREATE"
  qs_command=create-dashboard
fi

echo "== ${update_or_create} QUICKSIGHT DASHBOARD ${dashboard_id} into account ${account_id}"
echo "======================================================================================="

upsert_response=$( aws quicksight ${qs_command} \
    --aws-account-id "${account_id}" \
    --dashboard-id "${dashboard_id}" \
    --name "${dashboard_name}" \
    --definition "${dashboard_definition}" \
  )

# We have to wait only for dashboard creation
# because dashboard, tags and permissions can be updated concurrently.
if ( [ "${update_or_create}" == "CREATE" ] ) then
  echo "wait for dashboard creation"

  while ( [ ! "${dashboard_exsists}" -eq "1" ] ) do
    sleep 2 && test_max_time
    dashboard_exsists=$( \
      aws quicksight list-dashboards \
          --aws-account-id "${account_id}" \
        | jq '.DashboardSummaryList | [ .[] | select( .DashboardId == "'${dashboard_id}'" ) ] | length ' \
    )
  done
fi


# - Permissions handling
new_permissions=$( \
    echo "${dashboard_permissions}" \
    | jq -r '[ .[] | { "Actions": (.actions | sort), "Principal": .principal} ] | tojson'
)

actual_permissions=$( \
  aws quicksight describe-dashboard-permissions \
      --aws-account-id ${account_id} \
      --dashboard-id "${dashboard_id}" \
    |  jq -r '[ .Permissions | .[] | { "Principal": .Principal, "Actions": (.Actions | sort ) }] | tojson' \
)

permissions_to_revoke=$( \
  echo "{ \"new_permissions\": ${new_permissions}, \"actual_permissions\": ${actual_permissions} }" \
    | jq -r '[ .new_permissions as $todel | .actual_permissions | .[] | . as $tocheck |  select( all( $todel | .[]; . != $tocheck )) ] | tojson' \
)


echo ""
echo "== Update permissions: "
echo " - New Permissions"
echo $new_permissions | jq .
echo " - Actual Permissions on DataSet"
echo "$actual_permissions" | jq .
echo " - Permissions to be revoked"
echo "$permissions_to_revoke" | jq .

permissions_to_grant_quantity=$( echo ${new_permissions} | jq ' length' )
permissions_to_revoke_quantity=$( echo ${permissions_to_revoke} | jq ' length' )


permissions_handling_params=""

if ( [ "${permissions_to_grant_quantity}" -gt 0 ] ) then
  permissions_handling_params=" --grant-permissions ${new_permissions} "
fi

if ( [ "${permissions_to_revoke_quantity}" -gt 0 ] ) then
  permissions_handling_params=" --revoke-permissions ${permissions_to_revoke} "
fi

echo " - update permissions response"
aws quicksight update-dashboard-permissions \
    --aws-account-id "${account_id}" \
    --dashboard-id "${dashboard_id}" \
    ${permissions_handling_params}





# - Tags handling
echo ""
echo "== Update Tags: "

echo " - New Tags"
new_tags=${dashboard_tags}
echo $new_tags | jq .


echo " - Actual Tags on Dashboard ${dashboard_arn}"
actual_tags=$( \
  aws quicksight list-tags-for-resource \
      --resource-arn "${dashboard_arn}" \
    |  jq -r '[ .Tags | .[] | { "Key": .Key, "Value": .Value } ] | sort_by(.Key) | tojson' \
)
echo "$actual_tags" | jq .

echo " - Tags to be revoked"
tags_to_revoke=$( \
  echo "{ \"new_tags\": ${new_tags}, \"actual_tags\": ${actual_tags} }" \
    | jq -r '[ .new_tags as $todel | .actual_tags | .[] | . as $tocheck |  select( all( $todel | .[] | .Key; . != $tocheck.Key )) ] | tojson' \
)
echo "$tags_to_revoke" | jq .


tags_to_grant_quantity=$( echo ${new_tags} | jq ' length' )
tags_to_revoke_quantity=$( echo ${tags_to_revoke} | jq ' length' )


if ( [ "${tags_to_grant_quantity}" -gt 0 ] ) then
  echo " - tag resource response"
  aws quicksight tag-resource \
    --resource-arn "${dashboard_arn}" \
    --tags "${new_tags}"
fi

if ( [ "${tags_to_revoke_quantity}" -gt 0 ] ) then
  echo " - untag resource response"
  aws quicksight untag-resource \
    --resource-arn "${dashboard_arn}" \
    --tag-keys $( echo "${tags_to_revoke}" | jq -r '[ .[] | .Key ] | tojson' )
fi




# We have to wait for new dashboard version creation, so we can publish it
if ( [ "${update_or_create}" == "UPDATE" ] ) then
  dashboard_version_arn=$( echo "${upsert_response}" | jq -r '.VersionArn' )
  dashboard_version=$( echo "${dashboard_version_arn}" | sed -e 's|.*/||' )
  echo "wait for dashboard version ${dashboard_version} creation! Arn: ${dashboard_version_arn}"

  dashboard_version_ok="0"
  while ( [ ! "${dashboard_version_ok}" -eq "1" ] ) do
    sleep 2 && test_max_time
    dashboard_version_ok=$( \
      aws quicksight describe-dashboard \
          --aws-account-id "${account_id}" \
          --dashboard-id "${dashboard_id}" \
          --version-number "${dashboard_version}" \
        | jq '[. | select( .Dashboard.Version.Status == "CREATION_SUCCESSFUL" )] | length ' \
    )
  done

  echo "Publish new version ${dashboard_version_arn}"
  aws quicksight update-dashboard-published-version \
    --aws-account-id "${account_id}" \
    --dashboard-id "${dashboard_id}" \
    --version-number "${dashboard_version}"
fi
