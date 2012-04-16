module ExtScaffold

protected

  def pagination_state
    
    { :order => "#{params.delete(:sort)} #{params.delete(:dir)}", :offset => params.delete(:start).to_i, :limit => params.delete(:limit).to_i }
  end

  def options_from_search(restraining_model = nil)
    model_klass = (restraining_model.is_a?(Class) || restraining_model.nil? ? restraining_model : restraining_model.to_s.classify.constantize)
    {}.tap do |options|
      search_conditions = []
      unless [params[:fields], params[:query]].any?(&:blank?)
        ActiveSupport::JSON::decode(params[:fields]).each do |field|
          field.sub!(/(\A[^\[]*)\[([^\]]*)\]/,'\2') # fields may be passed as "object[attr]"
          next unless model_klass.nil? || model_klass.column_names.include?(field) # accept only valid column names
          search_conditions << "#{field} LIKE :query"
        end
      end
      
          
      options.merge!(:conditions => [search_conditions.join(' OR '), {:query => "%#{params[:query]}%"} ] ) unless search_conditions.empty?
    end
  end

  def sort_options(restraining_model = nil)
    if(params[:sort])

        model_klass = (restraining_model.is_a?(Class) || restraining_model.nil? ? restraining_model : restraining_model.to_s.classify.constantize)
        #sort= "#{params[:sort].sub(/\[#{model_klass}\]/i,'').gsub('[','').gsub(']','')} #{params[:dir]}" || " id asc"
        
        sort= "#{params[:sort].gsub('virtual','').sub(/#{model_klass}/i,'').gsub('[','').gsub(']','')} #{params[:dir]}" || " id asc"
        
        
        { :order => sort }
    else
      sort =  " id asc"
      { :order => sort }
    end
  
  end
  # controllers generated with ExtScaffold prior 5ae8b9177f5fab56bec8714faf687ef7129332b1
  # need this for backward compatibility
  def options_from_pagination_state(state)
    state
  end
  def update_pagination_state_with_params!(restraining_model = nil)
    pagination_state
  end
  # end of deprecated compatibility methods




    # save pagination state to session
    def save_pagination_state(pagination_state, model_klass = nil)
      session["#{model_klass.to_s.tableize.tr('/','_') if model_klass}_pagination_state"] = pagination_state
    end



end