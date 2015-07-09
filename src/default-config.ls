require! <[ path ]>

module.exports =
  environment: process.env.NODE_ENV or 'development'
  paths:
    app:
      abs: path.resolve '.'
      rel: path.relative __dirname, path.resolve '.'
    arch:
      abs: path.dirname require.resolve "../package.json"
      rel: path.relative (path.resolve '.'), (path.dirname require.resolve "../package.json")
    public: 'dist'
  port: 3000
