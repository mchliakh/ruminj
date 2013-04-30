=begin
Mikhail Chliakhovski
COMP 442
Assignment 1

A lexical analyser written in Ruby.

=end

# Lexical analyzer class. Generates tokens one by one and
# keeps track of errors.
class Scanner
	# Class for containing tokens.
	class Token
		def self.end_of_stream
			self.new('$', nil, nil, nil)
		end
		def initialize(name, value, line, position)
			@name = name
			@value = value
			@line = line
			@position = position
		end
		attr_reader :name, :value, :line, :position
		def to_s
			"#{@name} \"#{@value}\" #{@line+1}:#{@position+1}"
		end
	end
	
	def initialize(source, reg_exps, error_report)
		# clone the source
		@source = String.new source
		@reg_exps = reg_exps
		@error_report = error_report

		@tokenizer = Enumerator.new do |yielder|
			line = 0
			position = 0
			# repeat until source is consumed
			while !@source.empty? do
				success = false
				@reg_exps.each do |key, value|
					if @source[value]
						# save the last error
						@error_report.save
						# yield token
						yielder.yield Token.new(key, @source[value].sub(/\s+\z/, ''), line, position) unless [:comment, :mlcomment, :wsp].include? key
						newlines = @source[value].scan(/\n/).size
						# count newlines in match
						if newlines > 0
							# update line
							line = line + newlines
							# reset position
							position = 0
						else
							# increment position
							position += @source[value].length
						end
						# consume token
						@source.gsub!(value, '')
						success = true
						break
					end
				end
				unless success
					# add the first character to the current error
					@error_report.update_error(@source[0])
					# update position
					@error_report.update_position(position += 1)
					# remove the first character
					@source[0] = ''
				end
			end
		end

		# advance to the first token
		next_token
	end

	attr_reader :current

	def next_token
		begin
			@current = @tokenizer.next
			puts "TOKEN: #{@current}"
		rescue StopIteration
			@current = Token.end_of_stream
		end
	end

	def matches?(tokens)
		tokens.any? {|t| t == @current.name}
	end
end