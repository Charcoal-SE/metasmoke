module SE
  class API
    include Singleton

    attr_accessor :logger

    def get_response(*args, **opts, &block)
      setup_logger

      resp = Net::HTTP.get_response(*args, **opts, &block)
      unless resp.code.start_with? '2'
        logger.error "#{resp.code} on GET to #{args[0]}"
        logger.error 'Following: args, opts, response body'
        logger.error args.to_s
        logger.error opts.to_s
        logger.error resp.body
        logger.error ''
        logger.error ' ===================================================== '
        logger.error ''
      end
      resp
    end

    private

    def setup_logger
      return if logger.present?

      logger = ::Logger.new(Rails.root.join('log', 'se-api-errors.log').to_s)
      logger.level = :debug

      def msg2str(msg)
        case msg
        when ::String
          msg
        when ::Exception
          "#{msg.message} (#{msg.class})\n" <<
            (msg.backtrace || []).join("\n")
        else
          msg.inspect
        end
      end

      logger.formatter = proc do |severity, time, progname, msg|
        "%s, [%s #%d] %5s -- %s: %s\n" % [severity[0..0], time.strftime('%Y-%m-%d %H:%M:%S'), $$, severity, progname,
                                          msg2str(msg)]
      end
    end
  end
end

StackAPIHelper = SE::API.instance
