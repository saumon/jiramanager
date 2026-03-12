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

    # If no options provided, show welcome menu in loop
    if @options.empty?
      loop do
        menu_result = welcome_menu
        case menu_result[:action]
        when :exit
          puts_byebye
          return
        when :my_tickets
          execute_my_tickets
        when :email_tickets
          execute_email_tickets(menu_result[:email])
        when :assignee_or_was_assignee_tickets
          execute_assignee_or_was_assignee_tickets(menu_result[:email])
        end
      end
    else
      # Execute once with command line options
      elapsed_time = Benchmark.realtime do
        if @options[:assigned_or_was]
          assignee_or_was_assignee_tickets(email: @options[:assigned_or_was])
        elsif @options[:email]
          assignee_tickets_for_email(email: @options[:email])
        else
          assignee_tickets
        end
      end
      print italic "\nElapsed time: "
      print italic brown "#{elapsed_time.round(3)}s\n"
    end
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

  def assignee_tickets_for_email(email:)
    puts bold(cyan(">>> #{__method__} for #{email}"))
    print "retrieving jira tickets for #{email}... "
    array_jira = show_wait_spinner { @api_jira.assignee_tickets(email: email) }
    array_jira.each do |jira|
      puts " - #{jira[:updated]} `#{jira[:status]}` #{jira[:key]} : #{jira[:summary]}"
    end
    puts bold(cyan("<<< #{__method__}"))
  end

  def execute_my_tickets
    elapsed_time = Benchmark.realtime do
      assignee_tickets
    end
    print italic "\nElapsed time: "
    print italic brown "#{elapsed_time.round(3)}s\n"
  end

  def execute_email_tickets(email)
    elapsed_time = Benchmark.realtime do
      assignee_tickets_for_email(email: email)
    end
    print italic "\nElapsed time: "
    print italic brown "#{elapsed_time.round(3)}s\n"
  end

  def assignee_or_was_assignee_tickets(email:)
    puts bold(cyan(">>> #{__method__} for #{email}"))
    print "retrieving jira tickets assigned or was assigned to #{email}... "
    array_jira = show_wait_spinner { @api_jira.assignee_or_was_assignee_tickets(email: email) }
    array_jira.each do |jira|
      puts " - #{jira[:updated]} `#{jira[:status]}` #{jira[:key]} : #{jira[:summary]}"
    end
    puts bold(cyan("<<< #{__method__}"))
  end

  def execute_assignee_or_was_assignee_tickets(email)
    elapsed_time = Benchmark.realtime do
      assignee_or_was_assignee_tickets(email: email)
    end
    print italic "\nElapsed time: "
    print italic brown "#{elapsed_time.round(3)}s\n"
  end

  def welcome_menu
    puts ''
    puts bold(cyan('🎯 Welcome to JiraManager! 🎯'))
    puts ''

    options = [
      'Show my assigned tickets',
      'Show tickets assigned to a specific email',
      'Show tickets assigned or was assigned to a specific email',
      'Exit'
    ]

    choice = select_item_from_array(options, 'What would you like to do?')

    case choice
    when 0
      { action: :my_tickets }
    when 1
      print bold('Enter email address: ')
      email = gets.chomp.strip
      if email.empty?
        puts red('Error: Email cannot be empty!')
        return { action: :my_tickets }
      end
      { action: :email_tickets, email: email }
    when 2
      print bold('Enter email address: ')
      email = gets.chomp.strip
      if email.empty?
        puts red('Error: Email cannot be empty!')
        return { action: :my_tickets }
      end
      { action: :assignee_or_was_assignee_tickets, email: email }
    else
      { action: :exit }
    end
  end
end
