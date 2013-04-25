

module SymbolTable
	class Record
		def initialize(id=nil)
			@id = id unless id.nil?
			@declared = true
		end

		attr_accessor :id, :parent

		def declared?
			@declared
		end

		def descendant_of?(class_name)
			return false if parent.nil?
			parent.is_a?(class_name) || parent.descendant_of(class_name)
		end
	end

	class Scope < Record
		def initialize(id=nil)
			@symbol_table = {}
			super(id)
		end

		attr_reader :symbol_table

		def insert(record)
			puts "Inserted #{record.class.name.split('::').last} #{record.id} into #{self.id}".red
			record.parent = self
			@symbol_table[record.id] = record
		end

		# searches the local symbol table first
		# then delegates to the parent
		def find(id)
			(@symbol_table && @symbol_table[id]) || (parent && parent.find(id))
		end

		# searches the local symbol table only
		# restricts search to class name if given
		def find_local(id, class_name=nil)
			puts "class given #{class_name}" unless class_name.nil?
			result = @symbol_table && @symbol_table[id]
			puts "result: #{result}"
			return result if class_name.nil? || result.nil?
			return nil if !@symbol_table[id].is_a?(class_name)
		end

		# searches up to the given class name
		def find_up_to(id, class_name)
			if self.is_a? class_name
				self.find_local(id)
			else
				parent && parent.find_up_to(id, class_name)
			end
		end

		def clear
			@symbol_table.clear
		end

		def print
			recursive_print(self, '')
		end

		private
			def recursive_print(record, indent)
				message = "#{indent}#{record.class.name.split('::').last}: #{record.id}"
				message += " (#{record.type})" if record.respond_to? :type
				puts message
				if indent.empty?
					indent = '|--'
				else
					indent = '|  ' + indent
				end
				if record.is_a? Scope
					record.symbol_table.each do |k, v|
						recursive_print(v, indent)
					end
				elsif record.is_a? Array
					record.members.each do |k, v|
						recursive_print(v, indent)
					end
				end
			end
	end

	class Class < Scope
	end

	class Program < Scope
		def initialize
			super('_program')
		end
	end

	class Function < Scope
		def self.from_variable(variable)
			function = Function.new
			function.id = variable.id
			function.type = variable.type
			function
		end
		attr_accessor :id, :type, :params
	end

	class Variable < Record
		attr_accessor :id, :type
	end

	class Paramter < Variable
	end

	# class Array < Variable
	# 	def initialize(id, type, members)
	# 		@members = members
	# 		super(id, type)
	# 	end

	# 	attr_reader :members

	# 	def dimensions
	# 		@members.size
	# 	end
	# end
end

# x = SymbolTable::Variable.new('x', :integer)
# y = SymbolTable::Variable.new('y', :integer)
# z = SymbolTable::Variable.new('z', :integer)

# a = SymbolTable::Array.new('a', :integer, {x: x, y: y, z: z})

# foo = SymbolTable::Function.new('foo', :integer, [])


# my_class = SymbolTable::Class.new('my_class')
# test = my_class.insert(foo)
# p "TADA: #{test.class}"
# test.insert(a)

# my_class.print
