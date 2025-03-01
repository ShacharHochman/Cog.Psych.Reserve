const { NetlifyAPI } = require('netlify');

exports.handler = async (event) => {
  // Parse URL-encoded form data
  const params = new URLSearchParams(event.body);
  const data = {
    name: params.get('name'),
    email: params.get('email'),
    comment: params.get('comment'),
    postUrl: params.get('postUrl')
  };

  // Validate required fields
  if (!data.name || !data.comment || !data.postUrl) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: 'Missing required fields' })
    };
  }

  // Submit to Netlify Forms
  const client = new NetlifyAPI(process.env.NETLIFY_ACCESS_TOKEN);
  try {
    await client.submitFormSubmission({
      site_id: process.env.SITE_ID,
      form_id: 'comments',
      fields: data
    });

    return {
      statusCode: 200,
      body: JSON.stringify({ success: true })
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Failed to submit comment' })
    };
  }
};
