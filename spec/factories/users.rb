FactoryGirl.define do
  factory :user do |f|
    f.email "random@email.com"
    f.password 'open sesame'
    f.customer_id Time.now.to_i
  end
end