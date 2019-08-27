require "bundler/setup"
Bundler.require


require 'open-uri'
require 'tempfile'
require 'digest/md5'
require 'logger'

#
#= Image downloader for fire uploader
#
# Authors::   Yuki Matsukura
# Web::       https://matsu.teraren.com/blog/
# Version::   1.0 2012-07-28 Yuki Matsukura
# License::   CC BY-ND 2.1 http://creativecommons.org/licenses/by-nd/2.1/jp/
#
#== Histroy
# - 2012-07-28 Created
class Downloader
  attr_reader :logger

  # sleep after download a file.
  @@WAIT_TIME = 1

  # count of fail over
  @@MAX_FAILURE_COUNT = 5

  #
  # constructor
  #
  def initialize(params)
    @open_params = { :proxy => params[:proxy] || nil, 'User-Agent' => 'Mozilla/5.0 (iPad; U; CPU OS 4_3_5 like Mac OS X; ja-jp) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8L1 Safari/6533.18.5' || nil }
    @fail_count = 0
    @logger = params[:logger] || Logger.new(STDERR)
    @output = params[:output] || 'images'
  end

  #
  # parse the list page
  #
  def parseList(page = 1)
    url = format('http://up.pandoravote.net/up/index.php?page=%d&gal=1&mode=list&sword=&andor=', page)

    logger.info url

    doc = Nokogiri::HTML(open(url, @open_params))
    doc.xpath('//td[@class="img"]/a[@onclick][1]').each do |link|
      id = link.get_attribute('href').gsub!(/\D/, '')

      # comment out to parse the single page and find download link.
      #      self.parsePage(id)
      download('http://up.pandoravote.net/up/img/pandoraup' + id + '.jpg')
    end
  end

  #
  # parse the single download page
  #
  def parsePage(id = '00136024')
    url = format('http://up.pandoravote.net/up/index.php?id=%s', id)

    logger.info url

    begin
      doc = Nokogiri::HTML(open(url, @open_parms))
    rescue OpenURI::HTTPError => e
      logger.error e.to_s
    end

    doc.xpath('//a[@href]').each do |a_tag|
      path = a_tag.get_attribute('href')
      if path =~ %r{^/up/img}
        download('http://up.pandoravote.net' + path)
      elsif path =~ %r{^http://up\.pandoravote\.net/up/img}
        download(path)
      end
    end
    sleep @@WAIT_TIME
  end

  #
  # Download the file
  #
  def download(url = 'http://up.pandoravote.net/up/img/pandoraup00136024.jpg')
    # fail over
    raise 'Max failure count is exceeded.' if @@MAX_FAILURE_COUNT <= @fail_count

    logger.info url

    temp = Tempfile.new('', './tmp')

    begin
      open(url, @open_params) do |source|
        temp.puts source.read
      end

      extension = File.extname(url)

      destination = @output + '/' + fileToPath(Digest::MD5.file(temp.path).hexdigest) + extension

      # directory check
      unless File.directory?(File.dirname(destination))
        FileUtils.mkdir(File.dirname(destination))
      end

      # file check
      if File.file?(destination)
        logger.warn 'File already exists'
        @fail_count += 1
        return
      end

      FileUtils.copy_file(temp.path, destination)
      FileUtils.chmod(0o644, destination)

      @fail_count = 0

      logger.debug 'OK'
    rescue OpenURI::HTTPError => e
    rescue URI::InvalidURIError => e
    rescue Timeout::Error
      logger.error e.to_s
    end
  end

  #
  # Return file path corersponding to the file name.
  #
  def fileToPath(path = '86583c72275a8ca9214af5a0e4356a7f')
    path.insert(2, File::SEPARATOR)
  end
end
