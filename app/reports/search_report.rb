class SearchReport < Prawn::Document
  def initialize(params)
    super(:page_layout => :landscape)
    @search = params[:search]
    @data = params[:data]
    @column_names = ['name', 'address', 'phone', 'email', 'description']
    @column_widths = [120,100,70,120]
    @column_widths << (self.bounds.top_right[0] - self.bounds.top_left[0] - @column_widths.inject(0){|sum,item| sum + item})
  end

  def fonter(sz,str)
    return "<font size='" + sz.to_s + "'>" + str + "</font>"
  end

  def to_pdf
    text("find.coop search results for " + @search,
         :inline_format => true,
         :align => :center)
    move_down 6
    #text @column_names

    rows = [@column_names]
    for d in @data
      row = []
      sz = 8
      row << fonter(sz,d['name'])
      location = ""
      for l in d.locations
        unless l.physical_address1.blank?
          location = location + l.physical_address1 + "\n"
        end
        unless l.physical_address2.blank?
          location = location + l.physical_address2 + "\n"
        end
        unless l.physical_city.blank?
          location = location + l.physical_city + "\n"
        end
        unless l.physical_country.blank?
          location = location + l.physical_country + "\n"
        end
      end
      row << fonter(sz,location)
      row << fonter(sz,d['phone'])
      row << fonter(sz,d['email'])
      row << fonter(sz,d['description'])      
      # @column_names.map{|x| "<font size='8'>" + d[x].to_s + "</font>"}
      rows = rows << row
    end
    #rows = rows + [@data]
    #rows = [%w[head 1 2 3 4]]
    #data = data + [%w[Some data in a table]]*50
    table(rows, :header => true, :row_colors => %w[cccccc ffffff],
          :cell_style => {:inline_format => true},
          :column_widths => @column_widths) do
      row(0).style :background_color => '000000', :text_color => 'ffffff'
      cells.style :borders => []
    end


    number_pages "Page <page> of <total>", [bounds.right - 50, -20]

    render
  end
end
