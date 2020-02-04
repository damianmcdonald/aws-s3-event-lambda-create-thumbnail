#!/bin/bash

##############################################################
#                                                            #
# This sample demonstrates the following concepts:           #
#                                                            #
# * S3 Bucket creation                                       #
# * S3 Bucket object upload                                  #
# * S3 Bucket object retrieval                               #
# * IAM role creation                                        #
# * IAM policy creation and attachment to role               #
# * Lambda function creation                                 #
# * Lambda function invocation                               #
# * Cleans up all the resources created                      #
#                                                            #
##############################################################

# Colors
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT_GRAY='\033[0;37m'
DARK_GRAY='\033[1;30m'
LIGHT_RED='\033[1;31m'
LIGHT_GREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHT_BLUE='\033[1;34m'
LIGHT_PURPLE='\033[1;35m'
LIGHT_CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Global variable declarations
PROJECT_DIR=$PWD
AWS_PROFILE=<!-- ADD_YOUR_AWS_CLI_PROFILE_HERE -->
AWS_REGION=$(aws configure get region --output text --profile ${AWS_PROFILE})
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --profile ${AWS_PROFILE} --query "Account" --output text)
AWS_ACCOUNT_ARN=$(aws sts get-caller-identity --profile ${AWS_PROFILE} --query "Arn" --output text)
S3_SOURCE_BUCKET=imagesourcedcorp${RANDOM}
S3_RESIZED_BUCKET=${S3_SOURCE_BUCKET}-resized
IMAGE_FILE_DIR=${PROJECT_DIR}/images
SOURCE_DIR=${PROJECT_DIR}/src
LAMBDA_SRC=${SOURCE_DIR}/lambda
POLICIES_DIR=${PROJECT_DIR}/policies
TEST_DIR=${PROJECT_DIR}/test
UTIL_SRC=${SOURCE_DIR}/utils
LAMBDA_POLICY_NAME=lambda-s3-policy
LAMBDA_ROLE_NAME=lambda-s3-role
UNDEPLOY_FILE=aws-undeploy.sh

###########################################################
#                                                         #
#  Create and populate the S3 Buckets                     #
#                                                         #
###########################################################

# create the buckets
echo -e "[${LIGHT_BLUE}INFO${NC}] Creating S3 Bucket: ${YELLOW}$S3_SOURCE_BUCKET${NC}";
aws s3 mb s3://${S3_SOURCE_BUCKET} --profile ${AWS_PROFILE}

echo -e "[${LIGHT_BLUE}INFO${NC}] Creating S3 Bucket: ${YELLOW}$S3_RESIZED_BUCKET${NC}";
aws s3 mb s3://${S3_RESIZED_BUCKET} --profile ${AWS_PROFILE}

###########################################################
#                                                         #
#  Create the Lambda Execution Role                       #
#                                                         #
###########################################################
echo -e "[${LIGHT_BLUE}INFO${NC}] Creating lambda execution policy ${YELLOW}$LAMBDA_ROLE_NAME${NC}";
aws iam create-policy \
  --policy-name ${LAMBDA_POLICY_NAME} \
  --policy-document file://${POLICIES_DIR}/lambda-execute-role-policy.json \
  --profile ${AWS_PROFILE}

# delete any previous instance of lambda-trust-policy.json
if [ -f "${POLICIES_DIR}/lambda-trust-policy.json" ]; then
    rm "${POLICIES_DIR}/lambda-trust-policy.json"
fi

# create trust policy document
cat > "${POLICIES_DIR}/lambda-trust-policy.json" <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com",
        "AWS": "${AWS_ACCOUNT_ARN}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

echo -e "[${LIGHT_BLUE}INFO${NC}] Creating lambda execution role ${YELLOW}$LAMBDA_ROLE_NAME${NC}";
aws iam create-role \
	--role-name ${LAMBDA_ROLE_NAME} \
  --assume-role-policy-document file://${POLICIES_DIR}/lambda-trust-policy.json \
  --profile ${AWS_PROFILE}

LAMDBA_POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName == '$LAMBDA_POLICY_NAME'][Arn]" --output text --profile $AWS_PROFILE)

echo -e "[${LIGHT_BLUE}INFO${NC}] Attaching lambda policy to lambda execution role ${YELLOW}$LAMDBA_POLICY_ARN${NC}";
aws iam attach-role-policy \
  --policy-arn ${LAMDBA_POLICY_ARN} \
  --role-name ${LAMBDA_ROLE_NAME} \
  --profile ${AWS_PROFILE}

LAMBDA_S3_ROLE_ARN=$(aws iam get-role --role-name $LAMBDA_ROLE_NAME --query 'Role.Arn' --output text --profile $AWS_PROFILE)

echo -e "[${LIGHT_BLUE}INFO${NC}] Verify the lambda S3 role ARN ${YELLOW}LAMBDA_S3_ROLE_ARN${NC}";

