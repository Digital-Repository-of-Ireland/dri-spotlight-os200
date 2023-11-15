class DateFacetFieldPresenter < BlacklightRangeLimit::FacetFieldPresenter
  def min
    range_config[:min] || range_results_endpoint(:min)
  end

  def max
    range_config[:max] || range_results_endpoint(:max)
  end
end
