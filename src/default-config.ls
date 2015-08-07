require! <[ path, fs ]>

# RC automatically overwrites these with env variables.
# For example to edit environment set arch_environment
# To overwrite a nested variable use double underscore i.e. arch_paths__public

conf =
  app-path:     process.env.arch_app_path or path.resolve '.'
  arch-path:    process.env.arch_port or path.dirname require.resolve '../package.json'
  bundle:       process.env.arch_bundle or true
  debug:        process.env.arch_debug or false
  environment:  process.env.arch_environment or process.env.NODE_ENV or 'development'
  minify:       process.env.arch_minify or process.env.NODE_ENV is 'production'
  public:       process.env.arch_public or 'dist'
  port:         process.env.arch_port or 3000
  watch:        process.env.arch_watch or process.env.NODE_ENV isnt 'production'

module.exports = conf