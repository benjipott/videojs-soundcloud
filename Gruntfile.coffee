module.exports = (grunt) ->
	grunt.initConfig
		pkg: grunt.file.readJSON "package.json"
		concat:
			options:
				separator: ";"

			dist:
				src: ["src/**/*.js"]
				dest: "dist/<%= pkg.name %>.js"

		uglify:
			options:
				banner: "/*! <%= pkg.name %> <%= grunt.template.today(\"dd-mm-yyyy\") %> */\n"

			dist:
				files:
					"dist/<%= pkg.name %>.min.js": ["<%= concat.dist.dest %>"]

			test:
				files:
					"dist/<%= pkg.name %>.min.js": ["dist/media.soundcloud.js"]

		jshint:
			files: ["Gruntfile.js", "dist/**/*.js", "test/**/*.js"]
			options:

				# options here to override JSHint defaults
				globals:
					jQuery: true
					console: true
					module: true
					document: true

		watch:
			sources:
				files: ["src/*.coffee", "example/*.jade"]
				tasks: ["coffee_jshint", "compile"]
				options: livereload: true

		coffee:
			compile:
				files:
					"dist/media.soundcloud.js": "src/media.soundcloud.coffee"

		jade:
			compile:
				files:
					"example/index.html": "example/index.jade"

		karma:
			options:
				configFile: "test/karma.conf.coffee"

			watch: {}
			single:
				singleRun: true


		coffee_jshint:
			options:
				globals:[
					"SC"
					"URI"
					"videojs"
					"window"
					"document"
					"module"
					"console"
				]
			source:
				src: "src/**/*.coffee"
			gruntfile:
				src: "Gruntfile.coffee"


	grunt.loadNpmTasks "grunt-contrib-coffee"
	grunt.loadNpmTasks "grunt-coffee-jshint"
	grunt.loadNpmTasks "grunt-contrib-uglify"
	grunt.loadNpmTasks "grunt-contrib-watch"
	grunt.loadNpmTasks "grunt-contrib-concat"
	grunt.loadNpmTasks "grunt-contrib-jade"
	grunt.loadNpmTasks "grunt-karma"
	grunt.registerTask "compile", ["jade", "coffee"]
	grunt.registerTask "test", ["karma:watch"]
	grunt.registerTask "default", ["coffee_jshint", "karma:single", "compile" ]