###########################################################
#                                                         #
#  Create the JSON Test Event                             #
#                                                         #
###########################################################

# delete any previous instance of test-event.json
if [ -f "${TEST_DIR}/test-event.json" ]; then
    rm "${TEST_DIR}/test-event.json"
fi

# create test-event.json
cat > ${TEST_DIR}/test-event.json <<EOF
{
  "Records":[
    {
      "eventVersion":"2.0",
      "eventSource":"aws:s3",
      "awsRegion":"$AWS_REGION",
      "eventTime":"1970-01-01T00:00:00.000Z",
      "eventName":"ObjectCreated:Put",
      "userIdentity":{
        "principalId":"AIDAJDPLRKLG7UEXAMPLE"
      },
      "requestParameters":{
        "sourceIPAddress":"127.0.0.1"
      },
      "responseElements":{
        "x-amz-request-id":"C3D13FE58DE4C810",
        "x-amz-id-2":"FMyUVURIY8/IgAtTv8xRjskZQpcIZ9KG4V5Wp6S7S/JRWeUWerMUE5JgHvANOjpD"
      },
      "s3":{
        "s3SchemaVersion":"1.0",
        "configurationId":"testConfigRule",
        "bucket":{
          "name":"$S3_SOURCE_BUCKET",
          "ownerIdentity":{
            "principalId":"A3NL1KOZZKExample"
          },
          "arn":"arn:aws:s3:::$S3_SOURCE_BUCKET"
        },
        "object":{
          "key":"koala.jpg",
          "size":469,
          "eTag":"d41d8cd98f00b204e9800998ecf8427e",
          "versionId":"096fKKXTRTtl3on89fVO.nfljtsv6qko"
        }
      }
    }
  ]
}
EOF

###########################################################
#                                                         #
#  Build, deploy and test the Lambda function             #
#                                                         #
###########################################################

# change to the lambda source dir
cd $LAMBDA_SRC

# Install the Sharp and Async libraries with NPM
npm install

# Create a deployment package with the function code and dependencies
zip -r function.zip .

echo -e "[${LIGHT_BLUE}INFO${NC}] Creating the lambda function ${YELLOW}CreateThumbnail${NC}";
aws lambda create-function \
	--function-name CreateThumbnail \
	--zip-file fileb://function.zip \
	--handler index.handler \
	--runtime nodejs12.x \
	--timeout 20 \
	--memory-size 1024 \
	--role ${LAMBDA_S3_ROLE_ARN} \
	--profile ${AWS_PROFILE}

LAMBDA_S3_FUNCTION_ARN=$(aws lambda get-function --function-name CreateThumbnail --query 'Configuration.FunctionArn' --output text --profile $AWS_PROFILE)

echo -e "[${LIGHT_BLUE}INFO${NC}] Verify the lambda function ARN ${YELLOW}LAMBDA_S3_FUNCTION_ARN${NC}";

echo -e "[${LIGHT_BLUE}INFO${NC}] Testing the lambda function ${YELLOW}CreateThumbnail${NC}";

# empty the resized bucket so we have a clean env for the test
aws s3 rm s3://${S3_RESIZED_BUCKET}/ --recursive --profile ${AWS_PROFILE}

# add the koala.jpg image to the S3 source bucket for testing
aws s3api put-object \
	--bucket ${S3_SOURCE_BUCKET} \
	--storage-class STANDARD \
	--key koala.jpg \
	--body ${IMAGE_FILE_DIR}/koala.jpg \
	--profile ${AWS_PROFILE}

aws lambda invoke \
	--function-name CreateThumbnail \
	--payload file://${TEST_DIR}/test-event.json ${TEST_DIR}/test-event-result.txt \
	--profile ${AWS_PROFILE}

aws s3api head-object --bucket ${S3_RESIZED_BUCKET} --key resized-koala.jpg --profile ${AWS_PROFILE}
# assign the exit code to a variable
S3_OBJECT_EXISTS_VALIDAION_CODE="$?"

# check the exit code, anything other than 0 means the test failed
if [ $S3_OBJECT_EXISTS_VALIDAION_CODE != "0" ]; then
    echo -e "[${RED}FATAL${NC}] The Lambda function ${YELLOW}$CreateThumbnail${NC} failed to create the thumbnail for koala.jpg";
    # exit 999;
fi

# empty the buckets after the test
aws s3 rm s3://${S3_SOURCE_BUCKET}/ --recursive --profile ${AWS_PROFILE}
aws s3 rm s3://${S3_RESIZED_BUCKET}/ --recursive --profile ${AWS_PROFILE}

###########################################################
#                                                         #
#  Set permissions to permit S3 events to invoke          #
#  the Lambda function                                    #
#                                                         #
###########################################################

