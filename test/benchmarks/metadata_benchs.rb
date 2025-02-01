require 'ontologies_linked_data'
require_relative 'data_benchs'
module Benchmarks
  module Metadata

    def self.do_all_benchmarks
      # Benchmarks.bench("Fetch all ontologies (display=all)") do
      #   self.all_ontologies
      # end

      Benchmarks.bench("Fetch all submissions (display=all)") do
        Goo.logger.info("Fetching all submissions")
        self.all_submissions
      end
      # Benchmarks.bench("Old all submission query") do
      #   query = <<-SPARQL
      #     SELECT DISTINCT ?id ?attributeProperty ?attributeObject FROM <http://data.bioontology.org/metadata/OntologySubmission> WHERE { ?id a <http://data.bioontology.org/metadata/OntologySubmission> . OPTIONAL { { ?id ?attributeProperty ?attributeObject . FILTER(?attributeProperty = <http://data.bioontology.org/metadata/submissionId> || ?attributeProperty = <http://data.bioontology.org/metadata/prefLabelProperty> || ?attributeProperty = <http://data.bioontology.org/metadata/definitionProperty> || ?attributeProperty = <http://data.bioontology.org/metadata/synonymProperty> || ?attributeProperty = <http://data.bioontology.org/metadata/authorProperty> || ?attributeProperty = <http://data.bioontology.org/metadata/classType> || ?attributeProperty = <http://data.bioontology.org/metadata/hierarchyProperty> || ?attributeProperty = <http://data.bioontology.org/metadata/obsoleteProperty> || ?attributeProperty = <http://data.bioontology.org/metadata/obsoleteParent> || ?attributeProperty = <http://data.bioontology.org/metadata/createdProperty> || ?attributeProperty = <http://data.bioontology.org/metadata/modifiedProperty> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#URI> || ?attributeProperty = <http://www.w3.org/2002/07/owl#versionIRI> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#version> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#status> || ?attributeProperty = <http://www.w3.org/2002/07/owl#deprecated> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#hasOntologyLanguage> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#hasFormalityLevel> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#hasOntologySyntax> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#naturalLanguage> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#isOfType> || ?attributeProperty = <http://purl.org/dc/terms/identifier> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#description> || ?attributeProperty = <http://xmlns.com/foaf/0.1/homepage> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#documentation> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#notes> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#keywords> || ?attributeProperty = <http://www.w3.org/2004/02/skos/core#hiddenLabel> || ?attributeProperty = <http://purl.org/dc/terms/alternative> || ?attributeProperty = <http://purl.org/dc/terms/abstract> || ?attributeProperty = <http://data.bioontology.org/metadata/publication> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#hasLicense> || ?attributeProperty = <http://creativecommons.org/ns#useGuidelines> || ?attributeProperty = <http://creativecommons.org/ns#morePermissions> || ?attributeProperty = <http://schema.org/copyrightHolder> || ?attributeProperty = <http://data.bioontology.org/metadata/released> || ?attributeProperty = <http://purl.org/dc/terms/valid> || ?attributeProperty = <http://purl.org/pav/curatedOn> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#creationDate> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#modificationDate> || ?attributeProperty = <http://data.bioontology.org/metadata/contact> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#hasCreator> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#hasContributor> || ?attributeProperty = <http://purl.org/pav/curatedBy> || ?attributeProperty = <http://purl.org/dc/terms/publisher> || ?attributeProperty = <http://xmlns.com/foaf/0.1/fundedBy> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#endorsedBy> || ?attributeProperty = <http://schema.org/translator> || ?attributeProperty = <http://purl.org/dc/terms/audience> || ?attributeProperty = <http://usefulinc.com/ns/doap#repository> || ?attributeProperty = <http://usefulinc.com/ns/doap#bugDatabase> || ?attributeProperty = <http://usefulinc.com/ns/doap#mailingList> || ?attributeProperty = <http://purl.org/vocommons/voaf#toDoList> || ?attributeProperty = <http://schema.org/award> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#knownUsage> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#designedForOntologyTask> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#hasDomain> || ?attributeProperty = <http://purl.org/dc/terms/coverage> || ?attributeProperty = <http://purl.org/vocab/vann/example> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#conformsToKnowledgeRepresentationParadigm> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#usedOntologyEngineeringMethodology> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#usedOntologyEngineeringTool> || ?attributeProperty = <http://purl.org/dc/terms/accrualMethod> || ?attributeProperty = <http://purl.org/dc/terms/accrualPeriodicity> || ?attributeProperty = <http://purl.org/dc/terms/accrualPolicy> || ?attributeProperty = <http://www.isibang.ac.in/ns/mod#competencyQuestion> || ?attributeProperty = <http://www.w3.org/ns/prov#wasGeneratedBy> || ?attributeProperty = <http://www.w3.org/ns/prov#wasInvalidatedBy> || ?attributeProperty = <http://data.bioontology.org/metadata/pullLocation> || ?attributeProperty = <http://purl.org/dc/terms/isFormatOf> || ?attributeProperty = <http://purl.org/dc/terms/hasFormat> || ?attributeProperty = <http://rdfs.org/ns/void#dataDump> || ?attributeProperty = <http://data.bioontology.org/metadata/csvDump> || ?attributeProperty = <http://rdfs.org/ns/void#uriLookupEndpoint> || ?attributeProperty = <http://rdfs.org/ns/void#openSearchDescription> || ?attributeProperty = <http://purl.org/dc/terms/source> || ?attributeProperty = <http://www.w3.org/ns/sparql-service-description#endpoint> || ?attributeProperty = <http://schema.org/includedInDataCatalog> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#hasPriorVersion> || ?attributeProperty = <http://purl.org/dc/terms/hasPart> || ?attributeProperty = <http://kannel.open.ac.uk/ontology#ontologyRelatedTo> || ?attributeProperty = <http://kannel.open.ac.uk/ontology#similarTo> || ?attributeProperty = <http://kannel.open.ac.uk/ontology#comesFromTheSameDomain> || ?attributeProperty = <http://kannel.open.ac.uk/ontology#isAlignedTo> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#isBackwardCompatibleWith> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#isIncompatibleWith> || ?attributeProperty = <http://kannel.open.ac.uk/ontology#hasDisparateModelling> || ?attributeProperty = <http://purl.org/vocommons/voaf#hasDisjunctionsWith> || ?attributeProperty = <http://purl.org/vocommons/voaf#generalizes> || ?attributeProperty = <http://kannel.open.ac.uk/ontology#explanationEvolution> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#useImports> || ?attributeProperty = <http://purl.org/vocommons/voaf#usedBy> || ?attributeProperty = <http://schema.org/workTranslation> || ?attributeProperty = <http://schema.org/translationOfWork> || ?attributeProperty = <http://rdfs.org/ns/void#uriRegexPattern> || ?attributeProperty = <http://purl.org/vocab/vann/preferredNamespaceUri> || ?attributeProperty = <http://purl.org/vocab/vann/preferredNamespacePrefix> || ?attributeProperty = <http://identifiers.org/idot/exampleIdentifier> || ?attributeProperty = <http://omv.ontoware.org/2005/05/ontology#keyClasses> || ?attributeProperty = <http://purl.org/vocommons/voaf#metadataVoc> || ?attributeProperty = <http://data.bioontology.org/metadata/uploadFilePath> || ?attributeProperty = <http://data.bioontology.org/metadata/diffFilePath> || ?attributeProperty = <http://data.bioontology.org/metadata/masterFileName> || ?attributeProperty = <http://schema.org/associatedMedia> || ?attributeProperty = <http://xmlns.com/foaf/0.1/depiction> || ?attributeProperty = <http://xmlns.com/foaf/0.1/logo> || ?attributeProperty = <http://data.bioontology.org/metadata/metrics> || ?attributeProperty = <http://data.bioontology.org/metadata/submissionStatus> || ?attributeProperty = <http://data.bioontology.org/metadata/missingImports> || ?attributeProperty = <http://data.bioontology.org/metadata/ontology>)  } } }
      #   SPARQL
      #   Goo.sparql_query_client.query(query)
      # end
      #
      # Benchmarks.bench("New all submission query") do
      #   attribute_properties = [
      #     "http://data.bioontology.org/metadata/submissionId",
      #     "http://data.bioontology.org/metadata/prefLabelProperty",
      #     "http://data.bioontology.org/metadata/definitionProperty",
      #     "http://data.bioontology.org/metadata/synonymProperty",
      #     "http://data.bioontology.org/metadata/authorProperty",
      #     "http://data.bioontology.org/metadata/classType",
      #     "http://data.bioontology.org/metadata/hierarchyProperty",
      #     "http://data.bioontology.org/metadata/obsoleteProperty",
      #     "http://data.bioontology.org/metadata/obsoleteParent",
      #     "http://data.bioontology.org/metadata/createdProperty",
      #     "http://data.bioontology.org/metadata/modifiedProperty",
      #     "http://omv.ontoware.org/2005/05/ontology#URI",
      #     "http://www.w3.org/2002/07/owl#versionIRI",
      #     "http://omv.ontoware.org/2005/05/ontology#version",
      #     "http://omv.ontoware.org/2005/05/ontology#status",
      #     "http://www.w3.org/2002/07/owl#deprecated",
      #     "http://omv.ontoware.org/2005/05/ontology#hasOntologyLanguage",
      #     "http://omv.ontoware.org/2005/05/ontology#hasFormalityLevel",
      #     "http://omv.ontoware.org/2005/05/ontology#hasOntologySyntax",
      #     "http://omv.ontoware.org/2005/05/ontology#naturalLanguage",
      #     "http://omv.ontoware.org/2005/05/ontology#isOfType",
      #     "http://purl.org/dc/terms/identifier",
      #     "http://omv.ontoware.org/2005/05/ontology#description",
      #     "http://xmlns.com/foaf/0.1/homepage",
      #     "http://omv.ontoware.org/2005/05/ontology#documentation",
      #     "http://omv.ontoware.org/2005/05/ontology#notes",
      #     "http://omv.ontoware.org/2005/05/ontology#keywords",
      #     "http://www.w3.org/2004/02/skos/core#hiddenLabel",
      #     "http://purl.org/dc/terms/alternative",
      #     "http://purl.org/dc/terms/abstract",
      #     "http://data.bioontology.org/metadata/publication",
      #     "http://omv.ontoware.org/2005/05/ontology#hasLicense",
      #     "http://creativecommons.org/ns#useGuidelines",
      #     "http://creativecommons.org/ns#morePermissions",
      #     "http://schema.org/copyrightHolder",
      #     "http://data.bioontology.org/metadata/released",
      #     "http://purl.org/dc/terms/valid",
      #     "http://purl.org/pav/curatedOn",
      #     "http://omv.ontoware.org/2005/05/ontology#creationDate",
      #     "http://omv.ontoware.org/2005/05/ontology#modificationDate",
      #     "http://data.bioontology.org/metadata/contact",
      #     "http://omv.ontoware.org/2005/05/ontology#hasCreator",
      #     "http://omv.ontoware.org/2005/05/ontology#hasContributor",
      #     "http://purl.org/pav/curatedBy",
      #     "http://purl.org/dc/terms/publisher",
      #     "http://xmlns.com/foaf/0.1/fundedBy",
      #     "http://omv.ontoware.org/2005/05/ontology#endorsedBy",
      #     "http://schema.org/translator",
      #     "http://purl.org/dc/terms/audience",
      #     "http://usefulinc.com/ns/doap#repository",
      #     "http://usefulinc.com/ns/doap#bugDatabase",
      #     "http://usefulinc.com/ns/doap#mailingList",
      #     "http://purl.org/vocommons/voaf#toDoList",
      #     "http://schema.org/award",
      #     "http://omv.ontoware.org/2005/05/ontology#knownUsage",
      #     "http://omv.ontoware.org/2005/05/ontology#designedForOntologyTask",
      #     "http://omv.ontoware.org/2005/05/ontology#hasDomain",
      #     "http://purl.org/dc/terms/coverage",
      #     "http://purl.org/vocab/vann/example",
      #     "http://omv.ontoware.org/2005/05/ontology#conformsToKnowledgeRepresentationParadigm",
      #     "http://omv.ontoware.org/2005/05/ontology#usedOntologyEngineeringMethodology",
      #     "http://omv.ontoware.org/2005/05/ontology#usedOntologyEngineeringTool",
      #     "http://purl.org/dc/terms/accrualMethod",
      #     "http://purl.org/dc/terms/accrualPeriodicity",
      #     "http://purl.org/dc/terms/accrualPolicy",
      #     "http://www.isibang.ac.in/ns/mod#competencyQuestion",
      #     "http://www.w3.org/ns/prov#wasGeneratedBy",
      #     "http://www.w3.org/ns/prov#wasInvalidatedBy",
      #     "http://data.bioontology.org/metadata/pullLocation",
      #     "http://purl.org/dc/terms/isFormatOf",
      #     "http://purl.org/dc/terms/hasFormat",
      #     "http://rdfs.org/ns/void#dataDump",
      #     "http://data.bioontology.org/metadata/csvDump",
      #     "http://rdfs.org/ns/void#uriLookupEndpoint",
      #     "http://rdfs.org/ns/void#openSearchDescription",
      #     "http://purl.org/dc/terms/source",
      #     "http://www.w3.org/ns/sparql-service-description#endpoint",
      #     "http://schema.org/includedInDataCatalog",
      #     "http://omv.ontoware.org/2005/05/ontology#hasPriorVersion",
      #     "http://purl.org/dc/terms/hasPart",
      #     "http://kannel.open.ac.uk/ontology#ontologyRelatedTo",
      #     "http://kannel.open.ac.uk/ontology#similarTo",
      #     "http://kannel.open.ac.uk/ontology#comesFromTheSameDomain",
      #     "http://kannel.open.ac.uk/ontology#isAlignedTo",
      #     "http://omv.ontoware.org/2005/05/ontology#isBackwardCompatibleWith",
      #     "http://omv.ontoware.org/2005/05/ontology#isIncompatibleWith",
      #     "http://kannel.open.ac.uk/ontology#hasDisparateModelling",
      #     "http://purl.org/vocommons/voaf#hasDisjunctionsWith",
      #     "http://purl.org/vocommons/voaf#generalizes",
      #     "http://kannel.open.ac.uk/ontology#explanationEvolution",
      #     "http://omv.ontoware.org/2005/05/ontology#useImports",
      #     "http://purl.org/vocommons/voaf#usedBy",
      #     "http://schema.org/workTranslation",
      #     "http://schema.org/translationOfWork",
      #     "http://rdfs.org/ns/void#uriRegexPattern",
      #     "http://purl.org/vocab/vann/preferredNamespaceUri",
      #     "http://purl.org/vocab/vann/preferredNamespacePrefix",
      #     "http://identifiers.org/idot/exampleIdentifier",
      #     "http://omv.ontoware.org/2005/05/ontology#keyClasses",
      #     "http://purl.org/vocommons/voaf#metadataVoc",
      #     "http://data.bioontology.org/metadata/uploadFilePath",
      #     "http://data.bioontology.org/metadata/diffFilePath",
      #     "http://data.bioontology.org/metadata/masterFileName",
      #     "http://schema.org/associatedMedia",
      #     "http://xmlns.com/foaf/0.1/depiction",
      #     "http://xmlns.com/foaf/0.1/logo",
      #     "http://data.bioontology.org/metadata/metrics",
      #     "http://data.bioontology.org/metadata/submissionStatus",
      #     "http://data.bioontology.org/metadata/missingImports",
      #     "http://data.bioontology.org/metadata/ontology"
      #   ]
      #   total_count = 0
      #   chunks = attribute_properties.each_slice(100).to_a
      #   # Process each chunk and construct the query
      #   chunks.each_with_index do |chunk, index|
      #     query = <<-SPARQL
      #       SELECT ?id ?attributeProperty ?attributeObject
      #       FROM <http://data.bioontology.org/metadata/OntologySubmission>
      #       WHERE {
      #         ?id a <http://data.bioontology.org/metadata/OntologySubmission> .
      #
      #           ?id ?attributeProperty ?attributeObject .
      #           VALUES ?attributeProperty {
      #             #{chunk.map { |ap| "<#{ap}>" }.join(" ")}
      #           }
      #       }
      #     SPARQL
      #
      #     count = 0
      #     page = 1
      #     size = 50_000
      #     while count > 0 || page == 1
      #       r = Goo.sparql_query_client.query("#{query} LIMIT #{size} OFFSET #{(page-1)*size}")
      #       count = r.length
      #       total_count += count
      #       page+=1
      #     end
      #   end
      #   puts "Total count: #{total_count}"
      # end
    end

    def self.all_ontologies
      attr_ontology = LinkedData::Models::Ontology.attributes(:all)
      LinkedData::Models::Ontology.where.include(attr_ontology).all.count
    end

    def self.all_submissions
      attr_ontology = LinkedData::Models::Ontology.attributes(:all)
      attr = LinkedData::Models::OntologySubmission.attributes(:all)
      attr << { ontology: attr_ontology }
      LinkedData::Models::OntologySubmission.where.include(attr).all.count
    end
  end
end
