module SearchHelper
  def clean_params
    return params.reject{|x,y| ['Map','commit','page'].member? x}
  end
end
