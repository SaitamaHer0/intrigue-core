module Intrigue
  module Task
    class SearchPulsedive < BaseTask

      def self.metadata
        {
          :name => "search_pulsedive",
          :pretty_name => "Search Pulsedive",
          :authors => ["Anas Ben Salah"],
          :description => "This task hits the Pulsedive API and enriches a domain",
          :references => ["https://pulsedive.com/api/"],
          :type => "discovery",
          :passive => true,
          :allowed_types => ["Domain","IpAddress","Uri"],
          :example_entities => [
            {"type" => "String", "details" => {"name" => "intrigue.io"}}
          ],
          :allowed_options => [],
          :created_types => []
        }
      end

      ## Default method, subclasses must override this
      def run
        super

        entity_name = _get_entity_name
        entity_type = _get_entity_type_string

        api_key = _get_task_config("pulsedive_api_key")

        url = "https://pulsedive.com/api/info.php?indicator=#{entity_name}&pretty=1&key=#{api_key}"

        begin

          response = http_get_body url
          result = JSON.parse(response)

          if result["risk"] == "none"
            _log "No information found about #{entity_name}"
            return
          end

          if result["risk"] == "critical"
            sev = 1
          elsif result["risk"] == "high"
            sev = 2
          elsif result["risk"] == "medium"
            sev = 3
          elsif result["risk"] == "low"
            sev = 4
          else
            sev = 5 # informational
          end

          if entity_type == "Domain"
            if result["threats"]
              result["threats"].each do |u|
                # create an issue to track this
                _create_issue({
                  name: "#{entity_name}  [Pulsedive]",
                  type: "threat_check",
                  category: "network",
                  severity: sev ,
                  status: "confirmed",
                  description: "Location: #{result["properties"]["geo"]["country"]} Threats: \n" + " #{u["name"]} category: #{u["category"]} risk level: #{u["risk"]}",
                  details: u
                })
              end
            else
              _log "No threats detected!"
            end

          elsif entity_type == "IpAddress"
            if result["threats"]
              result["threats"].each do |u|
                # create an issue to track this
                _create_issue({
                  name: "Malicious Entity Found (Pulsedive)",
                  type: "threat_check",
                  category: "network",
                  severity: sev,
                  status: "confirmed",
                  description: "Location: #{json["properties"]["geo"]["country"]} Threats: \n" + " #{u["name"]} category: #{u["category"]} risk level: #{u["risk"]}",
                  details: json
                })
              end
            end
          elsif entity_type == "Uri"
            if result["feeds"]
              result["feeds"].each do |v|
                # create an issue to track this
                _create_issue({
                  name: "Malicious Entity Found (Pulsedive)",
                  type: "threat_check",
                  category: "network",
                  severity: sev ,
                  status: "confirmed",
                  description: "Location: #{json["properties"]["geo"]["country"]} Threats: \n" + " #{v["name"]} category: #{v["category"]} risk level: #{json["risk"]}",
                  details: json
                })
              end
            end

          else
            _log_error "Unsupported entity type"
            return
          end

    if result["risk"] == "critical"
      sev = 1
    elsif result["risk"] == "high"
      sev = 2
    elsif result["risk"] == "medium"
      sev = 3
    elsif result["risk"] == "low"
      sev = 4
    else
      sev = 5 # informational
    end

    if entity_type == "Domain"
      if result["threats"]
        result["threats"].each do |u|
          # create an issue to track this
          ############################################
          ###      Old Issue                      ###
          ###########################################
          # _create_issue({
          #   name: "#{entity_name}  [Pulsedive]",
          #   type: "malicious_check",
          #   category: "network",
          #   severity: sev ,
          #   status: "confirmed",
          #   description: "Location: #{result["properties"]["geo"]["country"]} Threats: \n" + " #{u["name"]} category: #{u["category"]} risk level: #{u["risk"]}",
          #   details: u
          # })
          ############################################
          ###         New Issue                   ###
          ###########################################
          _create_linked_issue("suspicious_domain",{
            source: "Pulsdive",
            severity: sev ,
            detailed_description: "Location: #{result["properties"]["geo"]["country"]} Threats: \n" + " #{u["name"]} category: #{u["category"]} risk level: #{u["risk"]}",
            details: u
           })
        end
      else
        _log "No threats detected!"
      end
    elsif entity_type == "IpAddress"
      if result["threats"]
        result["threats"].each do |u|
          # create an issue to track this
          ############################################
          ###      Old Issue                      ###
          ###########################################
          # _create_issue({
          #   name: "Malicious Entity Found (Pulsedive)",
          #   type: "malicious_check",
          #   category: "network",
          #   severity: sev,
          #   status: "confirmed",
          #   description: "Location: #{json["properties"]["geo"]["country"]} Threats: \n" + " #{u["name"]} category: #{u["category"]} risk level: #{u["risk"]}",
          #   details: json
          # })
          ############################################
          ###         New Issue                   ###
          ###########################################
          _create_linked_issue("suspicious_ip",{
            source: "Pulsdive",
            severity: sev ,
            detailed_description: "Location: #{json["properties"]["geo"]["country"]} Threats: \n" + " #{u["name"]} category: #{u["category"]} risk level: #{u["risk"]}",
            details: json
           })
        end
      end
    elsif entity_type == "Uri"
      if result["feeds"]
        result["feeds"].each do |v|
          # # create an issue to track this
          # _create_issue({
          #   name: "Malicious Entity Found (Pulsedive)",
          #   type: "malicious_check",
          #   category: "network",
          #   severity: sev ,
          #   status: "confirmed",
          #   description: "Location: #{json["properties"]["geo"]["country"]} Threats: \n" + " #{v["name"]} category: #{v["category"]} risk level: #{json["risk"]}",
          #   details: json
          # })
          _create_linked_issue("suspicious_uri",{
            source: "Pulsdive",
            severity: sev ,
            detailed_description: "Location: #{json["properties"]["geo"]["country"]} Threats: \n" + " #{v["name"]} category: #{v["category"]} risk level: #{json["risk"]}",
            details: json
           })
        end
      end

    else
      _log_error "Unsupported entity type"
      return
    end


    rescue JSON::ParserError => e
      _log_error "unable to parse json!"
    end
  end #end run

end #end class
end
end
