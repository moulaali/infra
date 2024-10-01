import boto3
from datetime import datetime, timedelta

# Initialize Cost Explorer client
ce = boto3.client('ce')

# Get start and end date (for the last day)
end = datetime.utcnow()
start = end - timedelta(days=1)
start_date = start.strftime('%Y-%m-%d')
end_date = end.strftime('%Y-%m-%d')

# Query AWS Cost Explorer for cost and usage
response = ce.get_cost_and_usage(
    TimePeriod={
        'Start': start_date,
        'End': end_date
    },
    Granularity='DAILY',
    Metrics=['BlendedCost', 'UsageQuantity'],
    GroupBy=[{'Type': 'DIMENSION', 'Key': 'SERVICE'}]
)

# Print the results with wider columns
print("Timerange, start:" + start_date + " end: " + end_date);
print(f"{'Service':<50} {'BlendedCost($)':<20} {'UsageQuantity':<20}")
print("="*90)

for group in response['ResultsByTime'][0]['Groups']:
    service = group['Keys'][0]
    cost = float(group['Metrics']['BlendedCost']['Amount'])
    usage = group['Metrics']['UsageQuantity']['Amount']
    if cost > 0:
        print(f"{service:<50} ${cost:<20.4f} {usage:<20}")

