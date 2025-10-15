from dateutil import parser
import math
import boto3

def create_export(logs_client, start, end, log_group, bucket):
    from_epoch = math.floor(start.timestamp() * 1000)
    to_epoch = math.floor(end.timestamp() * 1000)

    export_response = logs_client.create_export_task(
        fromTime = from_epoch,
        to = to_epoch,
        logGroupName = log_group,
        destination = bucket,
        destinationPrefix = f'year={start.year}/month={start.month}/day={start.day}'
    )
    return export_response['taskId']



def handler(event, context=None):
    print(f'EVENT: {event}')

    logs_start = parser.isoparse(event['logs_date'])
    logs_end = logs_start.replace(hour=23, minute=59, second=59, microsecond=999999)
    print(f'logs_start: {logs_start}')
    print(f'logs_end: {logs_end}')

    logs_client = boto3.client('logs') 
    task_id = create_export(logs_client, logs_start, logs_end, event['log_group'], event['bucket'])
    print(f'task_id: {task_id}')
    return { "task_id": task_id }
