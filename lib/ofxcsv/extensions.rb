require 'date'
require 'time'

# Extensions on standard types to provide my desired behavior.
module Extensions
  refine NilClass do
    def to_s
      ''
    end

    def to_title
      ''
    end

    def method_missing *args
      self
    end
  end

  refine Date do
    def to_s
      to_time.utc.to_s
    end
  end

  refine DateTime do
    def to_s
      to_time.utc.to_s
    end
  end

  refine Time do
    old_to_s = instance_method(:to_s)
    def to_s
      old_to_s.bind(utc).()
    end
  end

  refine String do
    def to_title
      ActiveSupport::Inflector.titleize(self)
    end
  end
end
