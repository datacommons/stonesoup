require 'routing_filter'

module RoutingFilter
  class GlobalRouter < Filter

    @@include_default_locale = true
    cattr_writer :include_default_locale

    class << self
      def include_default_locale?
        @@include_default_locale
      end

      def locales
        @@locales ||= [:en, :fr, :es] # I18n.available_locales.map(&:to_sym)
      end

      def locales=(locales)
        @@locales = locales.map(&:to_sym)
      end

      def locales_pattern
        @@locales_pattern ||= %r(^/(#{self.locales.map { |l| Regexp.escape(l.to_s) }.join('|')})(?=/|$))
      end
    end

    def around_recognize(path, env, &block)
      locale = extract_segment!(self.class.locales_pattern, path) # remove the locale from the beginning of the path
      yield.tap do |params|                                       # invoke the given block (calls more filters and finally routing)
        params[:locale] = locale if locale                        # set recognized locale to the resulting params hash
      end
    end

    def around_generate(*args, &block)
      params = args.extract_options!                              # this is because we might get a call like forum_topics_path(forum, topic, :locale => :en)

      locale = params.delete(:locale)                             # extract the passed :locale option
      locale = I18n.locale if locale.nil?                         # default to I18n.locale when locale is nil (could also be false)
      locale = nil unless valid_locale?(locale)                   # reset to no locale when locale is not valid

      args << params

      yield.tap do |result|
        prepend_segment!(result, locale) if prepend_locale?(locale)
      end
    end

    protected

      def valid_locale?(locale)
        locale && self.class.locales.include?(locale.to_sym)
      end

      def default_locale?(locale)
        locale && locale.to_sym == I18n.default_locale.to_sym
      end

      def prepend_locale?(locale)
        locale && (self.class.include_default_locale? || !default_locale?(locale))
      end
  end

    # DB_SEGMENT = %r(^/(en|es|fr)(/)?)
    
    # def around_recognize(path, env, &block)
    #   db = extract_segment!(DB_SEGMENT, path)
    #   yield.tap do |params|
    #     params[:db] = db if db
    #   end
    # end

    # def around_generate(*args, &block)
    #   params = args.extract_options! 
    #   db = params.delete(:db)
    #   yield.tap do |result|
    #     prepend_segment!(result, "#{db}") if db
    #   end
    # end
end
