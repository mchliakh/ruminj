# Custom String methods to allow colorized string output.
class String
	def green; colorize(32); end
	def red; colorize(31); end

	private
		def colorize(color_code)
  		"\e[#{color_code}m#{self}\e[0m"
		end
end

class ErrorReport
	def initialize(source)
		@source = source
		@lines = []
		# save each line
		@source.each_line {|line| @lines << line}

		@errors = []
		@current_error = ''
		@current_position = nil
	end

	def update_error(error)
		@current_error += error
	end

	def update_position(position)
		@current_position = position
	end

	def save
		unless @current_error.empty?
			# save current error
			@errors << [@current_error, @current_position]
			# reset variables
			@current_error = ''
			@current_position = nil
		end
	end

	def syntax_error(actual, expected)
		@syntax_error = [actual.value, actual.position, expected]
	end

	def count
		@errors.count
	end

	def log_errors(file_name)
		File.open("#{file_name}.log", 'a') {|f| f.write "[#{Time.now}]\n#{get_errors}"} unless @errors.empty?
	end

	def get_errors(highlight=false)
		errors = ''
		# append lexical errors
		@errors.each do |error|
			line_number, relative_position = get_line_number_and_relative_position(error[1])
			# highlight if the flag is set
			line = (highlight) ? highlight(String.new(@lines[line_number]), error[0], relative_position) : @lines[line_number]
			errors += "#{line_number + 1}: #{line}"
		end
		# append syntax error
		if @syntax_error
			line_number, relative_position = get_line_number_and_relative_position(@syntax_error[1] + 1)
			# highlight if the flag is set
			line = (highlight) ? highlight(String.new(@lines[line_number]), @syntax_error[0], relative_position) : @lines[line_number]
		end
		errors += "\nSyntax error on line #{line_number + 1}\n\n#{line}\n"
		errors += "#{@syntax_error[2].join ', '} expected."
	end

	def get_line_number_and_relative_position(position)
		total, last_total = 0, 0
		line_number = nil
		# count the number of lines until position is reached
		@lines.each_with_index do |line, index|
			# previous total is saved for calculating relative position
			last_total = total
			total += line.length
			if total >= position
				line_number = index
				break
			end
		end
		[line_number, position - last_total]
	end

	def highlight(line, error, relative_position)
		# replace the substring containing the error
		line[relative_position - error.length, error.length] = error.red
		line
	end
end