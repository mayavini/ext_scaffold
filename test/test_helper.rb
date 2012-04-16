require 'rubygems'
require 'test/unit'
require 'active_support'
require 'active_support/dependencies'
require 'active_record'
require 'logger'
require 'action_dispatch/http/mime_type'
require 'action_controller'

ActiveSupport::Dependencies.autoload_paths << File.expand_path(File.dirname(__FILE__) + "/../lib/")
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../lib/"))

RAILS_DEFAULT_LOGGER = ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/test.log")

#ActionController::Routing::Routes.draw do |map|
#Rails.application.routes.draw do | map| 
#  match ':controller/:action/:id'
#  match ':controller/:action/:id.:format'
#end


# initialize the ext_scaffold plugin
require File.dirname(__FILE__) + '/../init'

module TestHelper
  Routes = ActionDispatch::Routing::RouteSet.new
  Routes.draw do
    match ':controller(/:action(/:id))'
    match ':controller(/:action)'
  end

  ActionController::Base.send :include, Routes.url_helpers
end

ActiveSupport::TestCase.class_eval do
  setup do
    @routes = ::TestHelper::Routes
  end
end