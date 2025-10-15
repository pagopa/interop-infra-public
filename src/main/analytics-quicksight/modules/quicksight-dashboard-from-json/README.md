# Module usage

Use this module to handle dashboard edited from QuickSight console. 
The suggested process is 

 - Export dashboard using the scripts ```./scripts/quicksight_dashboard_export_from_aws.sh```.
 - Save the json file into the folder ```src/main/analytics-quicksight/quicksight-json-dashboards``` 
   inside the repository interop-infra.
 - Read the data sets list inside the json file. It is located in the ```.Definition.DataSetIdentifierDeclarations```
 - Define the datasources. If the datasource is a simple view wrapping you can use 
   [quicksight-data-set-view-wrapper](../quicksight-data-set-view-wrapper) module.
 - Insert a module block in your terraform configuration:
   - __source__ will take the path to the folder containing this README.md 
   - __dashboard_definition_file_path__ will take the absolute path to the exported json path; 
     this argument, usually, starts with `${module.path}`.
   - __data_sets_arns__ is used to override the data sets arns definitions inside dashboard definition file.
     Prepare a list of pairs with *identifier* and *data_set_arn*.
       - *identifier* is taken from the dashboard definition json file
       - and *data_set_arn* is obtained referencing a terraform resource property or module output.
   - __dashboard_permissions__ only two actions sets are allowed one for readers and one for authors.
    ```
    locals {
      quicksight_dashboard_read_only_actions = [
        "quicksight:DescribeDashboard",
        "quicksight:ListDashboardVersions",
        "quicksight:QueryDashboard"
      ]

      quicksight_dashboard_read_write_actions = [
        "quicksight:DescribeDashboard",
        "quicksight:ListDashboardVersions",
        "quicksight:UpdateDashboardPermissions",
        "quicksight:QueryDashboard",
        "quicksight:UpdateDashboard",
        "quicksight:DeleteDashboard",
        "quicksight:DescribeDashboardPermissions",
        "quicksight:UpdateDashboardPublishedVersion"
      ]
    }
    ```