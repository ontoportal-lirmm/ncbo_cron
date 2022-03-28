module NcboCron
  module Models

    class OntologySubmissionEradicator
      class RemoveSubmissionFileException < StandardError
      end

      class RemoveSubmissionDataException < StandardError
      end

      class RemoveNotArchivedSubmissionException < StandardError
      end

      def initialize()
      end

      def eradicate(ontology_acronym, submission , force=false)
        submission.bring(:submissionStatus) if submission.bring(:submissionStatus)
        if submission.archived? || force
          delete_submission_files ontology_acronym, submission
          delete_submission_data submission
        else submission.ready?
          raise RemoveNotArchivedSubmissionException, "Submission #{submission.submissionId} is not an archived submission"
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
          FileUtils.remove_dir(submission_dir, force: true)
        rescue Exception => e
          raise RemoveSubmissionFileException, e.message
        end
      end

    end
  end
end
