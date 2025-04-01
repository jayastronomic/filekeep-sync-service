ActiveSupport.on_load(:action_controller) do
    ActionDispatch::Request.parameter_parsers[:json] = lambda do |raw_post|
        JSON.parse(raw_post).deep_transform_keys!(&:underscore)
    end
end
