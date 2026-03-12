# frozen_string_literal: true

$LOAD_PATH << File.dirname(__FILE__)

require 'jiramanager/tools'
require 'jiramanager/api_jira'
require 'yaml'
require 'benchmark'
require 'date'

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
        when :audit
          execute_audit(menu_result[:email], menu_result[:start_date], menu_result[:end_date])
        end
      end
    else
      # Execute once with command line options
      elapsed_time = Benchmark.realtime do
        if @options[:action] == :audit
          start_date = Date.strptime(@options[:audit_start_date], '%d/%m/%Y').strftime('%Y-%m-%d')
          end_date = Date.strptime(@options[:audit_end_date], '%d/%m/%Y').strftime('%Y-%m-%d')
          audit_person(email: @options[:audit_email], start_date: start_date, end_date: end_date)
        elsif @options[:assigned_or_was]
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

  def execute_audit(email, start_date, end_date)
    elapsed_time = Benchmark.realtime do
      audit_person(email: email, start_date: start_date, end_date: end_date)
    end
    print italic "\nElapsed time: "
    print italic brown "#{elapsed_time.round(3)}s\n"
  end

  def audit_person(email:, start_date:, end_date:)
    puts bold(cyan(">>> Audit for #{email} (#{start_date} to #{end_date})"))
    print "retrieving jira tickets... "
    array_jira = show_wait_spinner { @api_jira.tickets_involved_during_period(email: email, start_date: start_date, end_date: end_date) }
    
    if array_jira.empty?
      puts yellow("No tickets found for #{email} during this period")
      return
    end

    total = array_jira.length
    puts bold(cyan("Found #{total} ticket(s) to analyze"))
    puts ''

    skipped_tickets = 0
    results = []

    array_jira.each_with_index do |jira, index|
      print "\r\e[K  Analyzing ticket #{index + 1}/#{total} (#{jira[:key]})..."
      begin
        issue_detail = @api_jira.get_issue_with_fields(key: jira[:key])
        changelog = @api_jira.get_issue_changelog_paginated(key: jira[:key])

        # Check if the person is the creator of the ticket (within the date range)
        is_creator = false
        created_ts = nil
        if issue_detail.is_a?(Hash) && issue_detail['fields']
          creator_info = issue_detail['fields']['reporter']
          created_date_str = issue_detail['fields']['created']
          if creator_info && person_match?(creator_info, email) && created_date_str
            begin
              created_ts = DateTime.parse(created_date_str)
              created_date_only = created_ts.strftime('%Y-%m-%d')
              is_creator = created_date_only >= start_date && created_date_only <= end_date
            rescue StandardError
              # ignore
            end
          end
        end

        # Filter actions by the person and by date range
        person_actions = filter_person_actions(changelog, email, start_date, end_date)

        # Get comments by the person during the period
        person_comments = []
        begin
          comments_data = @api_jira.get_issue_comments(key: jira[:key])
          person_comments = filter_person_comments(comments_data, email, start_date, end_date)
        rescue StandardError
          # Ignore comment retrieval errors
        end

        # Only keep tickets where the person had actions, commented, or created during the period
        next if person_actions.empty? && person_comments.empty? && !is_creator

        results << {
          jira: jira,
          is_creator: is_creator,
          created_ts: created_ts,
          person_actions: person_actions,
          person_comments: person_comments
        }
      rescue StandardError => e
        skipped_tickets += 1
      end
    end

    print "\r\e[K  Analysis complete.\n\n"

    # Build a flat list of all events grouped by day
    all_events = []

    results.each do |result|
      jira = result[:jira]
      ticket_ref = "#{jira[:key]} - #{jira[:summary]}"

      # Ticket creation event
      if result[:is_creator] && result[:created_ts]
        all_events << {
          sort_key: result[:created_ts].strftime('%Y-%m-%d %H:%M'),
          day: result[:created_ts].strftime('%Y-%m-%d'),
          time: result[:created_ts].strftime('%H:%M'),
          ticket: jira[:key],
          summary: jira[:summary],
          description: 'ticket created'
        }
      end

      # Changelog actions by the person
      result[:person_actions].each do |action|
        ts = DateTime.strptime(action[:date], '%d/%m/%Y %H:%M')
        field = action[:field]
        if %w[description labels].include?(field)
          desc = "#{field} updated"
        else
          desc = "#{field} changed to #{action[:new_value]}"
          if action[:old_value].nil? || action[:old_value].empty?
            desc += ' (from Unassigned)' if field == 'assignee'
          else
            desc += " (from #{action[:old_value]})"
          end
        end
        all_events << {
          sort_key: ts.strftime('%Y-%m-%d %H:%M'),
          day: ts.strftime('%Y-%m-%d'),
          time: ts.strftime('%H:%M'),
          ticket: jira[:key],
          summary: jira[:summary],
          description: desc
        }
      end

      # Comments by the person
      result[:person_comments].each do |comment|
        ts = DateTime.strptime(comment[:date], '%d/%m/%Y %H:%M')
        all_events << {
          sort_key: ts.strftime('%Y-%m-%d %H:%M'),
          day: ts.strftime('%Y-%m-%d'),
          time: ts.strftime('%H:%M'),
          ticket: jira[:key],
          summary: jira[:summary],
          description: 'comment added'
        }
      end
    end

    all_events.sort_by! { |e| e[:sort_key] }

    # Group events by day and display
    events_by_day = all_events.group_by { |e| e[:day] }

    # Iterate over each day in the date range (inclusive), even days with no events
    current_date = Date.parse(start_date)
    last_date = Date.parse(end_date)

    while current_date <= last_date
      day_str = current_date.strftime('%Y-%m-%d')
      day_display = current_date.strftime('%d/%m/%Y')
      day_name = current_date.strftime('%A')
      day_events = events_by_day[day_str]

      if day_events && !day_events.empty?
        puts gray('─' * 80)
        puts bold("#{day_display} (#{day_name}) — #{day_events.length} action(s) performed by #{email}")
        day_events.each do |event|
          puts "  #{event[:time]}  #{bold(event[:ticket])} #{event[:description]}"
        end
      end

      current_date += 1
    end

    puts gray('═' * 80)
    puts ''
    total_events = all_events.length
    days_with_activity = events_by_day.keys.length
    tickets_involved = all_events.map { |e| e[:ticket] }.uniq.length
    puts bold(cyan("<<< Audit complete: #{total_events} action(s) across #{tickets_involved} ticket(s) over #{days_with_activity} day(s), #{skipped_tickets} skipped"))
  end

  def filter_person_actions(changelog, email, start_date, end_date)
    actions = []
    
    return actions if changelog.nil? || changelog.empty?
    
    changelog.each do |history|
      next unless history.is_a?(Hash)
      
      # Get author info
      author = history['author']
      next if author.nil?

      # Check if this action is by our person
      next unless person_match?(author, email)

      # Check date range
      created_str = history['created']
      next if created_str.nil?
      
      begin
        timestamp = DateTime.parse(created_str)
        action_date = timestamp.strftime('%d/%m/%Y %H:%M')
        action_date_only = timestamp.strftime('%Y-%m-%d')

        next unless action_date_only >= start_date && action_date_only <= end_date

        # Process each item in this history change
        items = history['items']
        next if items.nil? || !items.is_a?(Array)
        
        items.each do |item|
          next unless item.is_a?(Hash)
          
          actions.push({
                         date: action_date,
                         field: item['field'] || 'unknown',
                         old_value: item['fromString'],
                         new_value: item['toString']
                       })
        end
      rescue StandardError => e
        puts red("    Warning: Error parsing date - #{e.message}")
        next
      end
    end

    actions
  end

  def filter_person_comments(comments_data, email, start_date, end_date)
    comments = []

    return comments unless comments_data.is_a?(Hash)

    (comments_data['comments'] || []).each do |comment|
      next unless comment.is_a?(Hash)

      author = comment['author']
      next if author.nil?

      next unless person_match?(author, email)

      created_str = comment['created']
      next if created_str.nil?

      begin
        timestamp = DateTime.parse(created_str)
        comment_date = timestamp.strftime('%d/%m/%Y %H:%M')
        comment_date_only = timestamp.strftime('%Y-%m-%d')

        next unless comment_date_only >= start_date && comment_date_only <= end_date

        comments.push({
                        date: comment_date
                      })
      rescue StandardError
        next
      end
    end

    comments.sort_by { |c| c[:date] }
  end

  def yellow(str) = "\e[33m#{str}\e[0m"

  def person_match?(author, email)
    return false if author.nil?

    email_down = email.downcase
    author_email = author['emailAddress']&.downcase
    author_name = author['displayName']&.downcase

    author_email == email_down || author_name == email_down
  end

  def welcome_menu
    puts ''
    puts bold(cyan('🎯 Welcome to JiraManager! 🎯'))
    puts ''

    options = [
      'Show my assigned tickets',
      'Show tickets assigned to a specific email',
      'Show tickets assigned or was assigned to a specific email',
      'Audit person',
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
    when 3
      { action: :audit, email: ask_for_email, start_date: ask_for_start_date, end_date: ask_for_end_date }
    else
      { action: :exit }
    end
  end

  def ask_for_email
    print bold('Enter email address: ')
    email = gets.chomp.strip
    if email.empty?
      puts red('Error: Email cannot be empty!')
      return ask_for_email
    end
    email
  end

  def ask_for_start_date
    print bold('Enter start date (DD/MM/YYYY): ')
    date_str = gets.chomp.strip
    begin
      Date.strptime(date_str, '%d/%m/%Y').strftime('%Y-%m-%d')
    rescue ArgumentError
      puts red('Error: Invalid date format! Please use DD/MM/YYYY')
      ask_for_start_date
    end
  end

  def ask_for_end_date
    print bold('Enter end date (DD/MM/YYYY): ')
    date_str = gets.chomp.strip
    begin
      Date.strptime(date_str, '%d/%m/%Y').strftime('%Y-%m-%d')
    rescue ArgumentError
      puts red('Error: Invalid date format! Please use DD/MM/YYYY')
      ask_for_end_date
    end
  end
end
