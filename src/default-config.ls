require! <[ path ]>

module.exports =
  environment: process.env.NODE_ENV or 'development'
  port: 3000
  public: 'dist'
