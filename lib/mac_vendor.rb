require 'net/http'

class MacVendor
  OUI_FULL_URL = 'http://standards.ieee.org/develop/regauth/oui/oui.txt'
  OUI_SINGLE_URL = 'http://standards.ieee.org/cgi-bin/ouisearch?'  # ex: http://standards.ieee.org/cgi-bin/ouisearch?00-11-22
  
  def initialize
    @prefix_cache = {}
    @preloaded = false
  end
  
  def lookup(mac)
    prefix = self.normalize_prefix mac
    return @prefix_cache if @preloaded
    @prefix_cache[prefix] or @prefix_cache[prefix] = fetch_single(prefix)
    # todo -- missing case where we found a nil witha  single lookup; we're re-looking up now.
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
    
    return nil if single_txt =~ /The public OUI listing contains no match for the query/
    
    puts single_txt
    
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
  
  def preload_cache
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
end

