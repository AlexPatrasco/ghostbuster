require 'rails_helper'

feature 'Fetching cutomer data on sign in' do
  let(:user) {FactoryGirl.create(:user)}
  
  scenario 'user signs in using valid credentials' do
    expect_any_instance_of(SpectreClient).to receive(:fetch_everything).with(user.customer_id)

    visit '/users/sign_in'
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password
    click_button 'Log in'

    expect(page).to have_text('Signed in successfully.')
    expect(page).to have_text("You are signed in as #{user.email}")
  end
end