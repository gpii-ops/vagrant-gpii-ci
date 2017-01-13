require 'spec_helper'
require 'vagrant-gpii-ci/action'

describe VagrantPlugins::GPIICi do
  it 'has a version number' do
    expect(VagrantPlugins::GPIICi::VERSION).not_to be nil
  end
end

describe VagrantPlugins::GPIICi::Action::BuildVagrantfile do

end