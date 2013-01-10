require 'test/unit'
require 'mac_vendor'

class MacVendorTest < Test::Unit::TestCase
  def setup
    @x = { :name=> "CIMSYS Inc",
           :address=> ["#301,Sinsung-clean BLDG,140, Nongseo-Ri,Kiheung-Eup",
                       "Yongin-City Kyunggi-Do 449-711",
                       "KOREA, REPUBLIC OF"] }
    @v = MacVendor.new :enable_network_tracking => true
  end

  def test_normalize_prefix
    [ 'aa-11-bb', 'aa:11:bb:22:cc:33', 'AA11BBCCDD22', 'aa-11-bb-00-00-00' ].each do |s|
      assert_equal @v.normalize_prefix(s), 'AA11BB'
    end
    assert_equal @v.normalize_prefix('junk'), ''
    assert_equal @v.network_hits, 0
  end
  
  def test_hyphen_prefix
    assert_equal @v.hyphen_prefix('AA11BB'), 'AA-11-BB'
    assert_equal @v.hyphen_prefix('junk'), 'ju-nk-'
    assert_equal @v.network_hits, 0
  end
  
  def test_fetch_single
    assert_equal @v.lookup('00:11:22:33:44:55'), @x
    assert_equal @v.lookup('00-11-22-33-44-55'), @x
    assert_equal @v.network_hits, 1
  end

  def test_fetch_single_not_found
    assert_equal @v.lookup('FF:FF:FF:33:44:55'), nil
    assert_equal @v.lookup('FF-FF-FF-33-44-55'), nil
    assert_equal @v.network_hits, 1
  end
  
  def test_preloaded_local
    mv = MacVendor.new :enable_network_tracking => true, :use_local => true
    assert_equal mv.network_hits, 0
    assert_equal mv.lookup('00-11-22-33-44-55'), @x
    assert_equal mv.network_hits, 0
    assert_equal mv.lookup('FF-FF-FF-33-44-55'), nil
    assert_equal mv.network_hits, 0
  end
  
  def test_preloaded
    @v.preload_cache
    assert_equal @v.network_hits, 1
    assert_equal @v.lookup('00-11-22-33-44-55'), @x
    assert_equal @v.network_hits, 1
    assert_equal @v.lookup('FF-FF-FF-33-44-55'), nil
    assert_equal @v.network_hits, 1
  end
end

