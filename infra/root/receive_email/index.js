const AWS = require('aws-sdk');
const ses = new AWS.SES();
const notificationEmail = process.env.NOTIFICATION_EMAIL;
const fromEmail = process.env.FROM_EMAIL;

function handler (event, context, callback) {
  try {
    const messageId = event.Records[0].ses.mail.messageId;
    const { from, to, subject } = event.Records[0].ses.mail.commonHeaders;
    const params = {
      Destination: { ToAddresses: [ notificationEmail ] },
      Source: fromEmail,
      Template: 'SamhstnTemplate',
      TemplateData: JSON.stringify({ from: from.join(', '), to: to.join(', '), subject, messageId })
    };
    ses.sendTemplatedEmail(params, (err, data) => {
      if (err) {
        console.log('EMAIL_SEND_ERROR', err);
        return;
      }
      console.log('EMAIL_SEND_SUCCESS', data.messageId);
    });
    console.log('FROM ', from.join(', '));
    console.log('TO ', to.join(', '));
    console.log('SUBJECT ', subject);
    console.log('MESSAGE_ID ', messageId);
    callback(null);
  } catch (e) {
    console.log('ERROR ', e);
    callback(true);
  }
}

exports.handler = handler;
