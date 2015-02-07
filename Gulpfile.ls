require! {
  gulp
  'gulp-livescript': ls
  'gulp-strip-code': strip
}
gulp.task 'default' ->
  gulp.src 'src/**/*.ls'
    .pipe strip do
      start_comment: \test-exports
      end_comment: \end-test-exports
    .pipe ls!
    .pipe gulp.dest 'lib'
  gulp.src 'src/index.jade'
    .pipe gulp.dest 'lib'