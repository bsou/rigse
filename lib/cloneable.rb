module Cloneable
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def cloneable_associations(*args)
      @cloneable_associations ||= []
      @cloneable_associations += args
      @cloneable_associations
    end
  end

  def clone(options = {})
    begin
      new_assocs = self.class.cloneable_associations
    rescue
      # Can't immagine how this would happen, but it would be hard to debug:
      throw("cloneable class #{self.class.name} fails #cloneable_associations {$!}")
    end
    if new_assocs.size > 0
      options[:include] ||= []
      if options[:include].kind_of? Hash
        options[:include] = Array(options[:include])
      end
      options[:include] += new_assocs
    end
    # invokes on superclas (possilby up to Object#clone)
    super(options)
  end
end
