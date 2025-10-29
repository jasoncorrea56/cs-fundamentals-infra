resource "aws_ecr_repository" "app" {
    name                 = var.app_name
    image_tag_mutability = "IMMUTABLE"
    image_scanning_configuration {
        scan_on_push = true
    }
}

resource "aws_ecr_lifecycle_policy" "keep_3" {
    repository = aws_ecr_repository.app.name
    policy = jsonencode(
        {
            rules = [
                {
                    rulePriority = 1
                    description  = "keep last 3 images"
                    selection    = {
                        tagStatus   = "any"
                        countType   = "imageCountMoreThan"
                        countNumber = 3
                    }
                    action = {
                        type = "expire"
                    }
                }
            ]
        }
    )
}

output "repo_url" {
    value = aws_ecr_repository.app.repository_url
}
output "repo_arn" {
    value = aws_ecr_repository.app.arn
}
