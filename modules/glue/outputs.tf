output "glue_crawler_arn" {
  value       = aws_glue_crawler.glue_crawler.arn
  description = "The arn of the Glue crawler"
}