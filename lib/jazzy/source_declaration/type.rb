# frozen_string_literal: true

require 'logger'
require 'active_support'
require 'active_support/inflector'

module Jazzy
  class SourceDeclaration
    # rubocop:disable Metrics/ClassLength
    class Type
      def self.all
        TYPES.keys.map { |k| new(k) }.reject { |t| t.name.nil? }
      end

      attr_reader :kind

      def initialize(kind, declaration = nil)
        kind = fixup_kind(kind, declaration) if declaration
        @kind = kind
        @type = TYPES[kind]
      end

      # Improve kind from full declaration
      def fixup_kind(kind, declaration)
        if kind == 'source.lang.swift.decl.class' &&
           declaration.include?(
             '<syntaxtype.keyword>actor</syntaxtype.keyword>',
           )
          'source.lang.swift.decl.actor'
        else
          kind
        end
      end

      def dash_type
        @type && @type[:dash]
      end

      def name
        @type && @type[:jazzy]
      end

      # kinds that are 'global' and should get their own pages
      # with --separate-global-declarations
      def global?
        @type && @type[:global]
      end

      # name to use for type subdirectory in URLs for back-compatibility
      def url_name
        @type && (@type[:url] || @type[:jazzy])
      end

      def name_controlled_manually?
        !kind.start_with?('source')
        # "'source'.lang..." for Swift
        # or "'source'kitten.source..." for Objective-C
        # but not "Overview" for navigation groups.
      end

      def plural_name
        name.pluralize
      end

      def plural_url_name
        url_name.pluralize
      end

      def objc_mark?
        kind == 'sourcekitten.source.lang.objc.mark'
      end

      # covers MARK: TODO: FIXME: comments
      def swift_mark?
        kind == 'source.lang.swift.syntaxtype.comment.mark'
      end

      def mark?
        objc_mark? || swift_mark?
      end

      # mark that should start a new task section
      def task_mark?(name)
        objc_mark? || (swift_mark? && name.start_with?('MARK: '))
      end

      def objc_enum?
        kind == 'sourcekitten.source.lang.objc.decl.enum'
      end

      def objc_typedef?
        kind == 'sourcekitten.source.lang.objc.decl.typedef'
      end

      def objc_category?
        kind == 'sourcekitten.source.lang.objc.decl.category'
      end

      def objc_class?
        kind == 'sourcekitten.source.lang.objc.decl.class'
      end

      def swift_type?
        kind.include? 'swift'
      end

      def swift_enum_case?
        kind == 'source.lang.swift.decl.enumcase'
      end

      def swift_enum_element?
        kind == 'source.lang.swift.decl.enumelement'
      end

      def should_document?
        declaration? && !param? && !generic_type_param?
      end

      def declaration?
        kind.start_with?('source.lang.swift.decl',
                         'sourcekitten.source.lang.objc.decl')
      end

      def extension?
        swift_extension? || objc_category?
      end

      def swift_extension?
        kind =~ /^source\.lang\.swift\.decl\.extension.*/
      end

      def swift_extensible?
        kind =~
          /^source\.lang\.swift\.decl\.(class|struct|protocol|enum|actor)$/
      end

      def swift_protocol?
        kind == 'source.lang.swift.decl.protocol'
      end

      def swift_typealias?
        kind == 'source.lang.swift.decl.typealias'
      end

      def swift_global_function?
        kind == 'source.lang.swift.decl.function.free'
      end

      def param?
        # SourceKit strangely categorizes initializer parameters as local
        # variables, so both kinds represent a parameter in jazzy.
        kind == 'source.lang.swift.decl.var.parameter' ||
          kind == 'source.lang.swift.decl.var.local'
      end

      def generic_type_param?
        kind == 'source.lang.swift.decl.generic_type_param'
      end

      def swift_variable?
        kind.start_with?('source.lang.swift.decl.var')
      end

      def objc_unexposed?
        kind == 'sourcekitten.source.lang.objc.decl.unexposed'
      end

      OVERVIEW_KIND = 'Overview'

      def self.overview
        Type.new(OVERVIEW_KIND)
      end

      def overview?
        kind == OVERVIEW_KIND
      end

      MARKDOWN_KIND = 'document.markdown'

      def self.markdown
        Type.new(MARKDOWN_KIND)
      end

      def markdown?
        kind == MARKDOWN_KIND
      end

      def hash
        kind.hash
      end

      alias equals ==
      def ==(other)
        other && kind == other.kind
      end

      TYPES = {
        # Markdown
        MARKDOWN_KIND => {
          jazzy: 'Guide',
          dash: 'Guide',
        }.freeze,

        # Group/Overview
        OVERVIEW_KIND => {
          jazzy: nil,
          dash: 'Section',
        }.freeze,

        # Objective-C
        'sourcekitten.source.lang.objc.decl.unexposed' => {
          jazzy: 'Unexposed',
          dash: 'Unexposed',
        }.freeze,
        'sourcekitten.source.lang.objc.decl.category' => {
          jazzy: 'Category',
          dash: 'Extension',
          global: true,
        }.freeze,
        'sourcekitten.source.lang.objc.decl.class' => {
          jazzy: 'Class',
          dash: 'Class',
          global: true,
        }.freeze,
        'sourcekitten.source.lang.objc.decl.constant' => {
          jazzy: 'Constant',
          dash: 'Constant',
          global: true,
        }.freeze,
        'sourcekitten.source.lang.objc.decl.enum' => {
          jazzy: 'Enumeration',
          url: 'Enum',
          dash: 'Enum',
          global: true,
        }.freeze,
        'sourcekitten.source.lang.objc.decl.enumcase' => {
          jazzy: 'Enumeration Case',
          dash: 'Case',
        }.freeze,
        'sourcekitten.source.lang.objc.decl.initializer' => {
          jazzy: 'Initializer',
          dash: 'Initializer',
        }.freeze,
        'sourcekitten.source.lang.objc.decl.method.class' => {
          jazzy: 'Class Method',
          dash: 'Method',
        }.freeze,
        'sourcekitten.source.lang.objc.decl.method.instance' => {
          jazzy: 'Instance Method',
          dash: 'Method',
        }.freeze,
        'sourcekitten.source.lang.objc.decl.property' => {
          jazzy: 'Property',
          dash: 'Property',
        }.freeze,
        'sourcekitten.source.lang.objc.decl.protocol' => {
          jazzy: 'Protocol',
          dash: 'Protocol',
          global: true,
        }.freeze,
        'sourcekitten.source.lang.objc.decl.typedef' => {
          jazzy: 'Type Definition',
          dash: 'Type',
          global: true,
        }.freeze,
        'sourcekitten.source.lang.objc.mark' => {
          jazzy: 'Mark',
          dash: 'Mark',
        }.freeze,
        'sourcekitten.source.lang.objc.decl.function' => {
          jazzy: 'Function',
          dash: 'Function',
          global: true,
        }.freeze,
        'sourcekitten.source.lang.objc.decl.struct' => {
          jazzy: 'Structure',
          url: 'Struct',
          dash: 'Struct',
          global: true,
        }.freeze,
        'sourcekitten.source.lang.objc.decl.union' => {
          jazzy: 'Union',
          dash: 'Union',
          global: true,
        }.freeze,
        'sourcekitten.source.lang.objc.decl.field' => {
          jazzy: 'Field',
          dash: 'Field',
        }.freeze,
        'sourcekitten.source.lang.objc.decl.ivar' => {
          jazzy: 'Instance Variable',
          dash: 'Ivar',
        }.freeze,
        'sourcekitten.source.lang.objc.module.import' => {
          jazzy: 'Module',
          dash: 'Module',
        }.freeze,

        # Swift
        'source.lang.swift.decl.actor' => {
          jazzy: 'Actor',
          dash: 'Actor',
          global: true,
        }.freeze,
        'source.lang.swift.decl.function.accessor.address' => {
          jazzy: 'Addressor',
          dash: 'Function',
        }.freeze,
        'source.lang.swift.decl.function.accessor.didset' => {
          jazzy: 'didSet Observer',
          dash: 'Function',
        }.freeze,
        'source.lang.swift.decl.function.accessor.getter' => {
          jazzy: 'Getter',
          dash: 'Function',
        }.freeze,
        'source.lang.swift.decl.function.accessor.mutableaddress' => {
          jazzy: 'Mutable Addressor',
          dash: 'Function',
        }.freeze,
        'source.lang.swift.decl.function.accessor.setter' => {
          jazzy: 'Setter',
          dash: 'Function',
        }.freeze,
        'source.lang.swift.decl.function.accessor.willset' => {
          jazzy: 'willSet Observer',
          dash: 'Function',
        }.freeze,
        'source.lang.swift.decl.function.operator' => {
          jazzy: 'Operator',
          dash: 'Function',
        }.freeze,
        'source.lang.swift.decl.function.operator.infix' => {
          jazzy: 'Infix Operator',
          dash: 'Function',
        }.freeze,
        'source.lang.swift.decl.function.operator.postfix' => {
          jazzy: 'Postfix Operator',
          dash: 'Function',
        }.freeze,
        'source.lang.swift.decl.function.operator.prefix' => {
          jazzy: 'Prefix Operator',
          dash: 'Function',
        }.freeze,
        'source.lang.swift.decl.function.method.class' => {
          jazzy: 'Class Method',
          dash: 'Method',
        }.freeze,
        'source.lang.swift.decl.var.class' => {
          jazzy: 'Class Variable',
          dash: 'Variable',
        }.freeze,
        'source.lang.swift.decl.class' => {
          jazzy: 'Class',
          dash: 'Class',
          global: true,
        }.freeze,
        'source.lang.swift.decl.function.constructor' => {
          jazzy: 'Initializer',
          dash: 'Constructor',
        }.freeze,
        'source.lang.swift.decl.function.destructor' => {
          jazzy: 'Deinitializer',
          dash: 'Method',
        }.freeze,
        'source.lang.swift.decl.var.global' => {
          jazzy: 'Global Variable',
          dash: 'Global',
          global: true,
        }.freeze,
        'source.lang.swift.decl.enumcase' => {
          jazzy: 'Enumeration Case',
          dash: 'Case',
        }.freeze,
        'source.lang.swift.decl.enumelement' => {
          jazzy: 'Enumeration Element',
          dash: 'Element',
        }.freeze,
        'source.lang.swift.decl.enum' => {
          jazzy: 'Enumeration',
          url: 'Enum',
          dash: 'Enum',
          global: true,
        }.freeze,
        'source.lang.swift.decl.extension' => {
          jazzy: 'Extension',
          dash: 'Extension',
          global: true,
        }.freeze,
        'source.lang.swift.decl.extension.class' => {
          jazzy: 'Class Extension',
          dash: 'Extension',
          global: true,
        }.freeze,
        'source.lang.swift.decl.extension.enum' => {
          jazzy: 'Enumeration Extension',
          dash: 'Extension',
          global: true,
        }.freeze,
        'source.lang.swift.decl.extension.protocol' => {
          jazzy: 'Protocol Extension',
          dash: 'Extension',
          global: true,
        }.freeze,
        'source.lang.swift.decl.extension.struct' => {
          jazzy: 'Structure Extension',
          dash: 'Extension',
          global: true,
        }.freeze,
        'source.lang.swift.decl.function.free' => {
          jazzy: 'Function',
          dash: 'Function',
          global: true,
        }.freeze,
        'source.lang.swift.decl.function.method.instance' => {
          jazzy: 'Instance Method',
          dash: 'Method',
        }.freeze,
        'source.lang.swift.decl.var.instance' => {
          jazzy: 'Instance Variable',
          dash: 'Property',
        }.freeze,
        'source.lang.swift.decl.var.local' => {
          jazzy: 'Local Variable',
          dash: 'Variable',
        }.freeze,
        'source.lang.swift.decl.var.parameter' => {
          jazzy: 'Parameter',
          dash: 'Parameter',
        }.freeze,
        'source.lang.swift.decl.protocol' => {
          jazzy: 'Protocol',
          dash: 'Protocol',
          global: true,
        }.freeze,
        'source.lang.swift.decl.function.method.static' => {
          jazzy: 'Static Method',
          dash: 'Method',
        }.freeze,
        'source.lang.swift.decl.var.static' => {
          jazzy: 'Static Variable',
          dash: 'Variable',
        }.freeze,
        'source.lang.swift.decl.struct' => {
          jazzy: 'Structure',
          url: 'Struct',
          dash: 'Struct',
          global: true,
        }.freeze,
        'source.lang.swift.decl.function.subscript' => {
          jazzy: 'Subscript',
          dash: 'Method',
        }.freeze,
        'source.lang.swift.decl.typealias' => {
          jazzy: 'Type Alias',
          url: 'Typealias',
          dash: 'Alias',
          global: true,
        }.freeze,
        'source.lang.swift.decl.generic_type_param' => {
          jazzy: 'Generic Type Parameter',
          dash: 'Parameter',
        }.freeze,
        'source.lang.swift.decl.associatedtype' => {
          jazzy: 'Associated Type',
          dash: 'Alias',
        }.freeze,
        'source.lang.swift.decl.macro' => {
          jazzy: 'Macro',
          dash: 'Macro',
        }.freeze,
      }.freeze
    end
    # rubocop:enable Metrics/ClassLength
  end
end
