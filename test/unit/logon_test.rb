require 'test_helper'

class LogonTest < ActiveSupport::TestCase
  context "Given an existing logon record" do
    setup do
      @logon = FactoryGirl.create(:logon)
    end
    subject { @logon }

    should validate_presence_of :ip_address
    should belong_to :user
  end
end
