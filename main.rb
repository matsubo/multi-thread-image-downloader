# frozen_string_literal: true

require 'logger'
require './Downloader'
#
#= Image downloader main script
#
logger = Logger.new(STDERR)

task = []

# number of list pges to download
min_page = 1
max_page = 1

min_page.upto(max_page) { |i| task << i }

# number of concurrency
concurrency = 5

threads = []
1.upto(concurrency) do
  threads << Thread.new do
    loop do
      break if task.count == 0

      begin
        page = task.pop
        # downloader = Downloader.new({ :proxy => 'http://212.90.161.214:3128/', :logger => logger })
        downloader = Downloader.new(logger: logger)
        downloader.parseList(page)
      rescue RuntimeError => e
        logger.warn e.to_s
      end
    end
  end
  sleep 0.1
end

(Thread.list - [Thread.current]).each &:join
