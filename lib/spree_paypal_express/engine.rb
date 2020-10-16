module SpreePaypalExpress
  class Engine < Rails::Engine
    isolate_namespace Spree
    engine_name 'spree_paypal_express'

    config.autoload_paths += %W(#{config.root}/lib)

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare &method(:activate).to_proc

    initializer "spree.paypal_express.payment_methods", :after => "spree.register.payment_methods" do |app|
      app.config.spree.payment_methods << Spree::Gateway::PayPalExpress
    end

    # Fixes the issue about some PayPal requests failing with
    # OpenSSL::SSL::SSLError (SSL_connect returned=1 errno=0 state=error: certificate verify failed)
    module CAFileHack
      # This overrides paypal-sdk-core default so we don't pass the cert the gem provides to the
      # NET::HTTP instance. This way we rely on the default behavior of validating the server's cert
      # against the CA certs of the OS (we assume), which tend to be up to date.
      #
      # See https://github.com/openfoodfoundation/openfoodnetwork/issues/5855 for details.
      def default_ca_file
        nil
      end
    end

    require 'paypal-sdk-merchant'
    ::PayPal::SDK::Core::Util::HTTPHelper.prepend(CAFileHack)
  end
end
