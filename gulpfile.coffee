# modules
fs = require('fs')
gulp = require('gulp')
gutil = require('gulp-util')
connect = require('gulp-connect')
coffee = require('gulp-coffee')
rename = require('gulp-rename')
uglify = require('gulp-uglifyjs')
minifycss = require('gulp-minify-css')
sass = require('gulp-sass')
include = require('gulp-file-include')
prettify = require('gulp-prettify')
autoprefixer = require('gulp-autoprefixer')
header = require('gulp-header')
size = require('gulp-size')
source = require('vinyl-source-stream')
run = require('run-sequence')
browserify = require('browserify')
clean = require('del')

# config
pak = JSON.parse(fs.readFileSync './package.json', 'utf8')
port = 1111
sassEntry = './src/sass/styles.sass'
sassBuildDir = './assets'
pluginScript = './src/coffeescript/notifyr.coffee'
pluginBuildDir = './dist'
pluginName = 'notifyr.js'
pluginNameMin = 'notifyr.min.js'
pluginCssName = 'notifyr.css'
pluginCssNameMin = 'notifyr.min.css'
banner = "/*!\n
        #{pak.name} v#{pak.version} (#{pak.homepage})\n
        Copyright (c) #{new Date().getFullYear()} #{pak.author}\n
        Licensed under the #{pak.license} license\n
        */\n"

# small wrapper around gulp util logging
log = (msg) ->
  gutil.log gutil.colors.blue(msg)

# gulp tasks
gulp.task 'server', ->
  connect.server
    root: [
      'example'
      'assets'
      'dist' # for serving compiled plugin
      'node_modules' # for serving jquery & requirejs
    ]
    port: port
    livereload: true
  log("Examples can be viewed at http://localhost:#{port}")

gulp.task 'clean', ->
  gulp
    .src('build', {read: false})
    .pipe(clean())

gulp.task 'clean', ->
  clean [pluginBuildDir]

gulp.task 'html', ->
  gulp
    .src('./example/**/*.html')
    .pipe(connect.reload())

gulp.task 'browserify', ->
  browserify('./example/commonjs/script.js')
    .bundle()
    .pipe(source('compiled.js'))
    .pipe(gulp.dest('./example/commonjs/'))

gulp.task 'compile-js', ->
  gulp
    .src(pluginScript)
    .pipe(coffee(
      bare: true
      sourceMap: false
    ).on('error', gutil.log))
    .pipe(rename(pluginName))
    .pipe(header(banner))
    .pipe(gulp.dest(pluginBuildDir))

gulp.task 'compile-css', ->
  gulp
    .src('./src/sass/notifications.scss')
    .pipe(sass({
      outputStyle: 'expanded' #compact; :expanded;
      includePaths: ['']
      errLogToConsole: false
      onError: (e) -> log e.message
    }))
    .pipe(rename(pluginCssName))
    .pipe(gulp.dest(pluginBuildDir))

gulp.task 'compile-dev-css', ->
  gulp
    .src('./src/sass/styles.scss')
    .pipe(sass({
      outputStyle: 'nested' #compressed
      includePaths: ['./src/sass/']
      errLogToConsole: false
      onError: (e) -> log e.message
    }))
    .pipe(autoprefixer({
      browsers: ['last 3 versions', 'Firefox >= 26', 'Explorer >= 8']
      cascade: false
    }))
    .pipe(gulp.dest(sassBuildDir))

gulp.task 'compile-html', ->
  gulp
    .src('./src/html/*.html')
    .pipe(include(
      prefix: '@@'
      basepath: '@file'))
    .pipe(prettify(
      indent_size: 2
    ))
    .pipe(gulp.dest('./'))

gulp.task 'refresh', (callback) ->
  run(
    'compile-js',
    'compile-dev-css',
    'compile-html',
    'browserify',
    'html',
    callback
  )
  return

gulp.task 'minify-js', ->
  gulp
    .src("#{pluginBuildDir}/#{pluginName}")
    .pipe(uglify())
    .pipe(rename(pluginNameMin))
    .pipe(header(banner))
    .pipe(size({showFiles: true}))
    .pipe(size({showFiles: true, gzip: true}))
    .pipe(gulp.dest(pluginBuildDir))

gulp.task 'minify-css', ->
  gulp
    .src("#{pluginBuildDir}/#{pluginCssName}")
    .pipe(minifycss())
    .pipe(rename(pluginCssNameMin))
    .pipe(size({showFiles: true}))
    .pipe(size({showFiles: true, gzip: true}))
    .pipe(gulp.dest(pluginBuildDir))
    .on 'error', (e) -> log.error e

gulp.task 'watch', ->
  gulp
    .watch [
      pluginScript
      './src/sass/*'
      './src/html/*'
      './example/*/*.html'
      './example/*/script.js'
    ], [
      'refresh'
    ]

gulp.task 'build', (callback) ->
  run(
    'clean',
    'compile-js',
    'compile-css',
    'browserify',
    'minify-js',
    'minify-css',
    callback
  )
  return

gulp.task 'default', [
  'server'
  'watch'
]
