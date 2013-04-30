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
	end

	def update_error(error)
		@current_error += error
	end

	def update_position(line, position)
		@current_line = line
		@current_position = position
	end

	def save
		unless @current_error.empty?
			# save current error
			@errors << [@current_error, @current_line, @current_position]
			# reset variables
			@current_error = ''
			@current_line = nil
			@current_position = nil
		end
	end

	def syntax_error(actual, expected)
		@syntax_error = [actual.value, actual.position, expected]
	end

	def log_errors(file_name)
		File.open("#{file_name}.log", 'a') {|f| f.write "[#{Time.now}]\n#{get_errors}"} unless @errors.empty?
	end

	def get_errors
		errors = ''
		# append lexical errors
		@errors.each do |error|
			# highlight if the flag is set
			line = highlight(String.new(@lines[error[1]]), error[0], error[2])
			errors += "#{error[1] + 1}: #{line}"
		end
		# # append syntax error
		# if @syntax_error
		# 	line_number, relative_position = get_line_number_and_relative_position(@syntax_error[1] + 1)
		# 	# highlight if the flag is set
		# 	line = (highlight) ? highlight(String.new(@lines[line_number]), @syntax_error[0], relative_position) : show_position(@lines[line_number], relative_position)
		# end
		# errors += "\nSyntax error on line #{line_number + 1}\n\n#{line}\n"
		# errors += "#{@syntax_error[2].join ', '} expected."
		errors
	end

	def print
		if @errors.count > 0
			puts "#{@errors.count} token error#{@errors.count == 1 ? '' : 's'}.\n".red
			puts get_errors
		else
			puts "No errors to report!".green
		end
	end

	private

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

		def highlight(str, target, position)
			# replace the substring containing the error
			str[position - target.length, target.length] = target.red
			str
		end

		def show_position(line, relative_position)
			"#{line.insert(relative_position, ' ')}#{(line.gsub(/\S/, ' ')).insert(relative_position, '^')}"
		end
end