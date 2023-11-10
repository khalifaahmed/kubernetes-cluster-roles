
# resource "aws_iam_role" "vpc_flow_logs_s3_role" {
#   name = "vpc-flow-logs-log-group"

#   # there must not be indentation in the json policy man
#   assume_role_policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",        
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "vpc-flow-logs.amazonaws.com"
#       }
#     }
#   ]
# }
# POLICY
# }

# resource "aws_iam_role_policy_attachment" "vpcflowlogs_s3_role_policy_attach" {
#   role       = aws_iam_role.vpc_flow_logs_s3_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
# }

# # resource "aws_cloudwatch_log_group" "vpc_flow_logs_log_group" {
# #   name              = "vpc-flow-logs-log-group"
# #   retention_in_days = 5
# # }

# resource "aws_s3_bucket" "vpcflowlogs_s3" {
#   bucket = "khalifa-s-bucket-for-vpc-flow-logs-man-v1"
# }

# resource "aws_s3_bucket_versioning" "vpcflowlogs_s3_versioning" {
#   bucket = aws_s3_bucket.vpcflowlogs_s3.id

#   versioning_configuration {
#     status = "Enabled"
#   }
# }


# resource "aws_s3_bucket" "vpcflowlogs_s3_2" {
#   bucket = "khalifa-s-bucket-for-vpc-flow-logs-man-v2"
# }

# resource "aws_s3_bucket_versioning" "vpcflowlogs_s3_versioning_2" {
#   bucket = aws_s3_bucket.vpcflowlogs_s3_2.id

#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# resource "aws_flow_log" "vpc_flow_log_1" {
#   # iam_role_arn         = aws_iam_role.vpc_flow_logs_s3_role.arn
#   log_destination      = aws_s3_bucket.vpcflowlogs_s3.arn
#   log_destination_type = "s3"
#   traffic_type         = "ALL"
#   eni_id               = aws_instance.db_server.primary_network_interface_id
# }








# resource "aws_iam_role" "es2_s3_role" {
#   name = "ec2-s3-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"    
#     Statement = [{
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Principal = {
#         Service = "ec2.amazonaws.com"
#       }
#     }]
#   })
# }

resource "aws_iam_role" "es2_s3_role" {
  name = "ec2-s3-role"

  # there must not be indentation in the json policy man
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",        
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    }
  ]
}
POLICY
}


# resource "aws_iam_policy" "es2_s3_policy" {
#   name = "es2-s3-policy"
#   path = "/"
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         "Effect" = "Allow",
#         "Action" = ["s3:*"],
#         "Resource" = ["*"]
#       }
#     ]  
#   })
# }

resource "aws_iam_policy" "es2_s3_policy" {
  name = "es2-s3-policy"
  path = "/"

  # there must not be indentation in the json policy man
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "s3:*",        
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
POLICY
}

# resource "aws_iam_policy" "es2_s3_policy" {
#   name = "es2-s3-policy"
#   path = "/"
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         "Effect": "Allow",
#         "Action": [
#           "s3:GetObject",
#           "s3:List*"
#         ],
#         "Resource": [
#           "arn:aws:s3:::khalifa-s-bucket-man/*"
#         ]  
#       }
#     ]  
#   })
# }

# resource "aws_iam_role_policy_attachment" "es2_s3_role_policy_attach" {
#   role       = aws_iam_role.es2_s3_role.name
#   policy_arn = aws_iam_policy.es2_s3_policy.arn
# }

resource "aws_iam_role_policy_attachment" "es2_s3_role_policy_attach" {
  role       = aws_iam_role.es2_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = "ec2-s3-profile"
  role = aws_iam_role.es2_s3_role.name
}
