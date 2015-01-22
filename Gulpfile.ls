require! {
  gulp
  'gulp-livescript': ls
}

gulp.task 'default' ->
  gulp.src 'src/**/*.ls'
    .pipe ls!
    .pipe gulp.dest 'lib'
  gulp.src 'src/index.jade'
    .pipe gulp.dest 'lib'