class SearchReport < Prawn::Document
  def initialize(params)
    super(:page_layout => :landscape)
    @search = params[:search]
    @data = params[:data]
    @column_names = ['name', 'address', 'phone', 'email', 'description']
    @column_widths = [120,100,80,120]
    @column_widths << (self.bounds.top_right[0] - self.bounds.top_left[0] - @column_widths.inject(0){|sum,item| sum + item})
  end

  def safe(str)
    return "" if str.nil?
    str
  end

  def fonter(sz,str)
    return "" if str.nil?
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
      if d.respond_to?('firstname')
        row << fonter(sz,safe(d['firstname']) + " " + safe(d['lastname']))
      else
        row << fonter(sz,d['name'])
      end
      location = ""
      if d.respond_to?('locations')
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
      else
        row << ""
      end
      row << fonter(sz,d['phone'])
      row << fonter(sz,d['email'])
      row << fonter(sz,safe(d['description']).gsub('<p>'," ").gsub('<P>'," "))
      rows = rows << row
    end

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
