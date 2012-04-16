require 'rails/generators'

class ExtScaffoldGenerator < Rails::Generators::NamedBase
  require 'active_support/all'

  source_root File.expand_path('../templates', __FILE__)
  
  
  argument :model_attributes, type: :array, default: [], banner: "model:attributes"
  class_option :skip_timestamps => false
  class_option :skip_migration => false
  

  attr_reader   :controller_name,
                :controller_class_path,
                :controller_file_path,
                :controller_class_nesting,
                :controller_class_nesting_depth,
                :controller_class_name,
                :controller_underscore_name,
                :controller_singular_name,
                :controller_plural_name
  alias_method  :controller_file_name,  :controller_underscore_name
  alias_method  :controller_table_name, :controller_plural_name
  
  
  def initialize(runtime_args, *options)
     super

     @args= runtime_args
      @rspec = has_rspec?

      @controller_name = @name.pluralize

      base_name, @controller_class_path, @controller_file_path, @controller_class_nesting, @controller_class_nesting_depth = extract_modules(@controller_name)
      @controller_class_name_without_nesting, @controller_underscore_name, @controller_plural_name = inflect_names(base_name)
      @controller_singular_name=base_name.singularize
      if @controller_class_nesting.empty?
        @controller_class_name = @controller_class_name_without_nesting
      else
        @controller_class_name = "#{@controller_class_nesting}::#{@controller_class_name_without_nesting}"
      end
      
      @attributes = []

      model_attributes.each do |attribute|
            @attributes << Rails::Generators::GeneratedAttribute.new(*attribute.split(":")) if attribute.include?(":")
            
      end
    
  end
  
  

  
  
  def manifest

      # Check for class naming collisions.
      Rails::Generators::NamedBase::check_class_collision controller_class_path
      Rails::Generators::NamedBase::check_class_collision "#{controller_class_name}Controller"
      Rails::Generators::NamedBase::check_class_collision "#{controller_class_name}Helper"
      Rails::Generators::NamedBase::check_class_collision class_path
      Rails::Generators::NamedBase::check_class_collision "#{class_name}"
      
      # Controller, helper, views, and test directories.
      empty_directory(File.join('app/models', class_path))
      empty_directory(File.join('app/controllers', controller_class_path))
      empty_directory(File.join('app/helpers', controller_class_path))
      empty_directory(File.join('app/views', controller_class_path, controller_file_name))
      empty_directory(File.join('app/views/layouts', controller_class_path))
     
      empty_directory('public/images/ext_scaffold')
      empty_directory(File.join('public/javascripts/ext_scaffold', "#{controller_class_path}"))

        if @rspec
          empty_directory(File.join('spec/controllers', controller_class_path))
          empty_directory(File.join('spec/helpers', class_path))
          empty_directory(File.join('spec/models', class_path))
          empty_directory(File.join('spec/views', controller_class_path, controller_file_name))
          empty_directory(File.join('spec/fixtures', class_path))
        else
          empty_directory(File.join('test/functional', controller_class_path))
          empty_directory(File.join('test/unit', class_path))
        end

        
        # index view
        template('view_index.html.erb', File.join('app/views', controller_class_path, controller_file_name, 'index.html.erb'))

        # ext component for scaffold
        template('ext_scaffold_panel.js', File.join('public/javascripts/ext_scaffold',controller_class_path, "#{class_name.demodulize.underscore}.js") )

          # layout
          template('layout.html.erb', File.join('app/views/layouts', controller_class_path, "#{controller_file_name}.html.erb"))

          # model --> use model generator
          
          
          generate 'model',  @args.join(" ")

          # controller
          template('controller.rb', File.join('app/controllers', controller_class_path, "#{controller_file_name}_controller.rb"))
          template('helper.rb',          File.join('app/helpers',     controller_class_path, "#{controller_file_name}_helper.rb"))

          # assets
          template('assets/javascripts/ext_scaffold.js', 'public/javascripts/ext_scaffold.js')
          template('assets/javascripts/xcheckbox.js', 'public/javascripts/xcheckbox.js')
          template('assets/images/arrowLeft.gif', 'public/images/ext_scaffold/arrowLeft.gif')
          template('assets/images/arrowRight.gif', 'public/images/ext_scaffold/arrowRight.gif')
          template('assets/images/find.png', 'public/images/ext_scaffold/find.png')
          template('assets/stylesheets/ext_scaffold.css', 'public/stylesheets/ext_scaffold.css')
        
          # tests
          if @rspec
            template('rspec/functional_spec.rb', File.join('spec/controllers', controller_class_path, "#{controller_file_name}_controller_spec.rb"))
            template('rspec/routing_spec.rb', File.join('spec/controllers', controller_class_path, "#{controller_file_name}_routing_spec.rb"))
            template('rspec/helper_spec.rb', File.join('spec/helpers', class_path, "#{controller_file_name}_helper_spec.rb"))
            template('rspec/unit_spec.rb', File.join('spec/models', class_path, "#{file_name}_spec.rb"))
          else
            template('functional_test.rb', File.join('test/functional', controller_class_path, "#{controller_file_name}_controller_test.rb"))
          end
          
          
          
          
          if @controller_class_nesting_depth > 0
            route_config =  @controller_class_path.split('/').collect{ |namespace| "namespace :#{namespace} do " }.join(" ")
            route_config << "resources :#{file_name.pluralize}"
            route_config << " end" * @controller_class_nesting_depth
            route route_config
          else
            route("resources :" + controller_file_name)
          end
          
  end
  
  protected
     # Override with your own usage banner.
     def banner
       "Usage: #{$0} ext_scaffold ModelName [field:type, field:type]"
     end

     def rspec_views
       %w[ index show ]
     end    

     def add_options!(opt)
       opt.separator ''
       opt.separator 'Options:'
       opt.on("--skip-timestamps",
              "Don't add timestamps to the migration file for this model") { |v| options[:skip_timestamps] = v }
       opt.on("--skip-migration",
              "Don't generate a migration file for this model") { |v| options[:skip_migration] = v }
       opt.on("--rspec", 
              "Force rspec mode (checks for RAILS_ROOT/spec by default)") { |v| options[:rspec] = true }
     end

     def model_name
       class_name.demodulize
     end
     
     
     def extract_modules(name)
              modules = name.include?('/') ? name.split('/') : name.split('::')
              name    = modules.pop
              path    = modules.map { |m| m.underscore }
              file_path = (path + [name.underscore]).join('/')
              nesting = modules.map { |m| m.camelize }.join('::')
              #puts name, path, file_path, nesting, modules.size
              [name, path.join('/'), file_path, nesting, modules.size]

     end

     def inflect_names(name)
              camel  = name.camelize
              under  = camel.underscore
              plural = under.pluralize
              [camel, under, plural]
     end
     
     # Lifted from Rick Olson's restful_authentication
     def has_rspec?
       options[:rspec] || (File.exist?('spec') && File.directory?('spec'))
     end
     
     def demodulize(class_name_in_module)
           class_name_in_module.to_s.gsub(/^.*::/, '')
    end
         
         
end
