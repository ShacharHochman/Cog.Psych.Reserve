exports.handler = async (event) => {
  const { name, email, comment, postUrl } = JSON.parse(event.body);

  // Validate input
  if (!name || !comment || !postUrl) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: 'Missing required fields' })
    };
  }

  // Process and store comment (Netlify will handle form storage)
  return {
    statusCode: 200,
    body: JSON.stringify({ success: true })
  };
};
