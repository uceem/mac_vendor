require 'net/http'

class MacVendor
  OUI_FULL_URL = 'http://www.ieee.org/netstorage/standards/oui.txt'
  OUI_SINGLE_URL = 'http://standards.ieee.org/cgi-bin/ouisearch?'  # ex: http://standards.ieee.org/cgi-bin/ouisearch?00-11-22
  
  def initialize(opts={})
    @prefix_cache = {}
    @preloaded = false
    @network_hits = 0 if opts[:enable_network_tracking]
    preload_cache_via_local_data if opts[:use_local]
  end
  
  def lookup(mac)
    prefix = self.normalize_prefix mac
    return @prefix_cache[prefix] if @preloaded or @prefix_cache.has_key?(prefix)
    @prefix_cache[prefix] = fetch_single(prefix)
  end

  # Attempts to turn anything MAC-like into the first six digits, e.g.: AABBCC
  def normalize_prefix(mac)
    mac.strip.upcase.gsub(/^0[xX]/,'').gsub(/[^0-9A-F]/,'')[0..5]
  end
  
  # Converts a normalized prefix into something with hyphens, e.g.: AA-BB-CC
  def hyphen_prefix(p)
    "#{p[0..1]}-#{p[2..3]}-#{p[4..5]}"
  end

  def get_url(url)
    @network_hits +=1 unless @network_hits.nil?
    Net::HTTP.get URI(url)
  end

  def fetch_single(prefix)
    single_txt = get_url OUI_SINGLE_URL + hyphen_prefix(prefix)
    
    if single_txt =~ /The public OUI listing contains no match for the query/
      return @prefix_cache[prefix] = nil
    end
    
    if single_txt.gsub(/[\r\n]/,"\t") =~ /([0-9A-F]+)\s+\(base 16\)(.*?)pre/
      mac_prefix = normalize_prefix $1
      lines = $2.strip.split("\t")
      company_name = lines[0]
      company_address = lines[1..-2].reject {|x| x.strip == ''}

      return @prefix_cache[prefix] = {:name => company_name, :address => company_address}
    end
    nil
  end
  
  def preload_cache_via_string(oui_txt)
    # First entry is a header
    entries = oui_txt.gsub(/\r\n/, "\n").split(/ *\n *\n/)

    entries[1..-1].each do |entry|
      base16_fields = entry.strip.split("\n")[1].split("\t")
      mac_prefix = base16_fields[0].strip[0..5]
      company_name = base16_fields[-1]
      company_address = entry.strip.gsub("\t",'').split("\n")[2..-1].map {|x| x.strip}

      # This actually happens three times in the current dataset!
      unless @prefix_cache[mac_prefix].nil?
        #puts "MAC PREFIX COLLISION: #{mac_prefix}"
        #puts "CURRENT = #{@prefix_cache[mac_prefix].inspect}"
        #puts "NEW = #{{:name => company_name, :address => company_address}.inspect}"
        #raise "MAC prefix key collision: #{mac_prefix}"
        next
      end
    
      @prefix_cache[mac_prefix] = {:name => company_name, :address => company_address}
    end
    @preloaded = true
  end

  def preload_cache_via_local_data
    local_path = File.expand_path(File.dirname(__FILE__) + "/../data/oui.txt.gz")
    preload_cache_via_string Zlib::GzipReader.open(local_path).read
  end
  
  def preload_cache
    preload_cache_via_string get_url(OUI_FULL_URL)
  end
  
  def network_hits
    @network_hits
  end
end

