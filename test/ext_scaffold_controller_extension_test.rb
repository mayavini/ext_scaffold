require 'test_helper'

class StubController < ActionController::Base
  include ::ExtScaffold

  def pagination
    @pagination_state = update_pagination_state_with_params!
    @options_from_pagination_state = options_from_pagination_state(@pagination_state)
    save_pagination_state(@pagination_state)
    head :ok
  end
  
  def search
    @options_from_search = options_from_search
    head :ok
  end
end

class StubControllerTest < ActionController::TestCase

  def test_pagination_state_should_be_stored_in_session
    get :pagination
    assert_response :success
    assert_equal assigns(:pagination_state).symbolize_keys, session['_pagination_state']
  end

  def test_pagination_options_should_be_converted
    get :pagination, { :sort => 'sortfield', :dir => 'DESC', :start => 123, :limit => 456 }
    assert_response :success
    assert_equal({:order => "sortfield DESC", :offset => 123, :limit => 456}, assigns(:options_from_pagination_state).symbolize_keys)
  end
  
  def test_search_options_should_be_converted
    get :search, { :fields => '["model[field1]","model[field2]"]', :query => 'searchterm' }
    assert_response :success
    assert_equal({:conditions=>["field1 LIKE :query OR field2 LIKE :query", {"query"=>"%searchterm%"}]}, assigns(:options_from_search).symbolize_keys)
  end

end