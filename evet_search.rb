#!/usr/local/bin/ruby
# encoding: utf-8

require 'net/http'
require 'uri'
require 'json'
require 'date'
require 'cgi'

def get_events(year, month, word)
  
  ym = sprintf("%04d%02d", year, month)
  #puts "[#{ym}]"
  
  puts "<div class='debug'>"
  
  infos = []
  infos += eventon(ym, word)
  infos += doorkeeper(year, month, word)
  infos += connpass(ym, word)
  infos += atnd(ym, word)
  infos += zusaar(ym, word)
  
  puts "Total #{infos.length}件</div>"
  
  return infos
  
end

def get_json(url)
  
  uri = URI.parse(URI.escape(url))
  json = Net::HTTP.get(uri)
  #puts json
  begin
    result = JSON.parse(json)
  rescue
    result = JSON.parse("{}")
  end
  
  return result
  
end

# Doorkeeper
# https://www.doorkeeperhq.com/developer/api

def doorkeeper(y, m, word)
  
  y2 = (m == 12) ? y+1 : y
  m2 = (m == 12) ? 1 : m+1
  
  result = get_json("https://api.doorkeeper.jp/events/?locale=ja&sort=starts_at&since=#{y}-#{m}-01&until=#{y2}-#{m2}-01&q=#{word}")
  puts "Doorkeeper #{result.length}件, "

  infos = []
  
  result.each do |row|
    vals = row["event"]
    infos << {
      "title" => vals["title"],
      "started_at" => vals["starts_at"],
      "event_url" => vals["public_url"],
      "address"=> vals["address"]
    }
  end
    
  return infos
  
end

# eventon
# https://eventon.jp/info/api/

def eventon(ym, word)
  
  result = get_json("http://eventon.jp/api/events.json?prefecture_id=32&ym=#{ym}&limit=100")
  if result.length == 1 then
    puts "eventon ERROR., "
    return []
  end
  
  puts "eventon #{result["count"]}件, "
  
  infos = []
  
  result["events"].each do |val|
    infos << {
      "title" => val["title"],
      "started_at" => val["started_at"],
      "event_url" => val["event_url"],
      "address" => val["address"] + " " + val["place"]
    }
  end
  
  return infos
  
end

# connpass
# http://connpass.com/about/api/

def connpass(ym, word)
  
  result = get_json("http://connpass.com/api/v1/event/?keyword=#{word}&ym=#{ym}&count=100")
  puts "connpass 全#{result["results_available"]}件中 #{result["results_returned"]}件, "
  
  infos = []
  
  result["events"].each do |val|
    infos << {
      "title" => val["title"],
      "started_at" => val["started_at"],
      "event_url" => val["event_url"],
      "address" => val["address"]
    }
  end
  
  return infos
  
end

# ATND
# http://api.atnd.org

def atnd(ym, word)
  
  result = get_json("http://api.atnd.org/events/?format=json&keyword=#{word}&ym=#{ym}&count=100")
  puts "ATND #{result["results_returned"]}件, "
  
  infos = []
  
  result["events"].each do |row|
    val = row["event"]
    infos << {
      "title" => val["title"],
      "started_at" => val["started_at"],
      "event_url" => val["event_url"],
      "address" => val["address"] + " " + val["place"]
    }
  end
  
  return infos
  
end

# Zusaar
# http://www.zusaar.com/doc/api.html

def zusaar(ym, word)

  result = get_json("http://www.zusaar.com/api/event/?ym=#{ym}&count=100&keyword_or=#{word}")
  puts "Zusaar #{result["results_returned"]}件, "

  infos = []
  
  result["event"].each do |val|
    infos << {
      "title" => val["title"],
      "started_at" => val["started_at"],
      "event_url" => val["event_url"],
      "address" => val["address"] + " " + val["place"]
    }
  end
  
  return infos
end

nil

cal = Array.new(32) do |map|
  []
end

cgi = CGI.new
date = DateTime.now()

