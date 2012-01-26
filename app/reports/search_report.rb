require 'tmpdir'
require 'fileutils'

# This file is experimental, and contains material that should be in
# a view - sorry for the poor separation. -paulfitz

class SearchReport < Prawn::Document
  def initialize(params)
    super(:page_layout => :landscape)
    @search = params[:search]
    @user = params[:user]
    @data = params[:data]
    @style = params[:style]
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

  def to_pdf_prawn
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

  def urly(s)
    return "" if s.nil?
    return s.gsub(/\\/,"/")
  end

  def latex(s)
    return "" if s.nil?
    #s.gsub!(/\\/,"\\textbackslash{}")
    #s.gsub!(/~/,"\\textasciitilde{}")
    s.gsub!(/<[^>]*>/,"")
    if (s.length>=300) 
      sn = s.match(/.{0,300}/m).to_s
      if (sn.length!=s.length) 
        s = sn+"..."
      end
    end
    s.gsub!("#","\\#")
    s.gsub!("%","\\%")
    s.gsub!("\r"," ")
    s.gsub!("\n"," ")
    # s.gsub!("-","\\hyp{}")
    s.gsub!("&"){'\&'}
    s.gsub!("_","\\_")
    s.gsub!("\$","\\\$")
    return s
  end

  def boxed(s)
    "\\mbox{" + s + "}"
  end



  def to_pdf_latex_style1
    
    #dir = "/tmp/foo"
    dir = Dir.mktmpdir
    need_rm = true
    fout = File.open("#{dir}/report.tex", 'w')

    doc = <<DOC
\\documentclass[7pt]{article}

\\usepackage{longtable}
%%\\usepackage{savetrees}
\\usepackage[margin=0.5in]{geometry}
\\usepackage[utf8]{inputenc}
\\usepackage{array}
\\usepackage{hyphenat}

\\def\\yy{\\\\\\rowcolor{red}}
\\usepackage{colortbl,ifthen}
\\newcounter{line}
\\newcommand\\xx{%
  \\addtocounter{line}{1}%
  \\ifthenelse{\\isodd{\\value{line}}}{\\\\\\rowcolor[gray]{0.95}}{\\\\}}

\\begin{document}


\\begin{center}
\\begin{longtable}{>{\\raggedright}p{1.5in}>{\\raggedright}p{1.5in}>{\\raggedright}p{1.5in}p{2in}}
%\\caption[findcoop]{Caption} \\label{thelabel} \\\\
%
%%\\multicolumn{4}{c}{Data} \\\\[0.5ex]
  \\hline \\\\ [-2ex] \\hline \\\\ [-2ex]
\\textbf{Name} & 
\\textbf{Address} & 
\\textbf{Phone, Email} & 
\\textbf{Description} \\\\[0.5ex] \\hline
\\\\[-1.8ex]
\\endhead
%Now the data...
DOC

    fout.write(doc)
    
    for d in @data
      sz = 8
      if d.respond_to?('firstname')
        fout.write(latex(d['firstname']) + latex(d['lastname']))
      else
        fout.write(latex(d['name']))
      end
      fout.write(" & ")
      location = ""
      if d.respond_to?('locations')
        for l in d.locations
          unless l.physical_address1.blank?
            location = location + latex(l.physical_address1) + "\\newline "
          end
          unless l.physical_address2.blank?
            location = location + latex(l.physical_address2) + "\\newline "
          end
          unless l.physical_city.blank?
            location = location + latex(l.physical_city) + "\\newline "
          end
          unless l.physical_state.blank?
            location = location + latex(l.physical_state) + "\\newline "
          end
          unless l.physical_country.blank?
            location = location + latex(l.physical_country) + "\\newline "
          end
        end
        fout.write(location)
      end
      fout.write(" & ")
      if d['phone']
        fout.write(boxed(latex(d['phone'])))
        fout.write("\\newline ")
      end
      fout.write(latex(d['email']))
      fout.write(" & ")
      fout.write(latex(safe(d['description']).gsub('<p>'," ").gsub('<P>'," ")))
      fout.write(" \\xx\n")
    end

    # a & b & c & d & e \\\\

    doc = <<DOC
\\end{longtable}
\\end{center}

\\end{document}

