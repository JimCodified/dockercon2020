require 'test_helper'

class CreateNewArticleTest < ActionDispatch::IntegrationTest

  def setup
    @user =  User.create(username: "test", email: "test@example.com", password: "password", admin: false)
  end

  test "Create a new article" do
    sign_in_as(@user, "password")
    get new_article_path
    assert_template 'articles/new'
    assert_difference 'Article.count', 1 do
      post articles_path, params: {article:{title: "test article by test user", description: "test description by test user"}}
      follow_redirect!
    end
  end

end
