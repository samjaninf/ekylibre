require "kame/finders"
require "kame/exporters"
require "kame/renderers"

module Kame

  class Table

    def view_method_name
      Kame.view_method_name(self.name)
    end

    def controller_method_name
      Kame.controller_method_name(self.name)
    end

    def records_variable_name
      Kame.records_variable_name(self.name)
    end

    def finder
      Kame.finders[@options[:finder]]
    end

    def renderer
      Kame.renderers[@options[:renderer]]
    end


    protected

    

    def generate_controller_method_code
      code  = "def #{Kame.controller_method_name(self.name)}\n"
      code += self.session_initialization_code.gsub(/^/, '  ')
      # Maximum priority action
      code += "  if request.xhr?\n"
      code += self.renderer.remote_update_code(self).gsub(/^/, '    ')
      # Actions
      for format, exporter in Kame.exporters
        code += "  elsif (#{exporter.condition})\n"
        code += exporter.send_data_code(self).gsub(/^/, '    ')
      end
      # Minimum priority action
      code += "  else\n"
      code += "    render(:inline=>'<%=#{Kame.view_method_name(self.name)}->', :layout=>true)\n"
      code += "  end\n"
      code += "end\n"
      list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
      return code
    end

    def generate_view_method_code
      code  = "def #{Kame.view_method_name(self.name)}(options={})\n"
      code += self.session_initialization_code.gsub(/^/, '  ')
      code += self.renderer.build_table_code(self).gsub(/^/, '  ')
      code += "end\n"
      list = code.split("\n"); list.each_index{|x| puts((x+1).to_s.rjust(4)+": "+list[x])}
      return code      
    end


    def session_initialization_code
      code  = "options ||= {}\n"
      code += "options = (params||{}).merge(options)\n"
      # Session values
      code += "session[:kame] = {} unless session[:kame].is_a? Hash\n"
      code += "kame_params = session[:kame][:#{self.name}]\n"
      code += "kame_params = {} unless kame_params.is_a? Hash\n"
      code += "kame_params[:hidden_columns] = [] unless kame_params[:hidden_columns].is_a? Array\n"
      # Order
      code += "order = nil\n"
      code += "options['#{self.name}_sort'] ||= kame_params[:sort]\n"
      code += "options['#{self.name}_dir']  ||= kame_params[:dir]\n"
      code += "unless options['#{self.name}_sort'].blank?\n"
      code += "  options['#{self.name}_dir'] ||= 'asc'\n"
      code += "  order  = ActiveRecord::Base.connection.quote_column_name(options['#{self.name}_sort'])\n"
      code += "  order += options['#{self.name}_dir']=='desc' ? ' DESC' : ' ASC'\n"
      code += "end\n"
      code += "kame_params[:sort] = options['#{self.name}_sort']\n"
      code += "kame_params[:dir]  = options['#{self.name}_dir']\n"
      return code
    end

  end
end
