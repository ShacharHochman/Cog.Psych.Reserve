exports.handler = async (event) => {
  const { post } = event.queryStringParameters;

  // Your existing code to fetch comments, then filter:
  const comments = submissions.filter(s =>
    s.data['post-url'] === post
  );

  return {
    statusCode: 200,
    body: JSON.stringify(comments)
  };
};
