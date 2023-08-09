import boto3
from datetime import datetime
from dateutil.tz import *

def handler(event, context):
    # Invoke ACM client
    acm_client = boto3.client('acm')

    try:
        # Retrieve all the certificates
        response = acm_client.list_certificates()

        certificates = response['CertificateSummaryList']

        results = []

        for certificate in certificates:
            certificate_arn = certificate['CertificateArn']
            #print(certificate_arn)
            certificate_domain = certificate['DomainName']
            #print(certificate_domain)

            # Describe the certificate
            certificate_info = acm_client.describe_certificate(CertificateArn=certificate_arn)
            #print(certificate_info)

            # Extract the expiration date and convert that into proper format
            expiration_date = str(certificate_info['Certificate']['NotAfter'].strftime('%Y-%m-%d %H:%M:%S'))
            expiration_datetime = datetime.strptime(expiration_date, '%Y-%m-%d %H:%M:%S')
            # Calculate the remaining days to expiry. Get the current date and as per the timezone and compare against the expiry date
            current_date = datetime.now(tzlocal()).strftime('%Y-%m-%d %H:%M:%S')
            current_datetime = datetime.strptime(current_date, '%Y-%m-%d %H:%M:%S')
            remaining_days = (expiration_datetime - current_datetime).days

            results.append({
                "Domain": certificate_domain,
                "ExpirationDate": expiration_date,
                "RemainingDays": remaining_days
            })
            print(results)

        return {
            "statusCode": 200,
            "body": results
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": f"Error getting the certificate details: {str(e)}"
        }