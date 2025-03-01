function Meta(meta)
  if meta["post-type"] == "article" then
    quarto.doc.include_text("after-body", "_includes/comments.html")
  end
  return meta
end
