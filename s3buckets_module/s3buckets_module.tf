module "shared_vars" {
    source =  "../shared_vars"
}

resource "aws_kms_key" "mykey" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket" "codepipeline-artifacts-s3" {
  bucket = "sample-codepipeline-artifacts-${module.shared_vars.env_suffix}"
  force_destroy = true
  

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.mykey.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}


#create bucket for s3 trigger


resource "aws_s3_bucket" "codebase-s3" {
  bucket = "sample-codebasezip-${module.shared_vars.env_suffix}"
  force_destroy = true
  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.mykey.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}



 

output "pipeline-bucket"{
    value = "${aws_s3_bucket.codepipeline-artifacts-s3.bucket}"
}

output "code-bucket"{
     value = "${aws_s3_bucket.codebase-s3.bucket}"

}