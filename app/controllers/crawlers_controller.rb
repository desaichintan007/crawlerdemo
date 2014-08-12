require 'rubygems'
require 'tf_idf'
class CrawlersController < ApplicationController

  def get_data

  end

  def show_data

    #uri = URI.parse('http://coderedsafety.com')
    #raise "#{uri.route_to('http://google.com').host} || #{uri.route_to('http://coderedsafety.com/locations.php').host}"
    #
    url_list = params[:list].split(" ")
    #raise "#{params[:element_type]} || #{params[:element_value]}"

    element_type = params[:element_type]
    find_content = nil

    unless params[:element_value].blank?
      case element_type
        when "tag"
          find_content = params[:element_value]
        when "class"
          find_content = ".#{params[:element_value]}"
        when "id"
          find_content = "\##{params[:element_value]}"
      end
    else
      find_content = "body"
    end

    @content_list = {}

    agent = Mechanize.new
    url_list.each do |link|
      http_type = nil
      data = agent.get("http://#{link}") rescue ""
      if data.blank?
        data = agent.get("https://#{link}") rescue ""
        http_type = "https://"
      else
        http_type = "http://"
      end

      body_content = data.body rescue ""

      if find_content=="body"
        # If full body is crawled then you can crawl all the links of that page as below
        body_links = Nokogiri::HTML(body_content).css("a")
        all_links = []
        absolute_links = []
        relative_links = []
        body_links.each do |a|
          all_links << a["href"]
        end

        (all_links.length == all_links.uniq.length) ? nil : (all_links.uniq!)

        all_links.each do |a|
          if a
            unless a[0..6] == "http://" || a[0..7] == "https://"
              relative_links << a
            end
          end
        end

        relative_links << relative_links[0]

        (relative_links.length == relative_links.uniq.length) ? nil : (relative_links.uniq!)

        uri = URI.parse("#{http_type}#{link}")
        (all_links-relative_links).each do |a|
          if a
            unless uri.route_to(a).host
              absolute_links << a
            end
          end
        end

        subcontent_list = {}
        relative_links.each do |a|
          unless a[a.length-4..a.length-1]==('.pdf') || a[a.length-4..a.length-1]==('.doc') || a=="#"
            if a
              if a[0]!="/"
                a="/#{a}"
              end
              p "111111111111111111111 #{a} | #{a[a.length-3..a.length-1]} 11111111111111111111111"
              temp_body_content = agent.get("#{http_type}#{link}#{a}").body rescue ""
              subcontent_list.merge!("#{http_type}#{link}#{a}" => (Nokogiri::HTML(temp_body_content).css(find_content).text rescue ""))
            end
          end
        end

        absolute_links.each do |a|
          unless a[a.length-4..a.length-1]==('.pdf') || a[a.length-4..a.length-1]==('.doc')
            p "22222222222222222222222 #{a} 222222222222222222222"
            temp_body_content = agent.get(a).body rescue ""
            subcontent_list.merge!(a => (Nokogiri::HTML(temp_body_content).css(find_content).text rescue ""))
          end
        end

        #raise subcontent_list.inspect
        content = subcontent_list

      else
        # If anything else is given into the value field, then go for that content only
        content = Nokogiri::HTML(body_content).css(find_content).text rescue ""
      end

      #unless data.blank?
      @content_list.merge!(link => content)
      #@content_list.each do |l,cnt|
      #  if lnk = Link.create(:url => l)
      #    cnt.each do |sl,scnt|
      #      Sublink.create(:url=>sl, :content=>scnt, :link_id=>lnk.id)
      #    end
      #  end
      #end
      #end
    end

    all_links = Link.pluck(:url)
    all_links_full = Link.all
    @content_list.each do |link_tmp,content_tmp|
      unless all_links.include?(link_tmp)
        # If the main link is not present into the database
        if new_link_tmp = Link.create(:url => link_tmp)
          content_tmp.each do |sublink_tmp,subcnt_tmp|
            Sublink.create(:url => sublink_tmp, :content => subcnt_tmp, :link_id => new_link_tmp.id)
          end
        end
      else
        # If the main link is present into the database
        all_sub_links = all_links_full.where(:url=>link_tmp).first.sublinks
        content_tmp.each do |sublink_tmp,subcnt_tmp|
          aaa = all_sub_links.where(:url=>sublink_tmp)
          if aaa.present?
            # If the sublink is present into the database, then update it
            aaa.first.update_attributes(:content=>subcnt_tmp)
          else
            # If the sublink is not present into the database, then create one
            Sublink.create(:url=>sublink_tmp,:content=>subcnt_tmp,:link_id=>Link.find_by_url(link_tmp).id)
          end
        end
      end
    end

  end


  def search_data

    @search_word = params[:search_word]
    @search_results = nil
    link_id = Link.where(:url => params[:link]).last.id.to_i

    search_wrd = @search_word

    unless search_wrd.blank?
      search = Sublink.search do
        fulltext "#{search_wrd}" do
          highlight :content
        end
        with :link_id, link_id
        paginate :page => params[:page], :per_page => 10
      end
      @search_results = search
    end

  end




  def search_links
    @search_word = params[:search_word]
    @search_results = nil

    search_wrd = @search_word
    unless search_wrd.blank?

      search = Sublink.search do
        fulltext "#{search_wrd}" do
          highlight :content
        end
        paginate :page => params[:page], :per_page => 10
      end

      @links_list = []
      search.each_hit_with_result do |l,c|
        root_link = c.url.split("/")
        @links_list << root_link[2]
      end
      @links_list.uniq!
    end
  end





  def crawled_links_list

    @sublinks_hash = {}
    @links = Link.all
    @links.each do |link|
      #@sublinks_hash = {}
      @sublinks_ary = []

      link.sublinks.each do |sublink|
        data = [sublink.content.split(" ")]
        a = TfIdf.new(data)
        a.tf.first.sort_by {|_key, value| value}.each do |asd|
          @sublinks_ary << asd
        end
        #raise a.tf.first.sort_by {|_key, value| value}.inspect
        #@sublinks_hash.merge!(sublink.url => a.tf.first.sort_by {|_key, value| value})
      end

      @sublinks_hash.merge!(link => @sublinks_ary.sort_by {|_key, value| value}[0..24])

    end


  end

  def tf_idf_results

    link = Link.find(params[:id])
    @sublinks_hash = {}
    asd = nil

    link.sublinks.each do |sublink|
      text = Highscore::Content.new sublink.content
      #raise text.keywords.top(text.keywords.length).inspect
      asd =  text.keywords.top(text.keywords.length)
      ary = []
      asd.each do |aa|
        ary << aa.text
      end
      #raise ary.inspect
      @sublinks_hash.merge!(sublink.url => ary)

      #data = [sublink.content.split(" ")]
      #a = TfIdf.new(data)
      #@sublinks_hash.merge!(sublink.url => a.tf.first.sort_by {|_key, value| value})
    end


    # Get the unique words list

    #@all_words = []
    #@sublinks_hash.each do |k,v|
    #  v.each do |v1|
    #    @all_words << v1[0]
    #  end
    #end
    #
    #@counting_words = {}
    #@all_words.each { |e| (@counting_words[e] += 1) rescue (@counting_words[e] = 1) }
    #
    #@uniq_words = []
    #
    #@counting_words.each do |wrd|
    #  if wrd[1]==1
    #    @uniq_words << wrd[0]
    #  end
    #end

  end

end