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

		@token_errors = []
		@current_token_error = ''
		@syntax_errors = []
	end

	def update_token_error(error)
		@current_token_error += error
	end

	def update_token_error_position(line, position)
		@current_line = line
		@current_position = position
	end

	def save_token_error
		unless @current_token_error.empty?
			# save current error
			@token_errors << [@current_token_error, @current_line, @current_position]
			# reset variables
			@current_token_error = ''
			@current_line = nil
			@current_position = nil
		end
	end

	def add_syntax_error(actual, expected)
		@syntax_errors << [actual, expected]
	end

	def syntax_error_count
		@syntax_errors.count
	end

	def log_token_errors(file_name)
		File.open("#{file_name}.log", 'a') {|f| f.write "[#{Time.now}]\n#{get_token_errors}"} unless @token_errors.empty?
	end

	def token_errors
		token_errors = ''
		# append lexical errors
		@token_errors.each do |error|
			line = highlight(String.new(@lines[error[1]]), error[0], error[2])
			token_errors += "#{error[1] + 1}: #{line}"
		end
		token_errors
	end

	def syntax_errors
		syntax_errors = ''
		@syntax_errors.each do |error|
			actual, expected = error[0], error[1]
			line = show_position(@lines[actual.line], actual.position)
			syntax_errors += "\nSyntax error on line #{actual.line + 1}\n\n#{line}\n"
			syntax_errors += "#{expected.join ', '} expected."
		end
		syntax_errors
	end

	def print
		if @token_errors.count > 0
			puts "#{@token_errors.count} token error#{s_if(@token_errors.count)}.\n".red
			puts token_errors
		end
		if @syntax_errors.count > 0
			puts "#{@syntax_errors.count} syntax error#{s_if(@syntax_errors.count)}.\n".red
			puts syntax_errors
		end
	end

	private

		def s_if(count)
			count == 1 ? '' : 's'
		end

		def highlight(str, target, position)
			# replace the substring containing the error
			str[position - target.length, target.length] = target.red
			str
		end

		def show_position(str, position)
			puts "position yo: #{position}"
			"#{str.insert(position, ' ')}\n#{(str.gsub(/\S/, ' ')).insert(position, '^')}"
		end
end