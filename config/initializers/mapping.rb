config = Rails.root.join('config', 'mapping.yml')

Mapping = if File.exists?(config)
            config_erb = ERB.new(IO.read(config)).result(binding)
            OpenStruct.new(YAML.safe_load(config_erb, permitted_classes: [], permitted_symbols: [], aliases: true)[Rails.env])
          else
          	nil
          end
