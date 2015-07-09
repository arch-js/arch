require! path

# I don't really see a use case where the user ever needs to modify these, so I've left them out of the config
paths =
  app:
    abs: path.resolve '.'
    rel: path.relative __dirname, path.resolve '.'
  arch:
    abs: path.dirname require.resolve "../package.json"
    rel: path.relative (path.resolve '.'), (path.dirname require.resolve "../package.json")

module.exports = paths