echo -e "[${LIGHT_BLUE}INFO${NC}] Create permissions to permit S3 to invoke lambda function ${YELLOW}CreateThumbnail${NC}";
aws lambda add-permission \
--function-name CreateThumbnail \
--principal s3.amazonaws.com \
--statement-id s3invoke \
--action "lambda:InvokeFunction" \
--source-arn arn:aws:s3:::${S3_SOURCE_BUCKET} \
--source-account ${AWS_ACCOUNT_ID} \
--profile ${AWS_PROFILE}

# Verify the Lambda function permissions
aws lambda get-policy --function-name CreateThumbnail --profile ${AWS_PROFILE}

###########################################################
#                                                         #
#  Create the S3 events on the source S3 bucket           #
#                                                         #
###########################################################

# delete any previous instance of set-s3-events-autogen.js
if [ -f "${TEST_DIR}/set-s3-events-autogen.js" ]; then
    rm "${TEST_DIR}/set-s3-events-autogen.js"
fi

# create set-s3-events-autogen.js
cat > ${UTIL_SRC}/set-s3-events-autogen.js <<EOF
var AWS = require("aws-sdk");

AWS.config.update({region: '${AWS_REGION}'});
s3 = new AWS.S3({apiVersion: '2006-03-01'});

var params = {
  Bucket: '${S3_SOURCE_BUCKET}',
  NotificationConfiguration: {
    LambdaFunctionConfigurations: [
      {
        Events: [
          's3:ObjectCreated:*'
        ],
        LambdaFunctionArn: '${LAMBDA_S3_FUNCTION_ARN}',
        Filter: {
          Key: {
            FilterRules: [
              {
                Name: 'suffix',
                Value: '.jpg'
              }
            ]
          }
        },
        Id: 'ImageResizeEvent'
      }
    ]
  }
};
s3.putBucketNotificationConfiguration(params, function(err, data) {
  if (err) console.log(err, err.stack); // an error occurred
  else     console.log(data);           // successful response
});
EOF

cd ${UTIL_SRC}
npm install
node ${UTIL_SRC}/set-s3-events-autogen.js

###########################################################
#                                                         #
# Undeployment file creation                              #
#                                                         #
###########################################################

# delete any previous instance of undeploy.sh
if [ -f "${PROJECT_DIR}/${UNDEPLOY_FILE}" ]; then
    rm "${PROJECT_DIR}/${UNDEPLOY_FILE}"
fi

cat > "${PROJECT_DIR}/${UNDEPLOY_FILE}" <<EOF
#!/bin/bash

# Colors
BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT_GRAY='\033[0;37m'
DARK_GRAY='\033[1;30m'
LIGHT_RED='\033[1;31m'
LIGHT_GREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHT_BLUE='\033[1;34m'
LIGHT_PURPLE='\033[1;35m'
LIGHT_CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

echo -e "[${LIGHT_BLUE}INFO${NC}] Delete S3 Bucket ${YELLOW}${S3_SOURCE_BUCKET}${NC}.";
aws s3 rm s3://${S3_SOURCE_BUCKET}/ --recursive --profile ${AWS_PROFILE}
aws s3 rb s3://${S3_SOURCE_BUCKET} --profile ${AWS_PROFILE}

echo -e "[${LIGHT_BLUE}INFO${NC}] Delete S3 Bucket ${YELLOW}${S3_RESIZED_BUCKET}${NC}.";
aws s3 rm s3://${S3_RESIZED_BUCKET}/ --recursive --profile ${AWS_PROFILE}
aws s3 rb s3://${S3_RESIZED_BUCKET} --profile ${AWS_PROFILE}

echo -e "[${LIGHT_BLUE}INFO${NC}] Delete the lambda function ${YELLOW}CreateThumbnail${NC}.";
aws lambda delete-function --function-name CreateThumbnail --profile ${AWS_PROFILE}

echo -e "[${LIGHT_BLUE}INFO${NC}] Detach the lambda iam policy ${YELLOW}${LAMDBA_POLICY_ARN}${NC} from the lambda role ${YELLOW}${LAMBDA_ROLE_NAME}${NC}.";
aws iam detach-role-policy --role-name ${LAMBDA_ROLE_NAME} --policy-arn ${LAMDBA_POLICY_ARN}

echo -e "[${LIGHT_BLUE}INFO${NC}] Delete the lambda iam role ${YELLOW}${LAMBDA_ROLE_NAME}${NC}.";
aws iam delete-role --role-name ${LAMBDA_ROLE_NAME} --profile ${AWS_PROFILE}

echo -e "[${LIGHT_BLUE}INFO${NC}] Delete the lambda policy ${YELLOW}${LAMDBA_POLICY_ARN}${NC}.";
aws iam delete-policy --policy-arn ${LAMDBA_POLICY_ARN}
EOF

chmod +x "${PROJECT_DIR}/${UNDEPLOY_FILE}"