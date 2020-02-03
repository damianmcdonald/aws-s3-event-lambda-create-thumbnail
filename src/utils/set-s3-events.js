var AWS = require("aws-sdk");

var params = {
  Bucket: '${S3_SOURCE_BUCKET}', /* required */
  NotificationConfiguration: { /* required */
    LambdaFunctionConfigurations: [
      {
        Events: [ /* required */
          s3:ObjectCreated:*
        ],
        LambdaFunctionArn: '${LAMBDA_S3_FUNCTION_ARN}', /* required */
        Filter: {
          Key: {
            FilterRules: [
              {
                Name: prefix | suffix,
                Value: 'jpg'
              },
              /* more items */
            ]
          }
        },
        Id: 'ImageResizeEvent'
      }
      /* more items */
    ]
  }
};
s3.putBucketNotificationConfiguration(params, function(err, data) {
  if (err) console.log(err, err.stack); // an error occurred
  else     console.log(data);           // successful response
});