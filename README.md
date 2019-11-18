# aws_bd
AWS Kinesis, EMR and S3 configurations with Terraform

There are several workflows included in this repository. 

1) An EC2 spot instance is created. A python script in /LogGenerator.py causes log files to be written to the /var/log/Cadabra directory, which is monitored by the Kinesis Agent, on the EC2 host (See user_data.tmpl for details).
2) The Kinesis Agent pushes any log updates to Kinesis Firehose and to the CadabraOrders Kinesis Stream.
3) Kinesis Firehose writes the data to an S3 bucket.
4) A Lambda function monitors the CadabraOrders stream and writes any records to CadabraOrder DynamoDB table.
5) A Kinesis Analytics application monitors the Kinesis Stream and writes data to an Alarm stream when data begins to come into the CadabraOrders stream too quickly.
6) A Lambda function monitors the alarm stream and creates SNS notifications (text message) when if finds data in the alarm stream. 

**The following environment variables need to be set locally:**
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
CELL_PHONE_NUMBER
```

To run:
```
make apply start-kinesis-analytics
```