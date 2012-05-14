class SearchItem
  def initialize(name,family,params)
    @name = name
    @family = family
    @params = params.delete_if{|x,y| y.nil?}
    @params = params.delete_if{|x,y| y.strip == ""}
    if family == "City" || family == "Postal code"
      if @params[:state]
        @name = @name + ", #{@params[:state]}" if @params[:state].length >= 1
      end
    end
    if family == "City" || family == "State" || family == "Postal code"
      @name = @name + ", #{@params[:country]}" if @params[:country]
    end
    if family == "Postal code"
      # temporary: need to delete country if USA, since a lot of US data snuck in without country
      @params = @params.delete_if{|x,y| x == :city or x == :state or (x==:country and (y.downcase.include? "united states" or y=="USA" or y=="US"))}
    end
  end

  def name
    @name
  end
  
  def family
    @family
  end

  def id
    0
  end

  def to_param
    @params
  end
end
