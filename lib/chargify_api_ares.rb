# Chargify API Wrapper using ActiveResource.
#
begin
  require 'active_resource'
rescue LoadError
  begin
    require 'rubygems'
    require 'active_resource'
  rescue LoadError
    abort <<-ERROR
The 'activeresource' library could not be loaded. If you have RubyGems 
installed you can install ActiveResource by doing "gem install activeresource".
ERROR
  end
end


# Version check
module Chargify
  ARES_VERSIONS = ['2.3.4', '2.3.5']
end
require 'active_resource/version'
unless Chargify::ARES_VERSION.includes?(ActiveResource::VERSION::STRING)
  abort <<-ERROR
    ActiveResource version #{Chargify::ARES_VERSION} is required.
  ERROR
end


# A patch for ActiveResource until a version after 2.3.4 fixes it.
module ActiveResource
  # Errors returned from the API layer were not getting put into our object as of Rails 2.3.4
  # See http://github.com/rails/rails/commit/1488c6cc9e6237ce794e3c4a6201627b9fd4ca09
  class Base
    def save
      save_without_validation
      true
    rescue ResourceInvalid => error
      case error.response['Content-Type']
      when /application\/xml/
        errors.from_xml(error.response.body)
      when /application\/json/
        errors.from_json(error.response.body)
      end
      false
    end
  end
end


module Chargify
  
  class << self
    attr_accessor :subdomain, :api_key, :site, :format
    
    def configure
      yield self
      
      Base.user      = api_key
      Base.password  = 'X'
      Base.site      = site.blank? ? "https://#{subdomain}.chargify.com" : site
    end
  end
  
  class Base < ActiveResource::Base
    class << self
      def element_name
        name.split(/::/).last.underscore
      end
    end
    
    def to_xml(options = {})
      options.merge!(:dasherize => false)
      super
    end
  end
  
  class Customer < Base
    def self.find_by_reference(reference)
      find(:all, :params => {:reference => reference})
    end
  end
  
  class Subscription < Base
    # Strip off nested attributes of associations before saving, or type-mismatch errors will occur
    def save
      self.attributes.delete('customer')
      self.attributes.delete('product')
      self.attributes.delete('credit_card')
      super
    end
    
    def cancel
      destroy
    end
  end

  class Product < Base
    def self.find_by_handle(handle)
      find(:first, :conditions => {:handle => handle})
    end
  end
end