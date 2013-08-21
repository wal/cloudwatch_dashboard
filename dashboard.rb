require 'rubygems'
require 'sinatra'
require 'json'
require 'aws'

DEFAULT_NAMESPACE = 'AWS/EC2'
DEFAULT_REGION = 'eu-west-1'
THREE_DAYS = 60 * 60 * 24 * 3

DATE_FORMAT = '%Y-%m-%d %H:%M'
CONFIG_FILE_NAME = 'dashboard_config.yml'

helpers do
  def format_date(date)
    date.strftime(DATE_FORMAT)
  end

  def namespaces
    @config['metrics'].keys
  end
end

get '/' do
  @region = DEFAULT_REGION

  @end_time = Time.now
  @start_time = (@end_time - THREE_DAYS)
  duration = @end_time.to_i - @start_time.to_i

  @config = load_config()

  load_cloudwatch_credentials(@config)

  @current_namespace = params[:namespace] || DEFAULT_NAMESPACE
  @graphs = []

  graph_configs = @config['metrics'][@current_namespace]

  graph_configs.each do |graph_config|

    period = graph_config['period']
    datapoint_count = duration/period

    graph_data = HighchartGraph.new(graph_config['title'])

    graph_data.x_axis_categories = generate_x_axis_categories(@start_time, period, datapoint_count)

    [graph_config['left'], graph_config['right']].each_with_index do |side, index|
      next if side.nil?

      graph_data.sides[index] = {label: side['label'], series: []}

      side['metrics'].each_with_index do |metric_config, i|

        log :INFO, "Adding metric #{metric_config.inspect}"

        dimensions = create_dimensions(metric_config)

        metric_name = metric_config['metric_name']
        statistics = metric_config['statistics']

        metric = AWS::CloudWatch::Metric.new(@current_namespace, metric_name, {:dimensions => dimensions})

        cloudwatch_statistics = metric.statistics(
            :start_time => @start_time,
            :end_time => @end_time,
            :statistics => statistics,
            :period => period)

        sorted_datapoints = sort_datapoints(datapoint_count, cloudwatch_statistics, period, statistics)

        graph_data.sides[index][:series] << {name: cloudwatch_statistics.label, data: sorted_datapoints, yAxis: index}

        if graph_data.graph_title.nil?
          graph_data.graph_title = "#{@current_namespace} - #{metric_name} - #{statistics[0]}"
        end
      end
    end

    @graphs << graph_data
  end

  erb :index
end

def create_dimensions(metric_config)
  dimensions = []
  unless metric_config['dimensions'].nil?
    metric_config['dimensions'].each do |k, v|
      dimensions << {:name => k, :value => v}
    end
  end
  dimensions
end

def load_cloudwatch_credentials(config)

  aws_config = {
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_KEY_ID'],
      :region => DEFAULT_REGION
  }

  AWS.config(aws_config)

  log :INFO, "Using Cloudwatch AccessKey #{AWS.config.access_key_id} in region #{AWS.config.region}"
end

def load_config
  YAML::load(File.open(CONFIG_FILE_NAME))
end

def sort_datapoints(bins_count, cloudwatch_stats, period, statistics)
  datapoints = Array.new(bins_count, '')

  cloudwatch_stats.sort_by { |stat| stat[:timestamp] }.each do |datapoint|
    slot = ((datapoint[:timestamp] - @start_time)/period).to_i
    datapoints[slot] = datapoint[statistics[0].downcase.to_sym].round(2)
  end

  datapoints
end

def generate_x_axis_categories(start_time, period, x_axis_slots)
  ret = []
  x_axis_slots.times do |i|
    ret << "#{(start_time + (period * i)).strftime(DATE_FORMAT)}"
  end
  ret
end

def log(level, message)
  puts "#{Time.now.to_s} [#{level}] #{message}"
end

class HighchartGraph
  attr_accessor :graph_title
  attr_accessor :x_axis_categories
  attr_accessor :sides

  def initialize(title)
    @sides = []
    @graph_title = title
  end

  def graph_data
    {
      title: title,
      xAxis: xaxis,
      yAxis: yaxis,
      series: series
    }.to_json
  end

  private

  def title
    {
        text: graph_title,
        x: -20
    }.to_json
  end

  def xaxis
    {
      categories: x_axis_categories ,
      labels: {
          style: {fontSize: '9px'}
      },
      tickInterval: x_axis_categories.size / 10
    }
  end

  def yaxis
    axs = []
    sides.each_with_index do |side, i|
      axis = {title: {text: side[:label]}}
      if i.odd?
        axis[:opposite] = true
      end

      axs << axis
    end
    axs
  end

  def series
    sides.map{|s| s[:series]}.flatten
  end
end