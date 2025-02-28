exports.handler = async (event) => {
  const { postUrl } = event.queryStringParameters;

  const client = new NetlifyAPI(process.env.NETLIFY_ACCESS_TOKEN);
  const submissions = await client.listFormSubmissions({
    formId: 'comments',
    siteId: process.env.SITE_ID
  });

  const filtered = submissions.filter(s =>
    s.data.postUrl === postUrl
  );

  return {
    statusCode: 200,
    body: JSON.stringify(filtered)
  };
};
