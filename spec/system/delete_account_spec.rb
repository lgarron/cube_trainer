# frozen_string_literal: true

require 'rails_helper'

describe 'account deletion', type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  it 'enables users to sign up and then delete their account' do
    visit ''
    click_link 'Sign Up'

    fill_in 'Username', with: 'system test user'
    fill_in 'Email', with: 'system_test@example.org'
    fill_in 'Password', with: 'password'
    fill_in 'Confirm Password', with: 'password'
    find(:css, '#cube-trainer-terms-and-conditions-accepted').set(true)
    find(:css, '#cube-trainer-privacy-policy-accepted').set(true)
    find(:css, '#cube-trainer-cookie-policy-accepted').set(true)
    click_button 'Submit'

    expect(page).to have_text('Signup successful!')

    user = User.find_by(name: 'system test user')
    user.admin_confirm!
    user.confirm
    user.password = 'password'

    login(user)

    visit '/modes'
    click_link user.name
    click_button 'Delete Account'
    click_button 'Ok'

    expect(page).to have_text('Account Deleted')
    expect(User.find_by(name: 'system test user')).to be_nil
  end
end
