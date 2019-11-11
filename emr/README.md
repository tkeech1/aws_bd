### To run the EMR Spark job:
1. Run 'make apply' on the top level project directory to create the ec2 key
2. Run 'terraform init; terraform fmt; terraform apply -auto-approve' on the emr directory
3. ssh to the emr master as hadoop: 'ssh hadoop@XXX'
4. Make sure the task node is in running state the AWS console
5. Run 'spark-submit als_example.py' on the master

