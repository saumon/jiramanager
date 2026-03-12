# frozen_string_literal: true

$LOAD_PATH << File.dirname(__FILE__)

require 'uri'
require 'net/http'
require 'openssl'
require 'json'
require 'date'

class ApiJira
  APP_JSON = 'application/json'
  public_constant :APP_JSON

  def initialize(secret, base_url)
    @secret = secret
    @base_url = base_url
  end

  def api_get(path)
    uri = URI("#{@base_url}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri)
    request['Accept'] = APP_JSON
    request['Authorization'] = @secret
    response = http.request(request)
    raise "HTTP #{response.code} for #{path}" unless response.code.to_i == 200

    JSON.parse(response.read_body)
  end

  def query_jira(jql)
    api_get("/rest/api/3/search/jql?jql=#{jql}&fields={key,summary,issuetype,status,assignee,updated,parent,creator,created}")
  end

  def query_jira_infinite(jql, next_page_token = '')
    array_hash_jira = []

    response_json = query_jira("#{jql}&nextPageToken=#{next_page_token}")
    # puts JSON.pretty_generate(response_json)

    next_page_token = response_json['nextPageToken']

    response_json['issues'].each do |issue|
      key = issue['key']
      summary = issue['fields']['summary']
      status = issue['fields']['status']['name']
      type = issue['fields']['issuetype']['name']
      assignee = issue['fields']['assignee']['displayName'] unless issue['fields']['assignee'].nil?
      creator = issue['fields']['creator']['displayName'] unless issue['fields']['creator'].nil?
      created = DateTime.parse(issue['fields']['created']).strftime('%d/%m/%Y') unless issue['fields']['created'].nil?
      updated = DateTime.parse(issue['fields']['updated']).strftime('%d/%m/%Y')
      parent_key = issue['fields']['parent']['key'] unless issue['fields']['parent'].nil?
      parent_summary = issue['fields']['parent']['fields']['summary'] unless issue['fields']['parent'].nil?
      array_hash_jira.push({
                             key:            key,
                             summary:        summary,
                             type:           type,
                             status:         status,
                             assignee:       assignee,
                             creator:        creator,
                             created:        created,
                             updated:        updated,
                             parent_key:     parent_key,
                             parent_summary: parent_summary
                           })
    end

    if next_page_token.nil? || next_page_token.empty?
      array_hash_jira
    else
      array_hash_jira.concat(query_jira_infinite(jql, next_page_token))
    end
  end

  def assignee_tickets(email:)
    query_jira_infinite("assignee = '#{email}' ORDER BY updated DESC, status DESC, created DESC")
  end

  def my_assignee_tickets
    query_jira_infinite('assignee = currentUser() ORDER BY updated DESC, status DESC, created DESC')
  end

  def assignee_or_was_assignee_tickets(email:)
    query_jira_infinite("assignee = '#{email}' OR assignee WAS '#{email}' ORDER BY updated DESC, status DESC, created DESC")
  end

  def get_issue_with_fields(key:)
    clean_key = key.strip.upcase
    api_get("/rest/api/3/issue/#{clean_key}")
  end

  def get_issue_changelog_paginated(key:)
    clean_key = key.strip.upcase
    all_histories = []
    start_at = 0

    loop do
      data = api_get("/rest/api/3/issue/#{clean_key}/changelog?startAt=#{start_at}&maxResults=100")
      values = data['values'] || []
      all_histories.concat(values)
      break if all_histories.length >= (data['total'] || 0)
      break if values.empty?

      start_at += values.length
    end

    all_histories
  end

  def get_issue_comments(key:)
    clean_key = key.strip.upcase
    api_get("/rest/api/3/issue/#{clean_key}/comment")
  end

  def tickets_involved_during_period(email:, start_date:, end_date:)
    # Search for tickets where the person was involved during the period:
    # - assigned or was assigned
    # - creator (reporter)
    # - logged work (worklogAuthor)
    # - changed the status (even on tickets not assigned to them)
    # Note: no upper bound on `updated` — a ticket modified by the person during
    # the period may have been further updated after end_date. The date filtering
    # is done in Ruby on each individual action.
    query_jira_infinite("(assignee = '#{email}' OR assignee WAS '#{email}' OR reporter = '#{email}' OR worklogAuthor = '#{email}' OR status CHANGED BY '#{email}') AND updated >= #{start_date} ORDER BY updated DESC")
  end
end
