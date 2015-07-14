require! <[ gulp gulp-load-plugins ]>

plugins = gulp-load-plugins!

err = (e) ->
  console.log "%s: %s", e.name, e.message
  this.emit 'end'

gulp.task 'default', [ 'compile' ]

gulp.task 'compile', [ 'compile-ls', 'copy-jade' ]

gulp.task 'compile-ls' ->
  gulp.src 'src/**/*.ls'
    .pipe plugins.strip-code do
      start_comment: \test-exports
      end_comment: \end-test-exports
    .pipe plugins.livescript!.on 'error', err
    .pipe gulp.dest 'lib'

gulp.task 'copy-jade' ->
  gulp.src 'src/server/index.jade'
    .pipe gulp.dest 'lib/server'

gulp.task 'watch' ->
  gulp.watch 'src/**/*.ls', [ 'compile-ls' ]
  gulp.watch 'src/**/*.jade', [ 'copy-jade' ]

bump = (up = 'prerelease') ->
  console.log up
  gulp
    .src './package.json'
    .pipe plugins.bump type: up
    .pipe gulp.dest './'

gulp.task 'prerelease', -> bump 'prerelease'
gulp.task 'patch', -> bump 'patch'
gulp.task 'minor', -> bump 'minor'
gulp.task 'major', -> bump 'major'
