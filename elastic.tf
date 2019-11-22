resource "aws_elasticsearch_domain" "es" {
  count = 1

  domain_name           = var.elasticsearch_domain_name
  elasticsearch_version = "6.4"

  cluster_config {
    instance_type            = "m4.large.elasticsearch"
    instance_count           = 1
    dedicated_master_enabled = false
    dedicated_master_count   = 0
    zone_awareness_enabled   = false
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }

  encrypt_at_rest {
    enabled = false
  }

  node_to_node_encryption {
    enabled = false
  }

  tags = {
    Domain = "TestDomain"
  }
}

data "aws_iam_policy_document" "es_management_access" {
  count = 1

  statement {
    actions = [
      "es:*",
    ]

    resources = [
      aws_elasticsearch_domain.es[0].arn,
      "${aws_elasticsearch_domain.es[0].arn}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = [var.client_ip_address]
    }
  }
}

resource "aws_elasticsearch_domain_policy" "es_management_access" {
  domain_name     = "cadabra"
  access_policies = data.aws_iam_policy_document.es_management_access[0].json
}