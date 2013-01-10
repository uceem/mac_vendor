require 'net/http'

class MacVendor
  OUI_FULL_URL = 'http://standards.ieee.org/develop/regauth/oui/oui.txt'
  OUI_SINGLE_URL = 'http://standards.ieee.org/cgi-bin/ouisearch?'  # ex: http://standards.ieee.org/cgi-bin/ouisearch?00-11-22
  
  def initialize(opts={})
    @prefix_cache = {}
    @preloaded = false
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

  def fetch_single(prefix)
    #single_txt = Net::HTTP.get URI(OUI_SINGLE_URL + hyphen_prefix(prefix))
    single_txt = File.open('/tmp/search.out').read
    
    if single_txt =~ /The public OUI listing contains no match for the query/
      return @prefix_cache[prefix] = nil
    end
    
    if single_txt.gsub(/[\r\n]/,"\t") =~ /([0-9A-F]+)\s+\(base 16\)(.*?)pre/
      mac_prefix = normalize_prefix $1
      lines = $2.strip.split("\t")
      company_name = lines[0]
      company_address = lines[1..-2].reject {|x| x == ''}

      return @prefix_cache[prefix] = {:name => company_name, :address => company_address}
    end
    nil
  end
  
  # todo -- test by preloading one instance and not another, and then spot checking
  # todo -- write tests
  
  def preload_cache_via_string(oui_txt)
    oui_txt = Net::HTTP.get URI(OUI_FULL_URL)

    # First entry is a header
    entries = oui_txt.split("\n\n")

    entries[1..-1].each.strip do |entry|
      base16_fields = entry.split("\n")[1].split("\t")
      mac_prefix = base16_fields[0][0..5]
      company_name = base16_fields[-1]
      company_address = entry.gsub("\t",'').split("\n")[2..-1]

      raise "MAC prefix key collision" unless @prefix_cache[mac_prefix].nil?
      @prefix_cache[mac_prefix] = {:name => company_name, :address => company_address}
    end
    @preloaded = true
  end

  def preload_cache_via_local_data
    local_path = File.expand_path(File.dirname(__FILE__) + "/../data/oui.txt.gz")
    preload_cache_via_string Zlib::GzipReader.open(local_path).read
  end
  
  def preload_cache
    preload_cache_via_string Net::HTTP.get URI(OUI_FULL_URL)
  end
end

