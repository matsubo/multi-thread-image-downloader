require 'logger'
require './Downloader'
#
#= Image downloader main script
#
logger = Logger.new(STDERR)

task = []

# number of list pges to download
min_page = 1
max_page = 3
min_page.upto(max_page) { |i| task << i }

# number of concurrency
concurrency = 5

threads = []
1.upto(concurrency) {
	threads << Thread.new do
		while true
			break if task.count() == 0
			begin
				page = task.pop()
				downloader = Downloader.new({:logger => logger })
				downloader.parseList(page)
			rescue RuntimeError => e
				logger.warn e.to_s
			end
		end
	end
	sleep 0.1
}


threads.each{|t| t.join }


