require 'test_helper'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database =>":memory:")

def setup_db
  ActiveRecord::Schema.define(:version => 1) do
    create_table :stub_models
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

setup_db

class StubModel < ActiveRecord::Base
  
  
end

class ActiveRecordToExtJsonTest < Test::Unit::TestCase
  def test_to_ext_json_should_be_defined
    assert StubModel.new.respond_to?(:to_ext_json)
  end
  
  def test_generate_ext_json_with_valid_model
    assert_equal({'success' => true, 'data' => {'stub_model[id]'=>nil}},ActiveSupport::JSON::decode(StubModel.new.to_ext_json))
  end

  def test_generate_ext_json_with_invalid_model
    stub_model = StubModel.new
    def stub_model.valid?
      false
    end
    assert_equal({'success' => false, 'errors' => {}},ActiveSupport::JSON::decode(stub_model.to_ext_json))
  end

  def test_generate_ext_json_with_additional_methods
   
    stub_model = StubModel.new
     def stub_model.my_method
        "my_value"
      end
    assert_equal({'success' => true, 'data' => {'stub_model[id]'=>nil,'stub_model[my_method]' => 'my_value'}},
                 ActiveSupport::JSON::decode(stub_model.to_ext_json(:methods => :my_method)))
  end
end
