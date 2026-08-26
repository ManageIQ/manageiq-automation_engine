require 'prism'

module MiqAeEngine
  # Validates and evaluates an assertion string (after substitution).
  #
  # Assertions must be simple Ruby expressions consisting only of literals,
  # comparison/logical operators, and Array#include? calls with a literal
  # receiver and literal argument.
  #
  # Any construct that could execute arbitrary code — bare method calls with
  # no receiver (e.g. system(), exit!), constant-qualified calls (e.g.
  # File.read), backtick strings, assignments, string interpolation, etc. —
  # is rejected before evaluation.
  module MiqAeAssertion
    # Isolated binding with no local variables and a plain Object as self,
    # so that eval cannot access MiqAeObject internals.
    ISOLATED_BINDING = Object.new.instance_eval { binding }.freeze

    # Literal leaf node types: the only values that may appear as operands.
    LITERAL_NODE_TYPES = [
      Prism::TrueNode,
      Prism::FalseNode,
      Prism::NilNode,
      Prism::IntegerNode,
      Prism::FloatNode,
      Prism::StringNode,
      Prism::SymbolNode,
    ].freeze

    # Operators that are desugared to CallNode by Prism but are safe binary/unary ops.
    ALLOWED_OPERATORS = %i[
      == != < > <= >= <=> ===
      + - * / %
      !
    ].to_set.freeze

    # Named predicate methods that are safe when the receiver is a literal
    # Array or String and the arguments are also literals.
    ALLOWED_PREDICATE_METHODS = %i[include?].to_set.freeze

    # Structural/logical node types that contain sub-expressions.
    LOGICAL_NODE_TYPES = [
      Prism::AndNode,
      Prism::OrNode,
      Prism::ParenthesesNode,
    ].freeze

    # Array literals built with %w() or [] whose elements are all literals.
    ARRAY_NODE_TYPE = Prism::ArrayNode

    class << self
      # Validates that +assertion+ is a safe expression, then evaluates it.
      # Raises +MiqAeException::AssertionFailure+ if the expression is invalid
      # or if evaluation raises.
      def evaluate(assertion)
        parse_result = Prism.parse(assertion)
        unless parse_result.success?
          raise MiqAeException::AssertionFailure, "Syntax Error in Assertion: <#{assertion}>"
        end

        stmts = parse_result.value.statements&.body
        unless stmts&.size == 1 && safe_node?(stmts.first)
          raise MiqAeException::AssertionFailure, "Assertion contains disallowed constructs: <#{assertion}>"
        end

        begin
          ISOLATED_BINDING.eval(assertion)
        rescue Exception => err # rubocop:disable Lint/RescueException
          raise MiqAeException::AssertionFailure, "Assertion Evaluation Failed: <#{assertion}> - #{err.message}"
        end
      end

      private

      def safe_node?(node)
        return false if node.nil?

        return true if LITERAL_NODE_TYPES.any? { |t| node.kind_of?(t) }

        # Reject interpolated strings even though plain StringNode is allowed.
        return false if node.kind_of?(Prism::InterpolatedStringNode)

        # Logical combinators — recursively validate both branches.
        if LOGICAL_NODE_TYPES.any? { |t| node.kind_of?(t) }
          return safe_logical_node?(node)
        end

        # Array literals: %w() or [] where every element is a literal.
        if node.kind_of?(ARRAY_NODE_TYPE)
          return node.elements.all? { |el| LITERAL_NODE_TYPES.any? { |t| el.kind_of?(t) } }
        end

        # CallNode covers both operators and named method calls.
        return safe_call_node?(node) if node.kind_of?(Prism::CallNode)

        false
      end

      def safe_logical_node?(node)
        case node
        when Prism::AndNode, Prism::OrNode
          safe_node?(node.left) && safe_node?(node.right)
        when Prism::ParenthesesNode
          body = node.body
          stmts = body.kind_of?(Prism::StatementsNode) ? body.body : [body]
          stmts.size == 1 && safe_node?(stmts.first)
        else
          false
        end
      end

      def safe_call_node?(node)
        name = node.name

        if ALLOWED_OPERATORS.include?(name)
          # Operator call: receiver must be a safe node, no explicit dot,
          # and at most one argument (unary ops have zero).
          return false unless node.call_operator_loc.nil?
          return false unless safe_node?(node.receiver)

          args = node.arguments&.arguments || []
          return false if args.size > 1

          args.all? { |a| safe_node?(a) }
        elsif ALLOWED_PREDICATE_METHODS.include?(name)
          # Predicate call: must have an explicit dot, a literal array or
          # string receiver, and exactly one literal argument.
          return false if node.call_operator_loc.nil?

          receiver = node.receiver
          return false unless receiver.kind_of?(ARRAY_NODE_TYPE) || receiver.kind_of?(Prism::StringNode)
          return false unless safe_node?(receiver)

          args = node.arguments&.arguments || []
          args.size == 1 && LITERAL_NODE_TYPES.any? { |t| args.first.kind_of?(t) }
        else
          false
        end
      end
    end
  end
end
