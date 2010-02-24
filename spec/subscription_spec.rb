require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Chargify::Subscription do
  
  context 'strips nested association attributes before saving' do
    before do
      @subscription = Factory.build(:subscription_with_extra_attrs)
    end
    
    it 'strips customer' do
      @subscription.attributes['customer'].should_not be_blank
      @subscription.save!
      @subscription.attributes['customer'].should be_blank
    end
    
    it 'strips product' do
      @subscription.attributes['product'].should_not be_blank
      @subscription.save!
      @subscription.attributes['product'].should be_blank
    end
    
    it 'strips credit card' do
      @subscription.attributes['credit_card'].should_not be_blank
      @subscription.save!
      @subscription.attributes['credit_card'].should be_blank
    end
    
    it 'doesn\'t strip other attrs' do
      subscription = Factory.build(:subscription)
      
      lambda { subscription.save! }.should_not change(subscription, :attributes)
    end
  end
  
  describe 'one-time charges' do
    it 'creates a one-time charge' do
      id = Factory.next(:subscription_id)
      subscription = Factory(:subscription, :id => id)
      expected_response = {:charge => {:amount_in_cents => 1000, :memo => "one-time charge", :success => true}}.to_xml
      FakeWeb.register_uri(:post, "#{test_domain}/subscriptions/#{id}/charges.xml?charge%5Bamount%5D=10.00&charge%5Bmemo%5D=one-time+charge", :status => 201, :body => expected_response)
      
      response = subscription.charge(:amount => "10.00", "memo" => "one-time charge")
      
      response.body.should == expected_response
      response.should be_a(Net::HTTPCreated)
    end
  end
  
  it 'cancels the subscription' do
    @subscription = Factory(:subscription, :id => 1)
    find_subscription = lambda { Chargify::Subscription.find(1) }
    
    find_subscription.should_not raise_error
    @subscription.cancel
    find_subscription.should raise_error
  end
  
end