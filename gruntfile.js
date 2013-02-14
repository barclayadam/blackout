module.exports = function(grunt) {  
  var rigger = require('rigger'),
      path = require('path');

  var lrSnippet = require('grunt-contrib-livereload/lib/utils').livereloadSnippet;

  var folderMount = function folderMount(connect, point) {
    return connect.static(path.resolve(point));
  };

  grunt.loadNpmTasks('grunt-contrib-uglify');

  grunt.loadNpmTasks('grunt-contrib-livereload');
  grunt.loadNpmTasks('grunt-regarde');
  grunt.loadNpmTasks('grunt-contrib-connect');

  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    meta: {
      banner: '/*!\n' +
        ' <%= pkg.name %> - v<%= pkg.version %>\n' +
        ' Copyright (c) <%= grunt.template.today("yyyy") %> Adam Barclay.\n' + 
        ' Distributed under MIT license\n' + 
        ' http://github.com/barclayadam/blackout\n' +
        '*/\n'
    },

    uglify: {
      options: {
        banner: '<%= meta.banner %>',

        sourceMap: 'lib/bo.min.sourcemap.js',
      },

      build: {
        files: {
          'lib/bo.min.js': ['lib/bo.js']
        }
      }
    },

    connect: {
      livereload: {
        options: {
          port: 9001,

          middleware: function(connect, options) {
            return [lrSnippet, folderMount(connect, '.')]
          }
        }
      }
    },

    // Configuration to be run (and then tested)
    regarde: {
      fred: {
        files: ['src/**/*.*', 'spec/**/*.*'],
        tasks: ['build', 'livereload']
      }
    }
  });

  grunt.registerTask('rig', 'Compile files using rigger', function() {     
    var inPath = 'src/bo.js',
        outPath = 'lib/bo.js',
        done = this.async();
   
      grunt.file.read(inPath)

      rigger.process(grunt.file.read(inPath), { cwd: path.resolve(path.dirname(inPath)), separator: grunt.util.linefeed }, function(_, output, settings) {  
        grunt.file.write(outPath, output, { encoding: 'utf8' });

        done();
      });
  });

  // Default task.
  grunt.registerTask('build', ['rig', 'uglify']);
  grunt.registerTask('test', ['build', 'jasmine']);
  grunt.registerTask('serve', ['livereload-start', 'connect', 'regarde']);

  grunt.registerTask('default', ['serve']);
};