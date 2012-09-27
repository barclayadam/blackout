/*global module:false*/
module.exports = function(grunt) {

  grunt.loadNpmTasks('grunt-rigger');
  grunt.loadNpmTasks('grunt-coffee');
  grunt.loadNpmTasks('grunt-coffeepot');
  grunt.loadNpmTasks('grunt-reload');

  // Project configuration.
  grunt.initConfig({
    pkg: '<json:package.json>',

    meta: {
      version: '2.0',
      banner: '###\n' +
        ' <%= pkg.name %> - v<%= pkg.version %>\n' +
        ' Copyright (c) <%= grunt.template.today("yyyy") %> Adam Barclay.\n' + 
        ' Distributed under MIT license\n' + 
        ' http://github.com/barclayadam/blackout\n' +
        '###\n'
    },

    lint: {
      files: ['src/backbone.marionette.*.js']
    },

    rig: {
      build: {
        src: ['<banner:meta.banner>', 'src/bo.coffee'],
        dest: 'lib/bo.coffee'
      }
    },

    coffee: {
      build: {
        src: ['lib/bo.coffee'],
        dest: 'lib',

        options: {
            bare: true
        }
      }
    },

    min: {
      build: {
        src: ['lib/bo.js'],
        dest: 'lib/bo.min.js'
      }
    },

    uglify: {},

    watch: {
      files: ['src/*', 'spec/*'],
      tasks: 'build reload'
    },

    reload: {
        port: 8000,
        proxy: {
            host: 'localhost',
            port: 8001
        }
    },

    coffeepot: {
      port: 8001,
      base: "./"
    }
  });

  // Default task.
  grunt.registerTask('build', 'rig coffee');
  grunt.registerTask('default', 'build min');
  grunt.registerTask('serve', 'build coffeepot reload watch');
};