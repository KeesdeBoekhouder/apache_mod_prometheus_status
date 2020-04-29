# mod_prometheus_status

mod_prometheus_status is a [Prometheus](https://prometheus.io/) white box exporter for [Apache HTTPD](https://httpd.apache.org/) metrics similar to mod_status.

The exporter is a loadable Apache module and serves metrics directly via the
apache webserver. It comes with dynamic and flexible labeling, see the example
configuration below.

## How it works
Since prometheus exporter are usually bound to a single process and the apache
webserver is a multiprocess daemon, this module starts a metrics collector in
the parent httpd process.

Upon start the main collector creates the prometheus client library registry
based on the `PrometheusStatusLabelNames`. It then opens a unix socket to
receive the metrics updates from the child workers.

On each request, the client worker sends its metrics based on
`PrometheusStatusLabelValues`, which utilizes Apaches LogFormat, to the metrics
collector.

## Build Requirements

  - gcc compiler to build (4.9 or newer)
    - apache header files
  - golang >= 1.12
  - docker/docker-compose for running tests

## Installation

> **_NOTE:_** Prebuild modules are available at https://github.com/ConSol/apache_mod_prometheus_status/releases

Compile the module like this:

```bash
  make
```

Copy *BOTH* .so files to the apache module directory and adjust the example
configuration.

## Configuration

### apache.conf:
```apache
LoadModule prometheus_status_module .../mod_prometheus_status.so
PrometheusStatusEnabled On
PrometheusStatusLabelNames  method;status;application
PrometheusStatusLabelValues %m;%s;

<Location /metrics>
  # make collected metrics available at this url
  SetHandler prometheus-metrics
</Location>

# optional custom labels for specific locations
<Location /test>
  PrometheusStatusLabel %m;%s;application1
</Location>

# disable collecting metrics for some locations
<Location /no_metrics_for_here>
  PrometheusStatusEnabled Off
</Location>
```

### Directives

#### PrometheusStatusEnabled
Enable or disable collecting metrics. Available on server and directory level.

#### PrometheusStatusLabelNames
Set label names separated by semicolon. This is a global setting and can only
be set once on server level since the metrics have to be registered and cannot
be changed later on.

> **_NOTE:_** Be aware of cardinality explosion and do not overuse labels.
Read more at https://prometheus.io/docs/practices/naming/#labels and
https://www.robustperception.io/cardinality-is-key

#### PrometheusStatusLabelValues
Set label values separated by semicolon. You can use the apache logformat here.
Some high cardinality variables are not implemented.

Useful examples are:

 - `%m` - request method: ex.: GET, POST, ...
 - `%s` - response code: ex.: 200, 404, 500, ...
 - `%v` - canonical ServerName

See http://httpd.apache.org/docs/current/mod/mod_log_config.html#formats for a
full list of available variables.

## Metrics

Then you can access the metrics with a URL like:

http://your_server_name/metrics

Or whatever you put your `SetHandler prometheus-metrics` to.

> **_NOTE:_** You may want to protect the /metrics location by password or domain so no one else can look at it.


So far this modules supports the following metrics:

```
  # HELP apache_cpu_load CPU Load 1
  # TYPE apache_cpu_load gauge
  # TYPE apache_requests_total counter
  # HELP apache_requests_total is the total number of http requests
  # TYPE apache_response_size_bytes histogram
  # HELP apache_response_size_bytes response size histogram
  # TYPE apache_response_time_seconds histogram
  # HELP apache_response_time_seconds response time histogram
  # HELP apache_server_config_generation current config generation
  # TYPE apache_server_config_generation gauge
  # TYPE apache_server_info counter
  # HELP apache_server_info information about the apache version
  # HELP apache_server_mpm_generation current mpm generation
  # TYPE apache_server_mpm_generation gauge
  # HELP apache_server_name contains the server name
  # TYPE apache_server_name counter
  # TYPE apache_server_uptime_seconds gauge
  # HELP apache_server_uptime_seconds server uptime in seconds
  # TYPE apache_workers gauge
  # HELP apache_workers is the total number of apache workers
  # TYPE apache_workers_scoreboard gauge
  # HELP apache_workers_scoreboard is the total number of workers from the scoreboard
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss
what you would like to change.

Please make sure to update tests as appropriate.

### Development Environment

There is a test/dev docker box located in `t/testbox` which can be started for
easy testing and development.

```bash
  make testbox
```

This creates a Centos 8 box which builds the module whenever the source file
changes. You can access the module at `http://localhost:3000/metrics`. It might
take a moment to startup.

You can access the grafana dashboard at
`http://localhost:3001/dashboard/grafana/` and the Prometheus instance at
`http://localhost:3001/dashboard/prometheus/`.

Run the unit/integration tests like this:

```bash
  make test
```

Cleanup docker machines and test environment by

```bash
  make clean
```

#### Ressources

Some useful ressources during development:

  - `Apache Module Development` - https://httpd.apache.org/docs/current/developer/modguide.html
  - `Apache API docs` - https://ci.apache.org/projects/httpd/trunk/doxygen/

## Roadmap

  - [ ] add memory metrics
  - [ ] add example grafana dashboard
  - [ ] add configuration directive for histogram buckets
  - [ ] add trimmable path label, ex.: %{p:1:2} which uses 2 directories levels, starting at the first level

## Changes

```
0.0.3   Wed Apr 29 10:01:17 CEST 2020
          - fixed reload issue on some systems

0.0.2   Tue Apr 21 16:53:05 CEST 2020
          - add missing includes
          - improve build from dist tarball

0.0.1   Tue Apr 21 09:43:37 CEST 2020
          - initial release
          - dynamic labeling
          - basic set of metrics
```

## License
[MIT](https://choosealicense.com/licenses/mit/)
