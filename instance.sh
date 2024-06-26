#!/bin/bash

AMI=ami-0f3c7d07486cad139 #this keeps on changing
SG_ID=sg-084ca7b232202f705 #replace with your SG ID
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "web")
ZONE_ID=Z069402810YRB7QM59AOY # replace your zone ID
DOMAIN_NAME="ajju.site"

for i in "${INSTANCES[@]}"
do
    if [ $i == "mongodb" ] || [ $i == "mysql" ] || [ $i == "shipping" ]
    then
        INSTANCE_TYPE="t3.small"
    else if [ $i == "web" ]
    then
        IP_ADDRESS1=$(aws ec2 run-instances --image-id $AMI --instance-type t2.micro --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]" --query 'Instances[0].PublicIpAddress' --output text)
        
        aws route53 change-resource-record-sets \
        --hosted-zone-id $ZONE_ID \
        --change-batch '
        {
            "Comment": "Creating a record set for cognito endpoint"
            ,"Changes": [{
            "Action"              : "UPSERT"
            ,"ResourceRecordSet"  : {
                "Name"              : "'$i'.'$DOMAIN_NAME'"
                ,"Type"             : "A"
               ,"TTL"              : 1
                ,"ResourceRecords"  : [{
                    "Value"         : "'$IP_ADDRESS1'"
              }]
           }
              }]
       }
        '

    else    
        INSTANCE_TYPE="t2.micro"
    fi

    IP_ADDRESS=$(aws ec2 run-instances --image-id $AMI --instance-type $INSTANCE_TYPE --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]" --query 'Instances[0].PrivateIpAddress' --output text)
    echo "$i: $IP_ADDRESS"

    #create R53 record, make sure you delete existing record
    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Creating a record set for cognito endpoint"
        ,"Changes": [{
        "Action"              : "UPSERT"
        ,"ResourceRecordSet"  : {
            "Name"              : "'$i'.'$DOMAIN_NAME'"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'$IP_ADDRESS'"
            }]
        }
        }]
    }
        '
done