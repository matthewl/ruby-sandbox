#!/usr/bin/env ruby

require 'minitest'
require 'minitest/spec'
require 'nokogiri'
require 'open-uri'
require 'time'

# Build a web crawler single web domain.

# - The crawler shouldn't flood the site, e.g. crawl no faster 2-3 pages a second.
# - Write tests/specs to cover the functionality of the web crawler
# - Generate a CSV file containing URL, title, and HTTP status code (e.g 200 or 404)

class WebCrawler
  DOMAIN = '' # Add your domain to crawl
  INTERVAL = 0.4

  def initialize
    @pages_collection = PagesCollection.new
    puts "Crawling through #{DOMAIN} ..."
  end

  def crawl(url = DOMAIN)
    url.chop! if url.end_with?('/')
    page_request = PageRequest.new(url)
    page_request.fetch
    return if page_request.nil?

    @pages_collection.add(url, page_request.title, page_request.status_code)
    page_urls = find_urls_on_page(url)

    page_urls.each do |page_url|
      page_url.chop! if page_url.end_with?('/')
      next if @pages_collection.url_exists?(page_url)

      puts "... #{page_url}"
      crawl(page_url)
      sleep(INTERVAL)
    end

    @pages_collection.to_csv if @pages_collection.size.positive?
  end

  private

  def find_urls_on_page(page)
    doc = Nokogiri::HTML(URI.open(page))

    links = doc.css('a')
    links = links.map { |link| link.attribute('href').to_s }.uniq.sort
    links.map! { |link| link.start_with?('/') ? "#{DOMAIN}#{link}" : link }
    links.delete_if { |href| invalid_url?(href) }
  end

  def invalid_url?(url)
    url.empty? || !starts_with_domain?(url) || url.include?('#')
  end

  def starts_with_domain?(url)
    url.start_with?(DOMAIN)
  end
end

# A class for making page requests
class PageRequest
  attr_reader :status_code, :title

  def initialize(url)
    @url = url
    @page_object = nil
  end

  def fetch
    begin
      @page_object = URI.open(@url)
      @title = page_title
      @status_code = 200
    rescue OpenURI::HTTPError => e
      response = e.io
      @page_object = nil
      @status_code = response.status.first.to_i
    end
  end

  def success?
    @page_status == 200
  end

  private

  def page_title
    body = @page_object.read
    titles = body.match(/<title>(.*)<\/title>/mi)

    @title =
      if titles.nil?
        ''
      else
        titles.captures.first
      end
  end
end

# A class for storing pages visited during a crawl
class PagesCollection
  DEFAULT_STATUS_CODE = 200
  Page = Struct.new(:url, :title, :status_code)

  def initialize
    @pages = []
  end

  def add(url, title, status_code = DEFAULT_STATUS_CODE)
    return if url_exists?(url)

    @pages << Page.new(url, title, status_code)
  end

  def find_by_url(url)
    return '' unless url_exists?(url)

    @pages.select { |page| page.url == url }.first
  end

  def url_exists?(url)
    @pages.collect(&:url).include?(url)
  end

  def urls
    @pages.collect(&:url)
  end

  def size
    @pages.size
  end

  def csv_payload
    @lines = []
    @pages.each do |page|
      @lines << "#{page.url}, '#{page.title}', #{page.status_code}\n"
    end
    @lines
  end

  def to_csv
    filename = "#{Time.now.strftime('%Y%m%d-%H%M')}.csv"
    File.open(filename, 'w') do |file|
      csv_payload.each { |csv_line| file.write csv_line }
    end
  end
end

# Start of our test suite.
describe PageRequest do
  it 'returns a 200 status code when a page exists' do
    page_request = PageRequest.new('https://mattisms.blog')
    page_request.fetch

    _(page_request.status_code).must_equal 200
  end

  it 'returns a 404 status code when a page does not exist' do
    page_request = PageRequest.new('https://mattisms.blog/blank')
    page_request.fetch

    _(page_request.status_code).must_equal 404
  end

  it 'returns a the pages title' do
    page_request = PageRequest.new('https://mattisms.blog')
    page_request.fetch

    _(page_request.title).must_match(/Mattism/)
  end
end

describe PagesCollection do
  def setup
    @pages = PagesCollection.new
    @pages.add('https://crawler-test.com/', 'Home')
  end

  it 'allows a link to be added to the pages collection' do
    _(@pages.size).must_equal 1
    _(@pages.urls).must_include 'https://crawler-test.com/'
  end

  it 'does not allow adding of duplicate urls' do
    @pages.add('https://crawler-test.com/', 'Home')

    _(@pages.size).must_equal 1
    _(@pages.urls).must_include 'https://crawler-test.com/'
  end

  it 'does not allow adding of duplicate urls with different status codes' do
    @pages.add('https://crawler-test.com/', 'Home', 500)

    _(@pages.find_by_url('https://crawler-test.com/').status_code).must_equal 200
  end

  it 'should indicate when a url already exists' do
    _(@pages.url_exists?('https://crawler-test.com/')).must_equal true
  end

  it 'exports all links to a csv file' do
    @pages.add('https://www.caseblocks.com/demo', 'Demo')
    @pages.add('https://www.caseblocks.com/products', 'Products')
    @pages.add('https://www.caseblocks.com/solutions', 'Solutions')
    @pages.add('https://www.caseblocks.com/about', 'About')
    csv_payload = @pages.csv_payload

    _(csv_payload).must_include "https://crawler-test.com/, 'Home', 200\n"
  end
end

# Start of the main script.
if Minitest.run
  puts "Tests passed! 😀 Proceeding to case crawler...\n\n\n"
  WebCrawler.new.crawl
else
  puts 'Test failed! 😧 Web crawl aborted.'
end