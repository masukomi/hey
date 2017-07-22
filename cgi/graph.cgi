#!/usr/bin/env ruby

require 'cgi'
cgi = CGI.new
graph_type = cgi['graph_type']
title      = cgi['title']
labels     = cgi['labels'] # json string
series     = cgi['series'] # json string

acceptable_graph_types = ['line_chart', 'stacked_bar_chart']
response_html=''
begin
  if acceptable_graph_types.include? graph_type
    # load ../#{graph_type}.html
    # insert
    lines = IO.readlines("#{graph_type}_template.html")
    response_html = lines.map{|line|
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
