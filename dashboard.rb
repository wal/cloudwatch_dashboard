require 'rubygems'
require 'sinatra'
require 'json'
require 'aws'

AWS_CREDS_FILE='aws-creds.yml'
DEFAULT_NAMESPACE = "AWS/ELB"

get '/' do

  @config = YAML::load( File.open('dashboard_config.yml'))

  set_cloudwatch_credentials(@config)

  @namespace = params[:namespace] || DEFAULT_NAMESPACE
  @graphs = []

  metric_configs = @config['metrics'][@namespace]

  metric_configs.each do |metric_config|
    graph_data = GraphData.new

    unless metric_config['dimensions'].nil?
      metric_config['dimensions'].each do |k,v|
        graph_data.dimensions << {:name => k, :value => v}
      end
    end

    graph_data.metric_name = metric_config['metric_name']
    graph_data.statistics = metric_config['statistics']
    graph_data.period = metric_config['period']

    puts graph_data.inspect

    metric = AWS::CloudWatch::Metric.new(@namespace, graph_data.metric_name, {:dimensions => graph_data.dimensions})

    puts metric.inspect

    @start_time = Time.now - (60 * 60 * 6)
    @end_time = Time.now

    cloudwatch_stats = metric.statistics(
        :start_time => @start_time,
        :end_time => @end_time,
        :statistics => graph_data.statistics,
        :period => graph_data.period)

    puts cloudwatch_stats.inspect

    cloudwatch_stats.each_with_index do |stat,i|
      puts i
    end

    graph_data.x_axis_categories = []
    graph_data.y_axis_label = ""
    graph_data.datapoints = []
    @series = []

    cloudwatch_stats.sort_by{|stat| stat[:timestamp]}.each do |datapoint|
      graph_data.x_axis_categories << "#{datapoint[:timestamp]}"
      graph_data.datapoints << datapoint[graph_data.statistics[0].downcase.to_sym]
    end

    graph_data.series << {name: cloudwatch_stats.label, data: graph_data.datapoints}

    graph_data.graph_title = "#{@namespace} - #{graph_data.metric_name} - #{graph_data.statistics[0]}"

    @graphs << graph_data
  end
  erb "boom"
end

def set_cloudwatch_credentials(config)
  aws_config =  YAML::load( File.open(AWS_CREDS_FILE))
  AWS.config(aws_config)
  @region = aws_config['region']
end

class GraphData
  attr_accessor :dimensions
  attr_accessor :metric_name
  attr_accessor :statistics
  attr_accessor :period
  attr_accessor :x_axis_categories
  attr_accessor :y_axis_label
  attr_accessor :datapoints
  attr_accessor :series
  attr_accessor :graph_title

  def initialize
    @dimensions = []
    @datapoints = []
    @series = []
  end
end