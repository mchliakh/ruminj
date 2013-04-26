=begin
Mikhail Chliakhovski
COMP 442
Assignment 2

A syntacitc analyser written in Ruby.

=end

$LOAD_PATH << '.'
require 'symbol_table'

# Syntacitc analyzer class.
class Parser
	EPSILON = -> {}

	def initialize(scanner, error_report)
		@scanner = scanner
		@error_report = error_report

		@current_record = @global_scope = SymbolTable::Scope.new('_global')

		# define functions corresponding to each production
		{
			prog: {
				[:classr, :programr, :integerr, :realr, :id] => -> { class_decl_list; prog_body	}
			},
			class_decl_list: {
				[:classr] => -> {
					match :classr
					insert SymbolTable::Class.new(match_id :id)
					match :lcbrace; var_or_func_list; match :rcbrace, :semicol
					scope_up
					class_decl_list
				},
				[:programr, :integerr, :realr, :id] => EPSILON
			},
			var_or_func_list: {
				[:integerr, :realr, :id] => -> {
					replace_with SymbolTable::Variable.new
					type
					@current_record.id = (match_id :id)
					var_or_func_; match :semicol
					scope_up
					var_or_func_list
				},
				[:rcbrace] => EPSILON
			},
			var_or_func_: {
				[:lsbracket, :semicol] => -> {
					check_for_duplicate_declaration(@current_record.id, SymbolTable::Variable)
					switch_back_and_point
					array_size_list
				},
				[:lbracket] => -> {
					check_for_duplicate_declaration(@current_record.id, SymbolTable::Function)
					function = SymbolTable::Function.from_variable(@current_record)
					switch_back_and_point(function)
					func_def
				}
			},
			prog_body: {
				[:integerr, :realr, :id, :programr] => -> {
					func_def_list; match :programr
					insert SymbolTable::Program.new
					func_body; match :semicol
					scope_up
					match '$'
				}
			},
			func_def_list: {
				[:integerr, :realr, :id] => -> {
					replace_with SymbolTable::Function.new
					type
					@current_record.id = (match_id :id)
					check_for_duplicate_declaration(@current_record.id, SymbolTable::Function)
					switch_back_and_point
					func_def; match :semicol
					scope_up
					func_def_list
				},
				[:programr] => EPSILON
			},
			func_head: {
				[:lbracket] => -> { match :lbracket; f_params; match :rbracket }
			},
			func_def: {
				[:lbracket] => -> { func_head; func_body }
			},
			func_body: {
				[:lcbrace] => -> { match :lcbrace; var_or_statement_list; match :rcbrace; }
			},
			var_or_statement_list: {
				[:id, :integerr, :realr, :ifr, :whiler, :readr, :writer, :returnr] => -> {
					var_or_statement; match :semicol
					var_or_statement_list
				},
				[:rcbrace] => EPSILON
			},
			var_or_statement: {
				[:id] => -> {
					variable = SymbolTable::Variable.new
					variable.type = match_id :id
					replace_with variable
					var_or_statement_
				},
				[:integerr, :realr] => -> { var_decl_no_id; switch_back },
				[:ifr, :whiler, :readr, :writer, :returnr] => -> { statement }
			},
			var_or_statement_: {
				[:id] => -> {
					confirm_class_declaration					
					var_decl; switch_back
				},
				[:lsbracket, :equal, :period] => -> { discard; var_statement }
			},
			var_decl_no_id: {
				[:integerr] => -> {
					variable = SymbolTable::Variable.new
					match :integerr
					variable.type = :integerr
					replace_with variable
					var_decl
				},
				[:realr] => -> {
					variable = SymbolTable::Variable.new
					match :realr
					variable.type = :realr
					replace_with variable
					var_decl
				}
			},
			var_decl: {
				[:id] => -> {
					@current_record.id = (match_id :id)
					check_for_duplicate_declaration(@current_record.id, SymbolTable::Variable)
					array_size_list
				}
			},
			var_statement: {
				[:equal, :lsbracket, :period] => -> { indice_list; r_id_nest_list; assign_op; expr }
			},
			array_size_list: {
				[:lsbracket] => -> { match :lsbracket, :int, :rsbracket; array_size_list },
				[:comma, :rbracket, :semicol] => EPSILON
			},
			statement: {
				[:ifr] => -> { match :ifr, :lbracket; expr; match :rbracket, :thenr; stat_block; match :elser; stat_block },
				[:whiler] => -> { match :whiler, :lbracket; expr; match :rbracket, :dor; stat_block },
				[:readr] => -> { match :readr, :lbracket; variable; match :rbracket },
				[:writer] => -> { match :writer, :lbracket; expr; match :rbracket },
				[:returnr] => -> { match :returnr, :lbracket; expr; match :rbracket }
			},
			stat_block: {
				[:lcbrace] => -> { match :lcbrace; statement_list; match :rcbrace },
				[:ifr, :whiler, :readr, :writer, :returnr] => -> { statement },
				[:elser, :semicol] => EPSILON
			},
			statement_list: {
				 [:ifr, :whiler, :readr, :writer, :returnr] => -> { statement; match :semicol, statement_list },
				 [:rcbrace] => EPSILON
			},
			expr: {
				[:num, :int, :lbracket, :bnot, :id, :plus, :minus] => -> { arith_expr; expr_ }
			},
			expr_: {
				[:bequal, :nequal, :lthan, :gthan, :ltoequal, :gtoequal] => -> { rel_op; arith_expr },
				[:comma, :rbracket, :semicol] => EPSILON
			},
			arith_expr: {
				[:num, :int, :lbracket, :bnot, :id, :plus, :minus] => -> { term; arith_expr_ }
			},
			arith_expr_: {
				[:plus, :minus, :bor] => -> { add_op; term; arith_expr_ },
				[:rsbracket, :bequal, :nequal, :lthan, :gthan, :ltoequal, :gtoequal, :comma, :rbracket, :semicol] => EPSILON
			},
			term: {
				[:num, :int, :lbracket, :bnot, :id, :plus, :minus] => -> { factor; term_ }
			},
			term_: {
				[:mult, :divide, :band] => -> { mult_op; factor; term_ },
				[:plus, :minus, :bor, :rsbracket, :bequal, :nequal, :lthan, :gthan, :ltoequal, :gtoequal, :comma, :rbracket, :semicol] => EPSILON
			},
			factor: {
				[:id] => -> { variable; factor_ },
				[:minus] => -> { match :minus; minusfactor },
				[:num] => -> { match :num },
				[:int] => -> { match :int },
				[:lbracket] => -> { match :lbracket; expr; match :rbracket },
				[:bnot] => -> { match :bnot; factor },
				[:plus] => -> { match :plus; factor }
			},
			factor_: {
				[:minus] => -> { match :minus, :gthan, :id, :lbracket; a_params; match :rbracket },
				[:mult, :divide, :band, :plus, :minus, :bor, :rsbracket, :bequal, :nequal, :lthan, :gthan, :ltoequal, :gtoequal, :comma, :rbracket, :semicol] => EPSILON
			},
			minusfactor: {
				[:gthan] => -> {
					match :gthan
					confirm_function_declaration(match_id :id)
					match :lbracket; a_params; match :rbracket
				},
				[:minus, :num, :int, :lbracket, :bnot, :plus, :id] => -> { factor }
			},
			variable: {
				[:id] => -> {
					confirm_variable_declaration(match_id :id)
					indice_list; r_id_nest_list 
				}
			},
			r_id_nest_list: {
				[:period] => -> { match :period, :id; indice_list; r_id_nest_list },
				[:equal, :minus, :rbracket, :mult, :divide, :band, :plus, :minus, :bor, :rsbracket, :bequal, :nequal, :lthan, :gthan, :ltoequal, :gtoequal, :comma, :semicol] => EPSILON
			},
			indice_list: {
				[:lsbracket] => -> { match :lsbracket; arith_expr; match :rsbracket; indice_list },
				[:period, :equal, :minus, :rbracket, :mult, :divide, :band, :plus, :minus, :bor, :rsbracket, :bequal, :nequal, :lthan, :gthan, :ltoequal, :gtoequal, :comma, :semicol] => EPSILON
			},
			type: {
				# set the type of the current record
				[:integerr] => -> { match :integerr; @current_record.type = :integerr },
				[:realr] => -> { match :realr; @current_record.type = :realr },
				[:id] => -> {
					@current_record.type = (match_id :id)
					confirm_class_declaration					
				}
			},
			f_params: {
				[:integerr, :realr, :id] => -> { type; match :id; array_size_list; f_params_tail_list },
				[:rbracket] => EPSILON
			},
			f_params_tail_list: {
				[:comma] => -> { match :comma; type; match :id; array_size_list; f_params_tail_list },
				[:rbracket] => EPSILON
			},
			a_params: {
				[:num, :int, :lbracket, :bnot, :id, :plus, :minus] => -> { expr; a_params_tail_list },
				[:rbracket] => EPSILON
			},
			a_params_tail_list: {
				[:comma] => -> { match :comma; expr; a_params_tail_list },
				[:rbracket] => EPSILON
			},
			assign_op: {
				[:equal] => -> { match :equal }
			},
			rel_op: {
				[:bequal] => -> { match :bequal },
				[:nequal] => -> { match :nequal },
				[:lthan] => -> { match :lthan },
				[:gthan] => -> { match :gthan },
				[:ltoequal] => -> { match :ltoequal },
				[:gtoequal] => -> { match :gtoequal }
			},
			add_op: {
				[:plus] => -> { match :plus },
				[:minus] => -> { match :minus },
				[:bor] => -> { match :bor }				
			},
			mult_op: {
				[:mult] => -> { match :mult },
				[:divide] => -> { match :divide },
				[:band] => -> { match :band }	
			}
		}.each do |n, f|
			self.class.send :define_method, n do
				puts "Now in #{n}"
				# puts "The current record is #{@current_record.class.name.split('::').last}"
				expected = []
				f.each do |p, e|
					# puts "Expanding #{n}"
					(e.call; return) if @scanner.matches? p
					expected += p
				end
				@error_report.syntax_error(@scanner.current, expected)
				exit_with_errors
			end
		end
	end

	def parse
		prog
		@current_record.print
	end

	private
		# attempts to match one or more tokens
		def match(*tokens)
			tokens.each do |t|
				if @scanner.matches? [t]
					@scanner.next_token
					puts "Matched #{t}".green
				else
					@error_report.syntax_error(@scanner.current, [t])
					exit_with_errors
				end
			end
		end

		# attempts to match an identifier
		# returns the name is successful
		def match_id(token)
			if @scanner.matches? [token]
				current = @scanner.current
				@scanner.next_token
				puts "Matched #{token}".green
				current.value
			else
				@error_report.syntax_error(@scanner.current, [token])
				exit_with_errors
			end
		end

		def scope_up
			@current_record = @current_record.parent
		end

		def insert(record)
			@current_record = @current_record.insert(record)
		end

		def replace_with(record)
			@temp = @current_record
			@current_record = record
		end

		def switch_back
			@temp.insert(@current_record)
			@current_record = @temp
		end

		def switch_back_and_point(record=nil)
			@current_record = @temp.insert(record || @current_record)
		end

		def discard
			@current_record = @temp
		end

		def confirm_class_declaration
			abort "Class #{@current_record.type} is undefined!" unless @global_scope.find(@current_record.type, SymbolTable::Class)
		end

		def confirm_variable_declaration(id)
			return if @current_record.find_local(id, SymbolTable::Variable)
			return if @current_record.descendant_of?(SymbolTable::Class) && @current_record.find_up_to(id, SymbolTable::Variable, SymbolTable::Class)
			abort "Variable #{id} is undefined!"
		end

		def confirm_function_declaration(id)
			if @current_record.is_a? SymbolTable::Program
				return if @global_scope.find(id, SymbolTable::Function)
			else
				return if @current_record.find_up_to(id, SymbolTable::Function, SymbolTable::Class)
			end
			abort "Function #{id} is undefined!"
		end

		def check_for_duplicate_declaration(id, klass)
			abort "#{klass.name.split('::').last} #{id} is defined twice!" if @temp.find_local(id, klass)
		end

		def exit_with_errors
			abort(@error_report.get_errors(false))
		end
end