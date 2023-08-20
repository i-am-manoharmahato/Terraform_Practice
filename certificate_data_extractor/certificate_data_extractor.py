import boto3
import logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    
    REGIONS = ['us-east-1', 'ap-southeast-2']
    results = []
    
    for current_region in REGIONS:
        try:
            acm_client = boto3.client('acm', region_name=current_region)
            paginator = acm_client.get_paginator('list_certificates')
            for page in paginator.paginate():
                certificates = page['CertificateSummaryList']
                
                for certificate in certificates:
                    certificate_arn = certificate['CertificateArn']
                    certificate_account = certificate_arn.split(":")[4]
                    certificate_region = certificate_arn.split(":")[3]
                    certificate_id = certificate_arn.split("/")[1]
                    certificate_domain = certificate['DomainName']
                    certificate_status = certificate['Status']
                    certificate_type = certificate['Type']
                    certificate_inuse = certificate['InUse']
                    certificate_renewal_eligibility = certificate['RenewalEligibility']
                    
                    certificate_tag_list = acm_client.list_tags_for_certificate(CertificateArn=certificate_arn)
                    tag_list = []
                    
                    if (len(certificate_tag_list['Tags'])):
                        for tag in certificate_tag_list['Tags']:
                            tag_list.append(tag)
                            
                    
                    results.append({
                        "CertificateID" : certificate_id,
                        "CertificateDomain" : certificate_domain,
                        "CertificateStatus": certificate_status,
                        "CertificateAccount" : certificate_account,
                        "CertificateRegion": certificate_region,
                        "CertificateTags" : tag_list
                    })
        except Exception as e:
            return {
                "StatusCode": 500,
                "body": f"Error getting the certificate details: {str(e)}"
            }
    # write the result to cloudwatch
    print(results)
    
    return {
        "body": results
        }