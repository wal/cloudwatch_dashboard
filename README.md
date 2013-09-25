# Cloudwatch Dashboard

A simple dashboard for rendering graphs of AWS Cloudwatch metrics.


## Configuration

The metrics to graph are configured in the dashboard_config.yml file.

Metrics are divided up by namespace, and each namespace graphs are rendered on different pages.


### Single Metric
To render a graph of the aggregated average CPUUtilization across your EC2 instances

<pre><code>
metrics: {
  "AWS/EC2": [
    {
      title: "CPUUtilization",
      period: 3600,
      left: {
        label: "CPU",
        metrics: [{metric_name: "CPUUtilization",statistics: ['Average']]
      }
    }
  ]
}
</code></pre>

### Multiple Metrics

You can graph multiple metrics on the same graph.


#### Multiple metrics same side

To graph of your ELB response codes together on the same graph

<pre><code>
metrics: {
  "AWS/ELB": [
    { title: "ELB - Response Codes",
      period: 300,
      left: {
        label: "Count",
        metrics: [
          {metric_name: "HTTPCode_Backend_2XX",statistics: ['Sum']},
          {metric_name: "HTTPCode_Backend_3XX", statistics: ['Sum']},
          {metric_name: "HTTPCode_Backend_4XX", statistics: ['Sum']},
          {metric_name: "HTTPCode_Backend_5XX", statistics: ['Sum']}
      ]
      }
    }
  ]
}
</code></pre>


#### Multiple metrics different sides

To draw a graph of ELB Latency (on the left) and ELB Request Count (on the right)

<pre><code>
metrics: {
  "AWS/ELB": [
    { title: "ELB - Requests/Latency",
      period: 3600,
      left: {
        label: "Latency",
        metrics: [{metric_name: "Latency", statistics: ['Average']}]
      },
      right: {
        label: "Requests",
        metrics: [{metric_name: "RequestCount",statistics: ['Sum']}]
      }
    }
  ]
}
</code></pre>

#### Multiple graphs

You can add multiple (per namespace) graphs on the same page

 <pre><code>
    metrics: {
        "AWS/ELB": [
            { title: "ELB - Requests/Latency",
                period: 3600,
                left: {
                    label: "Latency",
                    metrics: [{metric_name: "Latency", statistics: ['Average']}]
                },
                right: {
                    label: "Requests",
                    metrics: [{metric_name: "RequestCount",statistics: ['Sum']}]
                }
            },
            { title: "ELB - Response Codes",
                period: 300,
                left: {
                    label: "Count",
                    metrics: [
                        {metric_name: "HTTPCode_Backend_2XX",statistics: ['Sum']},
                        {metric_name: "HTTPCode_Backend_3XX", statistics: ['Sum']},
                        {metric_name: "HTTPCode_Backend_4XX", statistics: ['Sum']},
                        {metric_name: "HTTPCode_Backend_5XX", statistics: ['Sum']}
                    ]
                }
            }
        ]
    }
 </code></pre>


## Limitations

This implementation has some limitations for my use-case, but feel free to send on pull requests with your enhancements
* Single Region (eu-west-1)
* Static date range (fixed to last 3 days)
* Graphs are grouped per namespace


## Run
$ bundle install
$ export AWS_ACCESS_KEY_ID=you-aws-access-key
$ export AWS_SECRET_KEY_ID=your-aws-secret-key

## Technologies used
* Highcharts
* Sinatra
* Twitter Bootstrap