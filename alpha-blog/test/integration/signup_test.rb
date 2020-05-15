require 'test_helper'

class SingupTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create(username: "test", email: "test@example.com", password: "password", admin: false)
  end

  test "Login with user credetials" do
    sign_in_as(@user,"password")
    get articles_path
    assert_template 'articles/index'
  end

end
