require 'open-uri'
require_relative 'body_parser'
require './lib/pg_db_config_parse'
require 'colorize'


# -------------------- TO DO ----------------------------------------------------------------
# Etant donné que les urls sont amenées à être modifiées, cela serait mieux de les initialiser ici
#Url au 26 avril 2016
#https://candidat.pole-emploi.fr/candidat/rechercheoffres/resultats/A_d$00e9veloppeur_DEPARTEMENT_95___P__________INDIFFERENT_______________________
@job = nil
@zipcode = nil
@url = "http://candidat.pole-emploi.fr/candidat/rechercheoffres/resultats/A_#{@job}_DEPARTEMENT_#{@zipcode}___P__________INDIFFERENT_________________"


# -------------------- SOME COMMENTS AND DATA TO SEE PROCESS ---------------------------------
@nb_urls_add = 0
@urls_before = CONN.exec( "SELECT * FROM parse;").to_a

puts "-------------- >>> IL Y A #{@urls_before.length} URL(S) AVANT INSERTION <<< ----------------"

# --------------------- Open url for list of jobs for a métier by departemenent -----------------

def document_by_url(url)
	begin
		open(url).read
	rescue
		false
	end
end

def not_nil(url)
	if url == nil
		false
		puts "urls are nil"
	else
		true
	end
end


def urls #---------------------- création d'urls listant le résultat de recherches pour un métier et un département donné

	# --------------------- Récupération de la liste des métiers ----------------------------
	job_list = CONN.exec("SELECT slug FROM job_lists").to_a
	jobs = []
	job_list.each do |job|
		jobs << job["slug"]
	end

#---------------------- traitement des exceptions dans les numéros de département français (il manque les Dom Tom)

	if ARGV[0] == nil or ARGV[0] == "20" or ARGV[0].to_i > 95
		puts "Le département #{ARGV[0]} n'existe pas, veuillez tapez un ou deux numéros de département valide svp : de 1 à 19, 2A, 2B, de 21 à 95"
	else

		if  ARGV[0] == "2A" || ARGV[0] == "2B"
			if ARGV[1] == nil
				ARGV[1] = ARGV[0]
			end
			corse = [ARGV[0], ARGV[1]]
			corse.map do |zipcode|
				puts zipcode

				
				jobs.map {|job| job.gsub!(/\s/,'$0020'); "http://candidat.pole-emploi.fr/candidat/rechercheoffres/resultats/A_#{job}_DEPARTEMENT_#{zipcode}___P__________INDIFFERENT_________________"}

			# La modification des nom de métiers (gsub pour remplacer espace par le code $0020)devraient être faite au moment de la création et modification de la base de données. Là ça crée une dépendance
		end.flatten

		else
			if ARGV[1] == nil
				ARGV[1] = ARGV[0]
			end
			(ARGV[0].to_i..ARGV[1].to_i).map do |zipcode|

				if zipcode < 10
					zipcode= "0#{zipcode}"
				else
					zipcode = "#{zipcode}"
				end

				jobs.map {|job| job.gsub!(/\s/,'$0020'); "http://candidat.pole-emploi.fr/candidat/rechercheoffres/resultats/A_#{job}_DEPARTEMENT_#{zipcode}___P__________INDIFFERENT_________________"}
			end.flatten			
		end
	end
end

# Nouvel objet pour vérifier le contenu du code source 
def doc
	::BodyParser.new
end

# Save job est la méthode principale ?
def save_job(params)
	puts "----------------- Method Save Job -------------".colorize(:yellow)


	puts "----------- valeur de params id -------------".colorize(:orange)
	#nouvelle url pour le detail, y'a le numéro d'offre...
	#https://candidat.pole-emploi.fr/candidat/rechercheoffres/detail/039PTTP/A_d$00e9veloppeur_DEPARTEMENT_95___P__________INDIFFERENT_______________________
	
	url = 'http://candidat.pole-emploi.fr/candidat/rechercheoffres/detail/' # + "#{params[:id]}"
	puts "----------valeur de url dans save_jobs ???? -------- #{url}"
	puts "------this is url parsed from search result for dpt : #{url}"


	#if doc.offer_unavailable(url) == false && doc.check_code_rome(url) == true && doc.check_is_a_city(url) == true

		CONN.exec("INSERT INTO parse (url, id) SELECT '#{url}', '#{params[:id]}' WHERE NOT EXISTS (select id from parse WHERE id = '#{params[:id]}')")

		# ----------------- COUNTING OFFERS ADDED NB -----------------------
		@urls_after = CONN.exec( "SELECT * FROM parse;").to_a
		@nb_urls_add = @urls_after.length - @urls_before.length
		puts "//////////// #{@nb_urls_add} URL(S) SAVED IN DB WITH THIS SCRIPT ///////////////".colorize(:green)
		puts "  >>> IL Y A #{@urls_after.length} URL(S) DS LA BDD APRES INSERTION <<< "

	#end
end

#----------------- Parse les urls métiers par départements pour récupérer l'id ----------
def get_ids_by_document(document)
	document.scan(/detailoffre\/(.*?);/).flatten # renvoie nil actuellement...
	# renvoie un tableau 
	# ["039RBTB", "039RQTM", "7883714", "7887004", "7890803", "7891189", "7892427", "039PTTP", "039QLJV", "7844383", "7844405", "7844411", "7844423", "7844434", "7844436", "7844467", "7844480", "7849022", "7849191", "7849266"]
end


#########
# MAIN #

if urls != nil
	urls.each do |url|
		puts "-- this is url result for dpt and job title : #{url} --".colorize(:blue)
		document = document_by_url(url)

		if document 
			puts "------------------there is a document --------------------".colorize(:green)
			ids = get_ids_by_document(document)
			ids.each {|id| save_job({:id=>id})}
			puts "------------------does it start save_job method ? --------------------".colorize(:red)
		end
	end
end
