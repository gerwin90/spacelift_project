provider "aws" {
  region = var.aws_region
}

# S3 bucket for website hosting
resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name
}

# Bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "website" {
  bucket = aws_s3_bucket.website.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Public access settings for the bucket - MUST be applied before setting bucket policy
resource "aws_s3_bucket_public_access_block" "website" {
  bucket                  = aws_s3_bucket.website.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Enable website hosting on the bucket
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Bucket policy to allow public read access - added explicit dependency
resource "aws_s3_bucket_policy" "website" {
  depends_on = [aws_s3_bucket_public_access_block.website]
  bucket = aws_s3_bucket.website.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
}

# Bucket ACL to make objects public - moved after policy
resource "aws_s3_bucket_acl" "website" {
  depends_on = [
    aws_s3_bucket_ownership_controls.website,
    aws_s3_bucket_public_access_block.website,
  ]
  bucket = aws_s3_bucket.website.id
  acl    = "public-read"
}

# DynamoDB table for team scores
resource "aws_dynamodb_table" "team_scores" {
  name           = "TeamScores"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "TeamName"

  attribute {
    name = "TeamName"
    type = "S"
  }
}

# Add sample items to DynamoDB table
resource "aws_dynamodb_table_item" "team_score_1" {
  table_name = aws_dynamodb_table.team_scores.name
  hash_key   = aws_dynamodb_table.team_scores.hash_key

  item = jsonencode({
    TeamName = { S = "Bad Lads" },
    Score    = { S = "2 - 0" },
    KC     = { N = "1" },
    MS   = { N = "1" },
    GK    = { N = "0" }
  })
}

resource "aws_dynamodb_table_item" "team_score_2" {
  table_name = aws_dynamodb_table.team_scores.name
  hash_key   = aws_dynamodb_table.team_scores.hash_key

  item = jsonencode({
    TeamName = { S = "Juicy Lads" },
    Score    = { S = "2 - 0" },
    KC     = { N = "1" },
    MS   = { N = "1" },
    GK    = { N = "0" }
  })
}

resource "aws_dynamodb_table_item" "team_score_3" {
  table_name = aws_dynamodb_table.team_scores.name
  hash_key   = aws_dynamodb_table.team_scores.hash_key

  item = jsonencode({
    TeamName = { S = "Good Lads" },
    Score    = { S = "2 - 0" },
    KC     = { N = "0" },
    MS   = { N = "0" },
    GK    = { N = "2" }
  })
}

# Create Lambda function code
resource "local_file" "lambda_code" {
  content = <<EOF
// AWS SDK is available in the Lambda runtime through AWS_SDK_BUNDLE
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, ScanCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
  const params = {
    TableName: 'TeamScores'
  };
  
  try {
    const command = new ScanCommand(params);
    const data = await docClient.send(command);
    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(data.Items)
    };
  } catch (error) {
    return {
      statusCode: 500,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ error: error.message })
    };
  }
};
EOF
  filename = "${path.module}/index.js"
}

# Archive file for Lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = local_file.lambda_code.filename
  output_path = "${path.module}/lambda_function.zip"
}

# IAM role for Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "lambda_dynamodb_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for Lambda to access DynamoDB
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_dynamodb_policy"
  description = "IAM policy for Lambda to access DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:Scan",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Lambda function to get team scores
resource "aws_lambda_function" "get_scores" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "GetTeamScores"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  depends_on = [
    aws_iam_role_policy_attachment.lambda_attachment
  ]
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "scores_api" {
  name        = "TeamScoresAPI"
  description = "API for team scores"
}

# API Gateway Resource
resource "aws_api_gateway_resource" "scores_resource" {
  rest_api_id = aws_api_gateway_rest_api.scores_api.id
  parent_id   = aws_api_gateway_rest_api.scores_api.root_resource_id
  path_part   = "scores"
}

# API Gateway Method
resource "aws_api_gateway_method" "scores_method" {
  rest_api_id   = aws_api_gateway_rest_api.scores_api.id
  resource_id   = aws_api_gateway_resource.scores_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# API Gateway Integration
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.scores_api.id
  resource_id = aws_api_gateway_resource.scores_resource.id
  http_method = aws_api_gateway_method.scores_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_scores.invoke_arn
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "scores_deployment" {
  depends_on = [aws_api_gateway_integration.lambda_integration]

  rest_api_id = aws_api_gateway_rest_api.scores_api.id
  stage_name  = "prod"
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_scores.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.scores_api.execution_arn}/*/*"
}

# Upload index.html with JavaScript to fetch and display team scores
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  content      = <<EOF
<!DOCTYPE html>
<html>
<head>
  <title>Team Scores</title>
  <style>
    table {
      border-collapse: collapse;
      width: 50%;
      margin: 20px 0;
    }
    th, td {
      border: 1px solid #ddd;
      padding: 8px;
      text-align: left;
    }
    th {
      background-color: #f2f2f2;
    }
    h1 {
      color: #333;
    }
  </style>
</head>
<body>
  <h1>We are the Mad Lads!</h1>
  <h2>We rip through your defence like a bad curry through your cheeks</h2>
  <p>Current team stats below...</p>
  <h2>Team Scores</h2>
  <table id="scoresTable">
    <tr>
      <th>Team Name</th>
      <th>Score</th>
      <th>KC</th>
      <th>MS</th>
      <th>GK</th>
    </tr>
    <tbody id="scoresBody"></tbody>
  </table>

  <script>
    document.addEventListener('DOMContentLoaded', function() {
      const apiUrl = '${aws_api_gateway_deployment.scores_deployment.invoke_url}/scores';
      
      fetch(apiUrl)
        .then(response => response.json())
        .then(data => {
          const tableBody = document.getElementById('scoresBody');
          
          data.forEach(item => {
            const row = document.createElement('tr');
            
            const nameCell = document.createElement('td');
            nameCell.textContent = item.TeamName;
            row.appendChild(nameCell);
            
            const scoreCell = document.createElement('td');
            scoreCell.textContent = item.Score;
            row.appendChild(scoreCell);
            
            const kcCell = document.createElement('td');
            kcCell.textContent = item.KC;
            row.appendChild(kcCell);
            
            const msCell = document.createElement('td');
            msCell.textContent = item.MS;
            row.appendChild(msCell);
            
            const gkCell = document.createElement('td');
            gkCell.textContent = item.GK;
            row.appendChild(gkCell);
            
            tableBody.appendChild(row);
          });
        })
        .catch(error => {
          console.error('Error fetching data:', error);
          document.getElementById('scoresBody').innerHTML = 
            '<tr><td colspan="5">Error loading data</td></tr>';
        });
    });
  </script>       
</body>
</html>
EOF
  content_type = "text/html"
}

# Upload error.html
resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.website.id
  key          = "error.html"
  content      = "<html><body><h1>Error</h1></body></html>"
  content_type = "text/html"
}