y = (cgi['y'].to_i > 0) ? cgi['y'].to_i : date.year
m = (cgi['m'].to_i > 0) ? cgi['m'].to_i : date.month

y1 = (m == 1) ? y-1 : y
m1 = (m == 1) ? 12 : m-1

y2 = (m == 12) ? y+1 : y
m2 = (m == 12) ? 1 : m+1

url = "http://" + ENV['HTTP_HOST'] + ENV['REQUEST_URI']
base, parm = url.split('?')
#puts base

w = (cgi['w'].to_s.length == 0) ? "松江" : cgi['w']

print <<EOF
Content-Type: text/html

<html>
<head>
  <title>#{w}のイベントカレンダー</title>
<style>
* {
  padding: 0px;
  margin: 0px;
  font-family: sans-serif;
  font-size: 11pt;
}
h1 {
  padding: 10px;
  font-size: 24pt;
  background-color: #933;
  color: #FFF;
}
h2 {
  text-align: right;
  font-size: 14pt;
}
input {
  padding: 2px;
}
.calendar {
  border-collapse: collapse;
  border: 2px solid #000;
  margin: 10px;
}
.calendar td, .calendar th {
  width: 10%;
  vertical-align: top;
  border: 1px solid #000;
  padding: 3px;
}
.calendar th {
  background-color: #933;
  padding: 10px 0px;
  color: #FFF;
}
.calendar .today {
  background-color: #CFC;
}
.calendar .sunday {
  background-color: #FEE;
}
.calendar .saturday {
  background-color: #EEF;
}
.calendar .blank {
  background-color: #EEE;
}
.link {
  padding: 10px;
  font-size: 14pt;
}
.debug {
  color: #999;
  padding: 0px 10px;
  clear: both;
}
a {
/*
  color: #F00;
*/
  text-decoration: none;
}
</style>
</head>
<body>
  <h1>#{w}のイベントカレンダー</h1>
EOF

puts <<EOF
<div class="link" style="float: left;">
  <a href="#{base}?y=#{y1}&m=#{m1}&w=#{w}">#{m1}月</a> |
  <a href="#{base}">#{y}年#{m}月</a> |
  <a href="#{base}?y=#{y2}&m=#{m2}&w=#{w}">#{m2}月</a>
</div>
<div class="link">
  <form action="./">
    <input type="text" name="w" value="#{w}" />
    <input type="submit" name="設定" />
  </form>
</div>
EOF


get_events(y,m,w).each do |row|
  
  date = DateTime.parse(row["started_at"])
  cal[date.day] << row
  
end

date = Date.new(y,m,1)

puts <<EOF
  <table border="1" class="calendar">
    <tr>
      <th>日</th>
      <th>月</th>
      <th>火</th>
      <th>水</th>
      <th>木</th>
      <th>金</th>
      <th>土</th>
    </tr>
    <tr>
EOF

(0..date.wday - 1).each do |i|
  puts "<td class='blank'>&nbsp;</td>"
end

i = 1
j = date.wday

cal[1,cal.length - 1].each do |events|
  
  if j % 7 == 0 then
    puts "</tr><tr>"
    j = 0
  end
  
  if Date.today() == Date.new(y,m,i) then
    puts "<td class='today'>"
  elsif j == 0 then
    puts "<td class='sunday'>"
  elsif j == 6 then
    puts "<td class='saturday'>"
  else
    puts "<td>"
  end
  
  puts "<h2>#{i}</h2>"
  
  events.each do |row|
    puts <<EOF
  <div>
    <a href="#{row["event_url"]}" target="_blank">#{row["title"]}</a><br />
    [#{row["address"]}]
  </div>
EOF
  end
  
  puts "</td>"
  
  i += 1
  j += 1
  
  begin
    Date.new(y,m,i)
  rescue
    break
  end
  
end

(0..6-j).each do |i|
  puts "<td class='blank'>&nbsp;</td>"
end

puts "</tr></table></html>"

