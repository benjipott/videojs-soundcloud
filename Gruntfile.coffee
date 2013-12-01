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

		qunit:
			files: ["test/**/*.html"]

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
			files: ["<%= jshint.files %>"]
			tasks: ["coffee_jshint", "qunit"]

		coffee:
			compile:
				files:
					"dist/media.soundcloud.js": "src/media.soundcloud.coffee"

		coffee_jshint:
			options:
				globals:[
					"SC"
					"URI"
					"videojs"
					"window"
					"document"
					"module"
				]
			source:
				src: "src/**/*.coffee"
			gruntfile:
				src: "Gruntfile.coffee"


	grunt.loadNpmTasks "grunt-contrib-coffee"
	grunt.loadNpmTasks "grunt-coffee-jshint"
	grunt.loadNpmTasks "grunt-contrib-uglify"
	grunt.loadNpmTasks "grunt-contrib-qunit"
	grunt.loadNpmTasks "grunt-contrib-watch"
	grunt.loadNpmTasks "grunt-contrib-concat"
	grunt.registerTask "test", ["coffee_jshint", "qunit"]
	grunt.registerTask "default", ["coffee_jshint", "coffee" ]