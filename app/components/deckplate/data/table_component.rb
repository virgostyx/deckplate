module Deckplate
  module Data
    # Accessible data table. Columns: `t.with_column(:key, header: "Name", sortable: true, align: :end, numeric: true) { |row| ... }`.
    #
    # Sorting contract: the HOST sorts. Pass the current `sort:` / `dir:` (usually from params) and a `sort_url:` lambda
    # (key, dir) -> url. The component renders sortable headers as links and marks the sorted one with aria-sort. A `sort`
    # or `dir` that does not match a sortable column is ignored (it is user input). There is no client-side sorting.
    class TableComponent < BaseComponent
      ALIGNS = %i[start center end].freeze
      Column = Struct.new(:key, :header, :sortable, :align, :numeric, :row_header, :block)

      renders_one :footer
      renders_one :empty

      def self.block_name = "dp-table"

      def initialize(rows:, caption:, sort: nil, dir: nil, sort_url: nil, sticky: false, zebra: false, caption_hidden: false, row_id: nil, **html_options)
        super(**html_options)
        raise ArgumentError, "caption is required (it names the table for assistive technology)" if caption.to_s.strip.empty?

        @rows = rows.to_a
        @caption = caption
        @sort = sort.to_s
        @dir = dir.to_s
        @sort_url = sort_url
        @sticky = sticky
        @zebra = zebra
        @caption_hidden = caption_hidden
        @row_id = row_id
        @columns = []
      end

      def with_column(key, header:, sortable: false, align: nil, numeric: false, row_header: false, &block)
        raise ArgumentError, "column #{key.inspect} needs a header" if header.to_s.strip.empty?
        raise ArgumentError, "invalid align #{align.inspect}; valid: #{ALIGNS.join(', ')}" if align && !ALIGNS.include?(align.to_sym)
        raise ArgumentError, "column #{key.inspect} needs a block that renders its cell" unless block
        raise ArgumentError, "duplicate column key #{key.inspect} (keys must be unique)" if @columns.any? { |c| c.key.to_s == key.to_s }

        @columns << Column.new(key, header, sortable, (align || (numeric ? :end : :start)).to_sym, numeric, row_header, block)
      end

      def before_render
        content # evaluates the block, which declares the columns
        raise ArgumentError, "a table needs at least one column (with_column)" if @columns.empty?
        raise ArgumentError, "sort_url is required when a column is sortable (a lambda (key, dir) -> url)" if @sort_url.nil? && @columns.any?(&:sortable)
      end

      private

      attr_reader :columns

      def sorted_key = (@columns.any? { |c| c.sortable && c.key.to_s == @sort } ? @sort : nil)
      def sorted_dir = (sorted_key ? (%w[asc desc].include?(@dir) ? @dir : "asc") : nil)
      def sorted?(column) = column.key.to_s == sorted_key
      def next_dir(column) = (sorted?(column) && sorted_dir == "asc" ? "desc" : "asc")
      def aria_sort(column) = (sorted?(column) ? { asc: "ascending", desc: "descending" }.fetch(sorted_dir.to_sym) : nil)

      # Like `capture`, but a block may also return a number, a Date, nil...: ERB output wins, else the block's value
      def render_cell(column, row)
        value = nil
        output = capture { value = column.block.call(row) }
        output.presence || value.to_s
      end

      def cell_classes(column, base)
        [ base, "dp-table__cell--#{column.align}", ("dp-table__cell--numeric" if column.numeric) ]
      end

      def wrap_attributes
        html_attributes(classes: [ block_name, ("dp-table--sticky" if @sticky), ("dp-table--zebra" if @zebra) ],
                        role: "region", tabindex: 0, aria: { label: @caption })
      end
    end
  end
end
