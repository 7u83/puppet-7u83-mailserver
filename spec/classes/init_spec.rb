require 'spec_helper'
describe 'mailserver' do
  context 'with default values for all parameters' do
    it { should contain_class('mailserver') }
  end
end
