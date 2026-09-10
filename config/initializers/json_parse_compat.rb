# frozen_string_literal: true

# json 3.x accepts only keyword options. ActiveSupport::JSON.decode still
# calls JSON.parse(json, options) with a positional Hash, which on Ruby 3.4
# raises: ArgumentError (wrong number of arguments (given 2, expected 1)).
module JsonParsePositionalOptions
  def parse(source, opts = nil, **kwargs)
    if opts.nil?
      super(source, **kwargs)
    elsif opts.is_a?(Hash)
      super(source, **opts, **kwargs)
    else
      super(source, opts, **kwargs)
    end
  end
end

JSON.singleton_class.prepend(JsonParsePositionalOptions)
