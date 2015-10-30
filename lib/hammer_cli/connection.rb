module HammerCLI

  class AbstractConnector
    def initialize(params={}, options={})
    end
  end

  class Connection

    def self.drop(name)
      connections.delete(name)
    end

    def self.drop_all()
      connections.keys.each { |c| drop(c) }
    end

    def self.create(name, connector_params={}, options={})
      unless connections[name]
        Logging.logger['Connection'].debug "Registered: #{name}"
        connector = options[:connector] || AbstractConnector

        options.delete(:connector) unless options[:connector].nil?
        connections[name] = connector.new(connector_params, options)
      end
      connections[name]
    end

    def self.exist?(name)
      !get(name).nil?
    end

    def self.get(name)
      connections[name]
    end

    private

    def self.connections
      @connections_hash ||= {}
      @connections_hash
    end

  end
end
