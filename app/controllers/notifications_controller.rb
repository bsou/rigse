class NotificationsController < ApplicationController

  # action which triggers loading the latest learner data from the couch database
  def assessments
    db = params[:db]
    if db
      if JRUBY
        ::Assessments::LearnerDataImporter.new(db).run
      else
        # schedule the importer to run
        cmd = "::Assessments::LearnerDataImporter.new('#{db}').run"
        jobs = ::Bj.submit cmd, :tag => 'assessments_learner_data_import'
      end
    end
  end
end
