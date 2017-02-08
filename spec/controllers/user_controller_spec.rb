require 'rails_helper'

describe UserController, type: :controller do
  describe '#api' do
    it 'returns an instance of SpectreClient' do
      value = UserController.new.send(:api)

      expect(value).to be_an_instance_of(SpectreClient)
    end
  end
end