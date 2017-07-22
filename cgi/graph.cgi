#!/usr/bin/env ruby

require 'cgi'
require 'tempfile'
require 'fileutils'

cgi = CGI.new
graph_type = cgi['graph_type']
title      = cgi['title']
labels     = cgi['labels'] # json string
series     = cgi['series'] # json string

acceptable_graph_types = ['line_chart', 'stacked_bar_chart', 'scatter_plot']
response_html=''
tempfiles_dir = 'tempfiles'
max_age_in_days = 1
begin
  if acceptable_graph_types.include? graph_type
    # load ../#{graph_type}.html
    # insert
    lines = IO.readlines("#{graph_type}_template.html")
    graph_html = lines.map{|line|
      if line.include? 'FINAL_TITLE_HERE'
        line.sub('FINAL_TITLE_HERE', "\"#{title.gsub('"', '\"')}\"")
      elsif line.include? 'FINAL_LABELS_HERE'
        line.sub('FINAL_LABELS_HERE', labels)
      elsif line.include? 'FINAL_SERIES_HERE'
        line.sub('FINAL_SERIES_HERE', series)
      else
        line
      end
    }.join("\n") # + "<!-- #{cgi.inspect} -->"
    file_name = 'error.html'
    file = Tempfile.new(["hey-#{graph_type}-", '.html'], tempfiles_dir)
    file_name = file.path.split('/').last
    full_path = file.path

    file.write graph_html
    file.close

    FileUtils.chmod 0444, full_path

    response_html="https://interrupttracker.com/tempfiles/#{file_name}"
  else
    #load error file
    error_string = "#{graph_type} is not a recognized graph type."
    response_html = error_string + "\n\n#{cgi.inspect}"
  end
rescue Exception => e
  response_html = e.message
end



cgi.out{
  response_html
}

################################################################################
# cleanup
def file_age(name)
  (Time.now - File.ctime(name))/(24*3600)
end

Dir.chdir(tempfiles_dir)
Dir.glob(file_pattern).each { |filename|
  File.delete(filename) if file_age(filename) > max_age_in_days
}
