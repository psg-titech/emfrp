require 'emfrp/compile/c/monofy'
require 'emfrp/compile/c/alloc'
require 'emfrp/compile/c/codegen_context'
require 'emfrp/compile/c/syntax_codegen'

module Emfrp
  module Codegen
    extend self

    def codegen(top, c_output, h_output, main_output, name)
      Monofy.monofy(top)
      check_skip(top)
      ct = CodegenContext.new(top)
      ar = AllocRequirement.new(top)
      top.codegen(ct, ar)
      ct.code_generate(c_output, h_output, main_output, name)
    end

    # `skip' is compiled into an early return from the node function,
    # so it cannot be used outside of node definitions.
    def check_skip(top)
      exps = top[:dict][:ifunc_space].values.map{|x| x.get[:exp]}
      exps += top[:dict][:sorted_datas].map{|x| x.get[:exp]}
      exps += (top[:inputs] + top[:dict][:sorted_nodes].map(&:get)).map{|x| x[:init_exp]}.compact
      exps.each do |exp|
        exp.traverse_all_syntax do |s|
          if s.is_a?(SkipExp)
            msg = "`skip' in functions, datas or init-exps is not supported by the C backend:\n"
            raise CompileError.new(msg, :unsupported_skip, s)
          end
        end
      end
    end
  end
end
