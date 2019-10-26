# AWS
AWS_ACCESS_KEY_ID?=AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY?=AWS_SECRET_ACCESS_KEY
AWS_REGION?=AWS_REGION

apply:
	terraform init; terraform apply -auto-approve

destroy:
	terraform init; terraform destroy -auto-approve

ssh:
	ssh ec2-user@ec2-52-201-246-6.compute-1.amazonaws.com

