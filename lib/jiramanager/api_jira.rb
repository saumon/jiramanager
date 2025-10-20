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

  def query_jira(jql)
    uri = URI("#{@base_url}/rest/api/3/search/jql?jql=#{jql}&fields={key,summary,issuetype,status,assignee,updated,parent}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri)
    request['Accept'] = APP_JSON
    request['Authorization'] = @secret
    JSON.parse(http.request(request).read_body)
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
      updated = DateTime.parse(issue['fields']['updated']).strftime('%d/%m/%Y')
      parent_key = issue['fields']['parent']['key'] unless issue['fields']['parent'].nil?
      parent_summary = issue['fields']['parent']['fields']['summary'] unless issue['fields']['parent'].nil?
      array_hash_jira.push({
                             key:            key,
                             summary:        summary,
                             type:           type,
                             status:         status,
                             assignee:       assignee,
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
end
