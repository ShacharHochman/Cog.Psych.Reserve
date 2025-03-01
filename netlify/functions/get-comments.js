const { NetlifyAPI } = require('netlify');

exports.handler = async (event) => {
  const { postUrl } = event.queryStringParameters;
  const client = new NetlifyAPI(process.env.NETLIFY_ACCESS_TOKEN);

  try {
    const submissions = await client.listFormSubmissions({
      site_id: process.env.SITE_ID,
      form_id: 'comments'
    });

    const filtered = submissions
      .filter(s => s.data.postUrl === postUrl)
      .map(s => ({
        name: s.data.name,
        comment: s.data.comment,
        created_at: s.created_at
      }));

    return {
      statusCode: 200,
      body: JSON.stringify(filtered)
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Failed to fetch comments' })
    };
  }
};
