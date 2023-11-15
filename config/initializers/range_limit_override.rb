BlacklightRangeLimit::RangeLimitBuilder.module_eval do
  # Method added to to fetch proper things for date ranges.
    def add_range_limit_params(solr_params)
      ranged_facet_configs = blacklight_config.facet_fields.select { |_key, config| config.range }
      return solr_params unless ranged_facet_configs.any?

      solr_params["stats"] = "true"
      solr_params["stats.field"] ||= []

      ranged_facet_configs.each do |field_key, config|
        range_config = config.range_config
        solr_params["stats.field"] << config.field unless range_config[:date] == true

        next if range_config[:segments] == false

        selected_value = search_state.filter(config.key).values.first
        range = (selected_value if selected_value.is_a? Range) || range_config[:assumed_boundaries]

        add_range_segments_to_solr!(solr_params, field_key, range.first, range.last) if range.present?
      end

      solr_params
    end
end