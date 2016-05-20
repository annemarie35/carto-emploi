require_relative 'body_parser'
require 'geocoder'
require 'geokit'
require 'time'
require 'colorize'
require './lib/pg_db_config_parse'

Geokit::default_units = :kms

#----------------------- NEW INSTANCE ----------------------
def doc
  ::BodyParser.new
end

# --------------- FIRST STEP : DELETE URL DUPLICATE FROM PARSE TABLE -------

puts "----------------Nombre de doublons #{CONN.exec("SELECT * FROM parse WHERE EXISTS (SELECT offer_id FROM job_offers WHERE (parse.id = job_offers.offer_id));").to_a.length}"
puts "#{CONN.exec( "SELECT url FROM parse").to_a.length} - Offers in PARSE database BEFORE cleaning"

CONN.exec( "DELETE FROM parse WHERE EXISTS (SELECT offer_id FROM job_offers WHERE (parse.id = job_offers.offer_id));")

puts "#{CONN.exec( "SELECT url FROM parse").to_a.length} - Offers in PARSE database AFTER cleaning"

#---------------- GETTING AN ARRAY OF URLS & IDS FROM DB ------------
@result = CONN.exec( "SELECT * FROM parse;").to_a

puts "------------------->>> IL Y A #{@result.length} URL(S) A TRAITER <<<------------------------"

nb_offres = @result.length #décompte de ce qu'il reste à insérer ^^
offre_ajout = 0

#---------test avec url d'offre indisponible --------

@result[0..@result.length].each do |item|
  nb_offres = nb_offres - 1
  puts "_______________________________ STARTING ___________________________________"
  puts "-------------------- OFFER ID de l' offre : #{item["id"]} ------------------ "
  puts "---- Disponibilité de l'offre : #{doc.offer_unavailable(item["url"])} (true = indisponible) ---------".colorize(:blue)
  #puts "---- Code rome : #{doc.check_code_rome(item["url"])} (true = code rome informatique) ---------".colorize(:light_blue)
  puts "---- Is a city : #{doc.check_is_a_city(item["url"])} (true = c'est bien une ville) ---------".colorize(:green)

  # if url is valid, it's inserted in job_offers table if not, it is deleted from parse table

  #&& doc.check_code_rome(item["url"]) == true -> le code rome n'aparrait plus sur le détail de l'offre au 27/04/2016

  if doc.offer_unavailable(item["url"]) == false && doc.check_is_a_city(item["url"]) == true
    adress = doc.search_region(item["url"]).gsub(/''/, "'")

    # Récupération du groupe de langage

    groupes  = {javascript: 'javascript', angular: 'javascript', rails: 'ruby' } #hash lang et son groupe
    @lang = doc.search_language(item["url"])
    @lang_gr = groupes[@lang]



    # le search_region fait déjà un gsub... A vérifier

    puts "-- #{nb_offres} offre(s) encore à parser sur #{@result.length} au départ-----"

    # ------------------- GETTING LATITUDE & LONGITUDE // GEOKIT ------------------------
    #if adress != "" && adress == adress.upcase
    #déjà vérifié par check_is_a_city

      geodata = Geokit::Geocoders::GoogleGeocoder.geocode(adress, :bias => 'fr').to_hash
      @latitude, @longitude = geodata[:lat], geodata[:lng]
      puts "Latitude BEFORE --------- #{@latitude} // Longitude  ------------ #{@longitude}"

      #change a little bit data to see offers in the map when we zoom
      @latitude += rand(0.0007..0.0019)
      @longitude += rand(0.0004..0.0019)

      puts "Latitude AFTER  --------- #{@latitude} // Longitude  ------------ #{@longitude}"
      sleep(1)

      # #------- Use Geocoder Gem --------
      # if latitude == nil
      # d = Geocoder.search(adress)
      # puts "this is d---------- #{d}"
      # ll = d[0].data["geometry"]["location"]
      # @latitude, @longitude  = ll['lat'], ll['lng']
      # @latitude += rand(0.0007..0.0019)
      # @longitude += rand(0.0004..0.0019)

      if @latitude != nil #sometimes geocoder does not work well cause it is a google free service and we have a limited nb of request per 24 hours

        #  ------------------- USING BODY PARSER TO GET OFFERS DATA  ---------------------

        time = Time.now
        #data = [doc.search_region(item["url"]), item["id"], doc.search_title(item["url"]), doc.search_employment_type(item["url"]), doc.search_code_rome(item["url"]), doc.search_publication_date(item["url"]), doc.search_description_offer(item["url"]), item["url"], doc.search_company_description(item["url"]), @latitude, @longitude, doc.search_language(item["url"]), @lang_gr, time]
        data = [doc.search_region(item["url"]), item["id"], doc.search_title(item["url"]), doc.search_employment_type(item["url"]), doc.search_publication_date(item["url"]), doc.search_description_offer(item["url"]), item["url"], doc.search_company_description(item["url"]), @latitude, @longitude, doc.search_language(item["url"]), @lang_gr, time]
        values = data.map {|v| "\'#{v}\'"}.join(',').to_s

        #CONN.exec("INSERT INTO job_offers (region_adress, offer_id, title, contrat_type, code_rome, publication_date, offer_description, url, company_description, latitude, longitude, lang, lang_gr, created_at) VALUES (#{values});")
        CONN.exec("INSERT INTO job_offers (region_adress, offer_id, title, contrat_type, publication_date, offer_description, url, company_description, latitude, longitude, lang, lang_gr, created_at) VALUES (#{values});")

        offre_ajout = offre_ajout + 1

        sleep(1)

        puts "---------------------------- DEBUT DE L'INSERTION -------------------------- "
        puts "------------ ADRESS de l'offre : #{doc.search_region(item["url"])}---------- "

        puts "--------------------------- OFFER INSERTED INTO DB :) ---------------------- ".colorize(:green)
        puts "-- #{nb_offres} offre(s) encore à parser sur #{@result.length} au départ-----"
        puts "__________ Nb d'offres insérées : #{offre_ajout}_____________________________"

      end #fin du test latitude !=nil

    else
      # delete urls
      CONN.exec("DELETE FROM parse WHERE url = '#{item["url"]}'")
      puts "-------- L'url #{item["url"]} a été supprimé de la bdd parse -------- ".colorize(:red)
  end
end
