variable "pipeline-bucket"{

}

variable "s3projectzip"{

}

variable "ecs_cluster_name"{

}

variable "ecs_service_name"{

}

variable "code-bucket"{

}

variable "container_name"{

}

data "aws_kms_alias" "s3" {
  name = "alias/aws/s3"
}


module "shared_vars" {
   source =  "../shared_vars" 
}


#data source codebuild policy name-Ec2containerregistryfullaccess
data "aws_iam_policy" "codebuild-policy"{
     arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
 }

resource "aws_iam_policy" "codebuild-policydocument-second" {
  name        = "tf-policydocument"
  policy      = data.aws_iam_policy_document.codebuild-policy-second.json
}


data "aws_iam_policy_document" "codebuild-policy-second" {
  
  statement {
    actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
    ]

    resources = ["${aws_cloudwatch_log_group.log_group.arn}:*"]
   // arn:aws:logs:ap-south-1:710653795817:log-group:sample-codebuild-log-group-dev:log-stream:log-stream-dev/b68d1ead-5bde-4474-9b85-67d6b433cab9
   // "arn:aws:logs:ap-south-1:710653795817:log-group:sample-codebuild-log-group-dev"
    effect    = "Allow"

  }

  statement {
    actions = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketAcl",
        "s3:GetBucketLocation"
    ]

    resources = ["arn:aws:s3:::${var.pipeline-bucket}/*"]
   // arn:aws:s3:::sample-codepipeline-artifacts-dev/samplecodepipelinede/source_out/UHRGJVd.zip
    
    
    effect    = "Allow"

  }

  statement {
    actions = [
        "codebuild:CreateReportGroup",
        "codebuild:CreateReport",
        "codebuild:UpdateReport",
        "codebuild:BatchPutTestCases",
        "codebuild:BatchPutCodeCoverages"
    ]

    resources = [ "arn:aws:codebuild:${module.shared_vars.aws_region}:${module.shared_vars.AWS_ACCOUNT_ID}:report-group/${aws_codebuild_project.sample-codebuild.name}-*"]
    effect    = "Allow"

  }

   }


#create IAM role for codebuild project
 resource "aws_iam_role" "codebuild-role" {
  name = "sample-codebuild-${module.shared_vars.env_suffix}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "sample-codebuild-${module.shared_vars.env_suffix}"
  }
}

# #attach codebuild policy to above created codebuuild role
resource "aws_iam_role_policy_attachment" "codebuild-role-policy-attach" {
  role       = "${aws_iam_role.codebuild-role.name}"
  policy_arn = "${data.aws_iam_policy.codebuild-policy.arn}"
}

resource "aws_iam_role_policy_attachment" "codebuild-role-policy-attach-second" {
  role       = "${aws_iam_role.codebuild-role.name}"
  policy_arn = "${aws_iam_policy.codebuild-policydocument-second.arn}"
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = "sample-codebuild-log-group-${module.shared_vars.env_suffix}"

}

# create codebuild project needed for codepipeline
resource "aws_codebuild_project" "sample-codebuild" {
  name          = "sample-codebuild-${module.shared_vars.env_suffix}"
  description   = "sample codebuild project for codepipeline"
  //build_timeout = "5"
  service_role  = aws_iam_role.codebuild-role.arn

   source {
    type            = "CODEPIPELINE"
    
  }
  artifacts {
    type = "CODEPIPELINE"
  }
#   cache {
#     type     = "S3"
#     location = aws_s3_bucket.example.bucket
#   }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "${module.shared_vars.aws_region}"
    }
    environment_variable {
      name  = "DockerFilePath"
      value = "${module.shared_vars.Dockerfile}"
    }
    environment_variable {
      name  = "CONTAINER_NAME"
      value = "${var.container_name}"
    }
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "${module.shared_vars.AWS_ACCOUNT_ID}"
    }
    environment_variable {
      name  = "IMAGE_TAG"
      value = "${module.shared_vars.IMAGE_TAG}"
    }
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = "${module.shared_vars.IMAGE_REPO_NAME}"
    }

    # environment_variable {
    #   name  = "SOME_KEY2"
    #   value = "SOME_VALUE2"
    #   type  = "PARAMETER_STORE"
    # }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "sample-codebuild-log-group-${module.shared_vars.env_suffix}"
      stream_name = "log-stream-${module.shared_vars.env_suffix}"
    }

    # s3_logs {
    #   status   = "ENABLED"
    #   location = "${aws_s3_bucket.example.id}/build-log"
    # }
  }

  tags = {
    Environment = "Test"
  }
}



