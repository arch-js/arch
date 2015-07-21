require! <[ path rc ]>

# RC automatically overwrites these with env variables.
# For example to edit environment set arch_environment
# To overwrite a nested variable use double underscore i.e. arch_paths__public

module.exports = rc 'arch', do
  app-path: path.resolve '.'
  arch-path: path.dirname require.resolve '../package.json'
  bundle: true
  debug: false
  environment: process.env.NODE_ENV or 'development'
  minify: process.env.NODE_ENV is 'production'
  public: 'dist'
  port: 3000
  watch: process.env.NODE_ENV isnt 'production'