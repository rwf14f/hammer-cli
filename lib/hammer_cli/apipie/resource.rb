require 'apipie_bindings'
module HammerCLI::Apipie


  class ApipieConnector < HammerCLI::AbstractConnector

    attr_reader :api

    def initialize(params)
      options = {}
      if params[:rc_options]
        options = params[:rc_options]
        params.delete(:rc_options)
      end
      @api = ApipieBindings::API.new(params, options)
      if HammerCLI::Settings.get(:_params, :reload_cache) || HammerCLI::Settings.get(:reload_cache)
        @api.clean_cache
        Logging.logger['Init'].debug 'Apipie cache was cleared'
      end
    end
  end


  module Resource

    def self.included(base)
      base.extend(ClassMethods)
    end

    def resource
      self.class.resource || self.parent_command.class.resource
    end

    def action
      self.class.action
    end

    def resource_config
      self.class.resource_config
    end

    def connection_options
      self.class.connection_options
    end

    module ClassMethods

      def resource_config
        {}
      end

      def connection_options
        {
          :connector => HammerCLI::Apipie::ApipieConnector
        }
      end

      def connection_name(resource_class)
        :apipie
      end

      def class_resource
        return @api_resource if @api_resource
        return superclass.class_resource if superclass.respond_to? :class_resource
      end

      def module_resource
        return nil unless self.name
        enclosing_module = self.name.split("::")[0..-2].inject(Object) { |mod, cls| mod.const_get cls }

        if enclosing_module.respond_to? :resource
          enclosing_module.resource
        end
      end

      def resource(resource=nil, action=nil)
        unless resource.nil?
          api = HammerCLI::Connection.create(
            connection_name(resource),
            resource_config,
            connection_options).api
          if api.has_resource?(resource)
            @api_resource = api.resource(resource)
          else
            logger.warn "Resource '#{resource}' does not exist in the API"
          end
        end
        @api_action = action unless action.nil?

        # if the resource definition is not available in this class
        # try to look it up in it's enclosing module/class
        return class_resource || module_resource
      end

      def action(action=nil)
        @api_action = action unless action.nil?
        return @api_action if @api_action
        return superclass.action if superclass.respond_to? :action
      end

      def resource_defined?
        not (resource.nil? or action.nil?)
      end

    end

  end
end