resource "aws_codepipeline" "ecs-pipeline" {
  name     = "samplecodepipeline${module.shared_vars.env_suffix}"
  role_arn = "${aws_iam_role.sample-pipeline-role.arn}"

  # The Amazon S3 bucket where artifacts are stored for the pipeline.
  # https://docs.aws.amazon.com/codepipeline/latest/APIReference/API_ArtifactStore.html
  artifact_store {
    # You can specify the name of an S3 bucket but not a folder within the bucket.
    # A folder to contain the pipeline artifacts is created for you based on the name of the pipeline.
    # You can use any Amazon S3 bucket in the same AWS Region as the pipeline to store your pipeline artifacts.
    location = "${var.pipeline-bucket}"

    # The value must be set to S3.
    type = "S3"

    # The encryption key used to encrypt the data in the artifact store, such as an AWS KMS key.
    # If this is undefined, the default key for Amazon S3 is used.
    encryption_key {
      # The ID used to identify the key. For an AWS KMS key, this is the key ID or key ARN.
      //id = "${var.encryption_key_id != "" ? var.encryption_key_id : data.aws_kms_alias.s3.arn}"
        id = "${data.aws_kms_alias.s3.arn}"
      # The value must be set to KMS.
      type = "KMS"
    }
  }
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        S3Bucket    = "${var.code-bucket}"
        S3ObjectKey = "${var.s3projectzip}"
        PollForSourceChanges = false
      }
    }
  }
  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = 1
      run_order        = 1
      input_artifacts  = ["source_output"]
      output_artifacts = ["Build"]

      configuration ={
        ProjectName = "${aws_codebuild_project.sample-codebuild.name}"

        # One of your input sources must be designated the PrimarySource. This source is the directory
        # where AWS CodeBuild looks for and runs your buildspec file. The keyword PrimarySource is used to
        # specify the primary source in the configuration section of the CodeBuild stage in the JSON file.
        # https://docs.aws.amazon.com/codebuild/latest/userguide/sample-pipeline-multi-input-output.html
        PrimarySource = "Source"
      }
    }
  }
  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = 1
      run_order       = 1
      input_artifacts = ["Build"]

      configuration = {
        ClusterName = "${var.ecs_cluster_name}"
        ServiceName = "${var.ecs_service_name}"

        # An image definitions document is a JSON file that describes your ECS container name and the image and tag.
        # You must generate an image definitions file to provide the CodePipeline job worker
        # with the ECS container and image identification to use for your pipeline’s deployment stage.
        # https://docs.aws.amazon.com/codepipeline/latest/userguide/pipelines-create.html#pipelines-create-image-definitions
 //       FileName = "${var.file_name}"
      }
    }
  }
}

# Creating Role for codepipeline

resource "aws_iam_role" "sample-pipeline-role" {
  name               = "sample-pipeline-${module.shared_vars.env_suffix}-role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
  //path               = "${var.iam_path}"
  description        = "pipeline role"
 // tags               = "pipelien-role-${module.shared_vars.env_suffix}"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

# https://www.terraform.io/docs/providers/aws/r/iam_policy.html
resource "aws_iam_policy" "sample-pipeline-role-policy" {
  name        = "sample-pipeline-role-policy-${module.shared_vars.env_suffix}"
  //policy      = "${data.aws_iam_policy_document.policy.json}"
  policy = "${data.template_file.codepolicy.rendered}" 
       
 // path        = "${var.iam_path}"
  description = "policy for codepipeline"
}

data "template_file" "codepolicy" {
#  template = "${file("${path.module}/task_definition.json")}"
  template = file("./assets/${module.shared_vars.env_suffix}/codepipelinepolicy.json")
}

# https://www.terraform.io/docs/providers/aws/r/iam_role_policy_attachment.html
resource "aws_iam_role_policy_attachment" "sample-pipeline-role-attachment" {
  role       = "${aws_iam_role.sample-pipeline-role.name}"
  policy_arn = "${aws_iam_policy.sample-pipeline-role-policy.arn}"
}


/// the following part will use cloudwatch event to trigger codepipeline on s3 file upload

resource "aws_cloudwatch_event_rule" "s3_codepipelime_trigger" {
  name     = "s3-codepipeline-trigger-${module.shared_vars.env_suffix}"
  role_arn = aws_iam_role.cwe_role.arn

  event_pattern = <<EOF
{
  "source": [
    "aws.s3"
  ],
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "detail": {
    "eventSource": [
      "s3.amazonaws.com"
    ],
    "eventName": [
      "PutObject",
      "CompleteMultipartUpload",
      "CopyObject"
    ],
    "requestParameters": {
      "bucketName": [
        "${var.code-bucket}"
      ],
      "key": [
        "${var.s3projectzip}"
      ]
    }
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "codepipeline" {
  rule      = aws_cloudwatch_event_rule.s3_codepipelime_trigger.name
 // target_id = "sample-${module.shared_vars.env_suffix}-Image-Push-Codepipeline"
  arn       = "${aws_codepipeline.ecs-pipeline.arn}"
  role_arn  = aws_iam_role.cwe_role.arn
}


resource "aws_iam_role" "cwe_role" {
  name               = "sample-${module.shared_vars.env_suffix}-cwe-role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": ["events.amazonaws.com"]
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "cwe_policy" {
  name = "sample-${module.shared_vars.env_suffix}-cwe-policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "codepipeline:StartPipelineExecution",
            "Resource": "${aws_codepipeline.ecs-pipeline.arn}"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "cws_policy_attachment" {

  name       = "sample-${module.shared_vars.env_suffix}-cwe-policy"
  roles      = [aws_iam_role.cwe_role.name]
  policy_arn = aws_iam_policy.cwe_policy.arn
}




# resource "aws_cloudtrail" "example" {
#   name = "codepipeline-source-trail"
#   s3_bucket_name = "${var.pipeline-bucket}"

#   event_selector {
#     read_write_type           = "WriteOnly"
#     include_management_events = true

#     data_resource {
#       type = "AWS::S3::Object"

#       # Make sure to append a trailing '/' to your ARN if you want
#       # to monitor all objects in a bucket.
#       values = ["${var.code-bucket}/${var.s3projectzip}"]
#     }
#   }
# }

# resource "aws_event_selector" "foo_bucket_events" {
#   trail_name = "codepipeline-source-trail"

#   data_resources            = ["arn:aws:s3:::${var.code-bucket}/${var.s3projectzip}"] # max 250
#   include_management_events = true
#   read_write_type           = "WriteOnl"
# }