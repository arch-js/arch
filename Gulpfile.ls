require! <[ gulp gulp-load-plugins ]>

plugins = gulp-load-plugins!

gulp.task 'default', [ 'compile' ]

gulp.task 'compile' ->
  gulp.src 'src/**/*.ls'
    .pipe plugins.strip-code do
      start_comment: \test-exports
      end_comment: \end-test-exports
    .pipe plugins.livescript!
    .pipe gulp.dest 'lib'
  gulp.src 'src/index.jade'
    .pipe gulp.dest 'lib'

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
