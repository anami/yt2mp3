#!/usr/bin/ruby
# Youtube to MP3 ruby script
# (c) anamii
#
# Thanks to Hpricot - this would never have been so easy..

# requires..
require 'rubygems'
require 'pp'
require 'hpricot'
require 'net/http'
require 'uri'


class SongLink
	attr_accessor :title, :url
end

class YT2MP3
  # constants..
  YT_URL        = "http://www.youtube.com"
  V_URL         = "/watch?="
  S_URL         = "/results?search_query={0}&aq=0"
  G_URL         = "/get_video?video_id={0}&t={1}"
  FORMATS       = {
    '5'   => {   :label => "FLV 240p",   :type => "flv"  },
    '18'  => {   :label => "MP4 360p",   :type => "mp4"  },
    '22'  => {   :label => "MP4 720p",   :type => "mp4"  },
    '34'  => {   :label => "FLV 360p",   :type => "flv"  },
    '35'  => {   :label => "FLV 480p",   :type => "flv"  },
    '37'  => {   :label => "MP4 1080p",  :type => "mp4"  },
    '38'  => {   :label => "MP4 4K",     :type => "mp4"  },
    '43'  => {   :label => "webM 360p",  :type => "webm" },
    '44'  => {   :label => "webM 480p",  :type => "webm" },
    '45'  => {   :label => "webM 720p",  :type => "webm" }}
  FORMAT_ORDER  = ['5','18','34','43','35','44','22','45','37','38'];
  MAX_RESULTS   = 6
  USERAGENT     = "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.0)"


  def self.start
    puts "---------------------------------"
    puts "yt2mp3 - YouTube to mp3 converter"
    puts "Requires ffmpeg to be present in the folder or in your system."
    puts "Type: !q or nothing to quit"
    puts "---------------------------------"
    search_string = ask_for_song
    while (search_string)


      songs = search_youtube(search_string, MAX_RESULTS)
      if (songs)
        len = (songs.length > MAX_RESULTS) ? MAX_RESULTS : songs.length
        (0..len-1).each do |i|
          puts "#{i+1} - #{songs[i].title} - #{songs[i].url}"
        end

        puts "Choose a song (1 to #{len} / q to quit)"
        begin
          song_num = gets.chomp.to_i
          if song_num >= 1 && song_num <= len
            fetch_song(songs[song_num-1])
          end
        rescue
          #do nothing here..
        end
      end
      search_string = ask_for_song
    end
  end

  private

  def self.ask_for_song
    puts "Search for a song (be specific): [Type nothing to quit] "
    search_string = gets.chomp.to_s
    if search_string == "" || search_string.downcase == "!q" || search_string == nil then return nil else return search_string end
  end

  def self.search_youtube(search_string, max_results = 5)
    uri = URI.parse(YT_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    search_url = S_URL.gsub("{0}",get_querystring(search_string))
    request = Net::HTTP::Get.new(search_url, {"User-Agent" => USERAGENT})
    response = http.request(request)
    songslinks = []

    if response
      doc = Hpricot(response.body)
      links = doc.search("a[@class*=yt-uix-tile-link]")
      result_num = 0
      links.each do |link|
        if link
          link_url = link.get_attribute("href").to_s
          if link_url.index('watch') && !link_url.index('&')
            link_title = nil
            begin
              link_title = link.get_attribute("title").to_s
              if (link_title.length == 0) then link_title = search_string end
            rescue
              #don't process this link..
            ensure
              if link_title
                s = SongLink.new
                s.title = link_title
                s.url = link_url
                songslinks.push(s)
                result_num += 1
                break if (result_num == max_results)
              end
            end
          end
        end
      end
    end
    return songslinks
  end

  def self.get_querystring(search)
    search = search.gsub(" ","+")
    search
  end

  def self.fetch_song(songlink)
    puts "Downloading #{songlink.title} - #{songlink.url}"
    uri = URI.parse(YT_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(songlink.url, {"User-Agent" => USERAGENT})
    response = http.request(request)

    if (response)
      doc = Hpricot(response.body)

      # get videoID, temporary ticket and formats map
      flash_values = (doc/"#watch-player").inner_html
      if (!flash_values || flash_values.length == 0) then flash_values = doc.inner_html end
      
      video_id_matches = flash_values.scan(/(?:"|amp;)video_id=([^(\&|$|\\)]+)/)
      video_ticket_matches = flash_values.scan(/(?:"|amp;)t=([^(\&|$|\\)]+)/)
      video_format_matches = flash_values.scan(/(?:"|amp;)url_encoded_fmt_stream_map=([^(\&|$|\\)]+)/)

      video_id, video_ticket, video_formats = nil, nil, nil

      begin
        video_id = (video_id_matches) ? video_id_matches[0][0] : nil
        video_ticket = (video_ticket_matches) ? video_ticket_matches[0][0] : nil
        video_formats = (video_format_matches) ? video_format_matches[0][0] : nil
      rescue
        puts "Can't seem to get to the video - please choose another next time"
        return
      end


      if (!video_id && !video_formats)
        puts "Problem downloading.."
        return
      end

      # parse the formats map
      sep1, sep2, sep3 = '%2C', '%26', '%3D'
      i = video_formats.index(',')
      if (i && i > -1)
        sep1=','
        sep2=(video_formats.index('&')>-1)?'&':'\\u0026'
        sep3='='
      end

      # fill in the list of video urls indexed by format
      video_urls = {}
      video_formats_group = video_formats.split(sep1)

      video_formats_group.each do |video_format|
        video_format_element = video_format.split(sep2)
        next if (video_format_element.length < 5)

        partial_result1 = video_format_element[0].split(sep3)
        next if (partial_result1.length < 2)
        url = partial_result1[1];
        url = URI.unescape(URI.unescape(url)).gsub(/\\\//,'/').gsub(/\\u0026/,'&')

        partial_result2 = video_format_element[4].split(sep3)
        next if (partial_result2.length < 2)
        itag = partial_result2[1];
        if (url.downcase.index('http') == 0)
          full_url = url + "&title=#{URI.encode(songlink.title)}"
          if FORMATS.has_key?(itag)
            video_urls[itag] = {:url => full_url, :format => FORMATS[itag][:type]}
          end
        end
      end



      # for music - we don't need to download the highest quality video
      # usually the higher formats are for video and audio quality seems to be the same
      # download urls with format 18, 34 and 35
      format = '18'
      if (video_urls.key?('18'))
        format = '18'
      elsif (video_urls.key?('34'))
        format = '34'
      elsif (video_urls.key?('35'))
        format = '35'
      else
        # we are desperate here..
        format = '5'
      end

      download_song(songlink.title, video_urls[format][:url], video_urls[format][:format] )
    end
  end

  def self.download_song(title, url, ext)
    puts "Downloading from #{url}"
    uri = URI(url)
    # remove any problematic characters from the filename - this time remove " ' / \ : ; ? ! £ # $ % ^ *
    title = title.gsub(/[\"\'\/\\:;?!£#\$%^*]+/,'')
    file_name = "#{title}.#{ext}"
    http = Net::HTTP.new(uri.host, uri.port)
    file_downloaded = false

    begin
      request = Net::HTTP::Get.new(uri.request_uri, {"User-Agent" => USERAGENT} )
      response = http.request(request)

      file = open(file_name, "wb")
      file.write(response.body)
      file_downloaded = true
    rescue
      file_downloaded = false
    ensure
      file.close
    end

    convert_song(title, file_name) if file_downloaded
  end

  def self.convert_song(title, file_name)
    puts "Converting to mp3"
    mp3file = "#{title}.mp3"
    ffmpeg_cmd = "ffmpeg"
    if ENV['OS']
      if ENV['OS'].downcase.index("windows")
        ffmpeg_cmd = "ffmpeg.exe"
      end
    end
    `#{ffmpeg_cmd} -i "#{file_name}" -vn -ac 2 -ab 128k -ar 44100 -f mp3 -vol 400 "#{mp3file}"`

    # clean up
    if File.exist?(file_name) then File.delete(file_name) end
  end

end

# main starting point..
# just check if we are using OCRA to package the program as an EXE not to run the program..
if not defined?(Ocra)
  YT2MP3.start
end

