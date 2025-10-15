from datetime import date, datetime, timedelta, timezone
import math
import boto3


def get_start_date(logs_client, log_group):
    details = logs_client.describe_log_groups(logGroupNamePrefix=log_group)['logGroups'][0]
    creation_date = datetime.fromtimestamp(math.floor(details['creationTime'] / 1000), tz=timezone.utc)

    today = datetime.now(tz=timezone.utc)
    last_retention_day = today - timedelta(details['retentionInDays'])
    
    return max(creation_date, last_retention_day)

def get_latest_export(logs_client, log_group):
    paginator = logs_client.get_paginator('describe_export_tasks')
    tasks_iterator = paginator.paginate(statusCode='COMPLETED')
  
    # using JMESPath
    search_result = tasks_iterator.search(f'exportTasks[?logGroupName == `{log_group}`] | max_by([*], &to)')
    return next(search_result, None)

def calculate_export_dates(start_date_epoch):
    today = datetime.now(tz=timezone.utc)
    latest_exported_date = datetime.fromtimestamp(math.floor(start_date_epoch / 1000), tz=timezone.utc)
    delta_days = (today - latest_exported_date).days

    dates = [latest_exported_date + timedelta(days=n) for n in range(1, delta_days+1)]
    return dates


def handler(event, context):
    print(f'EVENT: {event}')

    logs_client = boto3.client('logs')
    start_date = get_start_date(logs_client, event['log_group'])
    print(f'log group start date: {start_date}')
    start_date_epoch = datetime(year=start_date.year, month=start_date.month, day=start_date.day).timestamp() * 1000

    latest_export = get_latest_export(logs_client, event['log_group'])
    print(f'log group latest_export: {latest_export}')

    if latest_export is not None:
        start_date_epoch = max(latest_export['to'], start_date_epoch)
    datetimes = calculate_export_dates(start_date_epoch)

    iso_dates = [dt.date().isoformat() for dt in datetimes]
    print(f'export_dates: {iso_dates}')

    return { 'export_dates': iso_dates }
