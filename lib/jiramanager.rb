# frozen_string_literal: true

$LOAD_PATH << File.dirname(__FILE__)

require 'jiramanager/tools'
require 'jiramanager/api_jira'
require 'yaml'
require 'benchmark'

# Main class
class Jiramanager
  include Tools

  CONF_FILE_NAME = 'jiramanager-config.yml'
  public_constant :CONF_FILE_NAME

  CONF_JIRA_SECRET = 'jira_secret'
  public_constant :CONF_JIRA_SECRET

  CONF_JIRA_BASEURL = 'jira_baseurl'
  public_constant :CONF_JIRA_BASEURL

  def initialize
    load_conf
    @api_jira = ApiJira.new(@conf_jira_secret, @conf_jira_baseurl)
    @options = {}
    @selected_squad_conf = nil
  end

  def load_conf
    config = YAML.load_file("#{__dir__}/../conf/#{CONF_FILE_NAME}")
    @conf_jira_secret = config[CONF_JIRA_SECRET]
    @conf_jira_baseurl = config[CONF_JIRA_BASEURL]
  end

  def main(options)
    @options = options

    elapsed_time = Benchmark.realtime do
      assignee_tickets
    end
    print italic "\nElapsed time: "
    print italic brown "#{elapsed_time.round(3)}s\n"
  rescue Interrupt
    puts_byebye
  rescue RuntimeError => exception
    puts ''
    puts red exception.message
    puts_error
  end

  def assignee_tickets
    puts bold(cyan(">>> #{__method__}"))
    print 'retrieving jira tickets... '
    array_jira = show_wait_spinner { @api_jira.my_assignee_tickets }
    array_jira.each do |jira|
      puts " - #{jira[:updated]} `#{jira[:status]}` #{jira[:key]} : #{jira[:summary]}"
    end
    puts bold(cyan("<<< #{__method__}"))
  end
end