DOC
    fout.write(doc)
    fout.close()

    system "cd #{dir}; /usr/bin/pdflatex report > /dev/null 2>&1"
    # system "cd #{dir}; /usr/bin/pdflatex report > /dev/null 2>&1"
    data = File.open("#{dir}/report.pdf", 'r') {|f| f.read() }
    if need_rm
      FileUtils.rm_rf dir
    end
    data
  end

  def list_name(d)
    return d['name'] unless d.respond_to?('firstname')
    d['firstname'] + " " + d['lastname']
  end

  def to_pdf_latex_style2
    
    #dir = "/tmp/foo"
    dir = Dir.mktmpdir
    need_rm = true
    fout = File.open("#{dir}/report.tex", 'w')

    title = "\`\`" + latex(@search) + "\'\'"
    author = "Anonymous"
    if @user
      unless @user.person.nil?
        author = latex(@user.person.to_s)
      else
        author = latex(@user.login)
      end
    end

    doc = <<DOC
\\documentclass[7pt]{article}

\\usepackage{multicol}
\\usepackage[margin=0.5in]{geometry}
\\usepackage[utf8]{inputenc}
\\usepackage{hyphenat}
\\usepackage{hyperref}
\\urlstyle{same}
\\hypersetup{
    colorlinks,%
    citecolor=black,%
    filecolor=black,%
    linkcolor=black,%
    urlcolor=black
}

\\raggedbottom
\\widowpenalty=1000
\\clubpenalty=1000

\\title{\\Huge #{title} \\\\ \\Large a \\url{find.coop} search result}
\\author{#{author}}

\\begin{document}

\\maketitle

%%\\addtolength{\\topskip}{0pt plus 10pt}

\\begin{multicols}{3}

DOC

    fout.write(doc)

    for d in @data.sort{ |a,b| list_name(a).downcase <=> list_name(b).downcase }    
      sz = 8
      fout.write("\\subsubsection*{\\protect\\raggedright ")
      if d.respond_to?('firstname')
        fout.write(latex(d['firstname']) + " " + latex(d['lastname']))
      else
        fout.write(latex(d['name']))
      end
      fout.write("}\n")
      location = ""
      if d.respond_to?('locations')
        for l in d.locations
          unless l.physical_address1.blank?
            location = location + latex(l.physical_address1) + "\\\\\n"
          end
          unless l.physical_address2.blank?
            location = location + latex(l.physical_address2) + "\\\\\n"
          end
          unless l.physical_city.blank?
            location = location + latex(l.physical_city) + "\\\\\n"
          end
          unless l.physical_state.blank?
            location = location + latex(l.physical_state) + "\\\\\n"
          end
          unless l.physical_country.blank?
            location = location + latex(l.physical_country) + "\\\\\n"
          end
        end
        fout.write(location)
      end
      need_break = false
      unless d['phone'].blank?
        fout.write(latex(d['phone']))
        need_break = true
      end
      unless d['email'].blank?
        if need_break
          fout.write("\\\\\n")
        end
        m = latex(d['email'])
        fout.write("{\\tt \\href{mailto:" + m + "}{" + m + "}}")
        need_break = true
      end
      unless d['description'].blank?
        if need_break
          fout.write("\\\\\n")
        end
        fout.write(latex(safe(d['description']).gsub('<p>'," ").gsub('<P>'," ")))
        need_break = true
      end
      unless d['website'].blank?
        if need_break
          fout.write("\\\\\n")
        end
        fout.write("{\\tt\\url{" + latex(safe(urly(d['website']).gsub('http://','').gsub(/\/$/,''))) + "}}")
      end
      # fout.write("\\vskip 10pt plus 50pt minus 3pt\n");
      fout.write("\n\n")
    end

    # a & b & c & d & e \\\\

    doc = <<DOC

\\end{multicols}

\\end{document}

DOC
    fout.write(doc)
    fout.close()

    system "cd #{dir}; /usr/bin/pdflatex report > /dev/null 2>&1"
    # system "cd #{dir}; /usr/bin/pdflatex report > /dev/null 2>&1"
    data = File.open("#{dir}/report.pdf", 'r') {|f| f.read() }
    if need_rm
      FileUtils.rm_rf dir
    end
    data
  end



  def to_pdf
    return to_pdf_prawn unless @style
    return to_pdf_prawn if @style == "prawn"
    return to_pdf_latex_style2 if @style == "article"
    to_pdf_latex_style1
  end

end
