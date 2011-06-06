require 'json'
require 'typhoeus'

API='testapi'
PASSWORD='testpass'
nameservers = ['ns1.example.com', 'ns2.example.com']


hydra = Typhoeus::Hydra.new(:max_concurrency => 5)
request = Typhoeus::Request.get("https://testapi.internet.bs/Domain/List?apiKey=#{API}&password=#{PASSWORD}&ResponseFormat=json")
domainarray = JSON.parse(request.body)['domain']


temparray = Marshal.load(Marshal.dump(domainarray))

(temparray.length).times do 
  domain=temparray.shift
  url= "https://testapi.internet.bs/Domain/Update?ApiKey=#{API}&Password=#{PASSWORD}&Domain=#{domain}&ResponseFormat=json&Ns_list="
  nameservers.each do |nameserver|
    url =  url + nameserver + ","
    url.chop
  end
  url = URI.encode(url)
  request = Typhoeus::Request.new(url,
  	  :method        => :get,
	  :headers       => {:Accept => "text/html"},
	  :timeout       => 50000, # milliseconds
	  :cache_timeout => 600, # seconds
  )

  request.on_complete do |response|
    response.success? or abort("request failed on #{url}")
    puts domain + ":" + JSON.parse(response.body)['status']
  end				
  hydra.queue(request)
end

hydra.run


domaininfo = []
temparray = Marshal.load(Marshal.dump(domainarray))

(temparray.length).times do 
  domain=temparray.shift
  url = URI.encode("https://testapi.internet.bs/Domain/Info?Domain=#{domain}&ApiKey=#{API}&Password=#{PASSWORD}&ResponseFormat=json")
  request = Typhoeus::Request.new(url,
	:method        => :get,
	:headers       => {:Accept => "text/html"},
	:timeout       => 50000, # milliseconds
	:cache_timeout => 600, # seconds
  )
  request.on_complete do |response|
    response.success? or abort("request failed on #{url}")
    domaininfo.push(JSON.parse(response.body)['nameserver'])
  end
				
  hydra.queue(request)
end

hydra.run


(domainarray.length).times do |domainnumber|
  domain = domainarray.shift
  puts "\nNameservers for #{domain}:"
  puts domaininfo[domainnumber]
end