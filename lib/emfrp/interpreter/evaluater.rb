module Emfrp
  class Interpreter
    module Evaluater
      extend self

      def eval_exp(top, exp, env={})
        case exp
        when FuncCall
          case f = top[:dict][:func_space][exp[:name][:desc]].get
          when PrimFuncDef
            if ruby_exp = f[:foreigns].find{|x| x[:language][:desc] == "ruby"}
              proc_str = "proc{|#{f[:params].map{|x| x[:name][:desc]}.join(",")}| #{ruby_exp[:desc]}}"
              return eval(proc_str).call(*exp[:args].map{|e| eval_exp(top, e, env)})
            else
              raise "Primitive Function `#{f[:name][:desc]}` is not defined for ruby"
            end
          when FuncDef
            f[:params].map{|param| [param[:name], Link.new(f)]}.zip(exp[:args]).each do |key, arg|
              env[key] = eval_exp(top, arg, env)
            end
            return eval_exp(top, f[:exp], env)
          end
        when ValueConst
          return [exp[:name][:desc].to_sym] + exp[:args].map{|e| eval_exp(top, e, env)}
        when LiteralIntegral
          return exp[:entity][:desc].to_i
        when LiteralChar
          return exp[:entity].ord
        when LiteralFloating
          return exp[:entity][:desc].to_f
        when VarRef
          key = [exp[:name], exp[:binder]]
          unless env[key]
            if exp[:binder].get.is_a?(DataDef)
              env[key] = eval_exp(top, exp[:binder].get[:exp], env)
            else
              raise "Assertion error: #{key} is unbound"
            end
          end
          return env[key]
        when MatchExp
          left_val = eval_exp(top, exp[:exp], env)
          exp[:cases].each do |c|
            if match_result = pattern_match(c, left_val)
              return eval_exp(top, c[:exp], env.merge(match_result))
            end
          end
          raise "pattern match fail"
        when SkipExp
          throw :skip, :skip
        else
          raise "Unexpected expression type #{exp.class} (bug)"
        end
      end

      def eval_node(top, node_def, exps)
        env = {}
        if node_def[:params].size != exps.size
          raise "Assertion error: invalid length of args"
        end
        node_def[:params].map{|param| [param[:as], Link.new(node_def)]}.zip(exps).each do |key, arg|
          env[key] = eval_exp(top, arg, env)
        end
        return catch(:skip) do
          return eval_exp(top, node_def[:exp], env)
        end
      end

      def pattern_match(c, v, pattern=c[:pattern], vars={})
        if pattern[:ref]
          key = [pattern[:ref], Link.new(c)]
          vars[key] = v
        end
        case pattern
        when ValuePattern
          if v.is_a?(Array) && pattern[:name][:desc].to_sym == v[0]
            res = v.drop(1).zip(pattern[:args]).all? do |ch_v, ch_p|
              pattern_match(c, ch_v, ch_p, vars)
            end
            return vars if res
          end
        when IntegralPattern
          if v.is_a?(Integer) && pattern[:val][:entity][:desc].to_i == v
            return vars
          end
        when AnyPattern
          return vars
        end
        return nil
      end

      def value_to_s(val)
        if val.is_a?(Array) && val.first.is_a?(Symbol)
          "#{val.first}" + (val.size > 1 ? "(#{val.drop(1).map{|x| value_to_s(x)}.join(", ")})" : "")
        else
          val.to_s
        end
      end
    end
  end
end
