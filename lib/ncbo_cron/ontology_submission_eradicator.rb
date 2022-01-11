module NcboCron
  module Models

    class OntologySubmissionEradicator
      class RemoveSubmissionFileException < StandardError
      end

      class RemoveSubmissionDataException < StandardError
      end

      def initialize()
      end

      def eradicate(ontology_acronym, submission)
        submission.bring(:submissionStatus) if submission.bring(:submissionStatus)
        if submission.archived?
          delete_submission_files ontology_acronym, submission
          delete_submission_data submission
        else
          raise RemoveSubmissionDataException, "Submission #{submission.submissionId} is not an archived submission"
        end

      end

      private
      def delete_submission_data(submission)
        begin
          submission.delete
        rescue Exception => e
          raise RemoveSubmissionDataException, e.message
        end
      end

      def delete_submission_files(ontology_acronym, submission)
        begin
          # delete the folder
          submission_dir = File.join(LinkedData.settings.repository_folder, ontology_acronym.to_s, submission.submissionId.to_s)
          FileUtils.rm_rf(submission_dir)
        rescue Exception => e
          raise RemoveSubmissionFileException, e.message
        end
      end

    end
  end
end
