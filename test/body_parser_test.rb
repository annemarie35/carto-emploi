require 'minitest/autorun'
require_relative '../parser/body_parser'

require File.expand_path '../test_helper.rb', __FILE__


class BodyParserTest < Minitest::Test

  #Aller voir ce github pour voir comment refactorer ses tests : https://github.com/seattlerb/minitest

  print ">>>> HEY !!!!!! Start a server with $ruby -run -e httpd . -p 8000 --------------"

  URL = "http://0.0.0.0:8000/test/offre_test_027FLJF.html"

  def doc
    ::BodyParser.new
  end

  def test_1_find_region
    #url = "http://0.0.0.0:8000/test/offre_test_027FLJF.html"
    expected = "75 , PARIS 16E  ARRONDISSEMENT, FRANCE"
    assert_equal expected, doc.search_region(URL)
  end

  def test_2_search_job_title
    url = "http://0.0.0.0:8000/test/offre_test_027FLJF.html"
    expect = "Développeur / Développeuse web"
    assert_equal expect, doc.search_title(url)
  end

  def test_2_search_employment_type
    url = "http://0.0.0.0:8000/test/offre_test_027FLJF.html"

    #expect = "Contrat à durée indéterminée\n"
    #"Contrat à durée déterminée - 6 Mois"
    expect = "Contrat à durée indéterminée"
    assert_equal expect, doc.search_employment_type(url)
  end

  def test_3_find_code_rome
    url = "http://0.0.0.0:8000/test/offre_test_027FLJF.html"
    #expect = "Métier du ROME E1101 -\nAnimation de site multimédia"
    expect = "E1101"
    assert_equal expect, doc.search_code_rome(url)
  end

  def test_4_find_publication_date
    url = "http://0.0.0.0:8000/test/offre_test_027FLJF.html"
    expect = "27/04/2016"

    assert_equal expect, doc.search_publication_date(url)
  end

  def test_5_job_offers_Description
    url = "http://0.0.0.0:8000/test/offre_test_027FLJF.html"
    expect = "Intégré(e) au sein d'une équipe d'une trentaine de personnes, organisée en projets et avec une gestion agile, vous principales missions sont:<br>- Développer et maintenir des applications web de gestion et traitements de contenu principalement développées en JAVA (JEE/GWT) et Javascript<br>- Assurez une veille technologique constante pour rester au plus haut niveau et garantir une adaptation des applications existantes reflétant l'état de l'art du domaine<br><br>De formation ingénieur informatique ou équivalent (Bac+5), vous justifiez d'une expérience significative d'au moins 3 ans sur un poste similaire. .<br><br>Compétences techniques requises<br>- JEE, GWT, JavaScript (JQuery, AngularJS, OpenLayer,) HTML, CSS<br>- Maîtrise de Linux<br><br>Aptitudes personnelles<br>Rigueur, autonomie, méthode, dynamisme, capacité d'analyse et de et de travail en équipe qui vous permettront de vous adapter rapidement à un environnement technique."
    assert_equal expect, doc.search_description_offer(url)
  end

  def test_6_Company_Description
    url = "http://0.0.0.0:8000/test/offre_test_027FLJF.html"
    expect = "INFO MAX"
    assert_equal expect, doc.search_company_description(url)
  end

  def test_7_Offre_Non_Disponible
    url = "http://0.0.0.0:8000/test/offre_non_disponible.html"
    assert_equal true, doc.offer_unavailable(url)
  end

  def test_8_Paris_dep_devient_ville
    url = "http://0.0.0.0:8000/test/offre_test_paris_dpt.html"
    expect = "75 , PARIS , FRANCE"
    assert_equal expect, doc.search_region(url)
  end

  def test_9_Est_bien_une_ville
    url = "http://0.0.0.0:8000/test/offre_test_027FLJF.html"
    assert_equal true, doc.check_is_a_city(url)
  end

end
