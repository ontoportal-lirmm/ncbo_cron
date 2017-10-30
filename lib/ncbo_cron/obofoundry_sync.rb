require 'base64'
require 'json'
require 'net/http'
require 'uri'

module NcboCron
  module Models
    class OBOFoundrySync

      # Map non-obsolete OBO ID spaces to BioPortal acronyms
      ACRONYMS = {
        aeo: "AEO", aero: "AERO", agro: "AGRO", apo: "APO", 
        bcgo: "OBI_BCGO", bco: "BCO", bfo: "BFO", bspo: "BSPO", bto: "BTO", 
        caro: "CARO", cdao: "CDAO", ceph: "CEPH", chebi: "CHEBI", cheminf: "CHEMINF", 
        chmo: "CHMO", cio: "CIO", cl: "CL", clo: "CLO", cmf: "CMF", cmo: "CMO", 
        cteno: "CTENO", cvdo: "CVDO", 
        ddanat: "DDANAT", ddpheno: "DDPHENO", dideo: "DIDEO", dinto: "DINTO", doid: "DOID", 
        dron: "DRON", duo: "DUO", 
        eco: "ECO", ehdaa2: "EHDAA2", emap: "EMAP", emapa: "EMAPA", envo: "ENVO", 
        eo: "PECO", ero: "ERO", exo: "EXO", 
        fao: "FAO", fbbi: "FBbi", fbbt: "FB-BT", fbcv: "FB-CV", fbdv: "FB-DV", fix: "FIX", 
        flopo: "FLOPO", fma: "FMA", foodon: "FOODON", fypo: "FYPO", 
        gaz: "GAZ", genepio: "GENEPIO", geno: "GENO", geo: "GEO", go: "GO", 
        hao: "HAO", hom: "HOM", hp: "HP", hsapdv: "HSAPDV", 
        iao: "IAO", ico: "ICO", ido: "IDO", idomal: "IDOMAL", 
        kisao: "KISAO",
        ma: "MA", mamo: "MAMO", mf: "MF", mfmo: "MFMO", mfoem: "MFOEM", mfomd: "MFOMD", 
        mi: "MI", miapa: "MIAPA", micro: "MICRO", mirnao: "MIRNAO", miro: "MIRO", 
        mmo: "MMO", mmusdv: "MMUSDV", mod: "PSIMOD", mondo: "MONDO", mop: "MOP", mp: "MP", 
        mpath: "MPATH", mro: "MHCRO", ms: "MS", 
        nbo: "NBO", ncbitaxon: "NCBITAXON", ncit: "NCIT", ncro: "NCRO", 
        oae: "OAE", oarcs: "OARCS", oba: "OBA", obcs: "OBCS", obi: "OBI", obib: "OBIB", 
        ogg: "OGG", ogi: "OGI", ogms: "OGMS", ogsf: "OGSF", ohd: "OHD", ohmi: "OHMI", 
        olatdv: "OLATDV", omiabis: "OMIABIS", omit: "OMIT", omp: "OMP", omrse: "OMRSE", 
        ontoneo: "ONTONEO", oostt: "OOSTT", opl: "OPL", ovae: "OVAE", 
        pato: "PATO", pco: "PCO", pdro: "PDRO", pdumdv: "PDUMDV", plana: "PLANA", po: "PO", 
        poro: "PORO", ppo: "PPO", pr: "PR", pw: "PW", 
        rex: "REX", rnao: "RNAO", ro: "RELO", rs: "RS", rxno: "RXNO", 
        sbo: "SBO", sep: "SEP", sibo: "SIBO", so: "SO", spd: "SPD", stato: "STATO", 
        swo: "SWO", symp: "SYMP", 
        tads: "TADS", taxrank: "TAXRANK", tgma: "TGMA", to: "PTO", trans: "PTRANS", 
        tto: "TTO", 
        uberon: "UBERON", uo: "UO", upheno: "UPHENO", 
        vario: "VARIO", vo: "VO", vt: "VT", vto: "VTO", 
        wbbt: "WB-BT", wbls: "WB-LS", wbphenotype: "WB-PHENOTYPE", 
        xao: "XAO", xco: "XCO", 
        zeco: "ZECO", zfa: "ZFA", zfs: "ZFS"
      }

      def run
        onts = get_obofoundry_ontologies
        onts.reject! { |ont| ont.key?("is_obsolete") }
        missing_onts = []

        # Are any OBO Library ontologies missing from BioPortal?
        if onts.size != ACRONYMS.size
          onts.each do |ont|
            if not ACRONYMS.key?(ont["id"].to_sym)
              missing_onts << ont
            end
          end
        end

        LinkedData::Utils::Notifications.obofoundry_sync(missing_onts)
      end

      def get_obofoundry_ontologies
        query = "query { 
                  repository(name: \"OBOFoundry.github.io\", owner: \"OBOFoundry\") {
                    object(expression: \"master:registry/ontologies.jsonld\") {
                      ... on Blob {
                        text
                      }
                    }
                  }
                }"

        oauth_token = Base64.decode64(NcboCron.settings.git_repo_access_token)
        uri = URI.parse("https://api.github.com/graphql")
        req_options = { use_ssl: uri.scheme == "https" }
        request = Net::HTTP::Post.new(uri)
        request["Authorization"] = "bearer #{oauth_token}"
        request.body = JSON.dump({"query" => query})
        
        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end

        parsed = JSON.parse(response.body)
        text = parsed.dig("data", "repository", "object", "text")
        ont_registry = JSON.parse(text)
        onts = ont_registry["ontologies"].to_a
        return onts
      end

    end
  end
end


