class SearchReport < Prawn::Document
  def initialize(params)
    super()
    @data = params[:data]
    # @column_names = params[:column_names]
    @column_names = ['name', 'phone', 'email', 'website']
  end

  def to_pdf
    text "Basis PDF search results (terse format)"
    #text @column_names

    rows = [@column_names]
    for d in @data
      rows = rows << @column_names.map{|x| d[x].to_s}
    end
    #rows = rows + [@data]
    #rows = [%w[head 1 2 3 4]]
    #data = data + [%w[Some data in a table]]*50
    table(rows, :header => true, :row_colors => %w[cccccc ffffff]) do
      row(0).style :background_color => '000000', :text_color => 'ffffff'
      cells.style :borders => []
    end

    if false

    font_size = 9

    widths = [50, 170]

    headers = ["Name","Address"]

      head = make_table([headers], :column_widths => widths)

    data = []

    def row(date, pt, charges, portion_due, balance, widths)
      rows = charges.map { |c| ["", "", c[0], c[1], "", ""] }

      # Date and Patient Name go on the first line.
      rows[0][0] = date
      rows[0][1] = pt

      # Due and Balance go on the last line.
      rows[-1][4] = portion_due
      rows[-1][5] = balance

      # Return a Prawn::Table object to be used as a subtable.
      make_table(rows) do |t|
        t.column_widths = widths
        t.cells.style :borders => [:left, :right], :padding => 2
        t.columns(4..5).align = :right
      end

    end

    data << row("1/1/2010", "", [["Balance Forward", ""]], "0.00", "0.00",
                widths)
    50.times do
      data << row("1/1/2010", "John", [["Foo", "Bar"], 
                                       ["Foo", "Bar"]], "5.00", "0.00",
                  widths)
    end

    # Wrap head and each data element in an Array -- the outer table has only one
    # column.
    table([[head], *(data.map{|d| [d]})], :header => true,
          :row_colors => %w[cccccc ffffff]) do
      
      row(0).style :background_color => '000000', :text_color => 'ffffff'
      cells.style :borders => []
    end

    end

    render
  end
end
