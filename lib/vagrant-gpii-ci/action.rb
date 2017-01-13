require "pathname"
require "vagrant/action/builder"

module VagrantPlugins
  module GPIICi
    module Action
      # Include the built-in modules so we can use them as top-level things.
      include Vagrant::Action::Builtin

      def self.action_init
        Vagrant::Action::Builder.new.tap do |b|
          b.use InitEnvironment
        end
      end

      def self.build_vagrantfile
        Vagrant::Action::Builder.new.tap do |b|
          b.use BuildVagrantfile
        end
      end

      # The autoload farm
      action_root = Pathname.new(File.expand_path("../action", __FILE__))
      autoload :InitEnvironment, action_root.join("init_environment")
      autoload :BuildVagrantfile, action_root.join("build_vagrantfile")

    end
  end
end
