# AWS
AWS_ACCESS_KEY_ID?=AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY?=AWS_SECRET_ACCESS_KEY
AWS_REGION?=AWS_REGION
CELL_PHONE_NUMBER?=CELL_PHONE_NUMBER
IP_ADDRESS?=IP_ADDRESS
VPC_ID?=VPC_ID

plan:
	terraform init; terraform validate; terraform plan -var="aws_access_key_id=${AWS_ACCESS_KEY_ID}" -var="aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}" -var="cell_phone_number=${CELL_PHONE_NUMBER}" -var="client_ip_address=${IP_ADDRESS}"

plan-athena:
	cd athena; terraform init; terraform validate; terraform plan -var="client_ip_address=${IP_ADDRESS}" -var="vpc_id=${VPC_ID}"

apply-athena:
	cd athena; terraform init; terraform fmt; terraform apply -auto-approve -var="client_ip_address=${IP_ADDRESS}" -var="vpc_id=${VPC_ID}"

destroy-athena:
	cd athena; terraform init; terraform destroy -auto-approve -var="client_ip_address=${IP_ADDRESS}" -var="vpc_id=${VPC_ID}"

apply:
	terraform init; terraform fmt; terraform apply -auto-approve -var="aws_access_key_id=${AWS_ACCESS_KEY_ID}" -var="aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}" -var="cell_phone_number=${CELL_PHONE_NUMBER}" -var="client_ip_address=${IP_ADDRESS}"

start-glue-crawler:
	~/.local/bin/aws glue start-crawler --name order_data

start-kinesis-analytics:
	~/.local/bin/aws kinesisanalytics start-application --application-name TransactionRateMonitor --input-configurations Id=1.1,InputStartingPositionConfiguration={InputStartingPosition=LAST_STOPPED_POINT}

destroy:
	terraform init; terraform destroy -auto-approve  -var="aws_access_key_id=${AWS_ACCESS_KEY_ID}" -var="aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}" -var="cell_phone_number=${CELL_PHONE_NUMBER}" -var="client_ip_address=${IP_ADDRESS}"

ssh:
	ssh ec2-user@ec2-52-201-246-6.compute-1.amazonaws.com

create_lambda_deployment_package:
	rm function.zip function-sns.zip function-weblog.zip || true
	zip function.zip lambda-function.py
	zip function-sns.zip lambda-sns.py
	zip function-weblog.zip lambda_log_transform.js

