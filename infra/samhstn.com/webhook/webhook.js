exports.handler = async (event) => {
  console.log(JSON.parse(decodeURIComponent(Buffer.from(event.body, 'base64').toString()).replace(/^payload=/, '')));

  const response = {
    statusCode: 200,
    body: JSON.stringify('Hello from Lambda!')
  };

  return response;
}
