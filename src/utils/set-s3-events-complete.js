var AWS = require("aws-sdk");

var params = {
  Bucket: 'STRING_VALUE', /* required */
  NotificationConfiguration: { /* required */
    LambdaFunctionConfigurations: [
      {
        Events: [ /* required */
          s3:ReducedRedundancyLostObject | s3:ObjectCreated:* | s3:ObjectCreated:Put | s3:ObjectCreated:Post | s3:ObjectCreated:Copy | s3:ObjectCreated:CompleteMultipartUpload | s3:ObjectRemoved:* | s3:ObjectRemoved:Delete | s3:ObjectRemoved:DeleteMarkerCreated | s3:ObjectRestore:* | s3:ObjectRestore:Post | s3:ObjectRestore:Completed | s3:Replication:* | s3:Replication:OperationFailedReplication | s3:Replication:OperationNotTracked | s3:Replication:OperationMissedThreshold | s3:Replication:OperationReplicatedAfterThreshold,
          /* more items */
        ],
        LambdaFunctionArn: 'STRING_VALUE', /* required */
        Filter: {
          Key: {
            FilterRules: [
              {
                Name: prefix | suffix,
                Value: 'STRING_VALUE'
              },
              /* more items */
            ]
          }
        },
        Id: 'STRING_VALUE'
      },
      /* more items */
    ],
    QueueConfigurations: [
      {
        Events: [ /* required */
          s3:ReducedRedundancyLostObject | s3:ObjectCreated:* | s3:ObjectCreated:Put | s3:ObjectCreated:Post | s3:ObjectCreated:Copy | s3:ObjectCreated:CompleteMultipartUpload | s3:ObjectRemoved:* | s3:ObjectRemoved:Delete | s3:ObjectRemoved:DeleteMarkerCreated | s3:ObjectRestore:* | s3:ObjectRestore:Post | s3:ObjectRestore:Completed | s3:Replication:* | s3:Replication:OperationFailedReplication | s3:Replication:OperationNotTracked | s3:Replication:OperationMissedThreshold | s3:Replication:OperationReplicatedAfterThreshold,
          /* more items */
        ],
        QueueArn: 'STRING_VALUE', /* required */
        Filter: {
          Key: {
            FilterRules: [
              {
                Name: prefix | suffix,
                Value: 'STRING_VALUE'
              },
              /* more items */
            ]
          }
        },
        Id: 'STRING_VALUE'
      },
      /* more items */
    ],
    TopicConfigurations: [
      {
        Events: [ /* required */
          s3:ReducedRedundancyLostObject | s3:ObjectCreated:* | s3:ObjectCreated:Put | s3:ObjectCreated:Post | s3:ObjectCreated:Copy | s3:ObjectCreated:CompleteMultipartUpload | s3:ObjectRemoved:* | s3:ObjectRemoved:Delete | s3:ObjectRemoved:DeleteMarkerCreated | s3:ObjectRestore:* | s3:ObjectRestore:Post | s3:ObjectRestore:Completed | s3:Replication:* | s3:Replication:OperationFailedReplication | s3:Replication:OperationNotTracked | s3:Replication:OperationMissedThreshold | s3:Replication:OperationReplicatedAfterThreshold,
          /* more items */
        ],
        TopicArn: 'STRING_VALUE', /* required */
        Filter: {
          Key: {
            FilterRules: [
              {
                Name: prefix | suffix,
                Value: 'STRING_VALUE'
              },
              /* more items */
            ]
          }
        },
        Id: 'STRING_VALUE'
      },
      /* more items */
    ]
  }
};
s3.putBucketNotificationConfiguration(params, function(err, data) {
  if (err) console.log(err, err.stack); // an error occurred
  else     console.log(data);           // successful response
});